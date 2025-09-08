# Decision Log

This file documents the key decisions we made while building **EVChargingStationsApp** and why.  
It helps reviewers and future contributors understand the rationale behind architectural and technical choices.

---

## 1. SwiftUI over UIKit
- **Decision:** Build the app entirely in **SwiftUI**.
- **Why:**  
  - Declarative and modern, aligns with Apple’s long-term direction.  
  - Natural fit for MVVM (with `@StateObject`, `@ObservedObject`, `@Published`).  
  - Handles adaptive UI (dark mode, accessibility, dynamic type) with minimal effort.  
  - UIKit would require more boilerplate for navigation, lists, and binding UI to state.
- **Benefit:** Faster iteration, cleaner code, future-proof.

---

## 2. Offline Persistence: SwiftData vs CoreData
- **Decision:** Use **SwiftData** on iOS 17+ and **CoreData** on iOS 15/16.
- **Why:**  
  - SwiftData is Apple’s new persistence layer, but only available starting iOS 17.  
  - To support older devices, CoreData is still required.  
  - Both are abstracted behind a common `PersistenceProtocol`, so ViewModels are unaware of the underlying store.
- **Benefit:** Backward compatibility + future readiness.

---

## 3. Architecture: MVVM with Dependency Injection
- **Decision:** Adopt **MVVM**, with **dependency injection** for services.
- **Why:**  
  - Keeps UI (`View`) separate from business logic (`ViewModel`).  
  - Makes ViewModels testable with injected mocks (`Service`, `Persistence`, `Location`).  
  - Avoids singletons/global state, which complicate testing and scaling.
- **Benefit:** Clear separation of concerns, better testability, and maintainability.

---

## 4. Offline-First Strategy
- **Decision:** Follow an **API → Cache → Error** strategy.
- **Why:**  
  - If online, fetch from API and update cache.  
  - If offline but cache exists, show cached results and indicate offline status.  
  - If both API and cache are unavailable, show a clear error message.  
- **Benefit:** Predictable, user-friendly experience even without stable internet.

---

## 5. Location-Based Fetching
- **Decision:** Prefer using the **user’s location** to fetch stations.
- **Why:**  
  - Charging stations are only useful if they’re nearby.  
  - Location-based results improve user relevance.  
  - If permission denied, fall back to generic (no-location) fetch.
- **Benefit:** Balances personalization with graceful fallback.

---

## 6. Network Monitoring
- **Decision:** Add a `NetworkMonitor` wrapper around `NWPathMonitor`.
- **Why:**  
  - Detects offline status proactively.  
  - Lets us avoid failed API calls and fall back immediately to cache.  
  - UI can display an “Offline” prompt clearly.
- **Benefit:** Smoother experience when connectivity is unstable.

---

## 7. Error Handling
- **Decision:** Handle errors with a layered fallback.
- **Why:**  
  - Avoids crashing or empty screens.  
  - Gives meaningful messages (“No internet”, “Unable to determine location”, etc.).  
  - Uses cache as a safety net when network fails.
- **Benefit:** Builds trust — users know why data is missing and what they can do.

---

## 8. Testing: Swift Testing over XCTest
- **Decision:** Use **Swift Testing** (`import Testing`) instead of XCTest.
- **Why:**  
  - Cleaner syntax (`#expect`) vs `XCTAssert`.  
  - Declarative style matches SwiftUI/MVVM better.  
  - Less boilerplate for grouping and running tests.
- **Benefit:** Faster to write and easier to maintain.

---

## Future Considerations
- **Pagination:** Current API supports only `maxResults`; true paging could be added if API evolves.  
- **Filters:** Filtering by connector type, power, or availability can be layered into ViewModel.  
- **Advanced Caching:** Cache eviction strategies (e.g., time-to-live) could be added.  
- **Background Refresh:** Stations could auto-refresh when network is restored.
