import Foundation

public class PollutionService {
    public init() {}
    public func fetchPollution(latitude: Double, longitude: Double) async throws -> PollutionData {
        let urlString = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(latitude)&longitude=\(longitude)&current=us_aqi,pm10,pm2_5"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PollutionResponse.self, from: data)
        
        return PollutionData(
            aqi: response.current.us_aqi ?? 0,
            pm10: response.current.pm10 ?? 0.0,
            pm2_5: response.current.pm2_5 ?? 0.0
        )
    }
}
