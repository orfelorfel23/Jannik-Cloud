import os
import hmac
import hashlib
from fastapi import FastAPI, HTTPException, Request, Response
import httpx
import logging
from datetime import datetime, timezone

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("fwproxy-middleware")

app = FastAPI()

SHLINK_URL = os.getenv("SHLINK_URL", "http://fwproxy-shlink:8080")
SHLINK_API_KEY = os.getenv("SHLINK_API_KEY")
SESSION_SECRET = os.getenv("SESSION_SECRET", "default_secret_change_me")

if not SHLINK_API_KEY:
    logger.error("SHLINK_API_KEY environment variable is not set!")

client = httpx.AsyncClient()

def sign_session(code: str):
    # Bind the session cookie to the specific short code
    signature = hmac.new(
        SESSION_SECRET.encode(),
        f"valid.{code}".encode(),
        hashlib.sha256
    ).hexdigest()
    return f"valid.{code}.{signature}"

def verify_session(cookie_value: str):
    if not cookie_value:
        return None
    try:
        parts = cookie_value.split(".")
        if len(parts) != 3:
            return None
        val, code, sig = parts
        expected_sig = hmac.new(
            SESSION_SECRET.encode(),
            f"{val}.{code}".encode(),
            hashlib.sha256
        ).hexdigest()
        is_valid = hmac.compare_digest(sig, expected_sig) and val == "valid"
        return code if is_valid else None
    except Exception as e:
        logger.error(f"Error verifying session cookie: {e}")
        return None

@app.get("/check{full_path:path}")
async def check_access(full_path: str, request: Request):
    path_parts = [p for p in full_path.split("/") if p]
    session_cookie = request.cookies.get("fwproxy_session")
    session_code = verify_session(session_cookie)
    
    # 1. Identify which short-code we are checking
    # Priority 1: The code in the URL path (e.g. /test/...)
    # Priority 2: The code in the session cookie (for sub-resources like /style.css)
    code = None
    if path_parts:
        code = path_parts[0]
    elif session_code:
        code = session_code

    if not code:
        logger.warning("No code found in path or session.")
        raise HTTPException(status_code=403, detail="Access Denied: Please use a valid link.")

    # 2. Strict Shlink Status Check (Active, Expiry, Limits)
    try:
        # We check the Shlink REST API on EVERY request for strict enforcement
        resp = await client.get(
            f"{SHLINK_URL}/rest/v3/short-urls/{code}",
            headers={"X-Api-Key": SHLINK_API_KEY}
        )
    except Exception as e:
        logger.error(f"Error connecting to Shlink API: {e}")
        raise HTTPException(status_code=500, detail="Internal connection error")

    if resp.status_code != 200:
        logger.warning(f"Invalid code or inactive link: {code}")
        raise HTTPException(status_code=403, detail="Unauthorized: Link is invalid or inactive.")

    data = resp.json()
    meta = data.get("meta", {})
    
    # A. Check Expiry
    valid_until_str = meta.get("validUntil")
    if valid_until_str:
        try:
            # Parse Shlink's ISO date string
            valid_until = datetime.fromisoformat(valid_until_str.replace("Z", "+00:00"))
            if datetime.now(timezone.utc) > valid_until:
                logger.warning(f"Link expired for {code}: {valid_until}")
                raise HTTPException(status_code=403, detail="Link has expired.")
        except ValueError as ve:
            logger.error(f"Error parsing date {valid_until_str}: {ve}")

    # B. Check Visit Limits
    max_visits = meta.get("maxVisits")
    current_visits = data.get("visitsSummary", {}).get("total", 0)
    if max_visits is not None and current_visits >= max_visits:
        logger.warning(f"Limit reached for {code}: {current_visits}/{max_visits}")
        raise HTTPException(status_code=403, detail="Visit limit reached.")

    # 3. Visit Counting & Handshake (Deduplicated via session)
    # Only increment if the user DOES NOT have a valid cookie for THIS code.
    if session_code != code:
        try:
            # Increment visit in Shlink
            domain = request.headers.get("X-Forwarded-Host", "fw.orfel.de")
            await client.get(
                f"{SHLINK_URL}/{code}", 
                headers={"Host": domain},
                follow_redirects=False
            )
            logger.info(f"Visit incremented for: {code} on {domain}")
        except Exception as e:
            logger.error(f"Failed to increment visit: {e}")

        # Perform the 302 Handshake to set the new session cookie
        response = Response(status_code=302)
        response.headers["Location"] = full_path
        response.set_cookie(
            key="fwproxy_session",
            value=sign_session(code),
            httponly=True,
            samesite="lax",
            path="/"
        )
        logger.info(f"New session established for {code}. Redirecting to: {full_path}")
        return response

    # 4. Success Case: Valid Session & Passed Strict Checks
    logger.debug(f"Authorized session for {code}: {full_path}")
    return Response(status_code=200)

@app.on_event("shutdown")
async def shutdown_event():
    await client.aclose()
