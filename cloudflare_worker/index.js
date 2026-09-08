// JWKS Caching for Google Public Keys
let cachedJwks = null;
let jwksCacheTime = 0;

async function getGooglePublicKeys() {
  const now = Date.now();
  if (cachedJwks && (now - jwksCacheTime < 3600000)) { // 1 hour cache
    return cachedJwks;
  }
  const res = await fetch('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
  if (!res.ok) throw new Error("Failed to fetch Google JWKS");
  const data = await res.json();
  cachedJwks = data.keys;
  jwksCacheTime = now;
  return cachedJwks;
}

function base64UrlDecode(str) {
  let base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  while (base64.length % 4 !== 0) base64 += '=';
  return atob(base64);
}

function base64UrlToUint8Array(str) {
  const raw = base64UrlDecode(str);
  const arr = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) {
    arr[i] = raw.charCodeAt(i);
  }
  return arr;
}

async function verifyFirebaseToken(idToken, projectId = "jntuk-notes") {
  if (!idToken) throw new Error("Token missing");

  const parts = idToken.split(".");
  if (parts.length !== 3) throw new Error("Invalid JWT format");

  const [headerB64, payloadB64, signatureB64] = parts;
  const header = JSON.parse(base64UrlDecode(headerB64));
  const payload = JSON.parse(base64UrlDecode(payloadB64));

  if (header.alg !== "RS256") throw new Error("Invalid algorithm");
  
  const nowInSec = Math.floor(Date.now() / 1000);
  if (payload.aud !== projectId) throw new Error(`Invalid audience: expected ${projectId}`);
  if (payload.iss !== `https://securetoken.google.com/${projectId}`) throw new Error("Invalid issuer");
  if (!payload.sub || typeof payload.sub !== "string" || payload.sub.trim() === "") throw new Error("Invalid subject");
  if (payload.exp && payload.exp <= nowInSec) throw new Error("Token expired");
  if (payload.iat && payload.iat > nowInSec + 300) throw new Error("Token issued in future");

  const keys = await getGooglePublicKeys();
  const matchingKey = keys.find(k => k.kid === header.kid);
  if (!matchingKey) throw new Error("Matching Google public key not found");

  const cryptoKey = await crypto.subtle.importKey(
    "jwk",
    matchingKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"]
  );

  const encoder = new TextEncoder();
  const data = encoder.encode(`${headerB64}.${payloadB64}`);
  const signature = base64UrlToUint8Array(signatureB64);

  const isValid = await crypto.subtle.verify("RSASSA-PKCS1-v1_5", cryptoKey, signature, data);
  if (!isValid) throw new Error("Invalid token signature");

  return payload;
}

async function hmacSha256(key, message) {
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    typeof key === "string" ? new TextEncoder().encode(key) : key,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign("HMAC", cryptoKey, typeof message === "string" ? new TextEncoder().encode(message) : message);
  return new Uint8Array(signature);
}

async function sha256Hex(message) {
  const msgUint8 = new TextEncoder().encode(message);
  const hashBuffer = await crypto.subtle.digest("SHA-256", msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => (b < 16 ? '0' : '') + b.toString(16)).join("");
}

function bytesToHex(bytes) {
  return Array.from(bytes).map(b => (b < 16 ? '0' : '') + b.toString(16)).join("");
}

async function generateR2PresignedUrl({ accessKeyId, secretAccessKey, endpoint, bucket, key, expiresInSeconds = 1800 }) {
  let cleanKey = key.replace(/\\/g, '/');
  while (cleanKey.startsWith('/')) cleanKey = cleanKey.substring(1);

  if (cleanKey.includes('..') || cleanKey.includes('\0')) {
    throw new Error("Invalid file path: Path traversal detected");
  }
  if (!cleanKey) {
    throw new Error("Invalid file path: Key cannot be empty");
  }

  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]/g, "").split(".")[0] + "Z";
  const datestamp = amzDate.substring(0, 8);

  const region = "auto";
  const service = "s3";
  const credentialScope = `${datestamp}/${region}/${service}/aws4_request`;

  const host = new URL(endpoint).host;
  const canonicalUri = `/${bucket}/${cleanKey.split('/').map(encodeURIComponent).join('/')}`;

  const queryParams = {
    "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    "X-Amz-Credential": `${accessKeyId}/${credentialScope}`,
    "X-Amz-Date": amzDate,
    "X-Amz-Expires": expiresInSeconds.toString(),
    "X-Amz-SignedHeaders": "host",
  };

  const sortedKeys = Object.keys(queryParams).sort();
  const canonicalQueryString = sortedKeys
    .map(k => `${encodeURIComponent(k)}=${encodeURIComponent(queryParams[k])}`)
    .join("&");

  const canonicalHeaders = `host:${host}\n`;
  const signedHeaders = "host";
  const payloadHash = "UNSIGNED-PAYLOAD";

  const canonicalRequest = [
    "GET",
    canonicalUri,
    canonicalQueryString,
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join("\n");

  const canonicalRequestHash = await sha256Hex(canonicalRequest);

  const stringToSign = [
    "AWS4-HMAC-SHA256",
    amzDate,
    credentialScope,
    canonicalRequestHash,
  ].join("\n");

  const kDate = await hmacSha256(`AWS4${secretAccessKey}`, datestamp);
  const kRegion = await hmacSha256(kDate, region);
  const kService = await hmacSha256(kRegion, service);
  const kSigning = await hmacSha256(kService, "aws4_request");

  const signatureBytes = await hmacSha256(kSigning, stringToSign);
  const signatureHex = bytesToHex(signatureBytes);

  return `${endpoint}${canonicalUri}?${canonicalQueryString}&X-Amz-Signature=${signatureHex}`;
}

