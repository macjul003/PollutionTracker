import SwiftUI
import CoreLocation

@main
struct PollutionApp: App {
    @StateObject private var locationManager = LocationManager()
    @State private var pollutionData: PollutionData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let service = PollutionService()
    
    var body: some Scene {
        MenuBarExtra {
            PollutionView(pollutionData: pollutionData, isLoading: isLoading, errorMessage: errorMessage, cityName: locationManager.cityName, onRefresh: fetchData)
                .onAppear {
                    locationManager.requestPermission()
                    locationManager.start()
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
    let onRefresh: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background Color
            if let data = pollutionData {
                color(for: data.color)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color(NSColor.windowBackgroundColor)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    Text("AIR QUALITY")
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .textCase(.uppercase)
                        .opacity(0.8)
                    
                    Spacer()
                    
                    // Dot pattern icon equivalent
                    Image(systemName: "aqi.medium")
                        .font(.system(size: 20))
                        .opacity(0.6)
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Main Content
                if let data = pollutionData {
                    VStack(alignment: .leading, spacing: -2) {
                        Text(data.description)
                            .font(.system(size: 34, weight: .bold, design: .default))
                            .layoutPriority(1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("\(data.aqi)")
                            .font(.system(size: 52, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                } else if isLoading {
                    ProgressView()
                        .padding(.leading, 16)
                } else if let error = errorMessage {
                   Text("Error")
                      .font(.headline)
                      .padding(.leading, 16)
                }
                
                Spacer()
                
                // Footer
                VStack(alignment: .leading, spacing: 2) {
                    if let city = cityName {
                         Text(city)
                            .font(.system(size: 15, weight: .regular))
                    } else {
                        Text("Current Location")
                             .font(.system(size: 15, weight: .regular))
                    }
                    
                    Text("Updated just now")
                        .font(.system(size: 11, weight: .regular))
                        .opacity(0.6)
                }
                .padding(.bottom, 16)
                .padding(.horizontal, 16)
            }
        }
        .frame(width: 220, height: 220) // Square shape matching reference
        .foregroundColor(textColor(for: pollutionData?.color))
    }
    
    func color(for name: String) -> Color {
        // Colors matching Apple Maps style (Vibrant/Light)
        switch name {
        case "Green": return Color(red: 0.6, green: 0.9, blue: 0.4) // Lighter Green
        case "Yellow": return Color(red: 1.0, green: 0.85, blue: 0.3) // Map Yellow
        case "Orange": return Color(red: 1.0, green: 0.6, blue: 0.2)
        case "Red": return Color(red: 1.0, green: 0.25, blue: 0.25)
        case "Purple": return Color(red: 0.8, green: 0.5, blue: 0.8)
        case "Maroon": return Color(red: 0.5, green: 0.0, blue: 0.0) // Dark
        default: return .gray
        }
    }
    
    func textColor(for colorName: String?) -> Color {
        guard let name = colorName else { return .primary }
        // Black text for light backgrounds, White for dark
        switch name {
        case "Green", "Yellow", "Orange": return .black.opacity(0.85)
        default: return .white
        }
    }
}

// Removing explicit DetailCard as we integrated it into the main view logic

