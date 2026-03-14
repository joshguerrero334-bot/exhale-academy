import type { Metadata } from "next";
import "./globals.css";
import AppHeader from "../components/AppHeader";
import SiteFooter from "../components/SiteFooter";
import { inter, playfair } from "../lib/fonts";
import { getSiteUrl } from "../lib/site";

export const metadata: Metadata = {
  title: "Exhale Academy",
  description: "Exhale Academy TMC preparation platform",
  metadataBase: new URL(getSiteUrl()),
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
      </body>
    </html>
  );
}
