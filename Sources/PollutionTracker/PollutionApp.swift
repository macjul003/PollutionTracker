import SwiftUI
import CoreLocation
import PollutionCore

@main
struct PollutionApp: App {
    @StateObject private var locationManager = LocationManager()
    @State private var pollutionData: PollutionData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastUpdated: Date?

    private let service = PollutionService()

    private let timer = Timer.publish(every: 1800, on: .main, in: .common).autoconnect()
    private let retryTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let bundleMonitor = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    init() {
        moveToApplicationsIfNeeded()
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

    var body: some Scene {
        MenuBarExtra {
            PollutionView(pollutionData: pollutionData, isLoading: isLoading, errorMessage: errorMessage, cityName: locationManager.cityName, location: locationManager.location, lastUpdated: lastUpdated, statusMessage: locationManager.statusMessage, onRefresh: {
                locationManager.start()
                fetchData()
            })
                .onAppear {
                    locationManager.requestPermission()
                    locationManager.start()
                }
                .onReceive(timer) { _ in
                    fetchData()
                }
                .onReceive(retryTimer) { _ in
                    if errorMessage != nil {
                        fetchData()
                    }
                }
                .onReceive(bundleMonitor) { _ in
                    checkBundleExists()
                }
        } label: {
            if let data = pollutionData {
                let iconName = getIconName(for: data.aqi)
                Image(systemName: iconName)
                Text("\(data.aqi)")
            } else {
                Image(systemName: "aqi.medium")
            }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: locationManager.location) { newLocation in
            if newLocation != nil {
               fetchData()
            }
        }
    }

    @MainActor
    private func fetchData() {
        guard let location = locationManager.location else {
            if locationManager.authorizationStatus == .denied {
                errorMessage = "Location access denied. Please enable in Settings."
            }
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let data = try await service.fetchPollution(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                self.pollutionData = data
                self.lastUpdated = Date()
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func checkBundleExists() {
        let bundlePath = Bundle.main.bundlePath
        if !FileManager.default.fileExists(atPath: bundlePath) {
            let alert = NSAlert()
            alert.messageText = "PollutionTracker has been moved or deleted"
            alert.informativeText = "The app can no longer run because it has been moved to the Bin or deleted. The app will now quit."
            alert.addButton(withTitle: "Quit")
            alert.alertStyle = .critical
            alert.runModal()
            NSApplication.shared.terminate(nil)
        }
    }

    private func getIconName(for aqi: Int) -> String {
        switch aqi {
        case 0...50: return "aqi.low"
        case 51...100: return "aqi.medium"
        case 101...150: return "aqi.high"
        default: return "aqi.high"
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
    let onRefresh: () -> Void

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let data = pollutionData {
                LinearGradient(colors: [data.swiftUIColor, data.swiftUIColor.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color(NSColor.windowBackgroundColor)
                    .edgesIgnoringSafeArea(.all)
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cityName ?? "Current Location")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .shadow(radius: 1)
                        Text("Air Quality")
                            .font(.system(size: 10, weight: .medium))
                            .opacity(0.8)
                    }
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Button(action: onRefresh) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                                .opacity(0.6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 10)

                Spacer()

                if let data = pollutionData {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: -4) {
                            Text("\(data.aqi)")
                                .font(.system(size: 48, weight: .light, design: .rounded))
                                .shadow(radius: 2)
                            Text(data.description)
                                .font(.system(size: 16, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    Spacer()

                    HStack {
                         Text(lastUpdated != nil ? "Updated \(Self.timeFormatter.string(from: lastUpdated!))" : "Updating...")
                            .font(.system(size: 10, weight: .regular))
                            .opacity(0.6)
                         Spacer()
                         Button(action: {
                             NSApplication.shared.terminate(nil)
                         }) {
                             Image(systemName: "power")
                                 .font(.system(size: 10))
                                 .opacity(0.6)
                         }
                         .buttonStyle(.plain)
                         .help("Quit PollutionTracker")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                } else if let error = errorMessage {
                    VStack(alignment: .leading) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        Text(error)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                } else {
                     Text("Waiting: \(statusMessage)")
                        .font(.caption)
                        .padding(16)
                        .opacity(0.6)
                }
            }
        }
        .frame(width: 260, height: 220)
        .foregroundColor(.white)
    }
}
