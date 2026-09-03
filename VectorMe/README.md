# Vector Me

Vector Me is theAIgincy’s browser-first raster-to-vector production utility for converting PNG, JPG, and WEBP artwork into genuine SVG paths, vector PDF files, transparent PNGs, and packaged production downloads.

## Product status

The application is implemented as a production-oriented web app. Source artwork is processed locally in the browser; the server is used for accounts, saved SVG projects, export credits, Stripe checkout/webhooks, analytics events, and SEO landing routes.

### Conversion and production features

- PNG / JPG / WEBP upload with type, size, dimension, and decode validation
- drag-and-drop and mobile file-picker support
- automatic palette/source analysis
- production-use-case presets for apparel, jerseys, embroidery preparation, screen printing, signs, vinyl, stickers, packaging, business print, and digital use
- Trace and Rebuild modes
- 2 / 4 / 8 / 16 color quantization
- likely-background removal
- Low / Medium / High detail settings
- connected-region tracing and path simplification
- compound even-odd paths so holes/negative space remain cut out
- original, vector, and comparison views
- automated Print Check warnings
- genuine SVG output containing path geometry rather than embedded raster images
- vector PDF output using PDF path commands and even-odd fills
- transparent PNG export up to 4096px output dimension
- ZIP package containing SVG, vector PDF, PNG, and vendor README
- clear embroidery disclaimer: SVG/PDF preparation is not DST/PES digitization

### Accounts and monetization

- email/password registration and login
- scrypt password hashing
- signed HttpOnly session cookies
- one free first project export in the browser
- configurable paid credit packs exposed through the server
- Stripe Checkout session creation
- signed Stripe webhook verification
- idempotent purchase-credit grants
- server-side credit consumption
- saved vector projects
- project ownership authorization
- save/open/delete workflow

### Privacy and security

- source raster files are not uploaded by the normal conversion workflow
- only generated SVG output is stored when the user explicitly saves a project
- stored SVG is validated and rejects scripts, embedded raster images, foreignObject, iframe/object/embed elements, JavaScript URLs, and event-handler attributes
- no API secrets are exposed client-side
- mutation origin checks
- rate limiting for auth, checkout, analytics, project writes, and credit consumption
- Helmet security headers and CSP
- production startup refuses default session secrets or a missing database
- PostgreSQL foreign keys cascade project/purchase deletion when an account is removed administratively

## Running locally

```bash
cd VectorMe
npm install
npm start
```

Without `DATABASE_URL`, development and automated tests use an in-memory database adapter. Production refuses to start without a real PostgreSQL connection.

Open `http://localhost:8080`.

## Tests

```bash
npm test
```

The suite verifies core vector generation, no embedded raster `<image>` in SVG, vector PDF generation, compound cutouts, registration/login, private project ownership, malicious SVG rejection, credit underflow prevention, health checks, SEO routes, and sitemap output.

GitHub Actions also builds the Docker image and verifies the production secret guard.

## Deployment

1. Copy `.env.example` to `.env` on the deployment host.
2. Supply the production environment variables listed below.
3. Run `docker compose up -d --build` from `VectorMe/`, or build/deploy the included Dockerfile through the existing theAIgincy infrastructure.
4. Configure Stripe’s webhook endpoint to `https://YOUR_DOMAIN/api/stripe/webhook`.
5. Point the final domain/subdomain at the Vector Me container/reverse proxy.

The application creates its PostgreSQL tables idempotently on startup.

## Environment variables

Required in production:

- `NODE_ENV=production`
- `PORT`
- `BASE_URL`
- `SESSION_SECRET`
- `DATABASE_URL`

Required for paid checkout:

- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`

The supplied Docker Compose stack also uses `POSTGRES_PASSWORD`.

## Architecture

- `index.html` — conversion, account, project, pricing, education, and export UI
- `styles.css` — responsive design and accessibility states
- `app.js` — client workflow, local image analysis, API integration, auth, projects, export entitlement, analytics
- `vector-core.js` — deterministic color quantization, tracing, compound path construction, SVG/PDF generation, Print Check
- `zip.js` — dependency-free ZIP writer for production packages
- `server.js` — Express application server, security middleware, auth/projects/credits/checkout/SEO routes
- `auth.js` — password hashing and signed session utilities
- `db.js` — PostgreSQL and test/development in-memory adapters
- `test/` — server integration tests
- `Dockerfile` / `docker-compose.yml` — production container definitions
- `.env.example` — environment contract

## SEO routes

The application serves intent-specific metadata and canonical URLs for:

- `/png-to-vector`
- `/jpg-to-vector`
- `/image-to-svg`
- `/logo-to-vector`
- `/ai-image-to-vector`
- `/chatgpt-image-to-vector`
- `/logo-for-tshirt-printing`
- `/logo-for-screen-printing`
- `/logo-for-embroidery`
- `/logo-for-sign-printing`
- `/png-to-svg`

It also serves `robots.txt`, `sitemap.xml`, Open Graph/Twitter metadata, and SoftwareApplication structured data.

## Known technical boundary

Trace is a real deterministic vectorization engine and is suitable for flat logos, icons, badges, line art, and artwork with discrete color regions. Rebuild applies stronger geometric simplification and artifact reduction, but it is not presented as semantic AI reconstruction. Complex photographs, realistic texture, gradient-heavy artwork, and malformed typography may require manual design work or a future semantic reconstruction service. The application tells users this rather than pretending every image can become production-quality vector artwork automatically.

## Pre-launch owner actions

Code is complete without secrets. Public launch still requires the final values for `.env`, the production domain, Stripe credentials/webhook secret, PostgreSQL credentials, and legal review/final operating-entity details in `privacy.html` and `terms.html`.
