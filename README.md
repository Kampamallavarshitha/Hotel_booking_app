# StayScape – Hotel Booking App (Flutter)

Discover hotels, filter by what matters, check live room availability and send booking
requests. Backed by a **documented mock REST API** (see [`docs/API.md`](docs/API.md)).

## Features

| Requirement | Where |
|---|---|
| Hotel listing (image, name, location, rating, price) | `screens/explore_screen.dart`, `widgets/hotel_card.dart` |
| Search + filters (location/name, price range, rating, amenities, sort) | search bar + `widgets/filter_sheet.dart`, debounced API query |
| Hotel details (gallery, description, facilities, room types) | `screens/hotel_details_screen.dart` |
| Booking flow (date range, guests, live availability, room choice, price breakdown, guest form) | `screens/booking_screen.dart`, `providers/booking_flow_provider.dart` |
| Profile + booking history (upcoming / past / cancelled, cancel booking) | `screens/profile_screen.dart`, `screens/bookings_screen.dart` |
| Responsive UI | adaptive grid (1–3 columns), width-capped content, safe areas, scrollable forms |
| API integration | `core/api/mock_api_client.dart` behind an `ApiClient` interface |
| Validation, loading, errors | form validators, skeleton loaders, retry views, snackbars, **Simulate network errors** switch in Profile |

## Tech stack

Flutter 3.22+ · Dart 3.3+ · Provider (`ChangeNotifier`) · intl · Material 3

## Setup

This repo contains `lib/`, `test/`, `docs/` and `pubspec.yaml`. Generate the platform
folders once:

```bash
flutter create . --org com.yourname --project-name stayscape --platforms=android,ios
flutter pub get
flutter run
```

**Release APK needs internet permission** (hotel photos are loaded from Unsplash). After
`flutter create`, add this line inside `<manifest>` in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Then build the APK:

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

Run the tests: `flutter test`

## Architecture

```
UI (screens/widgets) ──► Providers (ChangeNotifier) ──► HotelRepository ──► ApiClient
                                                                              └─ MockApiClient (in-memory REST)
```

```
lib/
├─ core/            theme, formatting, validators, amenity icons
│  └─ api/          ApiClient interface, MockApiClient, seed data
├─ models/          Hotel, Room, Booking, UserProfile, HotelFilters
├─ repositories/    JSON → typed models
├─ providers/       state + business rules per feature
├─ screens/         one file per screen
└─ widgets/         reusable UI (cards, filter sheet, loading/error/empty views)
```

### Key decisions

- **Provider** – small app, simple mental model. App-wide state (hotel list, bookings,
  profile, tab index) is registered once in `main.dart`; screen-scoped state
  (`HotelDetailsProvider`, `BookingFlowProvider`) is created with the route and disposed with it.
- **Repository + `ApiClient` interface** – UI and providers never see raw JSON or the mock.
  Going live = implement one interface (see `docs/API.md`).
- **Mock API behaves like a server** – it validates input, returns 404/409/422/503,
  computes availability from existing bookings, and round-trips data through JSON so the
  parsing code is exercised exactly as it would be with a network.
- **Availability is computed server-side** and re-requested when dates or guests change; the
  provider ignores stale responses (request ids) and auto-selects a valid room.
- **Search is debounced** (400 ms) and filters are sent as query parameters, not filtered
  in the UI, so the same code works against a real backend with pagination.
- **Responsive** – `SliverGridDelegateWithMaxCrossAxisExtent` lets column count follow width;
  forms and details use `ContentWidth` to stay readable on tablets.
- **Booking = request** – new bookings start as `pending`, matching the "booking request" brief.

## Limitations / next steps

Data resets on app restart (in-memory). Next: persist with `shared_preferences`/SQLite, real
auth, pagination, payments, push notifications for confirmation.
