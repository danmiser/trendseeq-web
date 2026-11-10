#!/usr/bin/env bash
# Deploy www.trendseeq.com to GitHub Pages.
#
#   ./deploy.sh            first run: create repo, push, enable Pages + custom domain
#                          later runs: commit any changes and push (Pages redeploys automatically)
#   ./deploy.sh https      enforce HTTPS (run once DNS is live and the certificate is issued)
#   ./deploy.sh status     show Pages / certificate / DNS status
#   ./deploy.sh preview    serve the site locally at http://localhost:8000
set -euo pipefail
cd "$(dirname "$0")"

REPO_NAME="trendseeq-web"
DOMAIN="www.trendseeq.com"
APEX="trendseeq.com"

need() { command -v "$1" >/dev/null || { echo "Missing '$1'. Install it (brew install $1) and retry."; exit 1; }; }
need git; need gh
gh auth status >/dev/null 2>&1 || { echo "Run: gh auth login"; exit 1; }
OWNER="$(gh api user -q .login)"
FULL="$OWNER/$REPO_NAME"

case "${1:-deploy}" in
  preview)
    echo "http://localhost:8000"; exec python3 -m http.server 8000 ;;

  status)
    gh api "repos/$FULL/pages" -q '"Pages: \(.status)  URL: \(.html_url)  CNAME: \(.cname)  HTTPS enforced: \(.https_enforced)  Cert: \(.https_certificate.state // "none")"'
    echo "DNS $DOMAIN -> $(dig +short "$DOMAIN" | tr '\n' ' ')"
    echo "DNS $APEX   -> $(dig +short "$APEX" | tr '\n' ' ')"
    exit 0 ;;

  https)
    gh api -X PUT "repos/$FULL/pages" -F https_enforced=true >/dev/null && echo "HTTPS enforced on https://$DOMAIN"
    exit 0 ;;

  deploy) ;;
  *) echo "Unknown command: $1"; exit 1 ;;
esac

# 1. Git repo + commit
if [ ! -d .git ]; then
  git init -q -b main
fi
git add -A
if ! git diff --cached --quiet; then
  git commit -q -m "Update site $(date +%Y-%m-%d)"
  echo "Committed changes."
fi

# 2. GitHub repo (public: GitHub Pages is free for public repos)
if ! git remote get-url origin >/dev/null 2>&1; then
  if gh repo view "$FULL" >/dev/null 2>&1; then
    git remote add origin "https://github.com/$FULL.git"
  else
    gh repo create "$FULL" --public --description "TrendSeeq, LLC website" --homepage "https://$DOMAIN" --source . --remote origin
  fi
fi
git push -u origin main

# 3. Enable GitHub Pages from main branch root (idempotent)
if ! gh api "repos/$FULL/pages" >/dev/null 2>&1; then
  gh api -X POST "repos/$FULL/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null
  echo "GitHub Pages enabled."
fi
gh api -X PUT "repos/$FULL/pages" -f "cname=$DOMAIN" >/dev/null
echo "Custom domain set to $DOMAIN."

cat <<EOF

Deployed. Pages URL: https://$OWNER.github.io/$REPO_NAME/  (redirects to $DOMAIN once DNS is live)

One-time DNS setup at Hover (hover.com > $APEX > DNS), if not already done:
  - Delete the existing parking records for '@' and 'www' (A 216.40.34.41 / the '*' record).
  - Add  CNAME  www  ->  $OWNER.github.io
  - Add  A      @    ->  185.199.108.153
  - Add  A      @    ->  185.199.109.153
  - Add  A      @    ->  185.199.110.153
  - Add  A      @    ->  185.199.111.153
Then wait for DNS (minutes to a few hours), check with './deploy.sh status',
and once the certificate shows 'approved' run './deploy.sh https'.
EOF
