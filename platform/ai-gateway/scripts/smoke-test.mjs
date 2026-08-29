import http from "node:http";
import { spawn } from "node:child_process";
import assert from "node:assert/strict";

const inferencePort = 18081;
const gatewayPort = 13101;
let lastRequest;

const mock = http.createServer(async (req, res) => {
  if (req.method !== "POST" || req.url !== "/v1/chat/completions") {
    res.writeHead(404).end();
    return;
  }
  let body = "";
  for await (const chunk of req) body += chunk;
  lastRequest = JSON.parse(body);
  res.writeHead(200, { "content-type": "application/json" });
  res.end(JSON.stringify({
    choices: [{ message: { content: JSON.stringify({
      verdict: "rewrite",
      reason: "This reads as confrontational and is unlikely to advance the stated goal.",
      recommended_action: "rewrite",
      rewrite_options: ["Hey, can we talk about what happened?"]
    }) } }]
  }));
});

await new Promise((resolve) => mock.listen(inferencePort, "127.0.0.1", resolve));

const child = spawn(process.execPath, ["dist/server.js"], {
  stdio: ["ignore", "pipe", "pipe"],
  env: {
    ...process.env,
    NODE_ENV: "development",
    PORT: String(gatewayPort),
    LOCAL_LLM_BASE_URL: `http://127.0.0.1:${inferencePort}/v1`,
    LOCAL_LLM_MODEL: "qwen3:4b",
    SHOULD_I_TEXT_HIM_MODEL: "qwen3:8b",
    TRUST_PROXY_HOPS: "0",
    RATE_LIMIT_MAX: "20"
  }
});

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function waitForHealth() {
  for (let i = 0; i < 50; i++) {
    try {
      const response = await fetch(`http://127.0.0.1:${gatewayPort}/healthz`);
      if (response.ok) return;
    } catch {}
    await sleep(100);
  }
  throw new Error("gateway did not start");
}

const payload = {
  proposedMessage: "hello gangster what the fuck is your problem",
  goal: "getClarity",
  context: { quick: { whoTextedLast: "him", timeSinceLastMessage: "today", didHeRespond: "yes", additionalNotes: "" } }
};

try {
  await waitForHealth();

  const apps = await fetch(`http://127.0.0.1:${gatewayPort}/v1/apps`).then((r) => r.json());
  assert.deepEqual(apps.apps, [{ id: "should-i-text-him", task: "judge" }]);

  const modernResponse = await fetch(`http://127.0.0.1:${gatewayPort}/v1/apps/should-i-text-him/judge`, {
    method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(payload)
  });
  assert.equal(modernResponse.status, 200);
  assert.equal((await modernResponse.json()).verdict, "rewrite");
  assert.equal(lastRequest.model, "qwen3:8b");
  assert.equal(lastRequest.response_format.type, "json_schema");

  const legacyResponse = await fetch(`http://127.0.0.1:${gatewayPort}/api/judge`, {
    method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(payload)
  });
  assert.equal(legacyResponse.status, 200);
  assert.equal((await legacyResponse.json()).verdict, "rewrite");

  const unknown = await fetch(`http://127.0.0.1:${gatewayPort}/v1/apps/not-real/do-thing`, {
    method: "POST", headers: { "content-type": "application/json" }, body: "{}"
  });
  assert.equal(unknown.status, 404);

  console.log("AI gateway smoke test passed");
} finally {
  child.kill("SIGTERM");
  mock.close();
}
