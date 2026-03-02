export const STRONG_PASSWORD_REGEX = /^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$/;

export function isStrongPassword(password: string) {
  return STRONG_PASSWORD_REGEX.test(password);
}

export const STRONG_PASSWORD_HINT =
  "Password must be at least 8 characters and include 1 uppercase letter, 1 number, and 1 special character.";
