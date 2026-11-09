import { createServer } from "./server.js";

const port = Number.parseInt(process.env.PORT ?? "8080", 10);

if (!Number.isFinite(port) || port <= 0) {
  throw new Error(`Invalid PORT: ${process.env.PORT ?? ""}`);
}

const server = createServer();

server.listen(port, () => {
  console.log(
    JSON.stringify({
      level: "info",
      msg: "listening",
      service: "shipyard",
      port,
    }),
  );
});
