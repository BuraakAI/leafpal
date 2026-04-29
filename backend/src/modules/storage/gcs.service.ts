import { Storage } from '@google-cloud/storage';
import { env } from '../../config/env';

// GCS client — Cloud Run'da Workload Identity, localde key file kullanır.
function createStorage(): Storage {
  if (env.gcsKeyFile) {
    return new Storage({ projectId: env.gcsProjectId, keyFilename: env.gcsKeyFile });
  }
  return new Storage({ projectId: env.gcsProjectId });
}

let _storage: Storage | null = null;

function getStorage(): Storage {
  if (!_storage) _storage = createStorage();
  return _storage;
}

/**
 * Upload a file buffer to GCS and return its public URL.
 * Files are made publicly readable via bucket-level uniform access.
 *
 * @param folder  GCS "folder" prefix, e.g. "plants"
 * @param filename  Final filename, e.g. "abc123.jpg"
 * @param buffer  File content
 * @param mimeType  e.g. "image/jpeg"
 */
export async function uploadToGCS(
  folder: string,
  filename: string,
  buffer: Buffer,
  mimeType: string,
): Promise<string> {
  if (!env.gcsBucket) {
    throw new Error('GCS_BUCKET env variable is not set');
  }

  const bucket = getStorage().bucket(env.gcsBucket);
  const objectName = `${folder}/${filename}`;
  const file = bucket.file(objectName);

  await file.save(buffer, {
    metadata: { contentType: mimeType },
    resumable: false,
  });

  // Public URL — bucket must have uniform public read enabled
  return `https://storage.googleapis.com/${env.gcsBucket}/${objectName}`;
}

/**
 * Delete a file from GCS. Silently ignores missing files.
 */
export async function deleteFromGCS(publicUrl: string): Promise<void> {
  if (!env.gcsBucket || !publicUrl.includes(env.gcsBucket)) return;

  try {
    const prefix = `https://storage.googleapis.com/${env.gcsBucket}/`;
    const objectName = publicUrl.replace(prefix, '');
    await getStorage().bucket(env.gcsBucket).file(objectName).delete();
  } catch {
    // Ignore — file may already be gone
  }
}

/** Returns true if GCS is configured (bucket env set). */
export function isGcsEnabled(): boolean {
  return Boolean(env.gcsBucket);
}
