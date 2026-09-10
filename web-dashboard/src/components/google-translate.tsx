"use client";

import { useEffect } from "react";

export function GoogleTranslate() {
  useEffect(() => {
    // Only initialize if it hasn't been added yet
    if (!document.getElementById("google-translate-script")) {
      const script = document.createElement("script");
      script.id = "google-translate-script";
      script.src = "https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit";
      script.async = true;
      document.body.appendChild(script);

      window.googleTranslateElementInit = () => {
        new window.google.translate.TranslateElement(
          {
            pageLanguage: "en",
            autoDisplay: false,
          },
          "google_translate_element"
        );
      };
    }
  }, []);

  return <div id="google_translate_element" style={{ display: "none" }} />;
}

// Add type definition for window object
declare global {
  interface Window {
    googleTranslateElementInit: () => void;
    google: any;
  }
}
