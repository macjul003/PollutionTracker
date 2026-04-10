import SwiftUI
import CoreLocation
import PollutionCore
import Combine

// MARK: - View Model

class PollutionViewModel: ObservableObject {
    @Published var pollutionData: PollutionData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?

    let locationManager = LocationManager()
    private let service = PollutionService()

    init() {}

    @MainActor
    func fetchData() {
        let lat: Double
        let lon: Double

        if let location = locationManager.location {
            lat = location.coordinate.latitude
            lon = location.coordinate.longitude
        } else if let last = LocationManager.lastKnownLocation() {
            lat = last.latitude
            lon = last.longitude
        } else {
            if locationManager.authorizationStatus == .denied {
                errorMessage = "Location access denied. Please enable in Settings."
            }
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let data = try await service.fetchPollution(latitude: lat, longitude: lon)
                pollutionData = data
                lastUpdated = Date()
                isLoading = false
            } catch {
                errorMessage = "Failed to load: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// MARK: - App Entry Point

@main
struct PollutionApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var hostingController: NSHostingController<PollutionRootView>!
    private var viewModel: PollutionViewModel!
    private var pollTimer: Timer?
    private var retryTimer: Timer?
    private var bundleTimer: Timer?
    private var startupTimer: Timer?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        moveToApplicationsIfNeeded()

        // Initialize AFTER app is fully launched so the permission dialog can appear
        viewModel = PollutionViewModel()

        hostingController = NSHostingController(rootView: PollutionRootView(viewModel: viewModel))

        popover = NSPopover()
        popover.contentViewController = hostingController
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 260, height: 190)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "aqi.medium", accessibilityDescription: nil)
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.viewModel.fetchData() }
        }
        retryTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if self?.viewModel.errorMessage != nil { self?.viewModel.fetchData() }
            }
        }
        bundleTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.checkBundleExists()
        }

        // Attempt first fetch every 3s until we have data (gives location time to resolve)
        startupTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.viewModel.pollutionData != nil {
                self.startupTimer?.invalidate()
                self.startupTimer = nil
            } else {
                Task { @MainActor in self.viewModel.fetchData() }
            }
        }
        // Also try immediately
        Task { @MainActor in viewModel.fetchData() }

        viewModel.$pollutionData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.updateStatusItem(data: data)
                self?.popover.contentSize = NSSize(width: 260, height: 190)
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem(data: PollutionData?) {
        guard let button = statusItem?.button else { return }
        if let data = data {
            let icon: String
            switch data.aqi {
            case 0...50: icon = "aqi.low"
            case 51...100: icon = "aqi.medium"
            default: icon = "aqi.high"
            }
            button.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
            button.imagePosition = .imageLeft
            button.title = " \(data.aqi)"
        } else {
            button.image = NSImage(systemSymbolName: "aqi.medium", accessibilityDescription: nil)
            button.title = ""
        }
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            if popover.isShown {
                closePopover()
            } else {
                popover.contentSize = NSSize(width: 260, height: 190)
                popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
                eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                    self?.closePopover()
                }
            }
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let locationItem = NSMenuItem(title: "Location Settings…", action: #selector(openLocationSettings), keyEquivalent: "")
        locationItem.target = self
        menu.addItem(locationItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit PollutionTracker", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openLocationSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
    }

    private func checkBundleExists() {
        let bundlePath = Bundle.main.bundlePath
        guard !FileManager.default.fileExists(atPath: bundlePath) else { return }
        let alert = NSAlert()
        alert.messageText = "PollutionTracker has been moved or deleted"
        alert.informativeText = "The app can no longer run. It will now quit."
        alert.addButton(withTitle: "Quit")
        alert.alertStyle = .critical
        alert.runModal()
        NSApplication.shared.terminate(nil)
    }

    private func moveToApplicationsIfNeeded() {
        let bundlePath = Bundle.main.bundlePath
        let applicationsPath = "/Applications/PollutionTracker.app"
        guard !bundlePath.hasPrefix("/Applications") else { return }

        let alert = NSAlert()
        alert.messageText = "Move to Applications?"
        alert.informativeText = "PollutionTracker works best when installed in your Applications folder. Would you like to move it there now?"
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Not Now")
        alert.alertStyle = .informational

        if alert.runModal() == .alertFirstButtonReturn {
            do {
                if FileManager.default.fileExists(atPath: applicationsPath) {
                    try FileManager.default.removeItem(atPath: applicationsPath)
                }
                try FileManager.default.copyItem(atPath: bundlePath, toPath: applicationsPath)
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                task.arguments = [applicationsPath]
                try task.run()
                NSApplication.shared.terminate(nil)
            } catch {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Could not move app"
                errorAlert.informativeText = error.localizedDescription
                errorAlert.runModal()
            }
        }
    }
}

