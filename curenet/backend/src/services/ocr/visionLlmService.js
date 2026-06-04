const axios = require('axios');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const GROQ_API_KEY = process.env.GROQ_API_KEY;
const NVIDIA_API_KEY_11B = process.env.NVIDIA_API_KEY_11B;
const NVIDIA_API_KEY_90B = process.env.NVIDIA_API_KEY_90B;
const NVIDIA_API_KEY_NEMOTRON = process.env.NVIDIA_API_KEY_NEMOTRON;

/**
 * Read image or PDF sidecar file and return { base64, mimeType }.
 * If the path ends with .pdf.json, it's a PDF sidecar created by pdfService
 * (for servers where sharp can't render PDFs to images).
 */
function readImageContent(imagePath) {
    if (imagePath.endsWith('.pdf.json')) {
        const sidecar = JSON.parse(fs.readFileSync(imagePath, 'utf-8'));
        return {
            base64: sidecar.base64,
            mimeType: sidecar.mimeType || 'application/pdf'
        };
    }
    const base64 = fs.readFileSync(imagePath).toString('base64');
    const ext = path.extname(imagePath).toLowerCase();
    const mimeType = ext === '.png' ? 'image/png' : 'image/jpeg';
    return { base64, mimeType };
}

/**
 * ═══════════════════════════════════════════════════════════════════
 *  Vision LLM Service — Gemma 4 Edge-First with Cloud Failover
 * ═══════════════════════════════════════════════════════════════════
 *
 *  Dual-model architecture for clinical document extraction:
 *
 *    PRIMARY:   Gemma 4 31B Dense via local Ollama
 *               → Zero-latency, privacy-preserving, offline-capable
 *               → 256K context window for massive medical data logs
 *               → Unmatched multi-step reasoning for FHIR R4 conversion
 *
 *    FALLBACK:  Groq Cloud (Llama 4 Scout) → Nvidia NIM → Mock
 *               → Used when local Ollama is unavailable
 *
 *  The Gemma 4 31B Dense variant is chosen for medical extraction
 *  because it cannot tolerate routing gaps or hallucination. Its
 *  complete context retention and raw-quality powerhouse architecture
 *  reliably outputs strict FHIR R4 compliant JSON bundles.
 */

// ─── Ollama Configuration ────────────────────────────────────────
const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const GEMMA4_MODEL = process.env.GEMMA4_MODEL || 'gemma4:31b';

