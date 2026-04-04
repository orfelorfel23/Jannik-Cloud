import os
from fastapi import FastAPI, HTTPException, Request, Response
import httpx
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("middleware")

app = FastAPI()

SHLINK_URL = os.getenv("SHLINK_URL", "http://fwproxy-shlink:8080")
SHLINK_API_KEY = os.getenv("SHLINK_API_KEY")

if not SHLINK_API_KEY:
    logger.error("SHLINK_API_KEY environment variable is not set!")

# Use a single AsyncClient for all requests
client = httpx.AsyncClient()

@app.get("/check/{code}")
async def check_access(code: str):
    logger.info(f"Checking access for code: {code}")
    
    # 1. Fetch info from Shlink REST API
    try:
        resp = await client.get(
            f"{SHLINK_URL}/rest/v3/short-urls/{code}",
            headers={"X-Api-Key": SHLINK_API_KEY}
        )
    except Exception as e:
        logger.error(f"Error connecting to Shlink API: {e}")
        raise HTTPException(status_code=500, detail="Internal connection error")

    if resp.status_code == 404:
        logger.warning(f"Code not found: {code}")
        raise HTTPException(status_code=404, detail="Code not found")
    
    if resp.status_code != 200:
        logger.error(f"Shlink API returned status {resp.status_code}: {resp.text}")
        raise HTTPException(status_code=500, detail="Error from Shlink API")

    data = resp.json()
    
    # Shlink API v3 structure: meta.maxVisits and visitsSummary.total
    meta = data.get("meta", {})
    max_visits = meta.get("maxVisits")
    
    visits_summary = data.get("visitsSummary", {})
    current_visits = visits_summary.get("total", 0)

    logger.info(f"Code: {code} | Visits: {current_visits} | Max: {max_visits}")

    # 2. Check visit limits
    # If max_visits is None, it means unlimited
    if max_visits is not None and current_visits >= max_visits:
        logger.warning(f"Access denied for {code}: Limit reached ({current_visits}/{max_visits})")
        raise HTTPException(status_code=403, detail="Visit limit reached")

    # 3. Increment visit count via Shlink (Internal Request)
    # We perform a GET to the actual short URL to trigger Shlink's visit tracking
    try:
        # follow_redirects=False because we only want to trigger the visit, not follow the link
        await client.get(f"{SHLINK_URL}/{code}", follow_redirects=False)
        logger.info(f"Visit incremented for code: {code}")
    except Exception as e:
        logger.error(f"Error incrementing visit for {code}: {e}")
        # We still allow the user in even if increment fails, or should we?
        # Assuming we should proceed since the limit wasn't reached yet.

    return Response(status_code=200)

@app.on_event("shutdown")
async def shutdown_event():
    await client.aclose()
