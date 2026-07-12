const { createSign } = require("crypto");

const APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token";
const APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke";

module.exports = async function handler(request, response) {
  if (request.method !== "POST") {
    response.setHeader("Allow", "POST");
    return sendJSON(response, 405, { error: "method_not_allowed" });
  }

  try {
    const body = typeof request.body === "string" ? JSON.parse(request.body) : request.body;
    const authorizationCode = body && body.authorizationCode;
    if (typeof authorizationCode !== "string" || authorizationCode.trim() === "") {
      return sendJSON(response, 400, { error: "missing_authorization_code" });
    }

    const config = appleConfig();
    const clientSecret = createClientSecret(config);
    const tokenResponse = await exchangeAuthorizationCode({
      authorizationCode,
      clientID: config.clientID,
      clientSecret
    });

    const token = tokenResponse.refresh_token || tokenResponse.access_token;
    if (!token) {
      return sendJSON(response, 502, { error: "missing_apple_token" });
    }

    await revokeToken({
      token,
      clientID: config.clientID,
      clientSecret
    });

    return response.status(204).end();
  } catch (error) {
    const statusCode = error.statusCode || 500;
    return sendJSON(response, statusCode, {
      error: error.publicCode || "apple_revocation_failed"
    });
  }
};

function appleConfig() {
  const teamID = requiredEnv("APPLE_TEAM_ID");
  const clientID = requiredEnv("APPLE_CLIENT_ID");
  const keyID = requiredEnv("APPLE_KEY_ID");
  const privateKey = requiredEnv("APPLE_PRIVATE_KEY").replace(/\\n/g, "\n");
  return { teamID, clientID, keyID, privateKey };
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    const error = new Error(`Missing ${name}`);
    error.statusCode = 500;
    error.publicCode = "server_not_configured";
    throw error;
  }
  return value;
}

function createClientSecret({ teamID, clientID, keyID, privateKey }) {
  const now = Math.floor(Date.now() / 1000);
  const header = {
    alg: "ES256",
    kid: keyID
  };
  const payload = {
    iss: teamID,
    iat: now,
    exp: now + 60 * 60,
    aud: "https://appleid.apple.com",
    sub: clientID
  };
  const signingInput = `${base64urlJSON(header)}.${base64urlJSON(payload)}`;
  const derSignature = createSign("SHA256").update(signingInput).end().sign(privateKey);
  const signature = derToJoseES256(derSignature);
  return `${signingInput}.${base64url(signature)}`;
}

async function exchangeAuthorizationCode({ authorizationCode, clientID, clientSecret }) {
  const params = new URLSearchParams({
    client_id: clientID,
    client_secret: clientSecret,
    code: authorizationCode,
    grant_type: "authorization_code"
  });
  const response = await fetch(APPLE_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params
  });
  const body = await safeJSON(response);
  if (!response.ok) {
    const error = new Error("Apple token exchange failed");
    error.statusCode = response.status >= 400 && response.status < 500 ? 400 : 502;
    error.publicCode = "apple_token_exchange_failed";
    throw error;
  }
  return body;
}

async function revokeToken({ token, clientID, clientSecret }) {
  const params = new URLSearchParams({
    client_id: clientID,
    client_secret: clientSecret,
    token
  });
  const response = await fetch(APPLE_REVOKE_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params
  });
  if (!response.ok) {
    const error = new Error("Apple token revoke failed");
    error.statusCode = response.status >= 400 && response.status < 500 ? 400 : 502;
    error.publicCode = "apple_token_revoke_failed";
    throw error;
  }
}

async function safeJSON(response) {
  try {
    return await response.json();
  } catch {
    return {};
  }
}

function base64urlJSON(value) {
  return base64url(Buffer.from(JSON.stringify(value), "utf8"));
}

function base64url(value) {
  return Buffer.from(value)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function derToJoseES256(signature) {
  let offset = 0;
  if (signature[offset++] !== 0x30) {
    throw new Error("Invalid DER signature");
  }
  const sequenceLength = signature[offset++];
  if (sequenceLength + 2 !== signature.length) {
    throw new Error("Invalid DER signature length");
  }
  const r = readDERInteger(signature, offset);
  offset = r.nextOffset;
  const s = readDERInteger(signature, offset);
  return Buffer.concat([leftPad32(r.value), leftPad32(s.value)]);
}

function readDERInteger(signature, offset) {
  if (signature[offset++] !== 0x02) {
    throw new Error("Invalid DER integer");
  }
  const length = signature[offset++];
  const value = signature.subarray(offset, offset + length);
  return {
    value: trimLeadingZero(value),
    nextOffset: offset + length
  };
}

function trimLeadingZero(value) {
  if (value.length > 32 && value[0] === 0) {
    return value.subarray(1);
  }
  return value;
}

function leftPad32(value) {
  if (value.length > 32) {
    throw new Error("Invalid ES256 integer length");
  }
  if (value.length === 32) {
    return value;
  }
  return Buffer.concat([Buffer.alloc(32 - value.length), value]);
}

function sendJSON(response, statusCode, body) {
  response.setHeader("Content-Type", "application/json");
  return response.status(statusCode).json(body);
}