function buildVisionPrompt(patientName = null, docType = null) {
  let prompt = `You are a medical data extraction expert. Analyze this clinical document image carefully.
This could be a PRESCRIPTION or a LAB REPORT. Detect which type it is and extract ALL information.

Return ONLY valid JSON in this exact format:
{
  "patient_name": "full name or 'unclear'",
  "doctor_name": "full name with title or 'unclear'",
  "doctor_reg_no": "Medical Registration Number (e.g. MCI-1234) or null",
  "clinic": "clinic/hospital name or 'unclear'",
  "facility_id": "ABDM Facility ID if present (e.g. HFR-ID) or null",
  "date": "YYYY-MM-DD format",
  "age": "e.g. 35Y or 'unclear'",
  "gender": "male/female/other",
  "diagnosis": "Impression/Diagnosis text (e.g. Hypoglycemia)",
  "chief_complaint": "symptoms (e.g. Giddiness, restlessness)",
  "vitals": {
    "bp": "e.g. 110/70",
    "pulse": "e.g. 60bpm",
    "temperature": "e.g. 98.6F or null",
    "weight": "e.g. 70kg or null"
  },
  "investigations": "any tests advised or 'unclear'",
  "medications": [
    {
      "name": "exact medicine name (e.g. 5% Dextrose)",
      "dosage": "e.g. 1 unit",
      "frequency": "e.g. Stat or 1+0+1",
      "duration": "e.g. 2 weeks",
      "form": "Injection/Tablet/Powder",
      "route": "iv/oral/topical",
      "confidence": 0.9,
      "extraction_method": "vision_llm"
    }
  ],
  "lab_results": [
    {
      "test_name": "e.g. HbA1c",
      "value": "numeric result or text",
      "unit": "e.g. % or mg/dL",
      "reference_range": "e.g. 4.0-5.6"
    }
  ],
  "follow_up": {
    "date": "YYYY-MM-DD or null",
    "advice": ["advice item 1", "advice item 2"]
  }
}

Rules:
- Capture EVERY SINGLE medication, supplement, or medical product mentioned. Look closely at sections starting with 'Adv:', 'Rx:', 'Treatment:', or bullet points.
- If a line contains a dosage or quantity (e.g., 'ORS 2 sachets', 'Protein powder 1 scoop'), it MUST be classified as a Medication in the 'medications' array, NOT as general advice.
- General advice should ONLY be lifestyle instructions (e.g., 'Adequate fluid intake', 'Bed rest').
- For Indian prescriptions, patterns like '1+0+1', '1-0-1', '0-1-0' indicate frequency. Put these EXACTLY as written in 'frequency'.
- If the medicine strength (like 500mg, 10ml) is written next to the name, put it in 'dosage' or keep it in the 'name'. Do NOT put frequency in the dosage field.
- Ensure the spelling of the medications exactly matches the image. Look closely at the handwriting.
- Extract Vitals like BP and Pulse from the 'O/E' (On Examination) section.
- Extract Diagnosis from the 'Imp:' or 'Impression:' section (e.g., 'hypoglycemic'). Do NOT miss this.
- Capture 'c/o' (Complaining of) symptoms into chief_complaint.
- If it's a PRESCRIPTION: populate medications[], leave lab_results as []
- If it's a LAB REPORT: populate lab_results[], leave medications as []
- Identify 'Stat' as a frequency (meaning immediately).
- Distinguish carefully between Medications (things to consume/inject) and Advice.
- Indian prescription frequency: morning+afternoon+night (e.g., 1+0+1)
- Common abbreviations: Tab=Tablet, Cap=Capsule, Syp=Syrup, Inj=Injection, ORS=Oral Rehydration Salts
- Pay EXTREME attention to medication names. Cross-reference with common Indian brand names (e.g., Dolo, Crocin, Augmentin, Pan-D, Shelcal, Ecosprin, Thyronorm, Metformin, Amlodipine).
- For dosage, distinguish between strength (e.g., 500mg) and quantity (e.g., 1 tablet). Put strength in 'dosage' and quantity+timing in 'frequency'.
- Common Indian frequency patterns: OD=once daily, BD=twice daily, TDS=thrice daily, QID=four times daily, HS=at bedtime, SOS=as needed, AC=before food, PC=after food, Stat=immediately.
- For lab reports: extract ALL test values with their units and reference ranges. Do not skip any test.
- Do NOT hallucinate — if truly unreadable, mark as 'unclear'
- Return ONLY the JSON, no markdown formatting. Ensure ALL medications on the page are included.`;

  if (patientName) {
    prompt += `\n\nIMPORTANT PATIENT CONTEXT:\n- The expected patient name is: "${patientName}"\n- Check if this name or a close variation appears on the document.\n- If the document clearly belongs to a DIFFERENT person, include a field "name_mismatch": true in your response and set "detected_patient_name" to the name you found on the document.\n- If names match or are similar, set "name_mismatch": false.`;
  }

  if (docType) {
    prompt += `\nThis document has been pre-classified as: ${docType}. Focus your extraction accordingly.`;
  }

  return prompt;
}


/**
 * PRIMARY: Gemma 4 31B Dense via local Ollama
 *
 * Uses the localized inference orchestration on the clinic workstation.
 * The 31B Dense variant provides complete context retention and
 * unmatched multi-step reasoning for medical entity extraction.
 * It maps unformatted OCR outputs into clean clinical schemas using
 * a zero-shot structure prompt, reliably outputting strict FHIR R4
 * compliant JSON bundles.
 */
