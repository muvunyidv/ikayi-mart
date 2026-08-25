/** Strong password: 8+ chars, upper, lower, digit, special from @$!%*?& */
export const STRONG_PASSWORD_REGEX =
  /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$/;

export const STRONG_PASSWORD_MESSAGE =
  'Password must be at least 8 characters and include uppercase, lowercase, a number, and a special character (@$!%*?&)';

/** Rwandan mobile: +2507XXXXXXXX, 2507XXXXXXXX, or 07XXXXXXXX (MTN 78/79, Airtel 72/73). */
export const RWANDA_PHONE_REGEX = /^(?:\+250|250|0)?(7[2389]\d{7})$/;

export const RWANDA_PHONE_MESSAGE =
  'Enter a valid Rwandan phone number (+250 7XX XXX XXX or 07XX XXX XXX)';
