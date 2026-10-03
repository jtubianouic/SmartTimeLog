# SmartTimeLog

<p align="center">
  <img src="lib/icons/smarttimelog.png" alt="SmartTimeLog logo" width="160">
</p>

SmartTimeLog is a mobile attendance application that helps employees record
their workday accurately. It combines secure sign-in, location-aware clock-in,
break tracking, live shift timers, attendance history, and AI-assisted work
summaries in one guided workflow.

## What employees can do

- Sign in securely and restore an existing session when reopening the app.
- Confirm their location before clocking in.
- View live working-time and break-time counters.
- Start and end a break with confirmation prompts.
- Add work notes and generate an AI-assisted summary before clocking out.
- Review attendance events returned by the SmartTimeLog API.
- Switch between light and dark themes.

## Typical workday

1. Sign in with your SmartTimeLog employee account.
2. Allow location access when prompted.
3. Review your location and clock in.
4. Track the active shift and take the required break.
5. Enter details about the work you completed.
6. Review the generated summary and confirm clock-out.

The app securely stores the active access token on the device. When the app is
reopened, it restores the session and checks the current attendance status with
the backend. If the token has expired or is rejected, the employee is returned
to the login screen.

## Developer setup

### Requirements

- A Flutter SDK compatible with Dart `^3.12.2`
- Android Studio and an Android SDK for Android development
- Xcode and CocoaPods for iOS development
- A running SmartTimeLog backend API

### Installation

1. Clone the repository and enter the project directory.
2. Install the Flutter dependencies:

   ```bash
   flutter pub get
   ```

3. Create the local environment file from the included example:

   ```bash
   cp .env.example .env
   ```

   On Windows PowerShell, use:

   ```powershell
   Copy-Item .env.example .env
   ```

4. Set the backend URL in `.env`:

   ```dotenv
   BASE_URL=https://your-smarttimelog-api.example.com
   ```

5. Start an emulator, connect a device, and run the app:

   ```bash
   flutter run
   ```

Do not commit production credentials or private secrets to `.env`. Values
packaged with a mobile application can be inspected by users and should not be
treated as server-side secrets.

## Device permissions

SmartTimeLog needs location access to record attendance coordinates and compare
the employee's position with their assigned headquarters. Android and iOS will
request permission when the location workflow is used. If permission is denied,
clock-in, break, and clock-out actions that require a position cannot continue.

## Backend integration

The API base URL comes from `BASE_URL`. The mobile client currently uses these
authenticated workflows:

- Login and session restoration
- Current attendance status and server-backed timelogs
- Clock-in
- Start and end break
- AI summary generation
- Clock-out

Attendance history is loaded from the `timelogs` array returned by
`GET /api/mobile/status`. The client accepts the current payload shape:

```json
{
  "ok": true,
  "status": "clocked_in",
  "latestTimelog": {},
  "timelogs": [
    {
      "timelog_id": 123,
      "employee_id": 5,
      "log_type": "clock_in",
      "lat": 7.0731,
      "long": 125.6128,
      "timestamp": "2026-10-03T08:00:00Z"
    }
  ]
}
```

When legacy duration fields are absent, the client derives the active shift and
break durations from these timelogs.

## Quality checks

Run static analysis and the automated test suite before submitting changes:

```bash
flutter analyze
flutter test
```

The tests cover API payloads, authentication and session security, attendance
state transitions, and important UI workflows.

## Project structure

```text
lib/
  main.dart                 App startup, theme, and routes
  icons/                    SmartTimeLog visual assets
  providers/                App-level notifiers
  screens/                  Login and attendance workflow screens
  services/                 API, session, location, and onboarding services
  theme/                    Light and dark application themes
  widgets/                  Shared interface components
test/
  security_test.dart        Authentication and session safeguards
  smart_time_log_api_test.dart
  widget_test.dart
```

## Troubleshooting

- **The app does not start:** Confirm that `.env` exists and contains a valid
  `BASE_URL`.
- **Login fails:** Verify the backend is reachable and the employee credentials
  are valid.
- **Location actions fail:** Enable location services and grant location access
  to SmartTimeLog in the device settings.
- **An old app name or icon is displayed:** Uninstall and reinstall the app to
  clear launcher caches.
