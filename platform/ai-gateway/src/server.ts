import express, { type ErrorRequestHandler } from "express";
import { config } from "./lib/config.js";
import { startRateLimiterCleanup } from "./lib/rateLimiter.js";
import { gatewayRouter } from "./routes/gateway.js";

const app = express();
app.disable("x-powered-by");
app.set("trust proxy", config.trustProxyHops);
app.use(express.json({ limit: config.maxBodyBytes }));

app.get("/healthz", (_req, res) => res.status(200).json({ status: "ok", service: "theaigincy-ai-gateway" }));
app.use("/v1", gatewayRouter);

// Keep the original /api/judge contract available so Should I Text Him can
// switch infrastructure before requiring an App Store client update.
app.post("/api/judge", (req, res, next) => {
  req.url = "/legacy/should-i-text-him/judge";
  gatewayRouter(req, res, next);
});

app.use((_req, res) => res.status(404).json({ error: "not_found" }));
const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  console.error("request_error:", err instanceof Error ? err.name : "unknown");
  if (!res.headersSent) res.status(400).json({ error: "invalid_request" });
};
app.use(errorHandler);

startRateLimiterCleanup();
app.listen(config.port, () => {
  console.log(`theAIgincy AI Gateway listening on :${config.port} (env=${config.nodeEnv}, defaultModel=${config.localLlm.defaultModel})`);
});
