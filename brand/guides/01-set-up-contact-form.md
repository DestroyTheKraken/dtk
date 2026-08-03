# 01 — Set Up Your Contact Form (Formspree)

The contact form at the bottom of your website sends you an **email** when someone fills it out.  
Formspree is a free service that handles that for you.

---

## What is “form action”? (plain English)

On your website, the contact form is wrapped in a `<form>` tag. One line inside that tag is called **`action`**.

That line is the **address where the form data gets sent** when someone clicks “Send Message.”

Right now in your file it looks like this (placeholder):

```
action="https://formspree.io/f/YOUR_FORM_ID"
```

`YOUR_FORM_ID` is a stand-in. You will replace it with **your real ID** from Formspree.

**File:** `/home/kraken/Projects/DTK/index.html`  
**Line:** about **311** (search for `YOUR_FORM_ID` if the line number shifts)

---

## Step 1 — Create a Formspree account

1. Open a browser.
2. Go to: **https://formspree.io**
3. Click **Sign Up** (free tier is enough to start).
4. Confirm your email if Formspree asks you to.

---

## Step 2 — Create a new form

1. After logging in, click **+ New Form** (or **Create Form**).
2. Name it something like: `Joshua Hickman Website Contact`
3. Formspree will show you a **form endpoint** — a web address that looks like:

   ```
   https://formspree.io/f/xyzabcde
   ```

   The part after `/f/` (example: `xyzabcde`) is your **Form ID**.

4. **Copy the full URL** — you need it in the next step.

---

## Step 3 — Paste your Form ID into `index.html`

1. Open this file in any text editor (Cursor, VS Code, Notepad++, etc.):

   ```
   /home/kraken/Projects/DTK/index.html
   ```

2. Use **Find** (`Ctrl+F`) and search for:

   ```
   YOUR_FORM_ID
   ```

3. You should see this line:

   ```html
   action="https://formspree.io/f/YOUR_FORM_ID"
   ```

4. Replace **only** `YOUR_FORM_ID` with your real ID from Step 2.

   **Before:**
   ```html
   action="https://formspree.io/f/YOUR_FORM_ID"
   ```

   **After** (example — yours will be different):
   ```html
   action="https://formspree.io/f/xyzabcde"
   ```

   ### Common mistake (causes “METHOD UNSUPPORTED” error)

   If Formspree gave you this full URL:

   ```
   https://formspree.io/f/xwvjdqdj
   ```

   You must **not** paste the whole thing on top of the existing URL. That creates a broken line like:

   ```html
   action="https://formspree.io/f/https://formspree.io/f/xwvjdqdj"
   ```

   That is wrong and Formspree will reject it.

   **Correct:** keep `https://formspree.io/f/` and only swap `YOUR_FORM_ID` for the short code (example: `xwvjdqdj`).

   **Wrong:** paste the entire Formspree URL inside the quotes.

5. **Save the file.**

---

## Step 4 — Tell Formspree which fields you use (recommended)

Your form sends these field names:

| Field name in HTML | What the visitor fills in |
|--------------------|---------------------------|
| `name` | Name |
| `email` | Email |
| `phone` | Phone |
| `interested` | Interested In (dropdown) |
| `message` | Message |

Formspree usually accepts these automatically. In the Formspree dashboard:

1. Open your form → **Settings**.
2. Make sure notifications go to **your email**.
3. Optional: turn on spam filtering if offered on your plan.

---

## Step 5 — Test the form

1. Preview the site locally (see Guide 00) or after you deploy (Guide 03).
2. Scroll to **Ready to Get Started?**
3. Fill in the form with test data and click **Send Message**.
4. Check your email (and Formspree dashboard → **Submissions**) for the test message.

If nothing arrives:

- Double-check you saved `index.html` with the correct Form ID (no extra spaces).
- Check Formspree spam folder / submissions tab.
- Make sure you confirmed your Formspree account email.

---

## Summary

| Term | Meaning |
|------|---------|
| **form action** | The URL inside `action="..."` on the `<form>` tag — where submissions go |
| **YOUR_FORM_ID** | Placeholder you replace with your Formspree ID |
| **File to edit** | `/home/kraken/Projects/DTK/index.html` |

---

## Next step

Open **Guide 02**: `guides/02-edit-your-website.md` (phone number and footer links)