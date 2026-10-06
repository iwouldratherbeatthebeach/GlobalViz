#!/usr/bin/env bash
#
# Downloads CesiumJS + satellite.js into this app so the 3D Globe visualization
# works under Splunk's Content-Security-Policy (which blocks external CDNs).
#
# Run it once. If your Splunk server has no internet (air-gapped), run this on an
# internet-connected staging machine instead, then use bin/package_offline.sh to build a
# self-contained .spl and carry that to the air-gapped server.
#
# It writes into the app's static folder:
#   appserver/static/visualizations/globe/cesium/       (Cesium Build/Cesium)
#   appserver/static/visualizations/globe/satellite.min.js
#
# Usage:
#   bash bin/setup_libs.sh                 # auto-detects the app dir (this script's ../)
#   bash bin/setup_libs.sh /path/to/globe_viz
#
# Requires: curl and unzip (standard on macOS/Linux). Needs internet access.

set -euo pipefail

CESIUM_VERSION="1.118"
SAT_URL="https://cdn.jsdelivr.net/npm/satellite.js@5.0.0/dist/satellite.min.js"
CESIUM_URL="https://github.com/CesiumGS/cesium/releases/download/${CESIUM_VERSION}/Cesium-${CESIUM_VERSION}.zip"

# App root = argument, or the parent of this script's directory.
APP_DIR="${1:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}"
VIZ_DIR="${APP_DIR}/appserver/static/visualizations/globe"

echo "App dir : ${APP_DIR}"
echo "Viz dir : ${VIZ_DIR}"
mkdir -p "${VIZ_DIR}"

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "Downloading satellite.js ..."
curl -sSL "${SAT_URL}" -o "${VIZ_DIR}/satellite.min.js"

echo "Downloading CesiumJS ${CESIUM_VERSION} (~10-20 MB) ..."
curl -sSL "${CESIUM_URL}" -o "${TMP}/cesium.zip"

echo "Extracting Cesium ..."
unzip -q "${TMP}/cesium.zip" -d "${TMP}/cesium"

# Cesium release zips contain Build/Cesium/{Cesium.js,Workers,Assets,Widgets,...}
rm -rf "${VIZ_DIR}/cesium"
mkdir -p "${VIZ_DIR}/cesium"
cp -R "${TMP}/cesium/Build/Cesium/." "${VIZ_DIR}/cesium/"

echo
echo "Done. Installed:"
echo "  ${VIZ_DIR}/cesium/Cesium.js"
echo "  ${VIZ_DIR}/satellite.min.js"
echo
echo "Now reload Splunk Web (Settings > Server controls > Restart, or visit"
echo "  /en-US/_bump  and  /en-US/debug/refresh ) and reopen the dashboard."
