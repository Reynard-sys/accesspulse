# Gemini AI Setup

Milestone 6 adds a secure server-side Gemini wrapper through a Supabase Edge Function.

The important rule:

**Do not put your Gemini API key in Flutter, `web/index.html`, `.env.example`, or any committed file.**

The Gemini API key belongs in Supabase Edge Function secrets only.

## Files Added

- `supabase/functions/analyze-evidence/index.ts`
- `supabase/functions/analyze-evidence/.env.example`
- `.env.example`

## Values You Need

### Server-side secret

Set this in Supabase:

```txt
GEMINI_API_KEY=your Gemini API key
```

Optional:

```txt
GEMINI_MODEL=gemini-3.5-flash
```

### Flutter client values

These are not Gemini secrets:

```txt
ACCESSPULSE_AI_FUNCTION_URL=https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/analyze-evidence
ACCESSPULSE_SUPABASE_ANON_KEY=your Supabase anon key
```

## Step 1 - Add Gemini Secrets To Supabase

From the repo root, after installing and logging in to the Supabase CLI:

```powershell
supabase secrets set GEMINI_API_KEY="PASTE_YOUR_GEMINI_API_KEY_HERE"
supabase secrets set GEMINI_MODEL="gemini-3.5-flash"
```

You can also set these from the Supabase dashboard if you prefer:

1. Open your Supabase project.
2. Go to **Edge Functions**.
3. Open **Secrets**.
4. Add `GEMINI_API_KEY`.
5. Optionally add `GEMINI_MODEL`.

## Step 2 - Deploy The Edge Function

```powershell
supabase functions deploy analyze-evidence
```

After deployment, your function URL should look like:

```txt
https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/analyze-evidence
```

## Step 3 - Run Flutter With Server AI Enabled

Replace the placeholders:

```powershell
flutter run -d chrome `
  --dart-define=ACCESSPULSE_AI_FUNCTION_URL="https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/analyze-evidence" `
  --dart-define=ACCESSPULSE_SUPABASE_ANON_KEY="PASTE_YOUR_SUPABASE_ANON_KEY_HERE"
```

For web-server:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 `
  --dart-define=ACCESSPULSE_AI_FUNCTION_URL="https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/analyze-evidence" `
  --dart-define=ACCESSPULSE_SUPABASE_ANON_KEY="PASTE_YOUR_SUPABASE_ANON_KEY_HERE"
```

## Fallback Behavior

If `ACCESSPULSE_AI_FUNCTION_URL` is missing, the app uses the mock AI service.

If the Edge Function returns an error or cannot be reached, the Flutter app also falls back to the mock AI service so the hackathon demo remains usable.

## Manual Function Test

After deploying, test the function with:

```powershell
$body = @{
  dimension = "mobility_access"
  note = "The entrance has steps and the ramp required assistance."
  imagePath = "demo/main-entrance.jpg"
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/analyze-evidence" `
  -Headers @{
    "apikey" = "PASTE_YOUR_SUPABASE_ANON_KEY_HERE"
    "Authorization" = "Bearer PASTE_YOUR_SUPABASE_ANON_KEY_HERE"
    "Content-Type" = "application/json"
  } `
  -Body $body
```

Expected output shape:

```json
{
  "dimension": "mobility_access",
  "issueType": "entrance_ramp_usability",
  "observedFeatures": ["entrance", "steps"],
  "possibleBarrier": "independent wheelchair access may be unreliable",
  "missingEvidence": ["full side view of ramp"],
  "confidence": 0.75,
  "summary": "The evidence suggests mobility access may require assistance.",
  "recommendedAction": "lgu_review",
  "explanation": "AI structured the evidence but did not make an official judgment."
}
```

## Local Development Notes

To serve the function locally with Supabase CLI, copy the placeholder values from:

```txt
supabase/functions/analyze-evidence/.env.example
```

into the default local Supabase functions env file:

```txt
supabase/functions/.env
```

Then run:

```powershell
supabase functions serve analyze-evidence
```

You can also keep a function-specific local file and pass it explicitly:

```powershell
supabase functions serve analyze-evidence --env-file supabase/functions/analyze-evidence/.env
```

Both `.env` files are ignored by git.
