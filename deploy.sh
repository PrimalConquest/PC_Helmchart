#!/bin/bash
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────
SECRETS_FILE="./deploy-secrets"
HELM_CHART_DIR="./PrimalConquest"
HELM_PACKAGE="./primal-conquest-0.1.0.tgz"
KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
VALUES_FILE="$HELM_CHART_DIR/values.prod.yaml"
RELEASE_NAME="primal-conquest"

# ── Load secrets ──────────────────────────────────────────────────
if [ ! -f "$SECRETS_FILE" ]; then
  echo "ERROR: Secrets file '$SECRETS_FILE' not found."
  exit 1
fi
source "$SECRETS_FILE"

# ── Validate required secrets ─────────────────────────────────────
: "${JWT_SECRET:?JWT_SECRET is not set in $SECRETS_FILE}"
: "${INTERNAL_API_KEY:?INTERNAL_API_KEY is not set in $SECRETS_FILE}"
: "${DB_USERNAME:?DB_USERNAME is not set in $SECRETS_FILE}"
: "${DB_PASSWORD:?DB_PASSWORD is not set in $SECRETS_FILE}"

# ── Pull latest chart source ──────────────────────────────────────
echo ">>> Pulling latest changes..."
git pull

# ── Update Helm dependencies ──────────────────────────────────────
echo ">>> Updating Helm dependencies..."
sudo helm dependency update "$HELM_CHART_DIR"

# ── Package chart ─────────────────────────────────────────────────
echo ">>> Packaging chart..."
sudo helm package "$HELM_CHART_DIR"

# ── Deploy ────────────────────────────────────────────────────────
echo ">>> Deploying '$RELEASE_NAME'..."
sudo -E helm upgrade --install "$RELEASE_NAME" "$HELM_PACKAGE" \
  --kubeconfig "$KUBECONFIG" \
  -f "$VALUES_FILE" \
  --set database.dbsecret.username="$DB_USERNAME" \
  --set database.dbsecret.password="$DB_PASSWORD" \
  --set database.authsecret.jwtSecret="$JWT_SECRET" \
  --set database.authsecret.internalApiKey="$INTERNAL_API_KEY"

echo ">>> Deploy complete!"