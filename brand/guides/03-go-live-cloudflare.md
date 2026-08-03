# 03 — Go Live with Cloudflare (Complete Setup)

**Goal:** Anyone on the internet can open your website at a real address (example: `https://www.yourdomain.com`).

This is the **only guide you need for Cloudflare**. Work through every step in order. Check off each box as you go.

---

## Before you start

| Requirement | Status |
|-------------|--------|
| Guide 01 done (Formspree contact form works) | ☐ |
| Guide 02 done (phone + links in `index.html`) | ☐ |
| Docker installed on the computer that will run the site | ☐ |
| A domain name you own (example: `joshuahickman.com`) | ☐ |
| That domain added to your **Cloudflare** account | ☐ |

**Where your website files live:**

```
/home/kraken/Projects/DTK/
├── index.html          ← your website
├── img/                ← photos
├── .env                ← you create this (Cloudflare token)
└── docker-compose.yml  ← starts the site + tunnel
```

---

## How this works (30-second version)

```
Visitor types your domain in a browser
        ↓
Cloudflare (internet-facing, HTTPS)
        ↓
Cloudflare Tunnel (secure pipe — no open ports on your router)
        ↓
Docker on your computer serves index.html
```

You configure **Cloudflare in the browser**. You paste **one token** into `.env`. You run **one command** in the terminal.

---

# Part A — Cloudflare Dashboard Setup

Do this in your web browser. Log in at: **https://one.dash.cloudflare.com**

---

## Step A1 — Confirm your domain is on Cloudflare

1. Open **https://dash.cloudflare.com**
2. You should see your domain listed (example: `yourdomain.com`).
3. If you do **not** see it:
   - Click **Add a site**
   - Enter your domain and follow Cloudflare’s steps to change nameservers at your domain registrar
   - Wait until Cloudflare shows the domain as **Active** (can take up to 24 hours, often faster)

You cannot get a public `https://yourdomain.com` address until the domain is Active on Cloudflare.

---

## Step A2 — Create a Tunnel

1. Go to **https://one.dash.cloudflare.com** (Zero Trust dashboard).
2. Left sidebar → **Networks** → **Connectors** → **Cloudflare Tunnels**  
   (Older UI may say **Networks** → **Tunnels**.)
3. Click **Create a tunnel**.
4. Choose **Cloudflared** → **Next**.
5. **Tunnel name:** `dtk-website` (or any name you like) → **Save tunnel**.

---

## Step A3 — Copy your tunnel token (`CLOUDFLARED_TOKEN`)

Your **`CLOUDFLARED_TOKEN`** is a long secret string Cloudflare gives you when you create a tunnel.  
It is **not** your Cloudflare account password. It is **not** your domain name. It usually starts with **`eyJ`**.

### Where to find it (brand-new tunnel)

Right after Step A2, Cloudflare shows the **Install connector** page.

1. Under **Choose an environment**, pick **Docker** or **Linux** (either is fine — you only need the token).
2. Look for a command box that looks like this:

   ```
   docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token eyJhIjoi...very-long-string...
   ```

   or:

   ```
   cloudflared tunnel run --token eyJhIjoi...very-long-string...
   ```

3. Copy **only the part after `--token`** (the long `eyJ...` string).
4. Paste it into a temporary note — you will put it in `.env` in Part B.

**Do not share this token publicly.** Anyone with it could route traffic through your tunnel.

You can click **Next** without running that command — Docker in Part C handles it.

---

## Step A3b — Can't find your token? (already created a tunnel)

Cloudflare **only shows the full token once** during setup. If you closed that page, use one of these:

### Method 1 — Get token from an existing tunnel (most common)

1. Go to **https://one.dash.cloudflare.com**
2. Left sidebar → **Networks** → **Connectors** → **Cloudflare Tunnels**
3. Click the **name** of your tunnel (example: `dtk-website`).
4. Open the **Configure** tab (or click **Edit** / **⋯** menu → **Configure**).
5. Look for **Install connector** or **Refresh token**.
6. Cloudflare shows the install command again. Copy everything after `--token`.

### Method 2 — Refresh / regenerate the token

If you still do not see a token:

1. On the same tunnel page → **Configure**.
2. Click **Refresh token** or **Regenerate token** (wording varies).
3. Confirm — the old token stops working; that is OK if you never used it.
4. Copy the **new** token from the updated install command (`--token eyJ...`).

### Method 3 — Create a fresh tunnel (if totally stuck)

1. **Networks** → **Cloudflare Tunnels** → **Create a tunnel**
2. Name it `dtk-website-v2` → save
3. Copy the token from the install command immediately
4. Add your public hostname (Step A4) to this new tunnel
5. Use this new token in `.env`

### What is NOT your token

| This is NOT it | What it actually is |
|----------------|---------------------|
| Your Cloudflare login email/password | Account login |
| Your domain name (`yourdomain.com`) | Website address |
| API Token from **My Profile → API Tokens** | Different feature — wrong type |
| Global API Key | Wrong — do not use this |
| Account ID / Zone ID | Wrong — do not use this |

