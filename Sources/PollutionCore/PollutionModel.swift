import Foundation
import SwiftUI

public struct PollutionResponse: Decodable {
    public let current: CurrentData
    
    public struct CurrentData: Decodable {
        public let us_aqi: Int?
        public let pm10: Double?
        public let pm2_5: Double?
    }
}

public struct PollutionData {
    public let aqi: Int
    public let pm10: Double
    public let pm2_5: Double
    
    public init(aqi: Int, pm10: Double, pm2_5: Double) {
        self.aqi = aqi
        self.pm10 = pm10
        self.pm2_5 = pm2_5
    }
    
    // Helper to get color based on US AQI
    public var color: String {
        switch aqi {
        case 0...50: return "Green"
        case 51...100: return "Yellow"
        case 101...150: return "Orange"
        case 151...200: return "Red"
        case 201...300: return "Purple"
        default: return "Maroon"
        }
    }
    
    public var description: String {
        switch aqi {
        case 0...50: return "Good"
        case 51...100: return "Moderate"
        case 101...150: return "Unhealthy for Sensitive Groups"
        case 151...200: return "Unhealthy"
        case 201...300: return "Very Unhealthy"
        default: return "Hazardous"
        }
    }

    public var swiftUIColor: Color {
        switch color {
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
