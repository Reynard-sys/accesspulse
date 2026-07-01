const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type EvidenceRequest = {
  dimension?: string;
  note?: string;
  imagePath?: string;
  imageBase64?: string;
  imageMimeType?: string;
  rampMeasurement?: RampMeasurementInput;
};

type RampMeasurementInput = {
  estimatedAngleDegrees?: number;
  qualityScore?: number;
  qualityLabel?: string;
  captureDurationMs?: number;
  sampleCount?: number;
  status?: string;
  source?: string;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return jsonResponse(
      {
        error:
          "GEMINI_API_KEY is not configured. Add it as a Supabase Edge Function secret.",
      },
      500,
    );
  }

  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";
  const body = (await request.json()) as EvidenceRequest;
  const note = body.note?.trim() ?? "";
  const dimension = body.dimension ?? "mobility_access";
  const parts: Array<Record<string, unknown>> = [
    {
      text: buildPrompt({
        dimension,
        note,
        imagePath: body.imagePath,
        hasImageBytes: Boolean(body.imageBase64 && body.imageMimeType),
        rampMeasurement: body.rampMeasurement,
      }),
    },
  ];

  if (body.imageBase64 && body.imageMimeType) {
    parts.push({
      inlineData: {
        mimeType: body.imageMimeType,
        data: body.imageBase64,
      },
    });
  }

  const geminiResponse = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify({
        contents: [
          {
            role: "user",
            parts,
          },
        ],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: {
            type: "object",
            properties: {
              dimension: { type: "string" },
              issueType: { type: "string" },
              observedFeatures: {
                type: "array",
                items: { type: "string" },
              },
              possibleBarrier: { type: "string" },
              missingEvidence: {
                type: "array",
                items: { type: "string" },
              },
              confidence: { type: "number" },
              confidenceLevel: {
                type: "string",
                enum: ["low", "moderate", "high"],
              },
              confidenceExplanation: { type: "string" },
              evidenceReadiness: {
                type: "string",
                enum: ["draft", "almostReady", "institutionReady"],
              },
              institutionReady: { type: "boolean" },
              summary: { type: "string" },
              recommendedAction: { type: "string" },
              nextBestAction: { type: "string" },
              explanation: { type: "string" },
            },
            required: [
              "dimension",
              "issueType",
              "observedFeatures",
              "possibleBarrier",
              "missingEvidence",
              "confidence",
              "confidenceLevel",
              "confidenceExplanation",
              "evidenceReadiness",
              "institutionReady",
              "summary",
              "recommendedAction",
              "nextBestAction",
              "explanation",
            ],
          },
        },
      }),
    },
  );

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    return jsonResponse(
      {
        error: "Gemini request failed",
        status: geminiResponse.status,
        detail: errorText,
      },
      502,
    );
  }

  const data = await geminiResponse.json();
  const text = extractOutputText(data);
  if (typeof text !== "string") {
    return jsonResponse(
      { error: "Gemini response did not include structured text" },
      502,
    );
  }

  const parsed = normalizeAssessment(JSON.parse(text));
  return jsonResponse(parsed);
});

function buildPrompt(input: {
  dimension: string;
  note: string;
  imagePath?: string;
  hasImageBytes: boolean;
  rampMeasurement?: RampMeasurementInput;
}) {
  const rampMeasurement = formatRampMeasurement(input.rampMeasurement);
  return `
You are AccessPulse's Accessibility Copilot for the hackathon MVP.

Scope:
- Dimension: ${input.dimension}
- Place type: public service building
- Scenario: entrance/ramp usability for independent wheelchair access

User note:
${input.note || "(No note provided.)"}

Image reference:
${input.imagePath || "(No uploaded image bytes were provided.)"}

Image bytes:
${
    input.hasImageBytes
      ? "An uploaded image is attached as a separate inlineData part. Use visual evidence from that image, but explain uncertainty and do not make official findings."
      : "(No image bytes were provided.)"
  }

Ramp slope field measurement:
${rampMeasurement}

Return only JSON matching the requested schema.

Rules:
- Structure evidence for institutional review.
- Identify visible or described features relevant to mobility access.
- Explain uncertainty and missing context.
- If a ramp slope field measurement is provided, reference it as an estimated supporting signal.
- Gemini must not calculate the ramp angle. Use only the provided measured estimate.
- Recommend a next action such as "lgu_review" when appropriate.
- Never state legal non-compliance.
- Never say "violation confirmed".
- Never say the reading proves non-compliance.
- Never say the reading is exact.
- Never say the ramp is illegal.
- Never mark a place officially verified.
- Never overrule a human verifier.
- If evidence is weak, say what is missing and lower confidence.
- Use confidenceLevel as low, moderate, or high; do not use percentages in user-facing language.
- Use evidenceReadiness as draft, almostReady, or institutionReady.
- Set institutionReady true only when the evidence is sufficient for LGU review.
- Always include a short confidenceExplanation.
- Include nextBestAction as one plain-language next step for the contributor.
`;
}

