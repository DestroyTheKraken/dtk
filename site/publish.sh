#!/usr/bin/env bash
# Publish DTK professional site + Media Hub installer artifacts.
# Live path: /home/kraken/www/destroythekraken (k8s hostPath + Cloudflare tunnel)
set -euo pipefail

DTK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MH="${DTK}/products/media-hub"
OUT_WWW="${DTK}/site/dist/www"
HOSTPATH="${HM_DTK_HOSTPATH:-/home/kraken/www/destroythekraken}"

if [[ ! -d "$MH" ]]; then
  echo "missing media-hub symlink: $MH" >&2
  exit 1
fi

echo "==> pack Media Hub release"
bash "${MH}/installer/pack-release.sh" --out "${MH}/dist/hickmedia-publish"
REL="${MH}/dist/hickmedia-publish"

echo "==> assemble www"
rm -rf "$OUT_WWW"
mkdir -p "$OUT_WWW/hickmedia" "$OUT_WWW/img" "$OUT_WWW/blog" "$OUT_WWW/js"
# Branded pages + assets (HTML, CSS, JS, blog)
cp -a "${DTK}/site/"*.html "$OUT_WWW/" 2>/dev/null || true
cp -a "${DTK}/site/"*.css "$OUT_WWW/" 2>/dev/null || true
cp -a "${DTK}/site/robots.txt" "$OUT_WWW/robots.txt" 2>/dev/null || true
cp -a "${DTK}/site/sitemap.xml" "$OUT_WWW/sitemap.xml" 2>/dev/null || true
rsync -a "${DTK}/site/img/" "$OUT_WWW/img/"
# Optional subdirs (Controlled Chaos portfolio)
[[ -d "${DTK}/site/js" ]] && rsync -a "${DTK}/site/js/" "$OUT_WWW/js/"
[[ -d "${DTK}/site/blog" ]] && rsync -a "${DTK}/site/blog/" "$OUT_WWW/blog/"
# drop publish helper if it ever lands as .html (none expected)
rm -f "$OUT_WWW/publish.html" 2>/dev/null || true
# Installer artifacts (stable paths)
install -m 644 "${MH}/public/hickmedia.sh" "$OUT_WWW/hickmedia.sh"
install -m 644 "${REL}/hickmedia-latest.tar.gz" "$OUT_WWW/hickmedia/latest.tar.gz"
(
  cd "$OUT_WWW"
  sha256sum hickmedia.sh hickmedia/latest.tar.gz > hickmedia/SHA256SUMS
)
cat >"$OUT_WWW/hickmedia/VERSION.txt" <<EOF
product=Sovereign Media Hub
brand=DestroyTheKraken
published=$(date -Is)
site=https://www.destroythekraken.com/
bootstrap=https://www.destroythekraken.com/hickmedia.sh
EOF

echo "==> sync hostPath $HOSTPATH"
mkdir -p "$HOSTPATH"
rsync -a --delete "${OUT_WWW}/" "${HOSTPATH}/"
# nginx in k8s must read files (world-readable; hostPath ownership is kraken)
find "$HOSTPATH" -type d -exec chmod 755 {} \;
find "$HOSTPATH" -type f -exec chmod 644 {} \;
# Restart nginx pod to clear any cache (optional)
if command -v kubectl >/dev/null 2>&1; then
  kubectl -n websites rollout restart deployment/destroythekraken 2>/dev/null || true
fi

echo "==> done"
du -sh "$OUT_WWW" "$HOSTPATH"
echo "Test: curl -fsSL https://www.destroythekraken.com/ | head -5"
echo "      curl -fsSL https://www.destroythekraken.com/hickmedia.sh | head -3"
