/** Rwanda mobile: +250 7XX XXX XXX or 07XX XXX XXX (MTN 78/79, Airtel 72/73). */
const LOCAL_MOBILE = /^7[2389]\d{7}$/;

export function normalizeRwandaPhone(input: string): string | null {
  const digits = input.replace(/\D/g, '');
  let local = digits;
  if (local.startsWith('250')) {
    local = local.slice(3);
  } else if (local.startsWith('0')) {
    local = local.slice(1);
  }
  if (!LOCAL_MOBILE.test(local)) {
    return null;
  }
  return `+250${local}`;
}

export function isValidRwandaPhone(input: string): boolean {
  return normalizeRwandaPhone(input) !== null;
}
