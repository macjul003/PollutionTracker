import WidgetKit
import SwiftUI
import CoreLocation
import PollutionCore

struct Provider: TimelineProvider {
    let service = PollutionService()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), pollutionData: PollutionData(aqi: 27, pm10: 10.0, pm2_5: 5.0), cityName: "Current Location")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), pollutionData: PollutionData(aqi: 27, pm10: 10.0, pm2_5: 5.0), cityName: "Current Location")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let lastKnown = LocationManager.lastKnownLocation()
            let lat = lastKnown?.latitude ?? 13.0827
            let lon = lastKnown?.longitude ?? 80.2707
            let cityName = lastKnown?.cityName ?? "Unknown"

            var data: PollutionData? = nil
            do {
                data = try await service.fetchPollution(latitude: lat, longitude: lon)
            } catch {
                print("Widget fetch error: \(error)")
            }

            let entry = SimpleEntry(date: Date(), pollutionData: data, cityName: cityName)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800)))
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
                    .fill(LinearGradient(colors: [data.swiftUIColor, data.swiftUIColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))

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
