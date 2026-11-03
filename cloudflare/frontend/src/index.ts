export interface Env {
  ASSETS: Fetcher;
  GATEWAY: Fetcher;
  GIFT_ASSETS: R2Bucket;
}

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, HEAD",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Telegram-Init-Data, X-User-Id, X-Username",
  "Access-Control-Max-Age": "86400",
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // 0. Handle CORS preflight for all endpoints
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    // 1. Direct 0ms internal handoff for API, WebSockets, and health checks to Gateway Worker
    if (
      url.pathname.startsWith("/api/") ||
      url.pathname.startsWith("/ws/") ||
      url.pathname === "/health"
    ) {
      const gatewayRes = await env.GATEWAY.fetch(request);
      const newHeaders = new Headers(gatewayRes.headers);
      for (const [k, v] of Object.entries(corsHeaders)) {
        newHeaders.set(k, v);
      }
      return new Response(gatewayRes.body, {
        status: gatewayRes.status,
        statusText: gatewayRes.statusText,
        headers: newHeaders,
      });
    }

    // 1.1 Explicit public tonconnect-manifest.json handler with CORS
    if (url.pathname === "/tonconnect-manifest.json" || url.pathname === "/assets/telegram/tonconnect-manifest.json") {
      const manifestRes = await env.ASSETS.fetch(new Request(new URL("/tonconnect-manifest.json", request.url).toString()));
      if (manifestRes.status === 200) {
        const headers = new Headers(manifestRes.headers);
        for (const [k, v] of Object.entries(corsHeaders)) {
          headers.set(k, v);
        }
        headers.set("Content-Type", "application/json");
        return new Response(manifestRes.body, { headers });
      }
    }

    // 2. Serve heavy .tgs / .webp gift animations from R2 with 1-year edge cache
    if (url.pathname.startsWith("/assets/telegram/gifts/")) {
      const key = url.pathname.replace("/assets/", "");
      const obj = await env.GIFT_ASSETS.get(key);
      if (obj) {
        const headers = new Headers();
        obj.writeHttpMetadata(headers);
        headers.set("Cache-Control", "public, max-age=31536000, immutable");
        headers.set("Access-Control-Allow-Origin", "*");
        return new Response(obj.body, { headers });
      }
    }

    // 3. Serve Flutter WASM / JS / static files with SPA fallback
    let response = await env.ASSETS.fetch(request);
    if (response.status === 404 && request.method === "GET") {
      const spaUrl = new URL(request.url);
      spaUrl.pathname = "/index.html";
      response = await env.ASSETS.fetch(new Request(spaUrl.toString(), { method: "GET" }));
    }

    return response;
  },
};
