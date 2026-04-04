import os
import hmac
import hashlib
from fastapi import FastAPI, HTTPException, Request, Response
import httpx
import logging

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

def sign_session():
    # Simple HMAC signature for the session cookie
    signature = hmac.new(
        SESSION_SECRET.encode(),
        "valid".encode(),
        hashlib.sha256
    ).hexdigest()
    return f"valid.{signature}"

def verify_session(cookie_value: str):
    if not cookie_value:
        return False
    try:
        val, sig = cookie_value.split(".")
        expected_sig = hmac.new(
            SESSION_SECRET.encode(),
            val.encode(),
            hashlib.sha256
        ).hexdigest()
        return hmac.compare_digest(sig, expected_sig) and val == "valid"
    except Exception:
        return False

@app.get("/check{full_path:path}")
async def check_access(full_path: str, request: Request):
    # Strip leading slash and split the path
    path_parts = [p for p in full_path.split("/") if p]
    
    # CASE 1: Check session cookie first for resource access
    session_cookie = request.cookies.get("fwproxy_session")
    if verify_session(session_cookie):
        logger.info(f"Authorized via session cookie: {full_path}")
        return Response(status_code=200)

    # CASE 2: No valid session, check if the first part of the path is a valid Shlink code
    if not path_parts:
        logger.warning("No code provided and no valid session.")
        raise HTTPException(status_code=403, detail="Access Denied: Please use a valid link.")

    potential_code = path_parts[0]
    logger.info(f"Checking potential code: {potential_code}")
    
    # 1. Fetch info from Shlink REST API
    try:
        resp = await client.get(
            f"{SHLINK_URL}/rest/v3/short-urls/{potential_code}",
            headers={"X-Api-Key": SHLINK_API_KEY}
        )
    except Exception as e:
        logger.error(f"Error connecting to Shlink API: {e}")
        raise HTTPException(status_code=500, detail="Internal connection error")

    if resp.status_code == 200:
        data = resp.json()
        meta = data.get("meta", {})
        max_visits = meta.get("maxVisits")
        current_visits = data.get("visitsSummary", {}).get("total", 0)

        # 2. Check visit limits
        if max_visits is not None and current_visits >= max_visits:
            logger.warning(f"Limit reached for {potential_code}: {current_visits}/{max_visits}")
            raise HTTPException(status_code=403, detail="Visit limit reached")

        # 3. Valid code! Increment visit count
        try:
            await client.get(f"{SHLINK_URL}/{potential_code}", follow_redirects=False)
            logger.info(f"Visit incremented for: {potential_code}")
        except Exception as e:
            logger.error(f"Failed to increment visit: {e}")

        # 4. Grant access and set session cookie
        response = Response(status_code=200)
        # We tell Caddy that this request is a 'code entry' so it can rewrite to root
        # Only rewrite if the path is EXACTLY the code
        if len(path_parts) == 1:
            response.headers["X-Is-Code"] = "true"
        
        response.set_cookie(
            key="fwproxy_session",
            value=sign_session(),
            httponly=True,
            samesite="lax"
            # Secure=True would be better but requires HTTPS in Caddy
        )
        return response

    # CASE 3: Not a valid code and no valid session
    logger.warning(f"Invalid code attempt or unauthorized resource access: {full_path}")
    raise HTTPException(status_code=403, detail="Unauthorized")

@app.on_event("shutdown")
async def shutdown_event():
    await client.aclose()
