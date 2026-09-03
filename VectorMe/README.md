# Vector Me

Vector Me is theAIgincy's raster-to-vector production utility for turning PNG, JPG, and WEBP artwork into scalable files for apparel, signs, stickers, jerseys, print, and related manufacturing workflows.

## Current MVP

The current implementation is intentionally dependency-light and browser-first. Uploaded artwork stays client-side in this phase. It performs color quantization, connected-region detection, pixel-boundary tracing, path simplification, and generates genuine SVG path geometry. It also exports a PDF whose artwork is represented by PDF vector path commands rather than a raster screenshot.

### Included

- PNG / JPG / WEBP upload and validation
- drag-and-drop and mobile file picker support
- production-use-case selector
- Trace and Rebuild processing modes
- 2 / 4 / 8 / 16 color quantization
- likely-background removal
- Low / Medium / High detail
- original vs vector preview
- automated Print Check warnings
- genuine SVG path export
- vector PDF export
- transparent PNG export
- client-side processing for privacy
- responsive UI
- zero runtime package dependencies

### Important limitations

This first vector engine is best suited to logos, icons, badges, flat graphics, line art, and other artwork with relatively discrete regions. Complex photography, realistic gradients, textured artwork, and difficult typography reconstruction require a more advanced vectorization/reconstruction pipeline before production launch.

`Rebuild` currently uses stronger path simplification than Trace. It does not yet perform semantic AI reconstruction of malformed symbols or typography. That should be introduced as a separate server-side reconstruction service so the core Trace path remains deterministic and inexpensive.

Embroidery output is preparation artwork only. Vector Me does not claim SVG or PDF is a machine embroidery file. A digitizer still needs to create formats such as DST or PES.

## Running locally

No package installation is needed for this MVP.

Serve the repository with any static HTTP server and open `VectorMe/index.html`. For example, with Python installed:

```bash
python3 -m http.server 8080
```

Then visit `/VectorMe/`.

## Tests

The vector core has a dependency-free Node smoke test:

```bash
node VectorMe/test-vector-core.js
```

GitHub Actions runs this test for changes under `VectorMe/`.

## Architecture

- `index.html` — application shell and accessible controls
- `styles.css` — responsive visual system
- `app.js` — upload, workflow, preview, exports, and UI state
- `vector-core.js` — deterministic raster-to-vector engine, SVG/PDF generation, Print Check
- `test-vector-core.js` — core geometry/export smoke tests

## Security and privacy

The current phase avoids server upload entirely. Images are decoded by the browser, processed through Canvas, and converted locally. Generated SVG is assembled from internally generated numeric geometry and RGB values rather than user-provided SVG/XML, eliminating arbitrary SVG script ingestion in this phase.

Before adding accounts/cloud storage, introduce private object storage, authorization checks, signed URLs, retention/deletion policies, rate limits, content validation, and server-side isolation for expensive reconstruction jobs.

## Next production phases

1. Improve path quality with curve fitting and hole-aware compound paths.
2. Add semantic image classification and more sophisticated production presets.
3. Add server-side AI Rebuild for geometry/symmetry/artifact reconstruction.
4. Add saved projects, authentication, credits, checkout, and re-downloads.
5. Add ZIP export package and plain-English vendor README.
6. Add SEO landing routes and analytics.
7. Add B2B print-shop portals and API architecture.