export default {
  async fetch(request, env) {
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, PUT, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, X-App-Key, X-User-ID",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);

    // ENDPOINT: Secure Presigned PDF URL Generation
    if (url.pathname === "/get-pdf-url" && request.method === "POST") {
      try {
        const authHeader = request.headers.get("Authorization");
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return new Response(JSON.stringify({ error: "Unauthorized: Missing or invalid Authorization header" }), {
            status: 401,
            headers: { "Content-Type": "application/json", ...corsHeaders }
          });
        }

        const idToken = authHeader.split("Bearer ")[1].trim();

        // Verify Firebase Token Server-Side
        try {
          await verifyFirebaseToken(idToken, "jntuk-notes");
        } catch (authError) {
          return new Response(JSON.stringify({ error: `Unauthorized: ${authError.message}` }), {
            status: 401,
            headers: { "Content-Type": "application/json", ...corsHeaders }
          });
        }

        const body = await request.json();
        const filePath = body.path;

        if (!filePath || typeof filePath !== "string") {
          return new Response(JSON.stringify({ error: "Missing or invalid 'path' parameter" }), {
            status: 400,
            headers: { "Content-Type": "application/json", ...corsHeaders }
          });
        }

        const accessKeyId = env.R2_ACCESS_KEY_ID;
        const secretAccessKey = env.R2_SECRET_ACCESS_KEY;
        const endpoint = env.R2_ENDPOINT || "https://1d069ed680ea3cf655e9b39b485541e4.r2.cloudflarestorage.com";
        const bucket = "jntuk-notes-pdfs";

        if (!accessKeyId || !secretAccessKey) {
          return new Response(JSON.stringify({ error: "Server Configuration Error: R2 secrets not configured on Worker" }), {
            status: 500,
            headers: { "Content-Type": "application/json", ...corsHeaders }
          });
        }

        const signedUrl = await generateR2PresignedUrl({
          accessKeyId,
          secretAccessKey,
          endpoint,
          bucket,
          key: filePath,
          expiresInSeconds: 1800, // 30 minutes
        });

        return new Response(JSON.stringify({ url: signedUrl }), {
          headers: { "Content-Type": "application/json", ...corsHeaders }
        });
      } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), {
          status: 500,
          headers: { "Content-Type": "application/json", ...corsHeaders }
        });
      }
    }

    // SECURITY: Restrict endpoints that modify state to only requests from our Flutter app
    if (url.pathname.startsWith("/upload/") || url.pathname === "/send-notification") {
      const appKey = request.headers.get("X-App-Key");
      if (appKey !== env.X_APP_KEY) {
        return new Response(JSON.stringify({ error: "Unauthorized app access. Invalid X-App-Key." }), {
          status: 403,
          headers: { "Content-Type": "application/json", ...corsHeaders }
        });
      }
    }

    // ENDPOINT 1: Direct Upload to R2 Bucket
    if (url.pathname.startsWith("/upload/") && request.method === "PUT") {
      try {
        const userId = request.headers.get("X-User-ID");
        if (!userId) {
          return new Response(JSON.stringify({ error: "Missing X-User-ID header" }), {
            status: 401,
            headers: { "Content-Type": "application/json", ...corsHeaders }
          });
        }

        // --- RATE LIMITING LOGIC (Check Phase) ---
        const today = new Date().toISOString().split('T')[0];
        const kvKey = `rate_limit:${userId}:${today}`;
        
        let currentCount = 0;
        if (env.RATE_LIMIT_KV) {
          const kvValue = await env.RATE_LIMIT_KV.get(kvKey);
          if (kvValue) currentCount = parseInt(kvValue, 10);
          
          if (currentCount >= 5) {
            return new Response(JSON.stringify({ error: "Daily upload limit (5) exceeded. Please try again tomorrow." }), {
              status: 429,
              headers: { "Content-Type": "application/json", ...corsHeaders }
            });
          }
        }

        const fileName = url.pathname.split("/upload/")[1];
        if (!fileName) return new Response("Missing filename", { status: 400 });

        // Extension security check (Allowlist approach)
        const extMatch = fileName.match(/\.([^.]+)$/);
        const ext = extMatch ? extMatch[1].toLowerCase() : "";
        
        const mimeTypes = {
          "pdf": "application/pdf",
          "doc": "application/msword",
          "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          "ppt": "application/vnd.ms-powerpoint",
          "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
          "xls": "application/vnd.ms-excel",
          "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          "txt": "text/plain",
          "rtf": "application/rtf",
          "csv": "text/csv",
          "jpg": "image/jpeg",
          "jpeg": "image/jpeg",
          "png": "image/png",
          "zip": "application/zip",
          "rar": "application/x-rar-compressed",
          "7z": "application/x-7z-compressed"
        };

        if (!ext || !mimeTypes[ext]) {
          return new Response(JSON.stringify({ 
            error: `Unsupported file type (.${ext}). Only notes and document formats are allowed.` 
          }), {
            status: 415,
            headers: { "Content-Type": "application/json", ...corsHeaders }
          });
        }

        // Enforce 100MB file size limit
        const contentLength = request.headers.get("Content-Length");
        const MAX_SIZE = 100 * 1024 * 1024; // 100MB in bytes
        if (contentLength && parseInt(contentLength, 10) > MAX_SIZE) {
          return new Response(JSON.stringify({ error: "Payload Too Large: File exceeds 100MB limit" }), { 
            status: 413, 
            headers: { "Content-Type": "application/json", ...corsHeaders } 
          });
        }

        await env.R2_BUCKET.put(fileName, request.body, {
          httpMetadata: { contentType: mimeTypes[ext] },
        });

        // --- RATE LIMITING LOGIC (Increment Phase) ---
        if (env.RATE_LIMIT_KV) {
          await env.RATE_LIMIT_KV.put(kvKey, (currentCount + 1).toString(), {
            expirationTtl: 86400
          });
        }

        const fileUrl = `${url.origin}/download/${fileName}`;

        return new Response(JSON.stringify({ message: "Success", fileUrl }), {
          headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      } catch (err) {
        return new Response(err.message, { status: 500, headers: corsHeaders });
      }
    }

    // ENDPOINT 2: Send Email via Resend
    if (url.pathname === "/send-notification" && request.method === "POST") {
      try {
        const body = await request.json();
        
        const resendResponse = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${env.RESEND_API_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            from: 'Student Notes <onboarding@resend.dev>',
            to: env.ADMIN_EMAIL,
            subject: `New File Submission: ${body.title}`,
            html: `
              <h2>New Material Submitted!</h2>
              <p><strong>Title:</strong> ${body.title}</p>
              <p><strong>Description:</strong> ${body.description}</p>
              <p><strong>Uploaded by:</strong> ${body.userEmail}</p>
              <p><strong>Submission ID:</strong> ${body.submissionId}</p>
              <br/>
              <p><a href="${body.fileUrl}" style="padding:10px 15px; background:#007bff; color:white; text-decoration:none; border-radius:5px;">Download Uploaded File</a></p>
            `
          })
        });

        const resendData = await resendResponse.json();
        return new Response(JSON.stringify(resendData), {
          headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      } catch (err) {
        return new Response(err.message, { status: 500, headers: corsHeaders });
      }
    }

    // ENDPOINT 3: Securely download files from R2
    if (url.pathname.startsWith("/download/") && request.method === "GET") {
      const fileName = url.pathname.split("/download/")[1];
      const object = await env.R2_BUCKET.get(fileName);

      if (object === null) {
        return new Response("Not found", { status: 404, headers: corsHeaders });
      }

      const headers = new Headers();
      object.writeHttpMetadata(headers);
      headers.set('etag', object.httpEtag);
      headers.set('Access-Control-Allow-Origin', '*');

      return new Response(object.body, { headers });
    }

    return new Response("Not Found", { status: 404, headers: corsHeaders });
  }
}
