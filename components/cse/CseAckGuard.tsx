"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

const ACK_KEY = "cse_ack_v1";

export default function CseAckGuard() {
  const router = useRouter();

  useEffect(() => {
    const acknowledged = window.localStorage.getItem(ACK_KEY) === "true";
    if (!acknowledged) {
      router.replace("/cse/how-it-works");
    }
  }, [router]);

  return null;
}
