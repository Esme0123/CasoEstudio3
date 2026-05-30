"""Endpoints de inferencia: predicción y Grad-CAM."""
from __future__ import annotations

from fastapi import APIRouter, File, HTTPException, Query, UploadFile

from ..config import settings
from ..ml import gradcam as gradcam_mod
from ..ml import inference
from ..ml.models import REGISTRY, get_entry
from ..schemas import GradCamResponse, Prediction

router = APIRouter(tags=["inferencia"])

_MAX_BYTES = 10 * 1024 * 1024  # 10 MB
_ModelQuery = Query(
    default=None,
    description=f"Modelo a usar. Opciones: {', '.join(REGISTRY)}. Por defecto: {settings.default_model}.",
)


async def _read_image(file: UploadFile):
    if file.content_type and not file.content_type.startswith("image/"):
        raise HTTPException(status_code=415, detail="El archivo debe ser una imagen.")
    raw = await file.read()
    if not raw:
        raise HTTPException(status_code=400, detail="Archivo vacío.")
    if len(raw) > _MAX_BYTES:
        raise HTTPException(status_code=413, detail="La imagen supera el límite de 10 MB.")
    try:
        return inference.load_image(raw)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


def _resolve_entry(model: str | None):
    try:
        return get_entry(model)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/predict", response_model=Prediction, summary="Clasificar una imagen")
async def predict(
    file: UploadFile = File(..., description="Imagen de la superficie a evaluar"),
    model: str | None = _ModelQuery,
) -> Prediction:
    entry = _resolve_entry(model)
    image = await _read_image(file)
    return inference.predict(entry, image)


@router.post(
    "/predict/gradcam",
    response_model=GradCamResponse,
    summary="Clasificar y devolver mapa de calor Grad-CAM",
)
async def predict_gradcam(
    file: UploadFile = File(..., description="Imagen de la superficie a evaluar"),
    model: str | None = _ModelQuery,
) -> GradCamResponse:
    entry = _resolve_entry(model)
    image = await _read_image(file)

    prediction = inference.predict(entry, image)
    target_idx = settings.class_names.index(prediction.label)
    try:
        overlay = gradcam_mod.generate_gradcam(entry, image, target_idx)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=f"Error generando Grad-CAM: {exc}") from exc

    return GradCamResponse(prediction=prediction, gradcam_image=overlay)
