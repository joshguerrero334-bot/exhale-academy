"use client";

import { useEffect, useMemo, useState } from "react";
import type { SlideshowSlide } from "../../lib/slideshows";

type SlideDeckViewerProps = {
  slides: SlideshowSlide[];
};

export default function SlideDeckViewer({ slides }: SlideDeckViewerProps) {
  const [index, setIndex] = useState(0);
  const [failedImages, setFailedImages] = useState<Set<string>>(() => new Set());
  const current = slides[index];
  const hasSlides = slides.length > 0;

  const progressLabel = useMemo(() => {
    if (!hasSlides) return "No slides";
    return `Slide ${index + 1} of ${slides.length}`;
  }, [hasSlides, index, slides.length]);

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "ArrowLeft") {
        setIndex((value) => Math.max(value - 1, 0));
      }
      if (event.key === "ArrowRight") {
        setIndex((value) => Math.min(value + 1, slides.length - 1));
      }
    }

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [slides.length]);

  if (!hasSlides || !current) {
    return null;
  }

  const imageFailed = failedImages.has(current.src);

  return (
    <section className="rounded-2xl border border-graysoft/30 bg-white p-4 shadow-sm sm:p-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">{progressLabel}</p>
          <h2 className="mt-1 text-lg font-semibold text-charcoal">{current.title}</h2>
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setIndex((value) => Math.max(value - 1, 0))}
            disabled={index === 0}
            className="rounded-lg border border-primary/40 bg-background px-4 py-2 text-sm font-semibold text-primary transition hover:bg-primary/5 disabled:cursor-not-allowed disabled:opacity-40"
          >
            Previous
          </button>
          <button
            type="button"
            onClick={() => setIndex((value) => Math.min(value + 1, slides.length - 1))}
            disabled={index === slides.length - 1}
            className="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white transition hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-40"
          >
            Next
          </button>
        </div>
      </div>

      <div className="mt-5 overflow-hidden rounded-2xl border border-graysoft/30 bg-slate-50">
        {imageFailed ? (
          <div className="flex aspect-video flex-col items-center justify-center p-6 text-center">
            <p className="text-sm font-semibold text-charcoal">Slide image not found yet</p>
            <p className="mt-2 max-w-md text-xs leading-relaxed text-graysoft">
              Expected file: <span className="font-mono text-charcoal">{current.src}</span>
            </p>
          </div>
        ) : (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={current.src}
            alt={current.alt}
            className="aspect-video w-full bg-white object-contain"
            onError={() => {
              setFailedImages((previous) => new Set(previous).add(current.src));
            }}
          />
        )}
      </div>

      <div className="mt-4 grid grid-cols-7 gap-2" aria-label="Slide navigation">
        {slides.map((slide, slideIndex) => (
          <button
            key={slide.src}
            type="button"
            onClick={() => setIndex(slideIndex)}
            className={`h-2 rounded-full transition ${
              slideIndex === index ? "bg-primary" : "bg-primary/20 hover:bg-primary/40"
            }`}
            aria-label={`Go to ${slide.title}`}
          />
        ))}
      </div>
    </section>
  );
}
