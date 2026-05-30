"""Endpoints de estado e información de modelos."""
from __future__ import annotations

from fastapi import APIRouter

from ..config import settings
from ..ml.models import DEVICE, REGISTRY
from ..schemas import HealthResponse, ModelInfo, ModelsResponse

router = APIRouter(tags=["estado"])


def _model_infos() -> list[ModelInfo]:
    return [
        ModelInfo(
            name=e.name,
            architecture=e.architecture,
            weights_loaded=e.weights_loaded,
            weights_path=str(e.weights_path) if e.weights_path else None,
        )
        for e in REGISTRY.values()
    ]


@router.get("/health", response_model=HealthResponse, summary="Estado del servicio")
def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        version=settings.version,
        device=str(DEVICE),
        models=_model_infos(),
    )


@router.get("/models", response_model=ModelsResponse, summary="Modelos disponibles")
def models() -> ModelsResponse:
    return ModelsResponse(default=settings.default_model, models=_model_infos())
