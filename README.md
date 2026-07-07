# AccessPulse

## Project Information

| Field | Details |
| --- | --- |
| Team Name | Mainit pa ang Kanin |
| Project Name | AccessPulse |
| Team Members | Reynard John Rabanal [Lead]<br>John Dinon Isaig<br>Emmanuel Azarcon<br>Gabriel Nicolai Pelagio |

## Project Brief

AccessPulse is a civic technology prototype that helps transform lived
accessibility experiences into trusted institutional intelligence. Built for the
Philippine accessibility context, it addresses the gap between what institutions
are expected to provide and what communities, especially Persons with
Disabilities, actually experience in public spaces. Instead of treating
accessibility as a static label, AccessPulse models each place as having a
living accessibility state that changes over time through community
observations, AI-assisted evidence structuring, LGU review, inspector
verification, and remediation follow-through.

The current MVP is built in Flutter and focuses on one accessibility dimension:
mobility access for public service building entrances. It includes Public, LGU,
and Inspector flows in a single demo experience, where users can submit evidence
such as photos, notes, and optional ramp slope readings, while AI helps
structure this evidence into clearer, institution-ready signals without
replacing human judgment. AccessPulse is not just a reporting app. It
demonstrates a new civic-tech model where accessibility is treated as a living
state of places, updated by real experiences, structured by AI, and made
actionable for institutions.

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
