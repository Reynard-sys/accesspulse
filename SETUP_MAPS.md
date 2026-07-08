# Google Maps Setup

Use this guide to turn on the Google Maps shell and map picker in AccessPulse.

## Important note first

The Flutter app does **not** read `.env` directly at runtime.

In this repo, `.env` is only a convenient local place to store values. You still
need to load those values into your shell and pass them through `--dart-define`
when running Flutter.

## 1. Add these values to your local `.env`

Keep real keys in your uncommitted `.env` file, not in `.env.example`.

```env
ACCESSPULSE_ENABLE_GOOGLE_MAPS=true
GOOGLE_MAPS_API_KEY_WEB=PASTE_YOUR_GOOGLE_MAPS_WEB_KEY_HERE
GOOGLE_MAPS_API_KEY_ANDROID=PASTE_YOUR_GOOGLE_MAPS_ANDROID_KEY_HERE
GOOGLE_MAPS_API_KEY_IOS=PASTE_YOUR_GOOGLE_MAPS_IOS_KEY_HERE
```

If you are only testing on web for now, `GOOGLE_MAPS_API_KEY_WEB` is the main
one you need immediately.

## 2. Load `.env` into PowerShell

From the project root:

```powershell
Get-Content .env | Where-Object { $_ -match '^[^#].+=' } | ForEach-Object {
  $name, $value = $_ -split '=', 2
  Set-Item -Path "Env:$name" -Value $value
}
```

## 3. Run Flutter with the map defines

For Chrome/web:

```powershell
flutter run -d chrome `
  --dart-define=ACCESSPULSE_AI_FUNCTION_URL=$env:ACCESSPULSE_AI_FUNCTION_URL `
  --dart-define=ACCESSPULSE_SUPABASE_ANON_KEY=$env:ACCESSPULSE_SUPABASE_ANON_KEY `
  --dart-define=ACCESSPULSE_ENABLE_GOOGLE_MAPS=$env:ACCESSPULSE_ENABLE_GOOGLE_MAPS `
  --dart-define=GOOGLE_MAPS_API_KEY_WEB=$env:GOOGLE_MAPS_API_KEY_WEB
```

For Android:

```powershell
flutter run -d android `
  --dart-define=ACCESSPULSE_AI_FUNCTION_URL=$env:ACCESSPULSE_AI_FUNCTION_URL `
  --dart-define=ACCESSPULSE_SUPABASE_ANON_KEY=$env:ACCESSPULSE_SUPABASE_ANON_KEY `
  --dart-define=ACCESSPULSE_ENABLE_GOOGLE_MAPS=$env:ACCESSPULSE_ENABLE_GOOGLE_MAPS `
  --dart-define=GOOGLE_MAPS_API_KEY_ANDROID=$env:GOOGLE_MAPS_API_KEY_ANDROID
```

For iOS:

```powershell
flutter run -d ios `
  --dart-define=ACCESSPULSE_AI_FUNCTION_URL=$env:ACCESSPULSE_AI_FUNCTION_URL `
  --dart-define=ACCESSPULSE_SUPABASE_ANON_KEY=$env:ACCESSPULSE_SUPABASE_ANON_KEY `
  --dart-define=ACCESSPULSE_ENABLE_GOOGLE_MAPS=$env:ACCESSPULSE_ENABLE_GOOGLE_MAPS `
  --dart-define=GOOGLE_MAPS_API_KEY_IOS=$env:GOOGLE_MAPS_API_KEY_IOS
```

## 4. What these values do

- `ACCESSPULSE_ENABLE_GOOGLE_MAPS=true`
  - turns on the map UI instead of the fallback card
- `GOOGLE_MAPS_API_KEY_WEB`
  - allows the web map shell and map picker to render
- `GOOGLE_MAPS_API_KEY_ANDROID`
  - reserved for Android map setup
- `GOOGLE_MAPS_API_KEY_IOS`
  - reserved for iOS map setup

## 5. Current behavior in this repo

Right now the app is designed to fail gracefully:

- if maps are not enabled, AccessPulse shows the list fallback
- if the web key is missing, AccessPulse shows the fallback message
- add-place still works through manual coordinates even without Maps

## 6. Web setup reminder

This repo now loads the Google Maps JavaScript API dynamically from Dart when
web maps are enabled and `GOOGLE_MAPS_API_KEY_WEB` is present.

If the app still shows the fallback card after adding your key, check:

1. `ACCESSPULSE_ENABLE_GOOGLE_MAPS=true`
2. `GOOGLE_MAPS_API_KEY_WEB` is passed through `--dart-define`
3. your Google Cloud key allows web usage for your local origin

## 7. Safety

- Do not commit real API keys
- Keep `.env.example` as placeholders only
- Restrict your Google Maps keys by platform in Google Cloud
