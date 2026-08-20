#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IPA="${1:-}"
if [[ -z "$IPA" ]]; then
  IPA="$(ls -1t "$ROOT"/build/export/*.ipa 2>/dev/null | head -1 || true)"
fi
API_KEY="${ASC_KEY_ID:-3K44W79Y8U}"
API_ISSUER="${ASC_ISSUER_ID:-b37f0fe7-81a4-439a-a070-18816dcf17ce}"

if [[ ! -f "$IPA" ]]; then
  echo "Missing IPA: $IPA"
  echo "Archive/export first, then re-run."
  exit 1
fi

mkdir -p "$HOME/.appstoreconnect/private_keys"
if [[ ! -f "$HOME/.appstoreconnect/private_keys/AuthKey_${API_KEY}.p8" ]]; then
  echo "Missing AuthKey_${API_KEY}.p8 in ~/.appstoreconnect/private_keys/"
  exit 1
fi

echo "==> Uploading $IPA to App Store Connect / TestFlight ..."
xcrun altool --upload-app -f "$IPA" -t ios --apiKey "$API_KEY" --apiIssuer "$API_ISSUER"
echo ""
echo "Upload submitted. In App Store Connect → TestFlight, wait for processing, then add testers."
