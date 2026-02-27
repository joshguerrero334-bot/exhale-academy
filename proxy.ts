import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { resolveIsSubscribed } from "./lib/auth/subscription-access";

const PUBLIC_PATHS = new Set([
  "/",
  "/login",
  "/signup",
  "/about",
  "/terms",
  "/privacy",
  "/coming-soon",
]);

function isPublicPath(pathname: string) {
  if (PUBLIC_PATHS.has(pathname)) return true;
  if (pathname.startsWith("/_next")) return true;
  if (pathname.startsWith("/favicon")) return true;
  if (pathname.startsWith("/public")) return true;
  if (pathname.startsWith("/api/stripe/webhook")) return true;
  return false;
}

function isAllowedWithoutSubscription(pathname: string) {
  if (isPublicPath(pathname)) return true;
  if (pathname.startsWith("/dashboard")) return true;
  if (pathname.startsWith("/billing")) return true;
  if (pathname.startsWith("/feedback")) return true;
  if (pathname.startsWith("/logout")) return true;
  if (pathname.startsWith("/api/stripe/create-checkout-session")) return true;
  if (pathname.startsWith("/api/stripe/sync-subscription-status")) return true;
  if (pathname.startsWith("/account")) return true;
  if (pathname.startsWith("/admin")) return true;
  return false;
}

function requiresSubscription(pathname: string) {
  if (pathname.startsWith("/tmc")) return true;
  if (pathname.startsWith("/quiz")) return true;
  if (pathname.startsWith("/master")) return true;
  if (pathname.startsWith("/master-test")) return true;
  if (pathname.startsWith("/cse")) return true;
  return false;
}

function sanitizeNextPath(pathname: string, search: string) {
  const raw = `${pathname}${search || ""}`;
  if (!raw.startsWith("/")) return "/dashboard";
  if (raw.startsWith("//")) return "/dashboard";
  return raw;
}

export async function proxy(request: NextRequest) {
  const pathname = request.nextUrl.pathname;
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-pathname", pathname);

  if (isPublicPath(pathname)) {
    return NextResponse.next({
      request: {
        headers: requestHeaders,
      },
    });
  }

  const response = NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          for (const { name, value, options } of cookiesToSet) {
            response.cookies.set(name, value, options);
          }
        },
      },
    }
  );

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.search = `?next=${encodeURIComponent(sanitizeNextPath(pathname, request.nextUrl.search))}`;
    return NextResponse.redirect(url);
  }

  const isSubscribed = await resolveIsSubscribed(supabase, user.id);
  if (requiresSubscription(pathname) && !isSubscribed && !isAllowedWithoutSubscription(pathname)) {
    const url = request.nextUrl.clone();
    url.pathname = "/billing";
    url.search = `?error=${encodeURIComponent("Subscription required to access this section.")}`;
    return NextResponse.redirect(url);
  }

  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
