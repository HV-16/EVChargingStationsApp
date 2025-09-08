# EVChargingStationsApp

An iOS app that displays nearby electric vehicle charging stations using the [OpenChargeMap API](https://openchargemap.org/).  
The app supports both online fetching and offline caching of stations.

---

## 🏗 Architecture Overview

- **SwiftUI-first UI**: Modern declarative UI framework with navigation and list/detail views.
- **MVVM pattern**: Separation of concerns with `View`, `ViewModel`, and `Service` layers.
- **Dependency Injection**: Services and persistence are injected, enabling mocking for tests.
- **Persistence**:
  - iOS 17+: [SwiftData](https://developer.apple.com/xcode/swiftdata/) for offline storage.
  - iOS 15/16: CoreData (`.xcdatamodeld`) for backwards compatibility.
- **Networking**:
  - `NetworkClient` built on `URLSession` with async/await.
  - Typed `NetworkRequest` and `NetworkError` handling.
- **Location**:
  - `LocationManager` using `CoreLocation` for one-shot location requests.
  - Falls back gracefully when location permission is denied.
- **Offline mode**:
  - `NetworkMonitor` detects connectivity.
  - Cached results displayed when offline.
- **Testing**:
  - Uses Swift’s new `Testing` framework instead of XCTest.
  - Unit tests for `OpenChargeMapService` and `ChargingStationsViewModel` with mocks.

---

## ⚙️ Setup Instructions

### 1. Clone the repository
```bash
git clone https://github.com/HV-16/EVChargingStationsApp.git
cd EVChargingStationsApp
```

### 2. Open the project
Open `EVChargingStationsApp.xcodeproj` in **Xcode 15 or later**.

### 3. Deployment target
- The app supports **iOS 15+**.  
  - On **iOS 17+**, SwiftData is used for persistence.  
  - On **iOS 15/16**, CoreData is used for persistence.  

### 4. Configure app capabilities
Ensure **Location Services** are enabled for the app in Xcode → *Signing & Capabilities*.

### 5. Add Info.plist keys
Add the following entries to **Info.plist** (already included in the repo, but verify):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to find nearby charging stations.</string>
```

### 6. Build & Run
- Select a simulator or real device.  
- Press **Run ▶** in Xcode.  
- The app will:
  - Request location permission.  
  - Fetch nearby charging stations using OpenChargeMap API.  
  - Cache results locally (SwiftData/CoreData depending on iOS version).  
  - Display cached results when offline.  

### 7. Running Unit Tests
- Open the **Test navigator** in Xcode (⌘6).  
- Run all tests.  
- Tests are written using Swift’s `Testing` framework.  
- Includes unit tests for:
  - `OpenChargeMapService`  
  - `ChargingStationsViewModel`  

---

## 📄 Decision Log

Detailed rationale behind technical decisions is documented in  
👉 [DECISION_LOG.md](https://github.com/HV-16/EVChargingStationsApp/blob/main/EVChargingStationsApp/Docs/DECISION_LOG.md)

---

## 📌 Notes

- This project is open source and available at:  
  [https://github.com/HV-16/EVChargingStationsApp.git](https://github.com/HV-16/EVChargingStationsApp.git)  
- API key for OpenChargeMap is embedded for development use.  
  For production, configure your own API key and inject via environment/configuration.  
