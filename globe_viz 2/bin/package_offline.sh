#!/usr/bin/env bash
#
# Build a SELF-CONTAINED, offline-ready .spl for an air-gapped Splunk.
#
# Run this ON AN INTERNET-CONNECTED STAGING MACHINE (not the air-gapped server).
# It downloads CesiumJS + satellite.js into the app, verifies they are present,
# then packages the whole app (libraries included) into globe_viz_offline.spl.
# Copy that single file to the air-gapped environment and install it there — no
# internet is needed at install time or at runtime.
#
# Usage:
#   bash bin/package_offline.sh
#
# Requires: curl, unzip, tar (standard on macOS/Linux).

set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="$(basename "${APP_DIR}")"
PARENT="$(dirname "${APP_DIR}")"
VIZ_DIR="${APP_DIR}/appserver/static/visualizations/globe"
OUT="${PARENT}/${APP_NAME}_offline.spl"

echo "==> Downloading libraries into the app ..."
bash "${APP_DIR}/bin/setup_libs.sh" "${APP_DIR}"

echo "==> Verifying libraries are present ..."
missing=0
[ -f "${VIZ_DIR}/cesium/Cesium.js" ] || { echo "MISSING: ${VIZ_DIR}/cesium/Cesium.js"; missing=1; }
[ -d "${VIZ_DIR}/cesium/Workers" ]   || { echo "MISSING: ${VIZ_DIR}/cesium/Workers/"; missing=1; }
[ -d "${VIZ_DIR}/cesium/Assets" ]    || { echo "MISSING: ${VIZ_DIR}/cesium/Assets/"; missing=1; }
[ -f "${VIZ_DIR}/satellite.min.js" ] || { echo "MISSING: ${VIZ_DIR}/satellite.min.js"; missing=1; }
if [ "${missing}" -ne 0 ]; then
    echo "ERROR: libraries are not fully present; aborting. Re-run setup_libs.sh."
    exit 1
fi

echo "==> Packaging self-contained ${OUT} ..."
rm -f "${OUT}"
COPYFILE_DISABLE=1 tar -C "${PARENT}" \
    --exclude='.DS_Store' --exclude='._*' \
    -czf "${OUT}" "${APP_NAME}"

SIZE="$(du -h "${OUT}" | cut -f1)"
echo
echo "Built: ${OUT}  (${SIZE})"
echo "This .spl contains Cesium + satellite.js and needs NO internet to install or run."
echo "Transfer it to the air-gapped Splunk and install via Apps > Install app from file."