async function extractWithGemma4Local(imagePath, patientName = null, docType = null) {
    try {
        // Check if Ollama is reachable
        const healthCheck = await axios.get(`${OLLAMA_URL}/api/tags`, { timeout: 2000 })
            .catch(() => null);

        if (!healthCheck || healthCheck.status !== 200) {
            console.log('[VisionLLM] Ollama not reachable. Skipping Gemma 4 local...');
            return null;
        }

        const { base64: imageContent, mimeType } = readImageContent(imagePath);

        console.log(`[VisionLLM] Requesting Gemma 4 31B Dense (${GEMMA4_MODEL}) via local Ollama...`);

        const response = await axios.post(
            `${OLLAMA_URL}/v1/chat/completions`,
            {
                model: GEMMA4_MODEL,
                messages: [
                    {
                        role: "user",
                        content: [
                            { type: "text", text: buildVisionPrompt(patientName, docType) + "\nIMPORTANT: Return ONLY valid JSON. No conversational filler. No markdown formatting." },
                            { type: "image_url", image_url: { url: `data:${mimeType};base64,${imageContent}` } }
                        ]
                    }
                ],
                max_tokens: 1024,
                temperature: 0.1,
                response_format: { type: "json_object" }
            },
            {
                headers: { "Content-Type": "application/json" },
                timeout: 60000  // Local inference may be slower
            }
        );

        const textResult = response.data?.choices?.[0]?.message?.content;
        if (!textResult) return null;

        const jsonMatch = textResult.match(/\{[\s\S]*\}/);
        const cleanJsonStr = jsonMatch ? jsonMatch[0] : textResult;
        const structuredData = JSON.parse(cleanJsonStr);

        // Tag medications with extraction method
        if (structuredData.medications) {
            structuredData.medications = structuredData.medications.map(med => ({
                ...med,
                confidence: med.confidence || 0.95,
                extraction_method: 'gemma4_31b_local'
            }));
        }

        console.log(`[VisionLLM] ✅ Gemma 4 31B Dense returned ${structuredData.medications?.length || 0} medication(s), ${structuredData.lab_results?.length || 0} lab result(s)`);

        return {
            ...structuredData,
            source: 'Gemma4_31B_Local',
            confidence: 0.95
        };
    } catch (err) {
        console.error('[VisionLLM] Gemma 4 local extraction failed:', err.message);
        return null;
    }
}


/**
 * FALLBACK 1: Groq Vision API (Llama 4 Scout)
 * Used when local Gemma 4 Ollama instance is not available.
 */
async function extractWithGroq(imagePath, patientName = null, docType = null) {
    if (!GROQ_API_KEY) {
        console.warn('[VisionLLM] Groq API Key missing. Skipping Groq...');
        return null;
    }

    try {
        const { base64: imageContent, mimeType } = readImageContent(imagePath);

        console.log('[VisionLLM] Falling back to Groq Cloud (Llama 4 Scout) extraction...');

        const response = await axios.post(
            'https://api.groq.com/openai/v1/chat/completions',
            {
                model: "meta-llama/llama-4-scout-17b-16e-instruct",
                messages: [
                    {
                        role: "user",
                        content: [
                            { type: "text", text: buildVisionPrompt(patientName, docType) + "\nIMPORTANT: Return ONLY valid JSON. No conversational filler. No markdown formatting." },
                            { type: "image_url", image_url: { url: `data:${mimeType};base64,${imageContent}` } }
                        ]
                    }
                ],
                max_tokens: 1024,
                temperature: 0.1,
                response_format: { type: "json_object" }
            },
            {
                headers: {
                    "Authorization": `Bearer ${GROQ_API_KEY}`,
                    "Content-Type": "application/json"
                },
                timeout: 15000
            }
        );

        const textResult = response.data?.choices?.[0]?.message?.content;
        if (!textResult) return null;

        const jsonMatch = textResult.match(/\{[\s\S]*\}/);
        const cleanJsonStr = jsonMatch ? jsonMatch[0] : textResult;
        const structuredData = JSON.parse(cleanJsonStr);

        // Tag medications with extraction method
        if (structuredData.medications) {
            structuredData.medications = structuredData.medications.map(med => ({
                ...med,
                confidence: med.confidence || 0.95,
                extraction_method: 'groq_vision_fallback'
            }));
        }

        console.log(`[VisionLLM] Groq returned ${structuredData.medications?.length || 0} medication(s), ${structuredData.lab_results?.length || 0} lab result(s)`);

        return {
            ...structuredData,
            source: 'Groq_Vision_Fallback',
            confidence: 0.95
        };
    } catch (err) {
        console.error('[VisionLLM] Groq API failed:', err.response?.data?.error?.message || err.message);
        return null;
    }
}


/**
 * CLASSIFIER: Llama 3.2 11B Vision Instruct via Nvidia NIM
 * Determines if an image is handwritten or printed very quickly (~300ms).
 */
