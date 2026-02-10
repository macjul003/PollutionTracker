import Foundation

public struct WAQIResponse: Decodable {
    public let status: String
    public let data: WAQIData
    
    public struct WAQIData: Decodable {
        public let aqi: Int
    }
}

public class AlternativePollutionService {
    public init() {}
    
    public func fetchWAQI(latitude: Double, longitude: Double, token: String) async throws -> Int {
        let urlString = "https://api.waqi.info/feed/geo:\(latitude);\(longitude)/?token=\(token)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        // print(String(data: data, encoding: .utf8)!) // Debugging
        let response = try JSONDecoder().decode(WAQIResponse.self, from: data)
        
        if response.status != "ok" {
            throw URLError(.cannotParseResponse)
        }
        
        return response.data.aqi
    }
}