### What the token looks like

- One long line, no spaces
- Often 200–400+ characters
- Starts with something like `eyJhIjoi...`
- Example shape (fake, shortened):

  ```
  eyJhIjoiYWJjMTIzIiwidCI6IjEyMzQ1NiIsInMiOiJYWVoifQ==
  ```

  Yours will be **much longer** than this example.

---

## Step A4 — Add a Public Hostname (this is your live website address)

Still in the tunnel setup (or open your tunnel → **Public Hostname** tab → **Add a public hostname**).

Fill in exactly:

| Field | What to enter |
|-------|----------------|
| **Subdomain** | `www` (recommended) or leave blank for root domain |
| **Domain** | Pick your domain from the dropdown (example: `yourdomain.com`) |
| **Path** | Leave **empty** |
| **Type** | `HTTP` |
| **URL** | `localhost:80` |

**Critical:** The URL must be **`localhost:80`** — not `8080`, not `web:80`, not your computer’s LAN IP.

Click **Save hostname**.

### Optional: also serve the root domain

Many people want both `yourdomain.com` and `www.yourdomain.com`:

1. Add a **second** public hostname.
2. Leave **Subdomain** blank (root).
3. Same domain, empty path, HTTP, `localhost:80`.
4. Save.

---

## Step A5 — Confirm tunnel route saved

In the tunnel’s **Public Hostname** list you should see something like:

```
www.yourdomain.com  →  http://localhost:80
```

Status can show **Inactive** until you start Docker in Part C — that is normal.

---

# Part B — Create Your `.env` File and Add the Token

The **`.env`** file is a small secret settings file on your computer.  
Docker reads it automatically. Visitors never see it.

**Full path:**

```
/home/kraken/Projects/DTK/.env
```

**What goes inside (one line):**

```
CLOUDFLARED_TOKEN=paste-your-token-here
```

The name `CLOUDFLARED_TOKEN` must be spelled exactly like that — all caps, underscore, no spaces.

---

## Step B1 — Create the `.env` file

Pick **one** method below.

### Method A — Terminal (easiest)

```bash
cd /home/kraken/Projects/DTK
cp .env.example .env
```

That creates `.env` from the example template.

### Method B — Cursor (click-by-click)

1. In Cursor, open the folder `/home/kraken/Projects/DTK`
2. In the file list on the left, find `.env.example`
3. Right-click `.env.example` → **Copy**
4. Right-click empty space in the file list → **Paste**
5. Rename the copy from `.env.example copy` to exactly: **`.env`**

   Important: the filename is `.env` — it starts with a dot and has no `.txt` at the end.

### Method C — Create from scratch in Cursor

1. In `/home/kraken/Projects/DTK`, click **New File**
2. Name it exactly: `.env`
3. Cursor may ask you to confirm — say yes

---

## Step B2 — Paste your token into `.env`

1. Open `.env` in Cursor (or any text editor).
2. Delete everything in the file.
3. Type or paste this **on one single line**:

   ```
   CLOUDFLARED_TOKEN=
   ```

4. Immediately after the `=` sign (no space), paste your full token from Step A3 or A3b.

### Correct example

```
CLOUDFLARED_TOKEN=eyJhIjoiOGQ2M2Y4NTQwZDY0OGFiMzkxZjNmY2U2YTcyMzgwYWQiLCJ0IjoiZjNmMmIxMmQtMDdlYy00Njg1LThjYWItNmI2OGM2OThmOWM4IiwicyI6Ik1HWXlORGd5T0dJdE9EQTNOeTAwT1RRNUxXRmhOakV0TWpJd01qUmxORE5oTURnMCJ9
```

(Use **your** token — not this example unless it is actually yours.)

### Wrong examples (will not work)

```
CLOUDFLARED_TOKEN = eyJ...          ← spaces around = are wrong
CLOUDFLARED_TOKEN="eyJ..."          ← do not use quotes
CLOUDFLARED_TOKEN=eyJ...
eyJ...more-on-next-line              ← must be ONE line only
```

5. **Save** the file (`Ctrl+S`).

---

## Step B3 — Confirm `.env` exists (terminal check)

```bash
cd /home/kraken/Projects/DTK
ls -la .env
```

You should see a file listed. Then verify the variable name (does not print your token):

```bash
grep CLOUDFLARED_TOKEN .env
```

You should see one line starting with `CLOUDFLARED_TOKEN=eyJ` — the rest of the token will follow.

If you see `your-tunnel-token-here`, you still have the placeholder — go back to Step A3b and get your real token.

---

# Part C — Start the Site

---

## Step C1 — Make sure Docker is running

```bash
docker --version
```

If that fails, install Docker first, then continue.

---

## Step C2 — Start containers

```bash
cd /home/kraken/Projects/DTK
docker compose up -d
```

