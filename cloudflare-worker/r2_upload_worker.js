/**
 * Cloudflare Worker / R2 upload proxy.
 *
 * Yêu cầu binding trong wrangler.toml:
 *   [[r2_buckets]]
 *   binding = "HEALTHTRACKER_BUCKET"
 *   bucket = "healthtracker"
 *
 * Deploy: wrangler publish
 */
function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Accept',
  };
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: corsHeaders(),
      });
    }

    // Serve uploaded objects from R2 for GET requests
    if (request.method === 'GET') {
      try {
        // path is /{key}
        const url = new URL(request.url);
        const key = url.pathname
          .split('/')
          .filter(Boolean)
          .map((segment) => decodeURIComponent(segment))
          .join('/');
        if (!key) {
          return new Response('Not Found', { status: 404, headers: corsHeaders() });
        }

        const obj = await env.HEALTHTRACKER_BUCKET.get(key);
        if (!obj || !obj.body) {
          return new Response('Not Found', { status: 404, headers: corsHeaders() });
        }

        const headers = corsHeaders();
        if (obj.httpMetadata && obj.httpMetadata.contentType) {
          headers['Content-Type'] = obj.httpMetadata.contentType;
        }
        // Stream the object body
        return new Response(obj.body, { status: 200, headers });
      } catch (err) {
        return new Response(JSON.stringify({ error: err.toString() }), { status: 500, headers: { ...corsHeaders(), 'Content-Type': 'application/json' } });
      }
    }

    if (request.method !== 'POST') {
      return new Response('Method Not Allowed', { status: 405, headers: corsHeaders() });
    }

    try {
      const url = new URL(request.url);
      const key = url.searchParams.get('key');
      const contentType = request.headers.get('content-type') || 'application/octet-stream';
      if (!key) {
        return new Response(JSON.stringify({ error: 'key is required as query parameter' }), { status: 400, headers: { ...corsHeaders(), 'Content-Type': 'application/json' } });
      }

      const body = await request.arrayBuffer();
      const bytes = new Uint8Array(body);

      await env.HEALTHTRACKER_BUCKET.put(key, bytes, {
        httpMetadata: {
          contentType,
        },
      });

      const encodedKey = key.split('/').map((segment) => encodeURIComponent(segment)).join('/');
      const fileUrl = `https://${request.headers.get('host')}/${encodedKey}`;
      return new Response(JSON.stringify({ ok: true, key, url: fileUrl }), {
        status: 200,
        headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
      });
    } catch (err) {
      return new Response(JSON.stringify({ error: err.toString() }), { status: 500, headers: { ...corsHeaders(), 'Content-Type': 'application/json' } });
    }
  },
};
