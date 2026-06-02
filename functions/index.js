const { onCall } = require("firebase-functions/v2/https");
const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const s3 = new S3Client({
  region: "auto",
  endpoint: "https://1d069ed680ea3cf655e9b39b485541e4.r2.cloudflarestorage.com",
  credentials: {
    accessKeyId: "a90de50e9e2fcfb668571d0319cece24",
    secretAccessKey: "f30f357326c88fb308f1164dba0a79bf53372cb29b78182d29b7deb0416fd813",
  },
});

exports.getPdfUrl = onCall(
  {
    memory: "128MiB",
    timeoutSeconds: 10,
    region: "us-central1"
  },
  async (request) => {
    try {
      console.log("getPdfUrl called");
      console.log("Auth context:", request.auth);
      console.log("Data:", request.data);

      // ✅ Check authentication
      if (!request.auth) {
        console.error("❌ No authentication - request.auth is undefined");
        throw new Error("UNAUTHENTICATED: User must be authenticated to access this function");
      }

      const userId = request.auth.uid;
      console.log("✅ Authenticated user ID:", userId);

      const filePath = request.data.path;

      if (!filePath) {
        throw new Error("Missing 'path' parameter");
      }

      console.log("📁 Generating signed URL for:", filePath);

      const command = new GetObjectCommand({
        Bucket: "jntuk-notes-pdfs",
        Key: filePath,
      });

      const url = await getSignedUrl(s3, command, { expiresIn: 1800 });

      console.log("✅ Signed URL generated successfully");
      return { url };
    } catch (error) {
      console.error("❌ Error:", error.message);
      throw new Error(`Failed to generate signed URL: ${error.message}`);
    }
  }
);