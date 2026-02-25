import type { Metadata } from "next";
import "./globals.css";
import AppHeader from "../components/AppHeader";
import { inter, playfair } from "../lib/fonts";

export const metadata: Metadata = {
  title: "Exhale Academy",
  description: "Exhale Academy TMC preparation platform",
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
      <body className={`${inter.className} ${inter.variable} ${playfair.variable} bg-background font-sans text-charcoal antialiased`}>
        <AppHeader />
        {children}
      </body>
    </html>
  );
}
