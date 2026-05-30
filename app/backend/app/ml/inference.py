"""Preprocesamiento de imágenes e inferencia."""
from __future__ import annotations

import io

import numpy as np
import torch
from PIL import Image
from torchvision import transforms

from ..config import settings
from ..schemas import ClassProbability, Prediction
from .models import DEVICE, ModelEntry

# Pipeline de preprocesamiento. SIN aumentos (eso es solo para entrenamiento):
# redimensionar, a tensor y normalizar con las estadísticas de ImageNet.
_preprocess = transforms.Compose(
    [
        transforms.Resize((settings.image_size, settings.image_size)),
        transforms.ToTensor(),
        transforms.Normalize(mean=list(settings.norm_mean), std=list(settings.norm_std)),
    ]
)


def load_image(raw: bytes) -> Image.Image:
    """Decodifica bytes a una imagen RGB de Pillow."""
    try:
        return Image.open(io.BytesIO(raw)).convert("RGB")
    except Exception as exc:  # noqa: BLE001
        raise ValueError(f"No se pudo leer la imagen: {exc}") from exc


def to_tensor(image: Image.Image) -> torch.Tensor:
    """Imagen PIL -> tensor con batch (1, 3, H, W) en el dispositivo activo."""
    return _preprocess(image).unsqueeze(0).to(DEVICE)


def to_rgb_float(image: Image.Image) -> np.ndarray:
    """Imagen redimensionada a [0,1] float (H, W, 3) para overlays de Grad-CAM."""
    resized = image.resize((settings.image_size, settings.image_size))
    return np.asarray(resized, dtype=np.float32) / 255.0


def _build_prediction(entry: ModelEntry, probs: torch.Tensor) -> Prediction:
    probs_list = probs.detach().cpu().tolist()
    top_idx = int(np.argmax(probs_list))

    probabilities = [
        ClassProbability(
            label=settings.class_names[i],
            label_es=settings.class_labels_es[i],
            probability=float(p),
        )
        for i, p in enumerate(probs_list)
    ]
    return Prediction(
        model=entry.name,
        label=settings.class_names[top_idx],
        label_es=settings.class_labels_es[top_idx],
        confidence=float(probs_list[top_idx]),
        probabilities=probabilities,
        weights_loaded=entry.weights_loaded,
    )


@torch.inference_mode()
def predict(entry: ModelEntry, image: Image.Image) -> Prediction:
    """Ejecuta la inferencia y devuelve la predicción estructurada."""
    tensor = to_tensor(image)
    logits = entry.module(tensor)
    probs = torch.softmax(logits, dim=1)[0]
    return _build_prediction(entry, probs)
