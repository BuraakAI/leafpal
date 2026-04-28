import { PlantMatch } from './identification.types';

export interface PlantIdentificationProvider {
  identify(imageBuffer: Buffer, mimeType: string): Promise<PlantMatch[]>;
}
