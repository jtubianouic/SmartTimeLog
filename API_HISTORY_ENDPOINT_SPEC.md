# Mobile Attendance History API Specification

## Overview

Add an authenticated, read-only endpoint for retrieving an employee's attendance history:

```http
GET /api/mobile/history?from=2026-09-01&to=2026-09-22&limit=20&cursor=<opaque-cursor>
Authorization: Bearer <access-token>
Accept: application/json
```

The `GET` request has no JSON body. The employee must be identified from the bearer token. Do not accept an `employeeId` from the mobile client, because that could expose another employee's attendance records.

## Query Parameters

| Parameter | Required | Description |
|---|---:|---|
| `from` | No | Inclusive date in `YYYY-MM-DD`; default: 30 days ago |
| `to` | No | Inclusive date in `YYYY-MM-DD`; default: today |
| `limit` | No | Number of attendance records; default: `20`, maximum: `50` |
| `cursor` | No | Opaque cursor returned by the previous response |

Recommended validation rules:

- Reject malformed dates.
- Reject a `from` date later than the `to` date.
- Limit the maximum date range, such as 90 days.
- Reject limits below 1 or above 50.
- Reject invalid or tampered cursors.
- Use ISO-8601 UTC timestamps in responses.
- Include the reporting timezone so the mobile app can display local times correctly.

## Successful Response

Group raw `employee_timelogs` rows into one attendance record per shift or attendance date. A grouped response is easier for the mobile app to display than an unstructured event list.

```json
{
  "ok": true,
  "timezone": "Asia/Manila",
  "records": [
    {
      "date": "2026-09-22",
      "status": "completed",
      "clockInAt": "2026-09-22T01:00:00.000Z",
      "clockOutAt": "2026-09-22T09:15:00.000Z",
      "clockedInDurationSeconds": 29700,
      "breakDurationSeconds": 3600,
      "activeWorkDurationSeconds": 26100,
      "events": [
        {
          "timelogId": 101,
          "type": "clock_in",
          "timestamp": "2026-09-22T01:00:00.000Z",
          "location": {
            "latitude": 7.0731,
            "longitude": 125.6128
          }
        },
        {
          "timelogId": 102,
          "type": "break",
          "timestamp": "2026-09-22T04:00:00.000Z",
          "location": {
            "latitude": 7.0731,
            "longitude": 125.6128
          }
        },
        {
          "timelogId": 103,
          "type": "break_end",
          "timestamp": "2026-09-22T05:00:00.000Z",
          "location": {
            "latitude": 7.0731,
            "longitude": 125.6128
          }
        },
        {
          "timelogId": 104,
          "type": "clock_out",
          "timestamp": "2026-09-22T09:15:00.000Z",
          "location": {
            "latitude": 7.0731,
            "longitude": 125.6128
          }
        }
      ],
      "workLog": {
        "employeeInput": "Activities and notes: Completed attendance module",
        "aiSummary": "Completed and tested the attendance module."
      }
    }
  ],
  "pagination": {
    "hasMore": true,
    "nextCursor": "MjAyNi0wOS0yMVQwMDowMDowMC4wMDBafDk4"
  }
}
```

## Response Field Rules

- `status` must be one of:
  - `in_progress`
  - `on_break`
  - `completed`
- `clockOutAt` is `null` for an active shift.
- `activeWorkDurationSeconds` equals `clockedInDurationSeconds - breakDurationSeconds`, with a minimum value of zero.
- `events[].type` should use the existing backend values:
  - `clock_in`
  - `break`
  - `break_end`
  - `clock_out`
- `workLog` is `null` until clock-out data exists.
- `location` may be omitted if exact coordinates should not be displayed in attendance history.
- For improved privacy, replace `location` with a boolean such as `withinGeofence` if users do not need to see exact coordinates.

## Empty Response

An empty history is a successful response, not an error:

```json
{
  "ok": true,
  "timezone": "Asia/Manila",
  "records": [],
  "pagination": {
    "hasMore": false,
    "nextCursor": null
  }
}
```

## Error Responses

Use the same error format as the existing mobile API.

### Invalid query — `400 Bad Request`

```json
{
  "ok": false,
  "message": "A valid date range is required."
}
```

Use this for malformed dates, an invalid date range, an excessive date range, an invalid limit, or an invalid cursor.

### Missing or expired token — `401 Unauthorized`

```json
{
  "ok": false,
  "message": "Authentication required."
}
```

### Unexpected database failure — `503 Service Unavailable`

```json
{
  "ok": false,
  "message": "Unable to load attendance history."
}
```

Do not return raw Supabase errors, SQL errors, stack traces, or other internal database details.

## Backend Implementation Plan

1. Add `src/app/api/mobile/history/route.ts` to `SmartTimeLog-Admin`.
2. Authenticate requests using the existing `authenticateMobileRequest(request)` helper.
3. Validate query parameters with Zod, following the existing HTTP helpers.
4. Query `employee_timelogs` using only the authenticated employee ID.
5. Filter by the requested date range.
6. Order records deterministically by `timestamp DESC, timelog_id DESC`.
7. Fetch related `employee_clock_out_logs` records for clock-out notes and AI summaries.
8. Group events into attendance records.
9. Calculate shift duration, total break duration, active-work duration, and status.
10. Return `noStoreHeaders` because attendance data should not be cached by shared infrastructure.
11. Add a database index on `(employee_id, timestamp DESC, timelog_id DESC)` if one does not already exist.
12. Add the endpoint to the backend OpenAPI documentation.
13. Update the Flutter API client with `getAttendanceHistory(...)`.
14. Replace the local-only loader in `attendance_history_screen.dart` with the authenticated API response.
15. Either remove the local ledger or retain it only as an explicitly labeled offline cache.

## Required Backend Tests

Add tests for the following cases:

- Reject requests without a bearer token.
- Reject expired or invalid bearer tokens.
- Never allow one employee to request another employee's history.
- Return an empty `records` list when no logs exist.
- Group clock-in, break, break-end, and clock-out events correctly.
- Calculate multiple completed breaks correctly.
- Calculate an active break up to the current time.
- Handle a missing clock-out event without crashing.
- Return clock-out notes and AI summary when available.
- Reject invalid date ranges.
- Reject excessive date ranges.
- Reject invalid limits.
- Reject invalid cursors.
- Return deterministic cursor pagination without duplicate records.
- Return records in the expected descending order.
- Do not expose raw database errors or sensitive internal information.

## Recommended API Contract Summary

```text
Endpoint: GET /api/mobile/history
Authentication: Bearer token required
Request body: None
Employee identity: Derived from authenticated token
Default range: Previous 30 days through today
Maximum range: 90 days
Default limit: 20
Maximum limit: 50
Pagination: Opaque cursor
Timestamp format: ISO-8601 UTC
Cache policy: No store
```
