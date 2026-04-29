import FormData from 'form-data';
import https from 'https';
import { env } from '../../config/env';
import { PlantIdentificationProvider } from './identification.provider';
import { PlantMatch } from './identification.types';

const TURKISH_NAMES: Record<string, string> = {
  'Monstera deliciosa': 'İsviçre Peyniri Bitkisi',
  'Ficus lyrata': 'Keman Yapraklı İncir',
  'Epipremnum aureum': 'Şeytan Sarmaşığı',
  'Spathiphyllum wallisii': 'Barış Çiçeği',
  'Sansevieria trifasciata': 'Kayınvalide Dili',
  'Aloe vera': 'Sarısabır',
  'Ficus elastica': 'Kauçuk Bitkisi',
  'Zamioculcas zamiifolia': 'ZZ Bitkisi',
  'Pothos': 'Pothos Sarmaşığı',
  'Dracaena': 'Drakena',
  'Calathea': 'Kalatya',
  'Philodendron': 'Filodendron',
  'Cactus': 'Kaktüs',
  'Succulents': 'Sukulent',
};

function turkishName(scientific: string, commonNames: string[]): string {
  for (const key of Object.keys(TURKISH_NAMES)) {
    if (scientific.toLowerCase().includes(key.toLowerCase())) {
      return TURKISH_NAMES[key];
    }
  }
  // Prefer a clean English common name over raw Latin
  if (commonNames.length > 0) {
    // Capitalize first letter of first common name
    const name = commonNames[0].trim();
    return name.charAt(0).toUpperCase() + name.slice(1);
  }
  return scientific;
}

function lightRequirement(tags: string[]): string {
  const t = tags.join(' ').toLowerCase();
  if (t.includes('shade') || t.includes('low')) return 'low_to_indirect';
  if (t.includes('full sun') || t.includes('direct')) return 'direct';
  return 'indirect';
}

export class PlantNetProvider implements PlantIdentificationProvider {
  async identify(imageBuffer: Buffer, mimeType: string): Promise<PlantMatch[]> {
    const form = new FormData();
    form.append('images', imageBuffer, {
      filename: 'plant.jpg',
      contentType: mimeType,
    });
    form.append('organs', 'leaf');

    const url = `/v2/identify/all?api-key=${env.plantApiKey}&lang=tr&nb-results=5&include-related-images=true`;

    const rawBody = await new Promise<string>((resolve, reject) => {
      const req = https.request(
        {
          hostname: 'my-api.plantnet.org',
          path: url,
          method: 'POST',
          headers: form.getHeaders(),
          timeout: 25000,
        },
        (res) => {
          let data = '';
          res.on('data', (chunk) => (data += chunk));
          res.on('end', () => resolve(data));
        },
      );
      req.on('error', reject);
      req.on('timeout', () => { req.destroy(); reject(new Error('PlantNet timeout')); });
      form.pipe(req);
    });

    const json = JSON.parse(rawBody) as PlantNetResponse;

    if (!json.results || json.results.length === 0) {
      throw new Error('Bitki tanımlanamadı. Lütfen daha net bir fotoğraf deneyin.');
    }

    return json.results.slice(0, 3).map((r) => {
      const scientific = r.species.scientificNameWithoutAuthor;
      const common = r.species.commonNames ?? [];
      return {
        scientificName: scientific,
        commonName: common[0] ?? scientific,
        turkishName: turkishName(scientific, common),
        confidence: r.score,
        imageUrl: r.images?.[0]?.url?.m ?? r.images?.[0]?.url?.s ?? '',
        description: `${scientific} — ${common.slice(0, 2).join(', ') || 'iç mekan bitkisi'}`,
        waterFrequencyDays: 7,
        lightRequirement: lightRequirement(r.species.gbif?.id ? ['indirect'] : []),
      };
    });
  }
}

// PlantNet API response types
interface PlantNetResponse {
  results: PlantNetResult[];
  remainingIdentificationRequests?: number;
}

interface PlantNetResult {
  score: number;
  species: {
    scientificNameWithoutAuthor: string;
    commonNames: string[];
    gbif?: { id: string };
  };
  images?: Array<{ url: { s: string; m: string } }>;
}
