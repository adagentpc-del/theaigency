import express, { type ErrorRequestHandler } from "express";
import { config } from "./lib/config.js";
import { judgeRouter } from "./routes/judge.js";
import { startRateLimiterCleanup } from "./lib/rateLimiter.js";

const app = express();

app.disable("x-powered-by");
// Trust only the configured number of reverse-proxy hops. Never use
// `trust proxy = true` here: that can allow a caller that reaches this
// process directly to spoof X-Forwarded-For and evade IP rate limiting.
app.set("trust proxy", config.trustProxyHops);

app.use(express.json({ limit: config.maxBodyBytes }));

app.get("/healthz", (_req, res) => {
  res.status(200).json({ status: "ok" });
});

app.use("/api", judgeRouter);

app.use((_req, res) => {
  res.status(404).json({ error: "not_found" });
});

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
      `(env=${config.nodeEnv}, model=${config.localLlm.model}, trustProxyHops=${config.trustProxyHops})`,
  );
});
