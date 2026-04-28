import { DiagnosisIssue, DiagnosisResult, Symptom } from './diagnosis.types';

const ISSUE_MAP: Record<Symptom, DiagnosisIssue> = {
  yellowing: {
    name: 'Sarı Yapraklar',
    description: 'Yapraklar sararıyorsa aşırı sulama, yetersiz ışık veya besin eksikliği olabilir.',
    solution: 'Sulama sıklığını azaltın. Bitkiyi daha aydınlık bir yere taşıyın. Aylık gübreleyerek besin desteği sağlayın.',
    severity: 'medium',
  },
  spots: {
    name: 'Yaprak Lekeleri',
    description: 'Kahverengi veya siyah lekeler genellikle mantar hastalığı ya da zararlı kaynaklıdır.',
    solution: 'Etkilenen yaprakları kesin. Yaprakları nemli bezle silin. Gerekirse bakır bazlı fungisit uygulayın.',
    severity: 'medium',
  },
  wilting: {
    name: 'Solan / Sarkan Yapraklar',
    description: 'Yapraklar sallaşıyor ya da yumuşuyorsa susuzluk veya kök çürümesi işareti olabilir.',
    solution: 'Önce toprağı kontrol edin. Kuru ise sulayın; ıslaksa sulamayı durdurun ve kök sağlığını kontrol edin.',
    severity: 'high',
  },
  dropping: {
    name: 'Dökülen Yapraklar',
    description: 'Ani yaprak dökümü genellikle sıcaklık şoku, hava akımı veya yer değişikliğinden kaynaklanır.',
    solution: 'Bitkiyi sıcak ve durgun hava ortamına alın. Yer değişikliklerini en aza indirin.',
    severity: 'low',
  },
  root_rot: {
    name: 'Kök Çürümesi',
    description: 'Aşırı sulama veya drenajı kötü toprak kök çürümesine yol açar. Kökler kahverengi ve kötü kokuluysa tehlikededir.',
    solution: 'Sulamayı hemen durdurun. Bitkiyi saksıdan çıkarın, çürük kökleri temizleyin, taze ve drene eden toprağa yeniden dikin.',
    severity: 'high',
  },
  pests: {
    name: 'Zararlı / Böcek',
    description: 'Yaprak altında ağ, beyaz toz veya küçük hareketli noktalar kırmızı örümcek, beyaz sinek veya yaprak biti işareti olabilir.',
    solution: 'Yaprakları sabunlu su ile silin. Neem yağı veya insektisit spreyi uygulayın. Diğer bitkilerden izole edin.',
    severity: 'high',
  },
  leggy: {
    name: 'Uzun ve Zayıf Gövde (Etiolasyon)',
    description: 'Gövde normalden uzun ve ince büyüyorsa ışık eksikliği nedeniyle bitki ışığa doğru uzanıyor olabilir.',
    solution: 'Bitkiyi daha fazla doğal ışık alan bir yere taşıyın. Gerekirse büyüme ışığı (grow light) kullanın.',
    severity: 'low',
  },
  pale: {
    name: 'Solgun / Açık Renk Yapraklar',
    description: 'Yapraklar normalden açık veya sarımsı yeşilse azot ya da demir eksikliği olabilir.',
    solution: 'Azot içeren yaprak gübresiyle besleyin. Toprağın pH değerini kontrol edin; asidik toprak demir alımını engeller.',
    severity: 'low',
  },
};

const GENERAL_ISSUES: DiagnosisIssue[] = [
  {
    name: 'Genel Sağlık Kontrolü',
    description: 'Belirti seçilmedi. Bitkinizi düzenli olarak kontrol edin.',
    solution: 'Haftada bir yaprakların altını kontrol edin. Toprak nemini ölçün. Aylık gübre uygulayın.',
    severity: 'low',
  },
];

export function analyzePlant(symptoms: string[]): DiagnosisResult {
  if (!symptoms || symptoms.length === 0) {
    return { possibleIssues: GENERAL_ISSUES, disclaimer: _disclaimer() };
  }

  const issues = symptoms
    .filter((s): s is Symptom => s in ISSUE_MAP)
    .map((s) => ISSUE_MAP[s]);

  return {
    possibleIssues: issues.length > 0 ? issues : GENERAL_ISSUES,
    disclaimer: _disclaimer(),
  };
}

function _disclaimer(): string {
  return 'Bu analiz kural tabanlı bir öneri sistemidir. Kesin tanı için uzman görüşü alınız.';
}
