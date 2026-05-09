from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime, timezone

app = FastAPI(title="Kickstart API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/ping")
def ping():
    return {
        "status": "ok",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "service": "kickstart-api",
    }


class EchoBody(BaseModel):
    message: str
    timestamp: int | None = None


@app.post("/api/echo")
def echo(body: EchoBody):
    return {
        "echo": body.message,
        "received_at": datetime.now(timezone.utc).isoformat(),
        "original_timestamp": body.timestamp,
    }
