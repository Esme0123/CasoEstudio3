"""Definición y carga de los modelos de clasificación.

Las arquitecturas replican las de ``src/architecture_models.py`` del proyecto
para que el backend sea autocontenido y desplegable sin los notebooks.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from pathlib import Path

import timm
import torch
import torch.nn as nn

from ..config import settings

logger = logging.getLogger("crack-api.models")

NUM_CLASSES = 2


# --------------------------------------------------------------------------- #
# Arquitecturas
# --------------------------------------------------------------------------- #
class BaselineCNN(nn.Module):
    """CNN entrenada desde cero (espejo de src/architecture_models.py)."""

    def __init__(self) -> None:
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(3, 32, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
            nn.Conv2d(64, 128, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
        )
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Linear(128 * 28 * 28, 128),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(128, NUM_CLASSES),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:  # noqa: D102
        return self.classifier(self.features(x))


def build_mobilenet() -> nn.Module:
    """Modelo de transferencia basado en MobileNetV3 (timm)."""
    model = timm.create_model("mobilenetv3_large_100", pretrained=True)
    for param in model.parameters():
        param.requires_grad = False
    num_features = model.classifier.in_features
    model.classifier = nn.Linear(num_features, NUM_CLASSES)
    return model


# --------------------------------------------------------------------------- #
# Registro de modelos disponibles
# --------------------------------------------------------------------------- #
@dataclass
class ModelEntry:
    name: str
    architecture: str
    builder: callable
    weights_filename: str
    # Cómo localizar la capa convolucional objetivo para Grad-CAM.
    gradcam_layer: callable

    # Estado en runtime
    module: nn.Module | None = None
    weights_loaded: bool = False
    weights_path: Path | None = None


def _baseline_gradcam_layer(model: nn.Module) -> nn.Module:
    # Última capa convolucional del bloque de features.
    return model.features[6]


def _mobilenet_gradcam_layer(model: nn.Module) -> nn.Module:
    # Último bloque convolucional de la red.
    return model.blocks[-1]


REGISTRY: dict[str, ModelEntry] = {
    "baseline": ModelEntry(
        name="baseline",
        architecture="BaselineCNN",
        builder=BaselineCNN,
        weights_filename=settings.baseline_weights,
        gradcam_layer=_baseline_gradcam_layer,
    ),
    "mobilenet": ModelEntry(
        name="mobilenet",
        architecture="MobileNetV3 (transfer learning)",
        builder=build_mobilenet,
        weights_filename=settings.mobilenet_weights,
        gradcam_layer=_mobilenet_gradcam_layer,
    ),
}


# --------------------------------------------------------------------------- #
# Dispositivo
# --------------------------------------------------------------------------- #
def get_device() -> torch.device:
    if torch.cuda.is_available():
        return torch.device("cuda")
    if torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


DEVICE = get_device()


# --------------------------------------------------------------------------- #
# Carga de pesos
# --------------------------------------------------------------------------- #
def _load_weights(model: nn.Module, path: Path) -> bool:
    """Carga pesos desde ``path``. Admite state_dict o modelo completo."""
    try:
        obj = torch.load(path, map_location=DEVICE, weights_only=True)
    except Exception:  # checkpoints guardados sin weights_only
        obj = torch.load(path, map_location=DEVICE, weights_only=False)

    if isinstance(obj, nn.Module):
        state_dict = obj.state_dict()
    elif isinstance(obj, dict):
        # Soporta checkpoints del tipo {"model_state_dict": ...} o state_dict directo.
        state_dict = obj.get("model_state_dict") or obj.get("state_dict") or obj
    else:
        raise ValueError(f"Formato de pesos no reconocido en {path}")

    model.load_state_dict(state_dict, strict=True)
    return True


def load_all_models() -> None:
    """Instancia cada modelo y carga sus pesos si están disponibles.

    Se ejecuta una vez al arrancar la app. Si no hay pesos para un modelo, se
    deja la arquitectura instanciada (backbone preentrenado en MobileNet,
    aleatorio en Baseline) y se marca ``weights_loaded=False``.
    """
    settings.models_dir.mkdir(parents=True, exist_ok=True)

    for entry in REGISTRY.values():
        logger.info("Instanciando modelo '%s' (%s)...", entry.name, entry.architecture)
        model = entry.builder()
        model.to(DEVICE)
        model.eval()

        weights_path = settings.models_dir / entry.weights_filename
        if weights_path.is_file():
            try:
                _load_weights(model, weights_path)
                entry.weights_loaded = True
                entry.weights_path = weights_path
                logger.info("  ✓ Pesos cargados desde %s", weights_path)
            except Exception as exc:  # noqa: BLE001
                entry.weights_loaded = False
                logger.error("  ✗ Error cargando pesos de '%s': %s", entry.name, exc)
        else:
            entry.weights_loaded = False
            logger.warning(
                "  ! Sin pesos para '%s' (esperaba %s). El modelo responderá sin entrenar.",
                entry.name,
                weights_path,
            )

        entry.module = model


def get_entry(name: str | None) -> ModelEntry:
    """Devuelve la entrada del modelo solicitado (o el por defecto)."""
    key = (name or settings.default_model).lower()
    entry = REGISTRY.get(key)
    if entry is None or entry.module is None:
        valid = ", ".join(REGISTRY)
        raise KeyError(f"Modelo '{name}' no disponible. Opciones: {valid}")
    return entry
