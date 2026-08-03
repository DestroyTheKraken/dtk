<!-- GrokBuild Prompt (Tailwind + Modals + Exact Formspree) to create a website landing page using Tailwind. This references several guiding documents within the project folder for content and references -->

#dtk #joshua-hickman #webdev

---

# GrokBuild Prompt

## Build a clean, professional single-page website for Joshua Hickman using Tailwind CSS + Alpine.js modals

### You are an expert front-end developer. Create a clean, modern, trustworthy single-page website for a local rural IT specialist.

#### Tech Stack (required):
- Tailwind CSS 3.4+ via Play CDN: `https://tailwindcss.com/docs/installation/play-cdn`
- Alpine.js via CDN for modals and interactivity: `https://unpkg.com/alpinejs`
- Single self-contained `index.html` file
- Fully responsive and mobile-first

#### Design Direction:

- Professional, trustworthy, and approachable rural Pacific Northwest aesthetic
- Color palette: Deep navy (`#0f2744`), warm amber accent (`#d97757`), clean whites, soft grays, and dark text
- Use the professional headshot prominently
- Use the three mountain/starry photos in `img/` for subtle backgrounds or accents
- Generous whitespace, clear hierarchy, and a grounded, reliable feel

#### Content Source

Use the exact marketing language, package descriptions, pricing, and brand story from:

- `Content_Master.md` — Single Source of Truth (client copy, packages, pricing)
- `DTK_About.md` — full biography, homelab detail, career direction (polished source for About section)

#### Required Page Structure:

**1. Sticky Navbar**
- Logo: `img/logo.png` (site logo + favicon) with “Destroy the Kraken” text beside it on larger screens
- Links: About, Audit, Packages, Why Local, Contact
- Mobile hamburger menu (using Alpine.js)

**2. Hero Section**
- Strong headline and subheadline from Content_Master.md
- Prominent headshot
- Primary CTA: “Get Your Free 15-Minute Audit”
- Secondary CTA that scrolls to packages

**3. About Section — Why Destroy the Kraken**
- Client-facing explanation of the name (from Content_Master “Brand” section)
- Condensed “Who I Am” bio; link to destroythekraken.com for portfolio

**4. The Local Challenge Section**
- Use the exact content from the Single Source of Truth document

**5. Free Audit Section**
- Include the audit description from Content_Master.md
- Single CTA button that scrolls to the contact form (conversation script is private — see `notes/Free-Audit-Conversation-Script.md`)

**6. Packages Section (with Modals)**
- Display 4 package cards using Tailwind grid/cards
- Each card shows: Title, Price, short description, and a **“Get Started”** button
- Clicking “Get Started” opens a **Tailwind + Alpine.js modal** containing:
  - Full package details (pulled from the document)
  - Benefits
  - “Contact Me About This Package” button that closes the modal and smoothly scrolls to the contact form while pre-selecting the package in a hidden or dropdown field

**7. Why Work With a Local Expert Section**
- Use the exact points from the document

**8. Contact Section**
- Clean contact form with these fields:
  - Name (required)
  - Email (required)
  - Phone
  - Interested In (select or checkboxes): Free Audit / Starlink Optimization / Nextcloud Hub / Monthly Retainer / Bundle
  - Message
- See `guides/01-set-up-contact-form.md` for Formspree setup

**9. Footer**
- Destroy the Kraken · Joshua Hickman
- Location text + phone + links to Google Business Profile and Facebook

**Modal Requirements:**
- Use Alpine.js for clean, accessible modals
- Modals should feel premium but lightweight
- Each package modal must include a clear “Contact Me” button that scrolls to the form and pre-fills the “Interested In” field
- Include a close button (X) and close on outside click / ESC key

**Additional Technical Instructions:**
- Make the site feel fast and lightweight - SINGLE PAGE ONLY
- Use Tailwind’s responsive utilities heavily
- Add subtle mountain-themed visual accents without clutter
- Include helpful HTML comments throughout the code explaining sections and how to customize
- At the very top of the file, add a comment block with today’s date and “Generated from Single Source of Truth v1.0 – Tailwind + Alpine Modals + Formspree”

**Output Instructions:**
Output the **complete, ready-to-use single `index.html` file**. The code should be clean, well-organized, and production-ready with minimal extra fluff. Respond with deployment instructions to my .env CLOUDFLARED_TOKEN to deploy.
