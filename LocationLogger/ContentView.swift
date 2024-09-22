import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
  @Binding var activityItems: [URL]
  let applicationActivities: [UIActivity]? = nil

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(
      activityItems: activityItems, applicationActivities: applicationActivities)
  }
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct RecordingView: View {
  @EnvironmentObject var locationManager: LocationManager

  @State var isPresentingAlert = false
  @State var isSharingButtonActive = true
  @State var isSharingDialogPresented = false
  @State var activityItems: [URL] = []

  var body: some View {
    VStack {
      Spacer()
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundColor(.accentColor)
      Text("緯度経度ロガー")
        .font(.title)
        .padding()
      if self.locationManager.isActive {
        Button(action: {
          self.locationManager.stop()
        }) {
          Text("ストップ")
            .padding()
            .foregroundColor(.white)
            .background(.indigo)
        }
      } else {
        Button(action: {
          self.locationManager.start()
        }) {
          Text("スタート")
            .padding()
            .foregroundColor(.white)
            .background(.indigo)
        }
      }
      Text("経過時間: \(self.locationManager.secondsElapsed)秒")
        .padding()
      Text("記録されたレコード数: \(self.locationManager.locations.count)")
        .padding()
      Spacer()
      HStack {
        Button(action: {
          self.isSharingButtonActive = false

          DispatchQueue.global(qos: .default).async {
            do {
              try self.save()
            } catch {
              fatalError("CSVファイルの作成が失敗しました: \(error)")
            }
          }
        }) {
          Text("CSVファイル出力")
            .padding()
            .foregroundColor(.white)
            .background(.indigo)
        }
        .disabled(!self.isSharingButtonActive && self.locationManager.locations.count < 1)
        Button(action: {
          self.isPresentingAlert = true
        }) {
          Text("記録を消去")
            .padding()
            .foregroundColor(.white)
            .background(.indigo)
        }
        .disabled(self.locationManager.locations.count < 1)
        .alert(
          Text("記録を消去しますか？"),
          isPresented: self.$isPresentingAlert
        ) {
          Button(role: .destructive) {
            self.locationManager.locations = []
            self.locationManager.secondsElapsed = 0
          } label: {
            Text("消去")
          }
        }
      }
      Spacer()
    }
    .sheet(isPresented: self.$isSharingDialogPresented) {
      ActivityView(activityItems: self.$activityItems)
        .onDisappear {
          self.isSharingButtonActive = true
        }
    }
  }
  func save() throws {
    if let csvFileURL = self.activityItems.first {
      try FileManager.default.removeItem(atPath: csvFileURL.path)
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMddHHmmss"
    let now = dateFormatter.string(from: Date.now)

    let fileName = "\(now)_coordinates.csv"
    let csvFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

    try self.locationManager.save(at: csvFileURL)

    DispatchQueue.main.async {
      self.activityItems = [csvFileURL]
      self.isSharingDialogPresented = true
    }
  }
}

struct NotDeterminedView: View {
  @EnvironmentObject var locationManager: LocationManager

  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundColor(.accentColor)
      Text("緯度経度ロガー")
        .font(.title)
        .padding()
      Text("記録を開始するには位置情報の取得を許可してください。")
        .padding()
      Button(action: {
        self.locationManager.requestAuthorization()
      }) {
        Text("次へ")
          .padding()
          .foregroundColor(.white)
          .background(.indigo)
      }

    }
  }
}

struct UnavailableView: View {
  var body: some View {
    VStack {
      Text("位置情報を取得できません。設定アプリを開き、再度許可してください。")
        .padding()
    }
  }
}

struct ContentView: View {
  @EnvironmentObject var locationManager: LocationManager

  var body: some View {
    VStack {
      switch self.locationManager.authorizationStatus {
      case .notDetermined:
        NotDeterminedView()
      case .authorizedAlways:
        RecordingView()
      default:
        UnavailableView()
      }
    }
  }
}
