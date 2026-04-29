import { v2 as cloudinary } from 'cloudinary';
import { env } from '../../config/env';

function configure() {
  cloudinary.config({
    cloud_name: env.cloudinaryCloudName,
    api_key: env.cloudinaryApiKey,
    api_secret: env.cloudinaryApiSecret,
  });
}

export function isCloudinaryEnabled(): boolean {
  return Boolean(env.cloudinaryCloudName && env.cloudinaryApiKey && env.cloudinaryApiSecret);
}

/**
 * Upload buffer to Cloudinary, returns secure URL.
 */
export async function uploadToCloudinary(
  buffer: Buffer,
  folder: string,
  publicId: string,
  mimeType: string,
): Promise<string> {
  configure();
  const resourceType = mimeType.startsWith('image/') ? 'image' : 'raw';
  const result = await new Promise<any>((resolve, reject) => {
    cloudinary.uploader.upload_stream(
      { folder, public_id: publicId, resource_type: resourceType, overwrite: true },
      (error, result) => { if (error) reject(error); else resolve(result); },
    ).end(buffer);
  });
  return result.secure_url as string;
}

/**
 * Delete a file from Cloudinary by its public URL.
 */
export async function deleteFromCloudinary(publicUrl: string): Promise<void> {
  if (!publicUrl.includes('cloudinary.com')) return;
  try {
    configure();
    // Extract public_id from URL: .../folder/publicId.ext
    const match = publicUrl.match(/\/upload\/(?:v\d+\/)?(.+?)(?:\.[a-z]+)?$/i);
    if (match) await cloudinary.uploader.destroy(match[1]);
  } catch { /* ignore */ }
}
