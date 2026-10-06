# 3D Globe custom visualization for Splunk

An interactive globe that plots ground objects **and** objects in space, and classifies
satellites by **orbit regime — LEO, MEO, GEO, HEO** — coloring each class and animating
the orbits.

**Version 2.0 is fully self-contained.** It uses no CesiumJS, no satellite.js, no
external files, and makes **no network requests**. The globe is drawn with the browser's
built-in Canvas 2D API, and the orbital mechanics are computed by a small Kepler
propagator embedded in the app. It therefore works out of the box on an **air-gapped
Splunk** — just install and go. Nothing to download.

Built on the classic Simple XML custom-visualization framework, so it installs as an
ordinary Splunk app and is available in Search & Reporting and any dashboard. No build
step.

---

## What it does

- Draws Earth as a rotatable, zoomable globe (drag to rotate, scroll to zoom) using an
  embedded **photoreal NASA Blue Marble** texture (2700x1350) with atmosphere glow and
  spherical shading. Drop a higher-res `earth.jpg` in the viz folder to override, or
  toggle "Textured Earth" off for a simple vector globe. The view defaults to framing all
  orbits so satellites are visible on load; scroll in for the map.
- **Latitude + longitude mapping**: any row with `lat`/`lon` (+ optional `alt`) is
  plotted; with altitude it floats above the surface.
- **Orbit-class visualization**: rows with `tle1`/`tle2` are propagated (two-body Kepler)
  and animated along their orbit, each classified and colored:
  - **LEO** — Low Earth Orbit (mean altitude < 2,000 km)
  - **MEO** — Medium Earth Orbit (2,000–35,586 km; GPS, Galileo)
  - **GEO** — Geostationary/synchronous (~35,786 km, ~1436 min, low inclination)
  - **HEO** — Highly Elliptical (eccentricity ≥ 0.25; Molniya, Tundra)
  - **Ground** — surface objects (stations/cities) from lat/lon
- **Interactive legend** (top-right): counts per class; click a class to show/hide it.
- **Click any object** for a tooltip: orbit class, apogee, perigee, period, inclination,
  eccentricity (satellites) or lat/lon/alt (ground).
- **On-globe speed controls** (bottom-left): pause / 1x / 10x / 60x / 300x. These always
  work regardless of dashboard settings; the dashboard's Animation-speed option just sets
  the initial value.

Classification is computed from the TLE elements; override per row with an `orbit_class`
column. Lat/lon rows are classified by altitude band (or `orbit_class`).

> Accuracy note: propagation is two-body Keplerian (no J2/drag), which reproduces orbit
> shape, size, inclination and period faithfully for visualization. It is not a
> precision conjunction/tracking tool; for high-accuracy ground tracks over long spans,
> refresh TLEs and expect small drift versus full SGP4.

---

## Install (works air-gapped, no extra steps)

1. **Apps → Manage Apps → Install app from file** → upload `globe_viz_v2.0.spl`
   (or, on-prem: `cp -r globe_viz $SPLUNK_HOME/etc/apps/`).
2. Restart / reload Splunk.
3. Open the **Globe Viz** app — the **Satellite Globe** dashboard is the default view.
   Or run a search and pick **3D Globe** from the Visualizations tab.

If you had an older version installed, do a browser hard-refresh (Ctrl/Cmd+Shift+R) after
upgrading so the cached script updates.

---

## Try it immediately (bundled sample)

The app ships with two lookups and a ready-made dashboard:

```
| inputlookup satellites.csv | table name orbit_class tle1 tle2
| append [| inputlookup ground_stations.csv | table name orbit_class lat lon]
```

Sample objects span every regime: ISS + Sentinel-2 (LEO), GPS + Galileo (MEO),
GOES-16 + Intelsat (GEO), Molniya + Tundra (HEO), plus ground stations.

`../globe_demo.html` is a standalone browser version (open it directly, no Splunk) that
mirrors the plugin.

---

## Files

```
globe_viz/
├── default/
│   ├── app.conf
│   ├── visualizations.conf
│   ├── transforms.conf
│   └── data/ui/
│       ├── nav/default.xml
│       └── views/satellite_globe.xml   # ready-made dashboard (filter + globe + panels)
├── lookups/
│   ├── satellites.csv                  # sample data: all orbit classes
│   └── ground_stations.csv             # sample ground sites (lat/lon)
├── metadata/default.meta
└── appserver/static/
    ├── appIcon.png, appIcon_2x.png, preview.png
    └── visualizations/globe/
        ├── visualization.js            # the whole plugin (globe + orbit math + coastline)
        ├── visualization.css
        ├── formatter.html              # Format-menu options
        └── preview.png
```

Everything needed is inside `visualization.js` — no `cesium/` folder, no `satellite.min.js`.

---

## Feeding it data

Provide **either** TLE columns **or** coordinate columns; names auto-detect, or map them
in **Format menu → Field mapping**.

**Orbital objects (TLE):** `name`, `tle1`, `tle2` (aliases `line1`/`line2`). Optional
`orbit_class` (override), `color` (per-row CSS color).
```
| inputlookup satellites.csv | table name orbit_class tle1 tle2
```

**Ground / precomputed positions:** `name`, `lat`, `lon`, optional `alt`
(km by default; switch to meters in the Format menu), optional `orbit_class`, `color`.
```
index=tracking sourcetype=positions | table object_name lat lon alt
```

To keep TLEs current in an air-gapped site, periodically import fresh TLE files (from
your approved data-transfer process) into `satellites.csv` or an index with `tle1`/`tle2`
fields. The visualization itself never reaches out to the network.

---

## Using real satellite imagery (NASA Blue Marble)

The app ships with a built-in stylized Earth texture so it works with zero setup. To get
**real satellite imagery**, supply one equirectangular Earth image — the app uses it
automatically:

1. On an internet-connected machine, download an **equirectangular** Earth image, e.g.
   NASA Blue Marble from https://visibleearth.nasa.gov/collection/1484/blue-marble
   (any size; 2048x1024 up to ~5400x2700 recommended). Save it as **`earth.jpg`**.
2. Copy it into the app so the path is:
   `$SPLUNK_HOME/etc/apps/globe_viz/appserver/static/visualizations/globe/earth.jpg`
3. Bump static assets (`/en-US/_bump`) and hard-refresh. The globe now uses the real image.

The plugin looks for `earth.jpg` (then `earth.png`) next to `visualization.js` and uses
it if present, otherwise falls back to the built-in texture. You can also point
**Format menu → Earth image → Earth texture URL** at any equirectangular image reachable
by the browser. It's a single same-origin file — no CSP or worker issues like Cesium.

(If you can get the image to me, I can also embed it directly into the app so it stays a
single self-contained `.spl` with no file to place.)

## Calling the visualization from other apps

It's exported globally (`export = system`), so once `globe_viz` is installed it's
available in every app. In any Simple XML dashboard:

```xml
<viz type="globe_viz.globe">
  <search><query>index=tracking | table name lat lon alt</query></search>
  <option name="display.visualizations.custom.globe_viz.globe.clockMultiplier">1</option>
</viz>
```

`type` is always `globe_viz.globe`; options are always
`display.visualizations.custom.globe_viz.globe.<option>`. Classic Simple XML and the
search viz picker only — not Dashboard Studio.

## Format-menu options
Orbit classes (color-by-class, legend, per-class colors), Appearance (default color,
point size, labels, graticule), Orbits & animation (draw paths, speed), altitude units,
field mapping.
