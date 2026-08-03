# 03 — Deploy Your Site Live (Cloudflare Tunnel)

This guide puts your website on the internet using **Cloudflare Tunnel**.

You only need to:

1. Put your token in a file named **`.env`**
2. Run **one command**

You do **not** put your Cloudflare token inside `index.html`.

---

## What file gets your token?

Create this file:

```
/home/kraken/Projects/DTK/.env
```

It is a **secret settings file** (not shown on the website).  
`docker-compose.yml` reads `CLOUDFLARED_TOKEN` from `.env` automatically.

---

## Step 1 — Get your Cloudflare Tunnel token

1. Log in to **Cloudflare Zero Trust**: https://one.dash.cloudflare.com
2. Go to **Networks** → **Tunnels** (left sidebar).
3. Click **Create a tunnel**.
4. Choose **Cloudflared** connector → **Next**.
5. Name the tunnel (example: `dtk-website`).
6. On the **Install connector** screen, copy the **token** (long string).

   It may look like a long encoded string starting with `eyJ...`

7. Keep that tab open — you will configure the hostname in Step 2.

---

## Step 2 — Configure the public hostname (in Cloudflare dashboard)

Still in the tunnel setup:

1. Go to the **Public Hostname** tab (or add a route after creating the tunnel).
2. Add a hostname, for example:

   | Field | Example value |
   |-------|----------------|
   | Subdomain | `joshua` or `www` |
   | Domain | your domain on Cloudflare |
   | Path | leave empty |
   | Type | **HTTP** |
   | URL | **`localhost:80`** |

   Because `docker-compose.yml` runs the web server on port 80 inside the container, use **`localhost:80`** as the service URL.

3. Save the hostname.

---

## Step 3 — Create your `.env` file

### Option A — Copy the example file (recommended)

In a terminal:

```bash
cd /home/kraken/Projects/DTK
cp .env.example .env
```

### Option B — Create `.env` manually

Create a new file at `/home/kraken/Projects/DTK/.env` with exactly this format:

```
CLOUDFLARED_TOKEN=paste-your-token-here
```

**Rules:**

- No quotes around the token
- No spaces before or after `=`
- One line only (unless you add more variables later)

**Example** (fake token — use yours):

```
CLOUDFLARED_TOKEN=eyJhIjoiOGQ2M2Y4NTQwZDY0OGFiMzkxZjNmY2U2YTcyMzgwYWQiLCJ0IjoiZjNmMmIxMmQtMDdlYy00Njg1LThjYWItNmI2OGM2OThmOWM4IiwicyI6Ik1HWXlORGd5T0dJdE9EQTNOeTAwT1RRNUxXRmhOakV0TWpJd01qUmxORE5oTURnMCJ9
```

### Important security note

- **Never** commit `.env` to git or post the token publicly.
- If you already have a token in another project’s `.env`, you can use the same variable name: `CLOUDFLARED_TOKEN=...`

---

## Step 4 — Deploy (one command)

Make sure Docker is installed and running, then:

```bash
cd /home/kraken/Projects/DTK
docker compose up -d
```

What this does:

| Container | Job |
|-----------|-----|
| `dtk-web` | Serves `index.html` and your `img/` folder |
| `dtk-cloudflared` | Connects Cloudflare to your site using your token |

---

## Step 5 — Verify it works

1. Open the hostname you configured (example: `https://joshua.yourdomain.com`).
2. You should see your landing page.
3. Test the contact form (Guide 01) on the live site.

### Useful commands

```bash
# See if containers are running
docker compose ps

# View logs if something fails
docker compose logs -f

# Stop the site
docker compose down

# Restart after editing index.html
docker compose restart web
```

After you edit `index.html`, run `docker compose restart web` — no need to recreate the tunnel.

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| Blank page or 502 | Check tunnel URL is `localhost:80`; run `docker compose logs` |
| Old content showing | Run `docker compose restart web` after saving `index.html` |
| Token error | Re-copy token into `.env`; no quotes; run `docker compose down` then `up -d` |
| Form does not email you | Finish Guide 01 — problem is Formspree, not Cloudflare |

---

## What you edited vs what you did not

| Item | File | Guide |
|------|------|-------|
| Contact form address | `index.html` | 01 |
| Phone, Google, Facebook | `index.html` | 02 |
| Cloudflare token | `.env` | 03 (this file) |

---

## You are done

When all three guides are complete:

- [ ] Formspree connected (Guide 01)
- [ ] Phone and links updated (Guide 02)
- [ ] `.env` has `CLOUDFLARED_TOKEN` and site is live (Guide 03)

You do **not** need `/execute-plan` for this project.

If you want major new features later, read **Guide 00** for when to run `/design` and then `/execute-plan`.