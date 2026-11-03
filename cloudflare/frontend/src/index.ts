export interface Env {
  ASSETS: Fetcher;
  GATEWAY: Fetcher;
  GIFT_ASSETS: R2Bucket;
  BACKEND_ORIGIN: string;
}

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, HEAD",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Telegram-Init-Data, X-User-Id, X-Username",
  "Access-Control-Max-Age": "86400",
};

function addCorsHeaders(response: Response): Response {
  const headers = new Headers(response.headers);
  for (const [key, value] of Object.entries(corsHeaders)) {
    headers.set(key, value);
  }
  headers.set("Cache-Control", "no-store");
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // 0. Handle CORS preflight for all endpoints
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    // Keep realtime Durable Object connections on the Cloudflare gateway.
    if (url.pathname === "/ws" || url.pathname.startsWith("/ws/")) {
      return env.GATEWAY.fetch(request);
    }

    // The game and wallet API is hosted by the Express backend on the VPS.
    if (
      url.pathname === "/api" ||
      url.pathname.startsWith("/api/") ||
      url.pathname === "/health"
    ) {
      try {
        const backendPath = url.pathname === "/health" ? "/api/health" : url.pathname;
        const backendUrl = new URL(`${backendPath}${url.search}`, env.BACKEND_ORIGIN);
        const backendRequest = new Request(backendUrl, request);
        return addCorsHeaders(await fetch(backendRequest));
      } catch (error) {
        console.error("[Frontend Worker] VPS backend request failed:", error);
        return new Response(
          JSON.stringify({ error: "Backend is unavailable." }),
          {
            status: 502,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
            },
          },
        );
      }
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
