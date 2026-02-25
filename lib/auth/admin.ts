type AdminIdentity = {
  id?: string | null;
  email?: string | null;
};

function parseList(value: string | undefined) {
  return String(value ?? "")
    .split(",")
    .map((entry) => entry.trim().toLowerCase())
    .filter(Boolean);
}

export function isAdminUser(identity: AdminIdentity) {
  const allowedEmails = parseList(process.env.EXHALE_ADMIN_EMAILS ?? process.env.ADMIN_EMAILS);
  const allowedUserIds = parseList(process.env.EXHALE_ADMIN_USER_IDS ?? process.env.ADMIN_USER_IDS);

  const email = String(identity.email ?? "").trim().toLowerCase();
  const userId = String(identity.id ?? "").trim().toLowerCase();

  if (allowedEmails.length === 0 && allowedUserIds.length === 0) {
    return false;
  }

  return (email && allowedEmails.includes(email)) || (userId && allowedUserIds.includes(userId));
}

