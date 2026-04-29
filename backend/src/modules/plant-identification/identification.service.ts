import { env } from '../../config/env';
import { PlantIdentificationProvider } from './identification.provider';
import { MockPlantProvider } from './mock.provider';
import { PlantNetProvider } from './plantnet.provider';
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

  const scan = await prisma.scanHistory.create({
    data: {
      userId,
      results: JSON.stringify(matches),
    },
  });

  return { scanId: scan.id, matches };
}
