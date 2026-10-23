# StayScape Mock API

The app talks to a **mock REST API** implemented in Dart (`lib/core/api/mock_api_client.dart`).
It behaves like a real backend: routes, query parameters, JSON envelope, validation,
HTTP-style status codes, simulated latency (700 ms) and in-memory persistence
(data resets when the app restarts).

Base path: `/` (no host – requests are handled in-process).
Seed data: `lib/core/api/mock_data.dart`.

## Response envelope

Success:

```json
{ "success": true, "data": <object | array>, "meta": { "total": 8 } }
```

Failure (thrown as `ApiException(code, message)` and shown in the UI):

| Code | Meaning                                                      |
|------|--------------------------------------------------------------|
| 404  | Route, hotel, room or booking not found                      |
| 409  | Conflict: room sold out, booking already cancelled/completed |
| 422  | Validation error (bad dates, guests, email, phone…)          |
| 503  | Simulated outage (Profile → *Simulate network errors*)       |

---

## Hotels

### `GET /hotels`
List hotel summaries (no `rooms`).

| Query       | Type   | Description                                                   |
|-------------|--------|---------------------------------------------------------------|
| `q`         | string | Matches hotel name, city or state (case-insensitive)          |
| `minPrice`  | number | Minimum "from" price per night (₹)                            |
| `maxPrice`  | number | Maximum "from" price per night (₹)                            |
| `minRating` | number | Minimum rating (0–5)                                          |
| `amenities` | string | Comma-separated; hotel must have **all** (`Pool,Spa`)         |
| `sort`      | string | `price_asc`, `price_desc`, `rating` (default: seed order)     |

```json
{
  "success": true,
  "data": [{
    "id": "h1", "name": "Azure Bay Resort", "city": "Calangute", "state": "Goa",
    "address": "Candolim Beach Road, Calangute, Goa 403516",
    "description": "…", "images": ["https://…"], "rating": 4.6, "reviewCount": 1284,
    "pricePerNight": 6200, "amenities": ["Wi-Fi", "Pool", "Spa"]
  }],
  "meta": { "total": 8 }
}
```

### `GET /hotels/{id}`
Full hotel including `rooms`.

```json
{
  "success": true,
  "data": {
    "id": "h1", "name": "Azure Bay Resort", "…": "…",
    "rooms": [{
      "id": "h1r1", "name": "Garden View Room", "description": "…",
      "pricePerNight": 6200, "capacity": 2, "bed": "1 Queen bed",
      "sizeSqm": 28, "totalRooms": 6, "image": "https://…"
    }]
  }
}
```
Errors: `404` unknown id.

### `GET /hotels/{id}/availability`

| Query      | Type       | Description               |
|------------|------------|---------------------------|
| `checkIn`  | YYYY-MM-DD | Required, not in the past |
| `checkOut` | YYYY-MM-DD | Required, after `checkIn` |
| `guests`   | int        | Optional, default 1       |

Each room gets an `available` count:
`totalRooms − simulated demand − overlapping pending/confirmed bookings`.
Simulated demand is deterministic per room + check-in day so some dates look busy
and the *sold out* state can be demonstrated.

```json
{
  "success": true,
  "data": {
    "hotelId": "h1", "checkIn": "2026-11-01", "checkOut": "2026-11-03",
    "guests": 2, "nights": 2,
    "rooms": [{ "id": "h1r1", "…": "…", "available": 3 }]
  }
}
```
Errors: `404` unknown hotel, `422` invalid dates.

---

## Bookings

### `GET /bookings`
All bookings, newest first.

### `POST /bookings`
Creates a booking **request** with status `pending`.

```json
{
  "hotelId": "h1", "roomId": "h1r2",
  "checkIn": "2026-11-01", "checkOut": "2026-11-03",
  "guests": 2,
  "guestName": "Varshitha Kampalla", "email": "varshitha@example.com",
  "phone": "9876543210", "notes": "Late check-in"
}
```

Response (`data`):

```json
{
  "id": "BK1003", "hotelId": "h1", "hotelName": "Azure Bay Resort",
  "hotelImage": "https://…", "city": "Calangute",
  "roomId": "h1r2", "roomName": "Sea View Deluxe",
  "checkIn": "2026-11-01", "checkOut": "2026-11-03", "nights": 2, "guests": 2,
  "guestName": "…", "email": "…", "phone": "…", "notes": "Late check-in",
  "subtotal": 17800, "taxes": 2136, "total": 19936,
  "status": "pending", "createdAt": "2026-10-23T10:15:00.000"
}
```

Pricing: `subtotal = pricePerNight × nights`, `taxes = round(subtotal × 12%)`.

Validation: all fields except `notes` required (`422`); guests ≤ room capacity (`422`);
valid email / 10-digit Indian mobile starting 6–9 (`422`); dates valid (`422`);
room available for the whole stay (`409`).

### `POST /bookings/{id}/cancel`
Sets status to `cancelled`. Errors: `404` unknown id; `409` already cancelled or completed.

Statuses: `pending` → `confirmed` (set by hotel in a real system) → `completed`; or `cancelled`.

---

## Profile

### `GET /profile`
```json
{ "success": true, "data": { "name": "Varshitha Kampalla", "email": "varshitha@example.com", "phone": "9876543210" } }
```

### `PUT /profile`
Body: `{ "name", "email", "phone" }` – same validation as the booking form (`422` on failure).

---

## Moving to a real backend

1. Implement `ApiClient` (`lib/core/api/api_client.dart`) with `package:http` or `dio`,
   mapping non-2xx responses to `ApiException`.
2. In `lib/main.dart`, replace `MockApiClient.instance` with your client.
3. Keep the same JSON shape as above; repository, providers and UI need no changes.
