"""Punto de entrada de la API FastAPI.

Arrancar en desarrollo:
    .venv/bin/uvicorn app.main:app --reload
"""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .ml.models import load_all_models
from .routers import health, predict

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Carga los modelos (y sus pesos si existen) una sola vez al arrancar.
    load_all_models()
    yield


app = FastAPI(
    title=settings.title,
    version=settings.version,
    description=settings.description,
    lifespan=lifespan,
)

# CORS abierto: el cliente principal es la app Flutter (móvil/web).
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(predict.router)


@app.get("/", tags=["estado"], summary="Información básica")
def root() -> dict:
    return {
        "service": settings.title,
        "version": settings.version,
        "docs": "/docs",
        "endpoints": ["/health", "/models", "/predict", "/predict/gradcam"],
    }
