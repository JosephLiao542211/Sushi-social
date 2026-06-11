const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const encoder = new TextEncoder();

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const bucket = Deno.env.get("GCS_PHOTOS_BUCKET");
  const clientEmail = Deno.env.get("GCS_CLIENT_EMAIL");
  const privateKey = Deno.env.get("GCS_PRIVATE_KEY")?.replaceAll("\\n", "\n");
  if (!bucket || !clientEmail || !privateKey) {
    return json({ error: "GCS upload signing is not configured" }, 500);
  }

  const userId = await authenticatedUserId(req);
  if (!userId) {
    return json({ error: "Unauthorized" }, 401);
  }

  const body = await req.json().catch(() => ({}));
  const contentType =
    typeof body.contentType === "string" ? body.contentType : "image/jpeg";
  if (!contentType.startsWith("image/")) {
    return json({ error: "Only image uploads are supported" }, 400);
  }

  const extension = extensionFor(contentType);
  const objectPath = `posts/${userId}/${crypto.randomUUID()}.${extension}`;
  const expires = Math.floor(Date.now() / 1000) + 10 * 60;
  const escapedObjectPath = encodeURIComponent(objectPath).replaceAll("%2F", "/");
  const resource = `/${bucket}/${escapedObjectPath}`;
  const stringToSign = [
    "PUT",
    "",
    contentType,
    expires.toString(),
    resource,
  ].join("\n");

  const signature = await sign(privateKey, stringToSign);
  const uploadUrl =
    `https://storage.googleapis.com${resource}` +
    `?GoogleAccessId=${encodeURIComponent(clientEmail)}` +
    `&Expires=${expires}` +
    `&Signature=${encodeURIComponent(signature)}`;

  return json({
    uploadUrl,
    method: "PUT",
    headers: { "Content-Type": contentType },
    bucket,
    objectPath,
    publicUrl: `https://storage.googleapis.com/${bucket}/${escapedObjectPath}`,
  });
});

async function authenticatedUserId(req: Request) {
  const authHeader = req.headers.get("authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!authHeader || !supabaseUrl || !anonKey) return null;

  const res = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      authorization: authHeader,
      apikey: anonKey,
    },
  });
  if (!res.ok) return null;
  const user = await res.json();
  return typeof user.id === "string" ? user.id : null;
}

async function sign(pem: string, value: string) {
  const keyData = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s/g, "");
  const binary = Uint8Array.from(atob(keyData), (char) => char.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(value),
  );
  return btoa(String.fromCharCode(...new Uint8Array(signature)));
}

function extensionFor(contentType: string) {
  if (contentType === "image/png") return "png";
  if (contentType === "image/webp") return "webp";
  if (contentType === "image/gif") return "gif";
  return "jpg";
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
