#!/bin/bash
# Deploy Streamlit apps via Community Cloud API.
# Prerequisites:
#   1. Streamlit connected to GitHub at share.streamlit.io
#   2. export STREAMLIT_TOKEN="..."  (Settings → API tokens)
#   3. export GROQ_API_KEY="..."     (same key as local .env)

set -euo pipefail

API="https://api.streamlit.io/v1"

if [[ -z "${STREAMLIT_TOKEN:-}" ]]; then
  echo "Missing STREAMLIT_TOKEN. Create one at https://share.streamlit.io → Settings → API tokens"
  exit 1
fi

if [[ -z "${GROQ_API_KEY:-}" ]]; then
  echo "Missing GROQ_API_KEY. Export your Groq key (do not commit it)."
  exit 1
fi

auth_header="Authorization: Bearer ${STREAMLIT_TOKEN}"

deploy_app() {
  local repo="$1"
  local name="$2"
  local main_file="${3:-app.py}"

  echo ""
  echo "=== Deploying ${name} (${repo}) ==="

  # Check if already deployed
  existing=$(curl -sS -H "$auth_header" "${API}/apps" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for app in data.get('apps', []):
    if app.get('repo') == '${repo}':
        print(app['id'])
        break
" 2>/dev/null || true)

  if [[ -n "$existing" ]]; then
    echo "Already deployed (app id: ${existing}). Updating secrets..."
    app_id="$existing"
  else
    response=$(curl -sS -X POST -H "$auth_header" -H "Content-Type: application/json" \
      -d "{\"repo\":\"${repo}\",\"branch\":\"main\",\"mainFile\":\"${main_file}\",\"appName\":\"${name}\"}" \
      "${API}/apps")
    app_id=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null || echo "")
    if [[ -z "$app_id" ]]; then
      echo "Deploy response: $response"
      echo "If deploy failed, create the app manually at https://share.streamlit.io"
      return 1
    fi
    echo "Deployed (app id: ${app_id})"
  fi

  curl -sS -X PUT -H "$auth_header" -H "Content-Type: application/json" \
    -d "$(GROQ_API_KEY="${GROQ_API_KEY}" python3 -c 'import json,os; print(json.dumps({"secrets": "GROQ_API_KEY = \"" + os.environ["GROQ_API_KEY"].replace("\\","\\\\").replace("\"","\\\"") + "\""}))')" \
    "${API}/apps/${app_id}/secrets" >/dev/null

  url=$(curl -sS -H "$auth_header" "${API}/apps/${app_id}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('url',''))" 2>/dev/null || echo "")
  echo "URL: ${url:-check https://share.streamlit.io}"
}

deploy_app "sarahazam112/ai-stock-research-assistant" "AI Stock Research Assistant"
deploy_app "sarahazam112/ai-business-consultant" "AI Business Consultant"
deploy_app "sarahazam112/cs-interview-copilot" "CS Interview Copilot"

echo ""
echo "Done. Copy the URLs above into index.html Open Live App buttons."