Expected output: containers `dtk-web` and `dtk-cloudflared` are **Started** or **Running**.

---

## Step C3 — Check containers are healthy

```bash
docker compose ps
```

Both services should show **running**.

If `dtk-cloudflared` keeps restarting:

```bash
docker compose logs cloudflared
```

Common causes: wrong token, extra spaces in `.env`, or expired token (create a new tunnel token in dashboard).

---

## Step C4 — Confirm tunnel is connected in Cloudflare

1. Back in **https://one.dash.cloudflare.com** → your tunnel.
2. The connector status should change to **Healthy** / **Connected** within a minute or two.

If it stays **Inactive**, check logs (Step C3) and re-verify your `.env` token.

---

# Part D — Verify the Public Can See Your Site

---

## Step D1 — Open your live URL

In a browser, go to the address you configured in Step A4, for example:

```
https://www.yourdomain.com
```

You should see your Joshua Hickman landing page (hero, packages, contact form).

**Tips:**

- Use **HTTPS** (Cloudflare adds this automatically).
- Try an **incognito/private** window to avoid cached old pages.
- Try your **phone on cellular** (not home WiFi) to confirm it is truly public.

---

## Step D2 — Quick local check (optional)

Your site is also reachable on this machine at:

```
http://localhost:8080
```

That address is **only for you on this computer** — it is not what the public uses. The public uses your Cloudflare domain from Step D1.

---

## Step D3 — Test the contact form on the live site

1. Scroll to **Ready to Get Started?**
2. Submit a test message.
3. Confirm email arrives (Guide 01 / Formspree).

---

# Part E — After You Go Live

### When you edit `index.html`

```bash
cd /home/kraken/Projects/DTK
docker compose restart web
```

No need to restart the tunnel for content changes.

### Stop the site temporarily

```bash
docker compose down
```

Your public URL will go offline until you run `docker compose up -d` again.

### View logs

```bash
docker compose logs -f
```

Press `Ctrl+C` to exit logs.

---

# Troubleshooting

| What you see | Likely cause | Fix |
|--------------|--------------|-----|
| **502 Bad Gateway** | Tunnel cannot reach the web server | Confirm public hostname URL is `localhost:80`. Run `docker compose ps` — both containers must be running. |
| **Tunnel Inactive / Disconnected** | Token wrong or cloudflared not running | Fix `.env`, then `docker compose down && docker compose up -d`. Check `docker compose logs cloudflared`. |
| **Can't find CLOUDFLARED_TOKEN** | Token only shown at tunnel creation | See **Step A3b** — open tunnel → Configure → Install connector or Refresh token |
| **`.env` file missing** | File not created yet | Follow **Part B** — run `cp .env.example .env` or create `.env` in Cursor |
| **Error 1033** or Cloudflare error page | Tunnel not connected | Same as above — wait for connector **Healthy** in dashboard. |
| **Site works locally on :8080 but not on domain** | Public hostname not configured or DNS not on Cloudflare | Finish Steps A1 and A4. Domain must be **Active** on Cloudflare. |
| **SSL / certificate warnings** | DNS still propagating | Wait 15–60 minutes. In Cloudflare → SSL/TLS, set mode to **Full** (not Strict unless you have origin certs). |
| **Old version of the page** | Browser cache | Hard refresh: `Ctrl+Shift+R`. Try incognito. |
| **Blank page** | `index.html` missing or wrong folder mounted | Confirm `/home/kraken/Projects/DTK/index.html` exists. `docker compose restart web`. |

### SSL/TLS setting (one-time, if HTTPS acts odd)

1. **https://dash.cloudflare.com** → your domain → **SSL/TLS**.
2. Set encryption mode to **Full** (recommended for this setup).

---

# Final Checklist — You Are Live When All Are Checked

- [ ] Domain is **Active** on Cloudflare (Step A1)
- [ ] Tunnel created and token copied (Steps A2–A3)
- [ ] Public hostname points to `http://localhost:80` (Step A4)
- [ ] `.env` file has `CLOUDFLARED_TOKEN=...` with no typos (Part B)
- [ ] `docker compose up -d` — both containers running (Part C)
- [ ] Tunnel shows **Healthy** in Cloudflare dashboard (Step C4)
- [ ] `https://www.yourdomain.com` loads your site in incognito (Step D1)
- [ ] Contact form works on the live URL (Step D3)

**When every box is checked, your site is live for the general public.**

---

## What to tell people

Share your public URL, for example:

> Visit **https://www.yourdomain.com** for Starlink optimization and private Nextcloud setup in Omak and Okanogan County.

---

## Need help?

If you are stuck, tell Grok:

1. Which step you are on (example: “Step C4 — tunnel stays Inactive”).
2. Output of `docker compose ps`.
3. Last 10 lines of `docker compose logs cloudflared` (redact your token).

Do **not** paste your full `CLOUDFLARED_TOKEN` in chat.