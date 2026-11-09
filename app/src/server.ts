import http from "node:http";

import { healthPayload, rootPayload } from "./health.js";

function json(res: http.ServerResponse, status: number, body: unknown): void {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "content-length": Buffer.byteLength(payload),
  });
  res.end(payload);
}

export function createServer(): http.Server {
  return http.createServer((req, res) => {
    const path = (req.url ?? "/").split("?")[0] ?? "/";

    if (req.method === "GET" && path === "/health") {
      json(res, 200, healthPayload());
      return;
    }

    if (req.method === "GET" && path === "/") {
      json(res, 200, rootPayload());
      return;
    }

    json(res, 404, { error: "not_found" });
  });
}