function formatRampMeasurement(measurement?: RampMeasurementInput) {
  if (!measurement || typeof measurement.estimatedAngleDegrees !== "number") {
    return "(No ramp slope measurement was provided.)";
  }

  const angle = measurement.estimatedAngleDegrees.toFixed(1);
  const quality = measurement.qualityLabel ?? "unknown stability";
  const status = measurement.status ?? "unknown";
  const source = measurement.source ?? "field capture";
  const samples =
    typeof measurement.sampleCount === "number"
      ? `${measurement.sampleCount} samples`
      : "sample count unavailable";
  const duration =
    typeof measurement.captureDurationMs === "number"
      ? `${measurement.captureDurationMs} ms`
      : "duration unavailable";

  return [
    `- Estimated ramp angle: ${angle} degrees`,
    `- Capture quality: ${quality}`,
    `- Status: ${status}`,
    `- Source: ${source}`,
    `- Capture window: ${duration}`,
    `- Sample count: ${samples}`,
    "- Treat this as citizen field evidence only; official review may still be required.",
  ].join("\\n");
}

function normalizeAssessment(value: Record<string, unknown>) {
  return {
    dimension: stringValue(value.dimension, "mobility_access"),
    issueType: stringValue(value.issueType, "entrance_ramp_usability"),
    observedFeatures: stringList(value.observedFeatures),
    possibleBarrier: stringValue(
      value.possibleBarrier,
      "independent wheelchair access may be unreliable",
    ),
    missingEvidence: stringList(value.missingEvidence),
    confidence: numberValue(value.confidence, 0.5),
    confidenceLevel: confidenceLevelValue(
      value.confidenceLevel,
      numberValue(value.confidence, 0.5),
    ),
    confidenceExplanation: stringValue(
      value.confidenceExplanation,
      defaultConfidenceExplanation(
        confidenceLevelValue(
          value.confidenceLevel,
          numberValue(value.confidence, 0.5),
        ),
      ),
    ),
    evidenceReadiness: evidenceReadinessValue(
      value.evidenceReadiness,
      value.institutionReady === true,
    ),
    institutionReady: booleanValue(
      value.institutionReady,
      evidenceReadinessValue(
        value.evidenceReadiness,
        value.institutionReady === true,
      ) === "institutionReady",
    ),
    summary: stringValue(value.summary, "Evidence needs human review."),
    recommendedAction: stringValue(value.recommendedAction, "lgu_review"),
    nextBestAction: stringValue(value.nextBestAction, "Submit for review."),
    explanation: stringValue(
      value.explanation,
      "AI structured this signal but did not make an official judgment.",
    ),
  };
}

function confidenceLevelValue(value: unknown, confidence: number) {
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    if (
      normalized === "high" ||
      normalized === "moderate" ||
      normalized === "low"
    ) {
      return normalized;
    }
  }
  if (confidence >= 0.8) return "high";
  if (confidence >= 0.5) return "moderate";
  return "low";
}

function defaultConfidenceExplanation(confidenceLevel: string) {
  if (confidenceLevel === "high") {
    return "The evidence strongly supports the mobility-access concern.";
  }
  if (confidenceLevel === "moderate") {
    return "The evidence supports the concern, but some context is still missing.";
  }
  return "The evidence is too limited for a strong review signal.";
}

function evidenceReadinessValue(value: unknown, institutionReady: boolean) {
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase().replace(/_/g, "");
    if (normalized === "institutionready") return "institutionReady";
    if (normalized === "almostready") return "almostReady";
    if (normalized === "draft") return "draft";
  }
  return institutionReady ? "institutionReady" : "almostReady";
}

function extractOutputText(data: unknown) {
  if (!data || typeof data !== "object") {
    return null;
  }
  const record = data as Record<string, unknown>;
  if (typeof record.output_text === "string") {
    return record.output_text;
  }
  if (Array.isArray(record.candidates)) {
    for (const candidate of record.candidates) {
      if (!candidate || typeof candidate !== "object") {
        continue;
      }
      const candidateRecord = candidate as Record<string, unknown>;
      const content = candidateRecord.content;
      if (!content || typeof content !== "object") {
        continue;
      }
      const contentRecord = content as Record<string, unknown>;
      if (!Array.isArray(contentRecord.parts)) {
        continue;
      }
      for (const part of contentRecord.parts) {
        if (!part || typeof part !== "object") {
          continue;
        }
        const partRecord = part as Record<string, unknown>;
        if (typeof partRecord.text === "string") {
          return partRecord.text;
        }
      }
    }
  }
  if (!Array.isArray(record.steps)) {
    return null;
  }
  for (const step of record.steps) {
    if (!step || typeof step !== "object") {
      continue;
    }
    const stepRecord = step as Record<string, unknown>;
    if (!Array.isArray(stepRecord.content)) {
      continue;
    }
    for (const content of stepRecord.content) {
      if (!content || typeof content !== "object") {
        continue;
      }
      const contentRecord = content as Record<string, unknown>;
      if (typeof contentRecord.text === "string") {
        return contentRecord.text;
      }
    }
  }
  return null;
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function stringValue(value: unknown, fallback: string) {
  return typeof value === "string" && value.trim().length > 0
    ? value
    : fallback;
}

function stringList(value: unknown) {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === "string")
    : [];
}

function numberValue(value: unknown, fallback: number) {
  if (typeof value !== "number" || Number.isNaN(value)) {
    return fallback;
  }
  return Math.max(0, Math.min(1, value));
}

function booleanValue(value: unknown, fallback: boolean) {
  return typeof value === "boolean" ? value : fallback;
}
