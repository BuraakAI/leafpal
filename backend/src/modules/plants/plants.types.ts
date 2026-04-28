export interface SavePlantBody {
  speciesId?: string;
  scientificName?: string;
  commonName?: string;
  turkishName?: string;
  nickname?: string;
  location?: string;
  imageUrl?: string;
  waterFrequencyDays?: number;
  lightRequirement?: string;
}