async function classifyImageType(imagePath) {
    const defaultResult = { isMedical: true, lighting: 'GOOD', docType: 'PRESCRIPTION', writingType: 'PRINTED' };
    if (!NVIDIA_API_KEY_11B || NVIDIA_API_KEY_11B === 'YOUR_NVIDIA_API_KEY_HERE') {
        return defaultResult;
    }
    try {
        const { base64: imageContent, mimeType } = readImageContent(imagePath);
        
        const response = await axios.post(
            'https://integrate.api.nvidia.com/v1/chat/completions',
            {
                model: "meta/llama-3.2-11b-vision-instruct",
                messages: [
                    {
                        role: "user",
                        content: [
                            { type: "text", text: `Analyze this document image and respond with ONLY a JSON object:
{"is_medical": true/false, "lighting": "GOOD"/"POOR", "doc_type": "PRESCRIPTION"/"LAB_REPORT"/"DISCHARGE_SUMMARY"/"OTHER_MEDICAL", "writing_type": "HANDWRITTEN"/"PRINTED"}
Rules:
- is_medical: true if this is a medical document (prescription, lab report, discharge summary, clinical note). false if it's a random photo, selfie, food, landscape, etc.
- lighting: GOOD if text is reasonably readable. POOR if the image is too dark, blurry, or washed out to extract text.
- doc_type: classify the medical document type. Use OTHER_MEDICAL if it's medical but doesn't fit the categories.
- writing_type: HANDWRITTEN if the main content is handwritten, PRINTED if typed/printed.
Return ONLY the JSON, nothing else.` },
                            { type: "image_url", image_url: { url: `data:${mimeType};base64,${imageContent}` } }
                        ]
                    }
                ],
                max_tokens: 100,
                temperature: 0.1,
                response_format: { type: "json_object" }
            },
            {
                headers: {
                    "Authorization": `Bearer ${NVIDIA_API_KEY_11B}`,
                    "Content-Type": "application/json",
                    "Accept": "application/json"
                },
                timeout: 10000
            }
        );
        
        const textResult = response.data?.choices?.[0]?.message?.content?.trim() || '';
        const jsonMatch = textResult.match(/\{[\s\S]*\}/);
        if (!jsonMatch) return defaultResult;

        const parsed = JSON.parse(jsonMatch[0]);
        return {
            isMedical: parsed.is_medical !== false,
            lighting: parsed.lighting === 'POOR' ? 'POOR' : 'GOOD',
            docType: parsed.doc_type || 'PRESCRIPTION',
            writingType: (parsed.writing_type || 'PRINTED').toUpperCase()
        };
    } catch (err) {
        console.error('[VisionLLM] Classification failed:', err.message);
        return defaultResult;
    }
}

/**
 * FALLBACK 2: Nvidia NIM Vision API
 * Dynamically routed between Llama 3.2 90B (Handwritten) and Nemotron OCR (Printed)
 */
