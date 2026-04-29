import { env } from '../../config/env';

export interface PerenualEnrichment {
  imageUrl: string;
  description: string;
  waterFrequencyDays: number;
  lightRequirement: string;
  turkishName?: string;
}

// Perenual watering string → gün sayısı
function wateringToDays(watering: string): number {
  switch (watering?.toLowerCase()) {
    case 'frequent':  return 4;
    case 'average':   return 7;
    case 'minimum':   return 14;
    case 'none':      return 30;
    default:          return 7;
  }
}

// Perenual sunlight field — bazen string bazen array geliyor
function sunlightToReq(sunlight: string | string[] | undefined): string {
  const combined = Array.isArray(sunlight)
    ? sunlight.join(' ').toLowerCase()
    : (sunlight ?? '').toLowerCase();
  if (combined.includes('full sun'))                    return 'direct';
  if (combined.includes('full shade'))                  return 'low_to_indirect';
  if (combined.includes('part') || combined.includes('indirect')) return 'indirect';
  return 'indirect';
}

/** Perenual species-list araması — tam isim sonuç vermezse cins adıyla tekrar dener */
async function fetchPerenualItems(query: string): Promise<any[]> {
  const url = `https://perenual.com/api/species-list?key=${env.perenualApiKey}&q=${encodeURIComponent(query)}&page=1`;
  const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
  if (!res.ok) {
    console.warn(`[perenual] HTTP ${res.status} for "${query}"`);
    return [];
  }
  const json = await res.json() as any;
  return json?.data ?? [];
}

/**
 * Perenual API'den bilimsel isme göre bitki verisi çeker.
 * Türe göre sonuç bulunmazsa cins adıyla fallback yapar.
 * Hata olursa null döner (non-fatal — PlantNet verisi kullanılmaya devam eder).
 */
export async function enrichFromPerenual(
  scientificName: string,
): Promise<PerenualEnrichment | null> {
  if (!env.perenualApiKey) return null;

  try {
    // 1. Tam tür adıyla dene
    let items = await fetchPerenualItems(scientificName);

    // 2. Sonuç yoksa ilk kelimeyi (cinsi) dene — örn. "Rafflesia" from "Rafflesia arnoldii"
    if (items.length === 0) {
      const genus = scientificName.split(' ')[0];
      if (genus && genus !== scientificName) {
        console.log(`[perenual] No results for "${scientificName}", retrying with genus "${genus}"`);
        items = await fetchPerenualItems(genus);
      }
    }

    if (items.length === 0) return null;

    // En yakın eşleşmeyi al
    const item = items[0];

    const imageUrl: string =
      item?.default_image?.regular_url ||
      item?.default_image?.medium_url ||
      item?.default_image?.original_url ||
      '';

    // Perenual ücretsiz planda bazı görseller "Upgrade" sayfasına yönleniyor
    const safeImageUrl = imageUrl.includes('upgrade') ? '' : imageUrl;

    const waterFrequencyDays = wateringToDays(item?.watering ?? '');
    const lightRequirement   = sunlightToReq(item?.sunlight ?? []);

    // Kısa açıklama: common_name + cycle + watering
    const commonName: string = Array.isArray(item?.common_name)
      ? item.common_name[0]
      : (item?.common_name ?? scientificName);

    const cycle: string   = item?.cycle ?? '';
    const watering: string = item?.watering ?? '';
    const description = [
      scientificName,
      commonName !== scientificName ? `(${commonName})` : '',
      cycle ? `· ${cycle}` : '',
      watering ? `· Sulama: ${watering}` : '',
    ].filter(Boolean).join(' ');

    return {
      imageUrl: safeImageUrl,
      description,
      waterFrequencyDays,
      lightRequirement,
    };
  } catch (err) {
    console.warn('[perenual] Enrichment failed, using PlantNet data:', err);
    return null;
  }
}
