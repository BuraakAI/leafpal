import { PlantIdentificationProvider } from './identification.provider';
import { PlantMatch } from './identification.types';

export class MockPlantProvider implements PlantIdentificationProvider {
  async identify(_imageBuffer: Buffer, _mimeType: string): Promise<PlantMatch[]> {
    console.log('Using mock plant identification provider');
    return [
      {
        scientificName: 'Monstera deliciosa',
        commonName: 'Swiss Cheese Plant',
        turkishName: 'İsviçre Peyniri Bitkisi',
        confidence: 0.94,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Monstera_deliciosa.jpg/800px-Monstera_deliciosa.jpg',
        description: 'Tropikal kökenli büyük yapraklı bir iç mekan bitkisidir. Karakteristik delikli yaprakları ile tanınır.',
        waterFrequencyDays: 7,
        lightRequirement: 'indirect',
      },
      {
        scientificName: 'Ficus lyrata',
        commonName: 'Fiddle Leaf Fig',
        turkishName: 'Keman Yapraklı İncir',
        confidence: 0.72,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7c/Ficus_lyrata.jpg/800px-Ficus_lyrata.jpg',
        description: 'Büyük keman şeklindeki yapraklarıyla dekoratif bir iç mekan bitkisidir. Parlak dolaylı ışık sever.',
        waterFrequencyDays: 10,
        lightRequirement: 'bright_indirect',
      },
      {
        scientificName: 'Epipremnum aureum',
        commonName: 'Pothos',
        turkishName: 'Şeytan Sarmaşığı',
        confidence: 0.61,
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Epipremnum_aureum_31082012.jpg/800px-Epipremnum_aureum_31082012.jpg',
        description: 'Bakımı kolay, sarılıcı bir iç mekan bitkisidir. Düşük ışıkta bile yaşayabilir.',
        waterFrequencyDays: 7,
        lightRequirement: 'low_to_indirect',
      },
    ];
  }
}
