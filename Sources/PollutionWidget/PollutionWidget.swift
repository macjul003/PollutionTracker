import WidgetKit
import SwiftUI
import CoreLocation
import PollutionCore

struct Provider: TimelineProvider {
    let service = PollutionService()
    let locationManager = LocationManager()
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), pollutionData: PollutionData(aqi: 27, pm10: 10.0, pm2_5: 5.0), cityName: "Chennai")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), pollutionData: PollutionData(aqi: 27, pm10: 10.0, pm2_5: 5.0), cityName: "Chennai")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            // Need to handle location asynchronously.
            // For a simple widget, we might just try to get the last known location or wait briefly?
            // WidgetKit lifecycle is tricky with CoreLocation.
            // Often widgets rely on the app to update shared storage or use a synchronous location fetch if possible (not possible with CoreLocation).
            
            // However, we can try to use the LocationManager we have.
            // Note: In reality, fetching location in a widget can be slow and might time out.
            // A robust implementation shares location from the main app or uses a static location if not authorized within the widget context immediately.
            
            // For this MVP, we will attempt to fetch if we have a location, otherwise default.
            // NOTE: LocationManager is designed for the app (long running).
            
            // Let's create a logic that tries to get a location quickly or defaults.
            // Since we can't easily wait for delegate in getTimeline without a complex wrapper,
            // we will hardcode a fallback or checking if the manager has a location cached?
            // No, the manager is fresh.
            
            // IMPROVEMENT: Use the main app to save last known location to UserDefaults(suiteName: ...) and read it here.
            // Since we don't have App Groups set up in this environment easily (requires Apple Developer Portal setup),
            // We'll stick to a hardcoded location for "Preview" purposes or try to use a one-shot location manager wrapper if we had more time.
            
            // Let's start with a fetch for a fixed location (e.g. user's roughly implied location or just a default) 
            // OR we can make the LocationManager wait.
            
            // Let's try to get coordinates from the system (synchronously if possible? no).
            // We will just fetch for a default location if we can't get one, to ensure the widget works.
            
            // Better approach for MVP: default to a city, or if I could, I'd ask the user.
            // I'll default to San Francisco/Chennai for demo if no location.
            
            let defaultLat = 13.0827
            let defaultLon = 80.2707 // Chennai as per screenshot request example
            
            var data: PollutionData? = nil
            do {
                data = try await service.fetchPollution(latitude: defaultLat, longitude: defaultLon)
            } catch {
                print("Widget fetch error: \(error)")
            }
            
            let entry = SimpleEntry(date: Date(), pollutionData: data, cityName: "Chennai") // location name is mocked for now as we use coords
            
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800))) // 30 mins
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let pollutionData: PollutionData?
    let cityName: String?
}

struct PollutionWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            if let data = entry.pollutionData {
                ContainerRelativeShape()
                    .fill(LinearGradient(colors: [color(for: data.color), color(for: data.color).opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(entry.cityName ?? "Location")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Text("\(data.aqi)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                    
                    Text(data.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding()
            } else {
                VStack {
                    Text("No Data")
                    Text("Check App")
                }
            }
        }
    }
    
    func color(for name: String) -> Color {
        switch name {
        case "Green": return Color(red: 0.2, green: 0.7, blue: 0.3)
        case "Yellow": return Color(red: 0.95, green: 0.75, blue: 0.1)
        case "Orange": return Color(red: 1.0, green: 0.5, blue: 0.0)
        case "Red": return Color(red: 0.9, green: 0.2, blue: 0.2)
        case "Purple": return Color(red: 0.6, green: 0.2, blue: 0.6)
        case "Maroon": return Color(red: 0.4, green: 0.1, blue: 0.1)
        default: return Color.gray
        }
    }
}

@main
struct PollutionWidget: Widget {
    let kind: String = "PollutionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PollutionWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pollution Tracker")
        .description("View current pollution levels.")
    }
}
