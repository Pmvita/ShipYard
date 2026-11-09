export function healthPayload(): { status: "ok" } {
  return { status: "ok" };
}

export function rootPayload(): { service: "shipyard"; ok: true } {
  return { service: "shipyard", ok: true };
}
