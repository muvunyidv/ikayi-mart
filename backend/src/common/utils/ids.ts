import { randomInt } from 'crypto';

export function generateTrackingCode(): string {
  const n = randomInt(1000, 10000);
  return `IKY-${n}`;
}

export function slugify(value: string): string {
  const slug = value
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
  return slug.length > 0 ? slug : `item-${Date.now()}`;
}
