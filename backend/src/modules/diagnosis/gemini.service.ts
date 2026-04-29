import { GoogleGenerativeAI } from '@google/generative-ai';
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
${env.geminiApiKey ? 'Eger bir bitki fotografı varsa gorsel analiz de ekle.' : ''}

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

  const genAI = new GoogleGenerativeAI(env.geminiApiKey);
  const model = genAI.getGenerativeModel({ model: 'gemini-pro' });

  const promptText = buildPrompt(symptoms, plantName);

  const result = await model.generateContent(promptText);
  const text = result.response.text().trim();

  // Strip markdown code fences if present
  const jsonStr = text.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/```\s*$/i, '').trim();

  try {
    const parsed = JSON.parse(jsonStr) as AiDiagnosisResult;
    // Ensure disclaimer is always set
    parsed.disclaimer = parsed.disclaimer || 'Bu analiz yapay zeka tarafindan uretilmistir. Ciddi durumlarda uzman gorusu aliniz.';
    return parsed;
  } catch {
    // Fallback if JSON parse fails
    return {
      summary: text.slice(0, 300),
      issues: [],
      generalAdvice: 'Lutfen tekrar deneyin veya bir uzmanla iletisime gecin.',
      disclaimer: 'Bu analiz yapay zeka tarafindan uretilmistir.',
    };
  }
}
