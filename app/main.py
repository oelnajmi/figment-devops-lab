from fastapi import FastAPI
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import PlainTextResponse

app = FastAPI(title="validator-sim")

requests_total = Counter("validator_requests_total", "Total HTTP requests", ["path"])

@app.get("/")
def root():
    requests_total.labels(path="/").inc()
    return {"ok": True, "service": "validator-sim"}

@app.get("/healthz")
def health():
    requests_total.labels(path="/healthz").inc()
    return {"status": "healthy"}

@app.get("/metrics")
def metrics():
    return PlainTextResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)
