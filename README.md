# AccessPulse

## Project Information

| Field | Details |
| --- | --- |
| Team Name | Mainit pa ang Kanin |
| Project Name | AccessPulse |
| Team Members | To be added |

## Project Brief

AccessPulse is a Flutter MVP for living accessibility intelligence. The demo
focuses on Mobility Access for public service buildings and shows how community
signals, AI-structured evidence, LGU review, and inspector verification can
update a shared accessibility state.

## Google Technologies Used

- Flutter
- Gemini API
- Google Fonts

AccessPulse was developed for SparkFest 2026.

## Local Setup

1. Install Flutter and run `flutter pub get`.
2. Create a local `.env` file from `.env.example`.
3. Put your local values in `.env`. Keep `.env.example` as placeholders only.
4. Apply the Supabase schema and seed data using `SETUP_DB.md`.
5. Configure the Gemini-backed Supabase Edge Function using `SETUP_AI.md`.

Load the local `.env` values into the current PowerShell session:

```powershell
Get-Content .env | Where-Object { $_ -match '^[^#].+=' } | ForEach-Object {
  $name, $value = $_ -split '=', 2
  Set-Item -Path "Env:$name" -Value $value
}
```

Then run the Flutter web app with:

```powershell
flutter run -d chrome `
  --dart-define=ACCESSPULSE_AI_FUNCTION_URL=$env:ACCESSPULSE_AI_FUNCTION_URL `
  --dart-define=ACCESSPULSE_SUPABASE_ANON_KEY=$env:ACCESSPULSE_SUPABASE_ANON_KEY
```

If you prefer, pass the values directly instead of loading them from your shell
environment.

## Demo Flow

1. Open the Public tab and choose a seeded public service building.
2. Confirm a visit to show a community signal changing state and pulse.
3. Add evidence to exercise Gemini-backed evidence structuring.
4. Switch to LGU and request inspection for a review case.
5. Switch to Inspector and submit a verification outcome.
6. Return to Public to see the updated state reflected in the place memory.

## Verification

The milestone test pass uses:

```powershell
dart format .
flutter analyze
flutter test
flutter build web
```
