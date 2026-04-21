import type { Metadata } from "next";
import "./globals.css";
import AppHeader from "../components/AppHeader";
import SiteFooter from "../components/SiteFooter";
import { inter, playfair } from "../lib/fonts";
import { getSiteUrl } from "../lib/site";
import { SpeedInsights } from "@vercel/speed-insights/next";

export const metadata: Metadata = {
  title: {
    default: "Exhale Academy | Respiratory Therapy Test Prep for TMC and CSE",
    template: "%s | Exhale Academy",
  },
  description:
    "Respiratory therapy test prep for TMC and CSE exam prep, including TMC practice exams, TMC practice questions, CSE clinical simulations, and respiratory therapy flashcards.",
  keywords: [
    "respiratory therapy test prep",
    "respiratory therapy exam prep",
    "TMC prep",
    "TMC exam prep",
    "TMC practice exam",
    "TMC practice questions",
    "TMC question bank",
    "CSE prep",
    "CSE exam prep",
    "CSE clinical simulations",
    "TMC flashcards",
    "respiratory therapy flashcards",
  ],
  metadataBase: new URL(getSiteUrl()),
  openGraph: {
    title: "Exhale Academy | Respiratory Therapy Test Prep for TMC and CSE",
    description:
      "Modern respiratory therapy exam prep with TMC practice exams, TMC practice questions, CSE clinical simulations, and flashcards built for RT students and new grads.",
    url: getSiteUrl(),
    siteName: "Exhale Academy",
    type: "website",
  },
  alternates: {
    canonical: "/",
  },
};

// Brand layout changes:
// 1) Integrated Inter + Playfair fonts via next/font/google.
// 2) Switched global app chrome to the new Exhale brand header (logo, CSE/TMC nav, user pill, logout).
// 3) Applied brand body defaults (background/text/font) through layout-level body classes.
export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${inter.className} ${inter.variable} ${playfair.variable} overflow-x-hidden bg-background font-sans text-charcoal antialiased`}
      >
        <div className="flex min-h-screen flex-col">
          <AppHeader />
          <div className="flex-1">{children}</div>
          <SiteFooter />
        </div>
        <SpeedInsights />
      </body>
    </html>
  );
}
