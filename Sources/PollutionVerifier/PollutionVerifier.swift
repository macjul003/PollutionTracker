import Foundation
import PollutionCore

@main
struct PollutionVerifier {
    static func main() async {
        print("--- POLLUTION TRACKER VERIFICATION TOOL ---")
        
        // 1. Verify Logic
        print("\n[1] Verifying Logic...")
        let testData = PollutionData(aqi: 55, pm10: 10, pm2_5: 5)
        if testData.color == "Yellow" && testData.description == "Moderate" {
            print("✅ Logic Check Passed")
        } else {
            print("❌ Logic Check Failed")
        }
        
        // 2. Verify Open-Meteo API
        print("\n[2] Verifying Open-Meteo API (Chennai)...")
        let service = PollutionService()
        do {
            let data = try await service.fetchPollution(latitude: 13.0827, longitude: 80.2707)
            print("✅ Fetch Success: AQI \(data.aqi) (\(data.description))")
        } catch {
            print("❌ Fetch Failed: \(error)")
        }
        
        // 3. Verify Comparison (Stub)
        print("\n[3] Verifying Comparison Capabilities...")
        let waqiService = AlternativePollutionService()
        // Stub check - just checking if we can instantiate and usage instructions are clear
        print("ℹ️  Alternative Service instantiated.")
        print("⚠️  To run full comparison, a WAQI token is needed in the source code.")
        
        print("\n-------------------------------------------")
        print("Verification Complete.")
    }
}
