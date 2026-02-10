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
        } label: {
            if let data = pollutionData {
                // Determine icon based on AQI
                let iconName = getIconName(for: data.aqi)
                Image(systemName: iconName)
                Text("\(data.aqi)")
            } else {
                Image(systemName: "aqi.medium")
            }
        }
        .menuBarExtraStyle(.window) // Allows for a popover view
        .onChange(of: locationManager.location) { newLocation in
            if let _ = newLocation {
               fetchData()
            }
        }
    }
    
    private func fetchData() {
        guard let location = locationManager.location else {
            // If no location yet, maybe just wait or show error if perms denied
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
                DispatchQueue.main.async {
                    self.pollutionData = data
                    self.lastUpdated = Date()
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func getIconName(for aqi: Int) -> String {
        // SF Symbols for different levels
        // These are approximations
        switch aqi {
        case 0...50: return "aqi.low"
        case 51...100: return "aqi.medium"
        case 101...150: return "aqi.high"
        default: return "aqi.high" // Or "exclamationmark.triangle"
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
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            if let data = pollutionData {
                LinearGradient(colors: [color(for: data.color), color(for: data.color).opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color(NSColor.windowBackgroundColor)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                // Header - Added padding to prevent clipping
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
                .padding(.top, 20) // More breathing room
                .padding(.bottom, 10)
                
                Spacer()
                
                // Main Content
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
                    
                    // Footer
                    HStack {
                         Text(lastUpdated != nil ? timeString(from: lastUpdated!) : "Updating...")
                            .font(.system(size: 10, weight: .regular))
                            .opacity(0.6)
                         Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20) // Ensure footer isn't too close to edge
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
        .frame(width: 260, height: 220) // Compact size
        .foregroundColor(.white) // Always white text due to vibrant backgrounds
    }
    
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Updated \(formatter.string(from: date))"
    }

    func color(for name: String) -> Color {
        // High fidelity Apple Weather colors
        switch name {
        case "Green": return Color(red: 0.2, green: 0.7, blue: 0.3) // Healthy Green
        case "Yellow": return Color(red: 0.95, green: 0.75, blue: 0.1) // Moderate Yellow
        case "Orange": return Color(red: 1.0, green: 0.5, blue: 0.0) // Unhealthy Sensitive
        case "Red": return Color(red: 0.9, green: 0.2, blue: 0.2) // Unhealthy
        case "Purple": return Color(red: 0.6, green: 0.2, blue: 0.6) // Very Unhealthy
        case "Maroon": return Color(red: 0.4, green: 0.1, blue: 0.1) // Hazardous
        default: return Color.gray
        }
    }
    
    // helper not needed anymore as we force white text
    func textColor(for colorName: String?) -> Color {
        return .white
    }
}

