#!/usr/bin/env bash
set -e

# ── Reads kickstart.config.yml and wires up GitHub + GH Pages ──
# Dependencies: gh (GitHub CLI), python3
# Usage: ./scripts/setup.sh

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/kickstart.config.yml"

# Parse YAML values (no yq dependency — pure python)
get() {
  python3 -c "
import re, sys
key = '$1'
for line in open('$CONFIG'):
    m = re.match(r'\s*' + re.escape(key) + r':\s*(.+)', line)
    if m: print(m.group(1).strip()); sys.exit()
print(''); sys.exit(1)
"
}

REPO=$(get github_repo)
VERCEL_URL=$(get vercel_production_url)
BASE_PATH=$(get github_pages_base_path)
PROJECT=$(get name)

echo "▶  Project  : $PROJECT"
echo "▶  Repo     : $REPO"
echo "▶  Vercel   : $VERCEL_URL"
echo "▶  GH Pages : https://${REPO%%/*}.github.io${BASE_PATH}"
echo ""

# ── GitHub Actions variables ────────────────────────────────
echo "Setting GitHub Actions variables..."
gh variable set VITE_API_URL  --body "${VERCEL_URL}/api" --repo "$REPO"
echo "  ✓ VITE_API_URL=${VERCEL_URL}/api"

# ── Update vite.config base path in workflow ────────────────
WORKFLOW="$ROOT/.github/workflows/deploy-pages.yml"
sed -i "s|VITE_BASE_PATH:.*|VITE_BASE_PATH: $BASE_PATH|" "$WORKFLOW"
echo "  ✓ VITE_BASE_PATH=$BASE_PATH in deploy-pages.yml"

# ── Enable GitHub Pages (idempotent) ───────────────────────
echo "Enabling GitHub Pages..."
gh api "repos/$REPO/pages" -X POST --field build_type=workflow 2>/dev/null \
  && echo "  ✓ GitHub Pages enabled" \
  || echo "  ✓ GitHub Pages already enabled"

echo ""
echo "Done. Commit any changed files and push to deploy."
