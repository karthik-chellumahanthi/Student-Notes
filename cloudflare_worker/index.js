export default {
  async fetch(request, env) {
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, PUT, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);

    // SECURITY: Restrict endpoints that modify state to only requests from our Flutter app
    if (url.pathname.startsWith("/upload/") || url.pathname === "/send-notification") {
      const appKey = request.headers.get("X-App-Key");
      if (appKey !== "student_notes_secure_api_key_2026") {
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

        // env.R2_BUCKET is the binding you will set up in Cloudflare Dashboard
        await env.R2_BUCKET.put(fileName, request.body, {
          httpMetadata: { contentType: mimeTypes[ext] },
        });

        // --- RATE LIMITING LOGIC (Increment Phase) ---
        if (env.RATE_LIMIT_KV) {
          await env.RATE_LIMIT_KV.put(kvKey, (currentCount + 1).toString(), {
            // Expire key automatically after 24 hours to keep KV clean
            expirationTtl: 86400
          });
        }

        // The public URL if your R2 bucket is mapped to a custom domain, 
        // OR a URL handled by this worker to serve files securely.
        // Easiest is to enable Public R2 bucket or return a worker-based download URL
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
        
        // Use Resend API
        const resendResponse = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${env.RESEND_API_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            from: 'Student Notes <onboarding@resend.dev>', // Update if you verify a domain
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
