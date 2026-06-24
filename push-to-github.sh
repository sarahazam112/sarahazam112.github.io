#!/bin/bash
set -euo pipefail

if ! gh auth status >/dev/null 2>&1; then
  echo "Not logged in. Run: gh auth login"
  exit 1
fi

USER=$(gh api user --jq .login)
echo "Logged in as ${USER}"

# Portfolio → sarahazam112.github.io (public site at https://USER.github.io)
PORTFOLIO_DIR="/Users/sarahazam/Downloads/website"
cd "$PORTFOLIO_DIR"
if gh repo view "${USER}.github.io" >/dev/null 2>&1; then
  echo "Repo ${USER}.github.io exists"
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/${USER}/${USER}.github.io.git"
else
  gh repo create "${USER}.github.io" --public --source=. --remote=origin --push
fi
git push -u origin main 2>/dev/null || git push -u origin main --force-with-lease

echo ""
echo "Enable GitHub Pages: https://github.com/${USER}/${USER}.github.io/settings/pages"
echo "Site URL (after Pages is on): https://${USER}.github.io/"

# AI Business Consultant
cd "/Users/sarahazam/Downloads/website/ai-business-consultant"
if gh repo view "ai-business-consultant" >/dev/null 2>&1; then
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/${USER}/ai-business-consultant.git"
else
  gh repo create "ai-business-consultant" --public --source=. --remote=origin
fi
git push -u origin main

# CS Interview Copilot
cd "/Users/sarahazam/Downloads/website/cs-interview-copilot"
if gh repo view "cs-interview-copilot" >/dev/null 2>&1; then
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/${USER}/cs-interview-copilot.git"
else
  gh repo create "cs-interview-copilot" --public --source=. --remote=origin
fi
git push -u origin main

echo ""
echo "Done. Repos:"
echo "  https://github.com/${USER}/${USER}.github.io"
echo "  https://github.com/${USER}/ai-business-consultant"
echo "  https://github.com/${USER}/cs-interview-copilot"
echo "  https://github.com/${USER}/ai-stock-research-assistant (push separately if needed)"
