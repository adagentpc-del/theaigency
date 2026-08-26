import express, { type ErrorRequestHandler } from "express";
import { config } from "./lib/config.js";
import { judgeRouter } from "./routes/judge.js";
import { startRateLimiterCleanup } from "./lib/rateLimiter.js";

const app = express();

app.disable("x-powered-by");
// Required for `req.ip` to reflect the real caller (not the reverse
// proxy) when this process sits behind one — see README.md's deployment
// section. Trusting the wrong hop here would make IP-based rate limiting
// meaningless, so this MUST be paired with a reverse proxy / TLS
// terminator that itself sets X-Forwarded-For correctly and is the only
// thing allowed to reach this process directly.
app.set("trust proxy", true);

app.use(express.json({ limit: config.maxBodyBytes }));

app.get("/healthz", (_req, res) => {
  res.status(200).json({ status: "ok" });
});

app.use("/api", judgeRouter);

app.use((_req, res) => {
  res.status(404).json({ error: "not_found" });
});

// Generic error handler — catches express.json()'s body-too-large /
// malformed-JSON errors and anything else thrown synchronously in a
// route. Never returns a stack trace or internal error detail to the
// client; only a fixed, generic error code.
const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  console.error("request_error:", err instanceof Error ? err.name : "unknown");
  if (res.headersSent) return;
  res.status(400).json({ error: "invalid_request" });
};
app.use(errorHandler);

startRateLimiterCleanup();

app.listen(config.port, () => {
  console.log(
    `should-i-text-him judge API listening on :${config.port} ` +
      `(env=${config.nodeEnv}, model=${config.localLlm.model})`,
  );
});
