import Combine
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
  private let manager = CLLocationManager()
  private var timer: Timer? = nil

  @Published var locations: [CLLocation] = []
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
  @Published var isActive = false
  @Published var secondsElapsed = 0

  override init() {
    super.init()

    self.manager.delegate = self
    self.manager.distanceFilter = kCLDistanceFilterNone
    self.manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation

    DispatchQueue.main.async {
      self.authorizationStatus = self.manager.authorizationStatus
    }
  }
  func requestAuthorization() {
    self.manager.requestAlwaysAuthorization()
  }
  func start() {
    if self.isActive {
      return
    }
    DispatchQueue.main.async {
      self.isActive = true
    }

    self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
      DispatchQueue.main.async {
        self.secondsElapsed += 1
      }
    }

    self.manager.startUpdatingLocation()
  }
  func stop() {
    if !self.isActive {
      return
    }
    DispatchQueue.main.async {
      self.isActive = false
    }

    if let timer = self.timer {
      timer.invalidate()
    }

    self.timer = nil
    self.manager.stopUpdatingLocation()
  }
  func save(at outputFileURL: URL) throws {
    var lines = "Date,Latitude,Longitude\n"

    for location in self.locations {
      let unixTimestamp = location.timestamp.timeIntervalSince1970
      let line = String(
        format: "%f,%f,%f\n",
        unixTimestamp, location.coordinate.latitude, location.coordinate.longitude
      )

      lines += line
    }

    try lines.write(to: outputFileURL, atomically: true, encoding: .utf8)
  }
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    DispatchQueue.main.async {
      self.authorizationStatus = manager.authorizationStatus
    }
  }
  func locationManager(_ manager: CLLocationManager, didUpdateLocations: [CLLocation]) {
    DispatchQueue.main.async {
      self.locations += didUpdateLocations
    }
  }
}
