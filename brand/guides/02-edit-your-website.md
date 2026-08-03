# 02 — Edit Your Website (`index.html`)

Everything visitors see is in **one file**:

```
/home/kraken/Projects/DTK/index.html
```

This guide covers **footer placeholders** in `index.html`:

1. Google Business Profile link (footer)
2. Facebook link (footer)

Phone is already set to **509.557.7298** in the footer. Skip Edit 1 unless you need to change it.

Yes — **all of these are in `index.html`**, at the **bottom of the page** in the section called **footer**.  
When you scroll to the very bottom of the website in a browser, you see a dark navy bar — that is the footer.

---

## How to open the file

1. In Cursor (or your editor), open:

   ```
   /home/kraken/Projects/DTK/index.html
   ```

2. Use **Find** (`Ctrl+F`) to jump to each placeholder below.

---

## Edit 1 — Phone number (footer, optional)

Already configured as `509.557.7298`. To change it, search for `tel:5095577298` in the footer and update both the `href` and visible number.

---

## Edit 2 — Google Business Profile link (footer)

### What to search for

```
YOUR_GOOGLE_BUSINESS
```

Around **line 370**.

### How to get your real link

1. Open **Google Business Profile** (Google Maps → your business → share link), **or**
2. Use a `g.page` short link if Google gave you one.

### Before

```html
<a href="https://g.page/YOUR_GOOGLE_BUSINESS" ...>Google Business Profile</a>
```

### After (example)

```html
<a href="https://g.page/my-business-name" ...>Google Business Profile</a>
```

Paste **your** full URL between the quotes after `href=`.

---

## Edit 3 — Facebook link (footer)

### What to search for

```
YOUR_PAGE
```

Around **line 371**.

### Before

```html
<a href="https://facebook.com/YOUR_PAGE" ...>Facebook</a>
```

### After (example)

```html
<a href="https://facebook.com/joshua.hickman.rural.it" ...>Facebook</a>
```

Use your real Facebook page username or full profile/page URL.

---

## Where is the footer in the file?

Look for this comment in `index.html`:

```html
<!-- FOOTER -->
```

Everything below that comment until the next `<!-- PACKAGE MODALS -->` comment is the footer.

**Visual map:**

```
index.html
├── Top: navbar + hero (your photo and headline)
├── Middle: packages, audit, why local
├── Contact form  ← Guide 01 (Formspree)
└── FOOTER        ← This guide (phone + links)
```

---

## Save and check

1. **Save** `index.html`.
2. Preview locally:

   ```bash
   cd /home/kraken/Projects/DTK
   python3 -m http.server 8080
   ```

3. Open **http://localhost:8080** and scroll to the bottom.
4. Confirm:
   - Phone number shows correctly
   - Google link opens your business page
   - Facebook link opens your page

---

## Next step

Open **Guide 03**: `guides/03-go-live-cloudflare.md`