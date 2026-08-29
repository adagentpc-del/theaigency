import http from "node:http";
import { spawn } from "node:child_process";

const MOCK_PORT = 18080;
const API_PORT = 13100;

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const mock = http.createServer((req, res) => {
  if (req.method !== "POST" || req.url !== "/v1/chat/completions") {
    res.writeHead(404).end();
    return;
  }

  let raw = "";
  req.on("data", chunk => { raw += chunk; });
  req.on("end", () => {
    const body = JSON.parse(raw);
    assert(body.model === "smoke-model", "API did not forward configured model");
    assert(body.response_format?.type === "json_schema", "structured-output schema missing");
    assert(Array.isArray(body.messages) && body.messages.length === 2, "prompt messages missing");

    res.writeHead(200, { "content-type": "application/json" });
    res.end(JSON.stringify({
      choices: [{
        message: {
          content: JSON.stringify({
            verdict: "rewrite",
            reason: "The tone is confrontational and does not advance the stated goal.",
            recommended_action: "rewrite",
            rewrite_options: ["Hey, can we talk about what happened?"],
          }),
        },
      }],
      usage: { completion_tokens: 42 },
    }));
  });
});

await new Promise(resolve => mock.listen(MOCK_PORT, "127.0.0.1", resolve));

const api = spawn(process.execPath, ["dist/server.js"], {
  env: {
    ...process.env,
    NODE_ENV: "development",
    PORT: String(API_PORT),
    LOCAL_LLM_BASE_URL: `http://127.0.0.1:${MOCK_PORT}/v1/`,
    LOCAL_LLM_MODEL: "smoke-model",
    LOCAL_LLM_TIMEOUT_MS: "3000",
    RATE_LIMIT_MAX: "2",
    RATE_LIMIT_WINDOW_MS: "60000",
    TRUST_PROXY_HOPS: "0",
  },
  stdio: ["ignore", "pipe", "pipe"],
});

let stderr = "";
api.stderr.on("data", chunk => { stderr += String(chunk); });

async function waitForApi() {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    try {
      const response = await fetch(`http://127.0.0.1:${API_PORT}/healthz`);
      if (response.ok) return;
    } catch {}
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  throw new Error(`API did not become ready. stderr=${stderr}`);
}

try {
  await waitForApi();

  const invalid = await fetch(`http://127.0.0.1:${API_PORT}/api/judge`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ proposedMessage: "hi" }),
  });
  assert(invalid.status === 400, `expected 400 for invalid request, got ${invalid.status}`);

  const judgment = await fetch(`http://127.0.0.1:${API_PORT}/api/judge`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      proposedMessage: "hello gangster what the fuck is your problem",
      goal: "getClarity",
      context: {
        quick: {
          whoTextedLast: "him",
          timeSinceLastMessage: "today",
          didHeRespond: "yes",
          additionalNotes: "We argued earlier.",
        },
      },
    }),
  });
  assert(judgment.status === 200, `expected 200 judgment, got ${judgment.status}`);
  const result = await judgment.json();
  assert(result.verdict === "rewrite", `hostile regression unexpectedly returned ${result.verdict}`);
  assert(result.recommended_action === "rewrite", "recommended action mismatch");

  const limited = await fetch(`http://127.0.0.1:${API_PORT}/api/judge`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      proposedMessage: "Hey",
      goal: "checkingIn",
      context: { conversation: "He said he would call later." },
    }),
  });
  assert(limited.status === 429, `expected 429 after configured limit, got ${limited.status}`);

  console.log("smoke test passed: health, validation, local inference, hostile regression, rate limit");
} finally {
  api.kill("SIGTERM");
  await new Promise(resolve => mock.close(resolve));
}
