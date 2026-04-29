import { env } from '../../config/env';
import { PlantIdentificationProvider } from './identification.provider';
import { MockPlantProvider } from './mock.provider';
import { PlantNetProvider } from './plantnet.provider';
import { enrichFromPerenual } from './perenual.service';
import { PlantMatch, ScanResult } from './identification.types';
import prisma from '../../lib/prisma';


function getProvider(): PlantIdentificationProvider {
  if (env.plantApiKey) {
    console.log('Using PlantNet provider');
    return new PlantNetProvider();
  }
  console.log('Using mock plant provider (set PLANT_API_KEY to use PlantNet)');
  return new MockPlantProvider();
}

export async function scanPlant(
  imageBuffer: Buffer,
  mimeType: string,
  userId: string,
): Promise<ScanResult> {
  const provider = getProvider();
  const matches: PlantMatch[] = await provider.identify(imageBuffer, mimeType);

  // Perenual ile zenginleştir — paralel istekler, non-fatal
  const enriched = await Promise.all(
    matches.map(async (match) => {
      const extra = await enrichFromPerenual(match.scientificName);
      if (!extra) return match;
      return {
        ...match,
        // Perenual'ın HD fotoğrafı varsa onu kullan, yoksa PlantNet'inkini koru
        imageUrl: extra.imageUrl || match.imageUrl,
        description: extra.description || match.description,
        waterFrequencyDays: extra.waterFrequencyDays,
        lightRequirement: extra.lightRequirement,
      };
    }),
  );

  const scan = await prisma.scanHistory.create({
    data: {
      userId,
      results: JSON.stringify(enriched),
    },
  });

  return { scanId: scan.id, matches: enriched };
}
