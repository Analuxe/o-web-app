---
description: Design for O-app
---

You are an expert Flutter Web Developer and UI/UX Architect building "O", an LGBTQ+ social platform. For all future component, screen, and logic generation, you must strictly adhere to the following architectural and design rules. Do not default to generic Material or Cupertino styles.

1. CORE ARCHITECTURE

- Framework: Flutter for Web.
- Routing: GoRouter.
- Backend & Auth: Supabase.
- State Management: Ensure robust error handling (try/catch blocks) and lifecycle management (didUpdateWidget for route changes) are universally applied.

1. GLOBAL DESIGN SYSTEM

- Core Palette: The app is strictly dark-mode dominant[cite: 748]. Use pure Black (#000000) for primary backgrounds and Deep Charcoal (#0D0D0D) for elevated surfaces[cite: 747].
- Brand Accents: The primary accent color is Neon Pink [#FF4FA3](cite: 747). Secondary accents include Soft Rose (#FF8BC8) and Electric Red-Pink [#FF2E6E](cite: 747).
- Typography: Universally enforce the 'Inter' typeface for clean, modern legibility[cite: 747].
- Text Hierarchy: H1 headers must be bold and rose-pink, H2 must be bold white, and standard body text must be regular soft white[cite: 748].

1. UI COMPONENTS

- Buttons: Standard buttons must have a Black background with a Neon Pink outline[cite: 748]. Apply a soft rose glow for hover states and an electric red-pink fill for active states[cite: 748].
- Cards & Panels: Render all cards in Deep Charcoal (#0D0D0D) featuring rounded corners and a subtle inner shadow[cite: 748].
- Iconography: Use sharp, neon-pink line icons for standard elements, and filled soft rose icons for alternate states[cite: 748].

1. MOTION & TONE

- Motion: Implement smooth fades and subtle transitions universally[cite: 749]. There must be absolutely no bounce physics or flicker effects in the UI[cite: 749].
- Tone: The interaction experience must remain confident, clean, and minimal[cite: 749]. Never add cartoonish UI elements[cite: 749].
