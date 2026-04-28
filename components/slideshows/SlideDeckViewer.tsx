"use client";

import { useEffect, useMemo, useState } from "react";
import type { SlideshowSlide } from "../../lib/slideshows";

type SlideDeckViewerProps = {
  slides: SlideshowSlide[];
};

const imageCacheVersion = "2026-04-28-cse-slides";

export default function SlideDeckViewer({ slides }: SlideDeckViewerProps) {
  const [index, setIndex] = useState(0);
  const [failedImageSrc, setFailedImageSrc] = useState<string | null>(null);
  const [retryVersions, setRetryVersions] = useState<Record<string, number>>({});
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

  useEffect(() => {
    setFailedImageSrc(null);
  }, [current?.src]);

  if (!hasSlides || !current) {
    return null;
  }

  const imageFailed = failedImageSrc === current.src;
  const retryVersion = retryVersions[current.src] ?? 0;
  const imageSrc = `${current.src}?v=${imageCacheVersion}&retry=${retryVersion}`;

  function retryCurrentImage() {
    setFailedImageSrc(null);
    setRetryVersions((previous) => ({
      ...previous,
      [current.src]: (previous[current.src] ?? 0) + 1,
    }));
  }

  return (
    <section className="rounded-2xl border border-graysoft/30 bg-white p-4 shadow-sm sm:p-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">{progressLabel}</p>
          {current.category ? (
            <p className="mt-1 text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">{current.category}</p>
          ) : null}
          <h2 className="mt-1 text-lg font-semibold text-charcoal">{current.title}</h2>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
          {slides.length > 1 ? (
            <label className="sr-only" htmlFor="slide-jump">
              Jump to slide
            </label>
          ) : null}
          {slides.length > 1 ? (
            <select
              id="slide-jump"
              value={index}
              onChange={(event) => setIndex(Number(event.target.value))}
              className="rounded-lg border border-graysoft/30 bg-white px-3 py-2 text-sm font-semibold text-charcoal shadow-sm outline-none transition focus:border-primary"
            >
              {slides.map((slide, slideIndex) => (
                <option key={slide.src} value={slideIndex}>
                  {slideIndex + 1}. {slide.title}
                </option>
              ))}
            </select>
          ) : null}
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

      <div className="relative mt-5 overflow-hidden rounded-2xl border border-graysoft/30 bg-slate-50">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          key={imageSrc}
          src={imageSrc}
          alt={current.alt}
          className="aspect-video w-full bg-white object-contain"
          onLoad={() => {
            setFailedImageSrc(null);
          }}
          onError={() => {
            setFailedImageSrc(current.src);
          }}
        />
        {imageFailed ? (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-slate-50/95 p-6 text-center">
            <p className="text-sm font-semibold text-charcoal">Slide image not found yet</p>
            <p className="mt-2 max-w-md text-xs leading-relaxed text-graysoft">
              Expected file: <span className="font-mono text-charcoal">{current.src}</span>
            </p>
            <div className="mt-4 flex flex-col gap-2 sm:flex-row">
              <button
                type="button"
                onClick={retryCurrentImage}
                className="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white transition hover:bg-primary/90"
              >
                Retry Image
              </button>
              <a
                href={current.src}
                target="_blank"
                rel="noreferrer"
                className="rounded-lg border border-primary/40 bg-white px-4 py-2 text-sm font-semibold text-primary transition hover:bg-primary/5"
              >
                Open Image
              </a>
            </div>
          </div>
        ) : null}
      </div>

      <div className="mt-4 grid grid-cols-8 gap-2 sm:grid-cols-12" aria-label="Slide navigation">
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
