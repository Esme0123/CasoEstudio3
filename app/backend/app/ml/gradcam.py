"""Generación de mapas de calor Grad-CAM superpuestos sobre la imagen."""
from __future__ import annotations

import base64
import io

import numpy as np
import torch
from PIL import Image
from pytorch_grad_cam import GradCAM
from pytorch_grad_cam.utils.image import show_cam_on_image
from pytorch_grad_cam.utils.model_targets import ClassifierOutputTarget

from .inference import to_rgb_float, to_tensor
from .models import ModelEntry


def _to_data_uri(rgb_uint8: np.ndarray) -> str:
    """Array (H, W, 3) uint8 -> data URI PNG base64."""
    buf = io.BytesIO()
    Image.fromarray(rgb_uint8).save(buf, format="PNG")
    encoded = base64.b64encode(buf.getvalue()).decode("ascii")
    return f"data:image/png;base64,{encoded}"


def generate_gradcam(entry: ModelEntry, image: Image.Image, target_class: int) -> str:
    """Calcula Grad-CAM para ``target_class`` y devuelve el overlay como data URI.

    Grad-CAM necesita gradientes, por eso no usa inference_mode.
    """
    # requires_grad en la entrada: con el backbone congelado, sin esto las
    # activaciones previas a la cabeza entrenable quedan fuera del grafo de
    # autograd y Grad-CAM no recibe gradientes (grads = None).
    input_tensor = to_tensor(image).requires_grad_(True)
    rgb = to_rgb_float(image)
    target_layers = [entry.gradcam_layer(entry.module)]

    with GradCAM(model=entry.module, target_layers=target_layers) as cam:
        grayscale = cam(
            input_tensor=input_tensor,
            targets=[ClassifierOutputTarget(target_class)],
        )[0]  # (H, W) en [0, 1]

    overlay = show_cam_on_image(rgb, grayscale, use_rgb=True)  # uint8 (H, W, 3)
    return _to_data_uri(overlay)
