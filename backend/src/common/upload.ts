import { existsSync, mkdirSync } from 'fs';
import { join } from 'path';

export const UPLOAD_DIR = join(process.cwd(), 'uploads');

export function ensureUploadDir(): string {
  if (!existsSync(UPLOAD_DIR)) {
    mkdirSync(UPLOAD_DIR, { recursive: true });
  }
  return UPLOAD_DIR;
}
