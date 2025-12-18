import Foundation

struct PollutionResponse: Decodable {
    let current: CurrentData
    
    struct CurrentData: Decodable {
        let us_aqi: Int?
        let pm10: Double?
        let pm2_5: Double?
    }
}

struct PollutionData {
    let aqi: Int
    let pm10: Double
    let pm2_5: Double
    
    // Helper to get color based on US AQI
    var color: String {
        switch aqi {
        case 0...50: return "Green"
        case 51...100: return "Yellow"
        case 101...150: return "Orange"
        case 151...200: return "Red"
        case 201...300: return "Purple"
        default: return "Maroon"
        }
    }
    
    var description: String {
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
