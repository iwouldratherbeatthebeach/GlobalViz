# READ THIS FIRST — the globe needs two library files added by hand

If you see **"Could not load the 3D globe libraries"** or **"No plottable rows found"**,
it is because CesiumJS and satellite.js are **not inside the app yet**. The `.spl` you
installed does **not** include them (they can't be redistributed in this package), and
Splunk's Content-Security-Policy blocks loading them from the internet. You must place
two things inside the app, once. No internet is needed at runtime after that.

## Step 1 — get the two libraries (on any machine WITH internet)

Download these exact files:

1. **CesiumJS 1.118** (zip):
   https://github.com/CesiumGS/cesium/releases/download/1.118/Cesium-1.118.zip
   Unzip it. Inside you will find a folder: `Cesium-1.118/Build/Cesium/`
   (it contains `Cesium.js` plus `Workers/`, `Assets/`, `Widgets/`, `ThirdParty/`).

2. **satellite.js 5.0** (single file):
   https://cdn.jsdelivr.net/npm/satellite.js@5.0.0/dist/satellite.min.js
   (Right-click → Save As `satellite.min.js`.)

## Step 2 — copy them into the installed app

On the Splunk server, the app lives at:
`$SPLUNK_HOME/etc/apps/globe_viz/` (Windows: `%SPLUNK_HOME%\etc\apps\globe_viz\`)

Place the files so you end up with EXACTLY this layout:

```
$SPLUNK_HOME/etc/apps/globe_viz/appserver/static/visualizations/globe/
    ├── visualization.js          (already there)
    ├── satellite.min.js          <-- the file from step 1.2
    └── cesium/                    <-- the CONTENTS of Build/Cesium/
        ├── Cesium.js
        ├── Workers/
        ├── Assets/
        ├── Widgets/
        └── ThirdParty/
```

Important: copy the **contents** of `Build/Cesium/` into a folder named `cesium`, so the
path is `.../globe/cesium/Cesium.js` (NOT `.../globe/cesium/Build/Cesium/Cesium.js`).

(On an internet-connected staging machine you can instead run
`bin/setup_libs.sh` / `bin/package_offline.sh`, which do steps 1–2 for you.)

## Step 3 — refresh Splunk (clears the old cached code too)

1. Restart Splunk, **or** visit these URLs in the browser while logged in:
   - `https://<your-splunk>/en-US/_bump`   (click the "Bump version" button)
   - `https://<your-splunk>/en-US/debug/refresh`   (refresh endpoints)
2. **Hard-reload** the dashboard page in your browser: **Ctrl+Shift+R** (Windows) /
   **Cmd+Shift+R** (Mac). This is required — the browser caches the old visualization.js.

## Step 4 — verify the files are being served

Open these two URLs directly in your browser (logged in). Both must return code, not a
404 page:

- `https://<your-splunk>/en-US/static/app/globe_viz/visualizations/globe/cesium/Cesium.js`
- `https://<your-splunk>/en-US/static/app/globe_viz/visualizations/globe/satellite.min.js`

If they load, reopen the **Satellite Globe** dashboard — the globe and satellites will
appear. If they 404, the files are in the wrong folder (recheck the layout in step 2) or
you skipped the `_bump` in step 3.

## Still failing? Confirm you're on the current code

Open the browser console (F12) on the dashboard. If the error text mentions
"cesiumBaseUrl / satelliteJsUrl … For Splunk Cloud", you are still running an **old
cached** `visualization.js` — repeat step 3 (bump + hard refresh), or reinstall the
latest `.spl`. The current code's error message instead points you to this file.