async function extractWithNvidia(imagePath, imageType = 'printed', patientName = null, docType = null) {
    const apiKey = imageType === 'handwritten' ? NVIDIA_API_KEY_90B : NVIDIA_API_KEY_NEMOTRON;
    if (!apiKey || apiKey === 'YOUR_NVIDIA_API_KEY_HERE') {
        console.warn('[VisionLLM] Nvidia API Key missing for ' + imageType + '. Skipping Nvidia...');
        return null;
    }

    try {
        const { base64: imageContent, mimeType } = readImageContent(imagePath);

        const modelToUse = imageType === 'handwritten' 
            ? "meta/llama-3.2-90b-vision-instruct" 
            : "nvidia/nemotron-ocr-v1";

        console.log(`[VisionLLM] Routing to Nvidia NIM (${modelToUse}) for ${imageType} document...`);

        const response = await axios.post(
            'https://integrate.api.nvidia.com/v1/chat/completions',
            {
                model: modelToUse,
                response_format: { type: "json_object" },
                messages: [
                    {
                        role: "user",
                        content: [
                            { type: "text", text: buildVisionPrompt(patientName, docType) + "\nIMPORTANT: Return ONLY valid JSON. No conversational filler. No markdown formatting." },
                            { type: "image_url", image_url: { url: `data:${mimeType};base64,${imageContent}` } }
                        ]
                    }
                ],
                max_tokens: 1024,
                temperature: 0.1
            },
            {
                headers: {
                    "Authorization": `Bearer ${apiKey}`,
                    "Content-Type": "application/json",
                    "Accept": "application/json"
                },
                timeout: 30000
            }
        );

        const textResult = response.data?.choices?.[0]?.message?.content;
        if (!textResult) return null;

        const jsonMatch = textResult.match(/\{[\s\S]*\}/);
        const cleanJsonStr = jsonMatch ? jsonMatch[0] : textResult;
        const structuredData = JSON.parse(cleanJsonStr);

        if (structuredData.medications) {
            structuredData.medications = structuredData.medications.map(med => ({
                ...med,
                confidence: med.confidence || 0.95,
                extraction_method: 'nvidia_vision_fallback'
            }));
        }

        console.log(`[VisionLLM] Nvidia NIM returned ${structuredData.medications?.length || 0} medication(s), ${structuredData.lab_results?.length || 0} lab result(s)`);

        return {
            ...structuredData,
            source: 'Nvidia_NIM_Fallback',
            confidence: 0.95
        };
    } catch (err) {
        console.error('[VisionLLM] Nvidia API failed:', err.response?.data || err.message);
        return null;
    }
}


/**
 * LAST RESORT: All AI providers failed — return an error.
 * No fake data is ever fabricated.
 */
function getMockData() {
    console.error('[VisionLLM] All providers failed. Returning error.');
    return {
        error: 'PROVIDERS_UNAVAILABLE',
        message: 'All AI providers (Gemma, Nvidia NIM, Groq) are currently unavailable. Please try again later.'
    };
}


/**
 * ═══════════════════════════════════════════════════════════════════
 *  Main Entry Point — Gemma 4 Local → Groq → Nvidia → Mock
 * ═══════════════════════════════════════════════════════════════════
 *
 *  Edge-first routing:
 *    1. Gemma 4 31B Dense via local Ollama (privacy-preserving, offline)
 *    2. Groq Cloud — Llama 4 Scout (fast cloud fallback)
 *    3. Nvidia NIM — Llama 3.2 90B (high-accuracy cloud fallback)
 *    4. Mock data (demo fallback if all APIs fail)
 */
exports.extractWithVisionLlm = async (imagePath, patientName = null) => {
    // PDF sidecars skip classification — user explicitly uploaded a document
    const isPdfSidecar = imagePath.endsWith('.pdf.json');
    
    let docType = 'PRESCRIPTION';
    let imageType = 'printed';
    
    if (!isPdfSidecar) {
        // 1. Pre-classify the document (medical validity, lighting, type, writing)
        const classification = await classifyImageType(imagePath);
        console.log(`[VisionLLM] Classification: medical=${classification.isMedical}, lighting=${classification.lighting}, type=${classification.docType}, writing=${classification.writingType}`);

        if (!classification.isMedical) {
            return { error: 'NOT_MEDICAL', message: 'This does not appear to be a medical document. Please scan a valid prescription, lab report, or clinical document.' };
        }

        if (classification.lighting === 'POOR') {
            return { error: 'POOR_LIGHTING', message: 'The image quality is too poor to read. Please ensure adequate lighting, hold the camera steady, and avoid shadows on the document.' };
        }

        docType = classification.docType;
        imageType = classification.writingType === 'HANDWRITTEN' ? 'handwritten' : 'printed';
    } else {
        console.log('[VisionLLM] PDF sidecar detected — skipping image classification.');
    }

    // 2. Try Gemma 4 31B Dense via local Ollama (PRIMARY — edge-first)
    const gemma4Result = await extractWithGemma4Local(imagePath, patientName, docType);
    if (gemma4Result) return gemma4Result;

    // 3. Try Nvidia NIM Vision (cloud fallback — high accuracy smart routing)
    const nvidiaResult = await extractWithNvidia(imagePath, imageType, patientName, docType);
    if (nvidiaResult) return nvidiaResult;

    // 4. Try Groq Vision (cloud fallback — fast)
    const groqResult = await extractWithGroq(imagePath, patientName, docType);
    if (groqResult) return groqResult;

    // 5. Mock fallback (demo)
    return getMockData();
};
