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

// Perenual sunlight array → bizim format
function sunlightToReq(sunlight: string[]): string {
  const combined = (sunlight ?? []).join(' ').toLowerCase();
  if (combined.includes('full sun'))                    return 'direct';
  if (combined.includes('full shade'))                  return 'low_to_indirect';
  if (combined.includes('part') || combined.includes('indirect')) return 'indirect';
  return 'indirect';
}

/**
 * Perenual API'den bilimsel isme göre bitki verisi çeker.
 * Hata olursa null döner (non-fatal — PlantNet verisi kullanılmaya devam eder).
 */
export async function enrichFromPerenual(
  scientificName: string,
): Promise<PerenualEnrichment | null> {
  if (!env.perenualApiKey) return null;

  try {
    const query = encodeURIComponent(scientificName);
    const url = `https://perenual.com/api/species-list?key=${env.perenualApiKey}&q=${query}&page=1`;

    const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
    if (!res.ok) {
      console.warn(`[perenual] HTTP ${res.status} for "${scientificName}"`);
      return null;
    }

    const json = await res.json() as any;
    const items: any[] = json?.data ?? [];
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
