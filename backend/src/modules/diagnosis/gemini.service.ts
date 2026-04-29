import { env } from '../../config/env';

interface AiDiagnosisResult {
  summary: string;
  issues: Array<{
    name: string;
    description: string;
    solution: string;
    severity: 'low' | 'medium' | 'high';
  }>;
  generalAdvice: string;
  disclaimer: string;
}

function buildPrompt(symptoms: string[], plantName?: string): string {
  const plantPart = plantName ? `Bitki turu: ${plantName}.` : 'Bitki turu bilinmiyor.';
  const symptomPart = symptoms.length > 0
    ? `Kullanici su belirtileri bildiriyor: ${symptoms.join(', ')}.`
    : 'Kullanici belirli bir belirti secmedi; genel saglik degerlendirmesi yap.';

  return `Sen uzman bir ic mekan bitki bakimi asistanisin. Asagidaki bilgilere gore Turkce ve detayli bir tani raporu olustur.

${plantPart}
${symptomPart}

Lutfen asagidaki JSON formatinda yanit ver (baska hicbir sey yazma, sadece gecerli JSON):
{
  "summary": "Kisaca 1-2 cumle ile genel degerlendirme",
  "issues": [
    {
      "name": "Sorun adi (Turkce)",
      "description": "Sorunun aciklamasi (2-3 cumle)",
      "solution": "Cozum onerisi (adim adim)",
      "severity": "low | medium | high"
    }
  ],
  "generalAdvice": "Genel bakim tavsiyesi (2-3 cumle)",
  "disclaimer": "Bu analiz yapay zeka tarafindan uretilmistir. Ciddi durumlarda uzman gorusu aliniz."
}`;
}

export async function analyzeWithGemini(
  symptoms: string[],
  plantName?: string,
  imageBuffer?: Buffer,
  imageMimeType?: string,
): Promise<AiDiagnosisResult> {
  if (!env.geminiApiKey) {
    throw new Error('GEMINI_API_KEY set edilmemis');
  }

  const prompt = buildPrompt(symptoms, plantName);

  // Build parts array — include image if provided
  const parts: any[] = [{ text: prompt }];
  if (imageBuffer && imageMimeType) {
    parts.unshift({
      inline_data: {
        mime_type: imageMimeType,
        data: imageBuffer.toString('base64'),
      },
    });
  }

  // gemini-2.0-flash-lite: daha yuksek rate limit, multimodal destekli
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${env.geminiApiKey}`;

  // 429 rate limit için 1 kez retry (2 sn bekle)
  let response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts }],
      generationConfig: { temperature: 0.4, maxOutputTokens: 1024 },
    }),
  });

  if (response.status === 429) {
    await new Promise((r) => setTimeout(r, 5000));
    response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts }],
        generationConfig: { temperature: 0.4, maxOutputTokens: 1024 },
      }),
    });
  }

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Gemini API error ${response.status}: ${errText}`);
  }

  const data = await response.json() as any;
  const text: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';

  const jsonStr = text.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/```\s*$/i, '').trim();

  try {
    const parsed = JSON.parse(jsonStr) as AiDiagnosisResult;
    parsed.disclaimer = parsed.disclaimer || 'Bu analiz yapay zeka tarafindan uretilmistir. Ciddi durumlarda uzman gorusu aliniz.';
    return parsed;
  } catch {
    return {
      summary: text.slice(0, 300),
      issues: [],
      generalAdvice: 'Lutfen tekrar deneyin veya bir uzmanla iletisime gecin.',
      disclaimer: 'Bu analiz yapay zeka tarafindan uretilmistir.',
    };
  }
}
