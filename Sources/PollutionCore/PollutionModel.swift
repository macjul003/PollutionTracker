import Foundation

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
}
