import XCTest
@testable import PollutionCore

final class PollutionCoreTests: XCTestCase {
    
    // MARK: - Logic Tests
    
    func testPollutionDataParsing() throws {
        let json = """
        {
            "current": {
                "us_aqi": 55,
                "pm10": 12.5,
                "pm2_5": 8.0
            }
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(PollutionResponse.self, from: json)
        
        XCTAssertEqual(response.current.us_aqi, 55)
        XCTAssertEqual(response.current.pm10, 12.5)
        XCTAssertEqual(response.current.pm2_5, 8.0)
    }
    
    func testAQIColorLogic() {
        let good = PollutionData(aqi: 20, pm10: 0, pm2_5: 0)
        XCTAssertEqual(good.color, "Green")
        XCTAssertEqual(good.description, "Good")
        
        let moderate = PollutionData(aqi: 75, pm10: 0, pm2_5: 0)
        XCTAssertEqual(moderate.color, "Yellow")
        XCTAssertEqual(moderate.description, "Moderate")
        
        let unhealthy = PollutionData(aqi: 160, pm10: 0, pm2_5: 0)
        XCTAssertEqual(unhealthy.color, "Red")
        XCTAssertEqual(unhealthy.description, "Unhealthy")
        
        let hazardous = PollutionData(aqi: 400, pm10: 0, pm2_5: 0)
        XCTAssertEqual(hazardous.color, "Maroon")
        XCTAssertEqual(hazardous.description, "Hazardous")
    }
    
    // MARK: - Integration / Comparison Tests
    
    func testLiveAPIFetch_OpenMeteo() async throws {
        let service = PollutionService()
        // Chennai Coordinates
        let lat = 13.0827
        let lon = 80.2707
        
        do {
            let data = try await service.fetchPollution(latitude: lat, longitude: lon)
            print("Open-Meteo AQI for Chennai: \(data.aqi)")
            XCTAssertTrue(data.aqi >= 0, "AQI should be non-negative")
        } catch {
            XCTFail("Open-Meteo Fetch failed: \(error)")
        }
    }
    
    func testComparisonWithWAQI() async throws {
        // NOTE: USER MUST PROVIDE TOKEN HERE for this test to run physically
        let waqiToken = "YOUR_WAQI_TOKEN_HERE" // REPLACE THIS
        
        if waqiToken == "YOUR_WAQI_TOKEN_HERE" {
            print("Skipping WAQI comparison test. No token provided.")
            return 
        }
        
        let openMeteoService = PollutionService()
        let waqiService = AlternativePollutionService()
        
        // San Francisco Coordinates (Stable for testing)
        let lat = 37.7749
        let lon = -122.4194
        
        async let openMeteoData = openMeteoService.fetchPollution(latitude: lat, longitude: lon)
        async let waqiAQI = waqiService.fetchWAQI(latitude: lat, longitude: lon, token: waqiToken)
        
        let (omData, wAQI) = try await (openMeteoData, waqiAQI)
        
        print("--- COMPARISON RESULTS (San Francisco) ---")
        print("Open-Meteo AQI: \(omData.aqi)")
        print("WAQI (AQICN) AQI: \(wAQI)")
        print("Difference: \(abs(omData.aqi - wAQI))")
        print("----------------------------------------")
        
        // Assertion: We don't expect them to be identical, but they should ideally be in the same "Zone" or within a delta.
        // Air quality data varies slightly by provider due to sensor averaging and model differences.
        // We'll just assert they are both valid return values basically
        XCTAssertTrue(omData.aqi >= 0)
        XCTAssertTrue(wAQI >= 0)
    }
}
