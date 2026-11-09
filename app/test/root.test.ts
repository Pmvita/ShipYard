import type { Server } from "node:http";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { createServer } from "../src/server.js";

describe("GET /", () => {
  let server: Server;
  let baseUrl: string;

  beforeAll(async () => {
    server = createServer();
    await new Promise<void>((resolve) => {
      server.listen(0, "127.0.0.1", () => resolve());
    });
    const address = server.address();
    if (address === null || typeof address === "string") {
      throw new Error("expected TCP listen address");
    }
    baseUrl = `http://127.0.0.1:${address.port}`;
  });

  afterAll(async () => {
    await new Promise<void>((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  });

  it("returns short service JSON", async () => {
    const response = await fetch(`${baseUrl}/`);
    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual({ service: "shipyard", ok: true });
  });

  it("returns 404 for unknown paths", async () => {
    const response = await fetch(`${baseUrl}/nope`);
    expect(response.status).toBe(404);
    await expect(response.json()).resolves.toEqual({ error: "not_found" });
  });
});
