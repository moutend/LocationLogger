import SwiftUI

@main
struct LocationLoggerApp: App {
  @StateObject var locationManager = LocationManager()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(self.locationManager)
    }
  }
}
