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
  const plantPart = plantName
    ? `Incelenen bitki: ${plantName}.`
    : 'Bitki turu kullanici tarafindan belirtilmemistir; gorselden tespit etmeye calis.';

  const symptomPart = symptoms.length > 0
    ? `Kullanicinin bildirdigi belirtiler: ${symptoms.join(', ')}.`
    : 'Kullanici herhangi bir belirti secmemistir. Gorsel uzerinden genel bir saglik degerlendirmesi yap.';

  return `Sen 20 yillik deneyime sahip uzman bir ziraat muhendisisin. Ic mekan bitki hastaliklari, zararlilari ve bakim sorunlari konusunda uzmanlasmissin. Elindeki gorsel ve belirti bilgilerine dayanarak bitmis bir tani raporu hazirlayacaksin.

${plantPart}
${symptomPart}

Raporu asagidaki JSON formatinda yaz. Kesinlikle sadece JSON don, hicbir aciklama veya markdown bloku ekleme:

{
  "summary": "Bitkinin genel durumunu 2-3 cumleyle degerlendir. Uzman edayla, net ve anlasilir yaz. Gorsel varsa onu da kullan.",
  "issues": [
    {
      "name": "Sorunun adi (Turkce, net ve kisa)",
      "description": "Sorunun ne oldugunu, neden kaynaklandigini ve bitkiyi nasil etkiledigini 2-3 cumleyle acikla. Teknik ama anlasilir ol.",
      "solution": "Adim adim, pratik cozum onerisi. Hangi urunu kullanmali, ne zaman sulama yapmali, nasil bir ortam saglamali gibi somut tavsiyeler ver.",
      "severity": "low veya medium veya high"
    }
  ],
  "generalAdvice": "Bu bitkinin genel bakimi icin 2-3 onemli tavsiye. Uzman gozuyle, kullanicinin hayatini kolaylastiracak pratik bilgiler.",
  "disclaimer": "Bu rapor yapay zeka destekli analiz sonucunda olusturulmustur. Agir vakalarda bir ziraat muhendisi veya bitki uzmaniyla gorusmenizi oneririz."
}`;
}

/** Gemini API yanıtından JSON'ı güvenli şekilde çıkarır */
function extractJson(text: string): string {
  // Önce ```json ... ``` bloğunu dene
  const codeBlock = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (codeBlock) return codeBlock[1].trim();

  // Sonra ilk { ... } bloğunu bul
  const jsonBlock = text.match(/\{[\s\S]*\}/);
  if (jsonBlock) return jsonBlock[0].trim();

  // Hiçbiri yoksa ham metni döndür
  return text.trim();
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

  const parts: any[] = [{ text: prompt }];
  if (imageBuffer && imageMimeType) {
    parts.unshift({
      inline_data: {
        mime_type: imageMimeType,
        data: imageBuffer.toString('base64'),
      },
    });
  }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${env.geminiApiKey}`;

  const body = JSON.stringify({
    contents: [{ parts }],
    generationConfig: {
      temperature: 0.3,
      maxOutputTokens: 2048,
      responseMimeType: 'application/json',
    },
  });

  let response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  });

  // 429 rate limit → 5 sn bekle, bir kez daha dene
  if (response.status === 429) {
    await new Promise((r) => setTimeout(r, 5000));
    response = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body });
  }

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Gemini API error ${response.status}: ${errText}`);
  }

  const data = await response.json() as any;
  const text: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';

  try {
    const jsonStr = extractJson(text);
    const parsed = JSON.parse(jsonStr) as AiDiagnosisResult;
    parsed.disclaimer = parsed.disclaimer ||
      'Bu rapor yapay zeka destekli analiz sonucunda olusturulmustur. Agir vakalarda uzman gorusu aliniz.';
    return parsed;
  } catch {
    // JSON parse hatası — ham metni summary olarak göster
    console.error('[gemini] JSON parse failed, raw text:', text.slice(0, 200));
    return {
      summary: 'Analiz tamamlandi ancak sonuc islenirken bir hata olustu. Lutfen tekrar deneyin.',
      issues: [],
      generalAdvice: '',
      disclaimer: 'Bu analiz yapay zeka tarafindan uretilmistir.',
    };
  }
}