// MARK: - Root View

struct PollutionRootView: View {
    @ObservedObject var viewModel: PollutionViewModel
    @ObservedObject var locationManager: LocationManager

    init(viewModel: PollutionViewModel) {
        self.viewModel = viewModel
        self.locationManager = viewModel.locationManager
    }

    var body: some View {
        PollutionView(
            pollutionData: viewModel.pollutionData,
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            cityName: locationManager.cityName,
            location: locationManager.location,
            lastUpdated: viewModel.lastUpdated,
            statusMessage: locationManager.statusMessage,
            authorizationStatus: locationManager.authorizationStatus,
            onRefresh: {
                locationManager.start()
                viewModel.fetchData()
            },
            onRequestPermission: {
                locationManager.requestPermission()
            }
        )
        .onChange(of: locationManager.location) { newLocation in
            if newLocation != nil && viewModel.pollutionData == nil && !viewModel.isLoading {
                viewModel.fetchData()
            }
        }
    }
}

struct PollutionView: View {
    let pollutionData: PollutionData?
    let isLoading: Bool
    let errorMessage: String?
    let cityName: String?
    let location: CLLocation?
    let lastUpdated: Date?
    let statusMessage: String
    let authorizationStatus: CLAuthorizationStatus?
    let onRefresh: () -> Void
    let onRequestPermission: () -> Void

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let data = pollutionData {
                LinearGradient(
                    colors: [data.swiftUIColor, data.swiftUIColor.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
            } else {
                Color(NSColor.windowBackgroundColor)
                    .edgesIgnoringSafeArea(.all)
            }

            VStack(alignment: .leading, spacing: 0) {

                // HEADER
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cityName ?? "Current Location")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Air Quality")
                            .font(.system(size: 11, weight: .regular))
                            .opacity(0.6)
                    }
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 14, height: 14)
                    } else {
                        Button(action: onRefresh) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .medium))
                                .opacity(0.5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

                if let data = pollutionData {

                    // AQI NUMBER + DESCRIPTION
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(data.aqi)")
                            .font(.system(size: 52, weight: .thin, design: .rounded))
                            .tracking(-1)
                        Text(data.description)
                            .font(.system(size: 13, weight: .medium))
                            .opacity(0.85)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)

                    Spacer(minLength: 0)

                    // FOOTER
                    HStack(alignment: .center) {
                        Text(lastUpdated != nil ? "Updated \(Self.timeFormatter.string(from: lastUpdated!))" : "Updating…")
                            .font(.system(size: 10, weight: .regular))
                            .opacity(0.5)
                        Spacer()
                        Button(action: { NSApplication.shared.terminate(nil) }) {
                            Image(systemName: "power")
                                .font(.system(size: 10, weight: .medium))
                                .opacity(0.5)
                        }
                        .buttonStyle(.plain)
                        .help("Quit PollutionTracker")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 10)

                } else if let error = errorMessage {
                    Spacer()
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 15))
                        Text(error)
                            .font(.system(size: 11))
                            .opacity(0.85)
                            .multilineTextAlignment(.leading)
                        locationPermissionButton
                    }
                    .padding(.horizontal, 16)
                    Spacer()
                } else {
                    Spacer()
                    VStack(alignment: .leading, spacing: 10) {
                        Text(statusMessage)
                            .font(.system(size: 11))
                            .opacity(0.5)
                        locationPermissionButton
                    }
                    .padding(.horizontal, 16)
                    Spacer()
                }
            }
        }
        .frame(width: 260, height: 190)
        .foregroundColor(.white)
    }

    @ViewBuilder
    private var locationPermissionButton: some View {
        switch authorizationStatus {
        case .notDetermined, .none:
            Button(action: onRequestPermission) {
                Label("Allow Location Access", systemImage: "location.fill")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        case .denied, .restricted:
            Button(action: {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
            }) {
                Label("Open Location Settings", systemImage: "gear")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        default:
            EmptyView()
        }
    }
}
