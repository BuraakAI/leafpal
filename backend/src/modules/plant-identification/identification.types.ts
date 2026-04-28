export interface PlantMatch {
  scientificName: string;
  commonName: string;
  turkishName: string;
  confidence: number;
  imageUrl: string;
  description: string;
  waterFrequencyDays: number;
  lightRequirement: string;
}

export interface ScanResult {
  scanId: string;
  matches: PlantMatch[];
}
