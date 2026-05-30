"""Entrenamiento local de ambos modelos y exportación de pesos para el backend.

Replica fielmente los notebooks (mismas arquitecturas de src/, semilla 42,
split 80/20, normalización ImageNet, 5 épocas) pero usando rutas locales en
lugar de las de Google Colab. Genera:

    app/backend/models/baseline_cnn.pth
    app/backend/models/mobilenet_v4.pth

Uso:
    # 1) Credenciales Kaggle (una de estas opciones):
    export KAGGLE_USERNAME=tu_usuario
    export KAGGLE_KEY=tu_api_key
    #    o bien coloca ~/.kaggle/kaggle.json

    # 2) Ejecutar:
    app/backend/.venv/bin/python scripts/train_local.py

Flags:
    --skip-baseline / --skip-mobilenet   omitir un modelo
    --epochs N                           nº de épocas (def. 5)
    --dataset DIR                        dir del dataset (def. ./dataset)
"""
from __future__ import annotations

import argparse
import os
import sys
import time
import zipfile
from pathlib import Path

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, random_split
from torchvision import datasets, transforms

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT))

from src.architecture_models import BaselineCNN, get_mobilenet_v4  # noqa: E402
from src.data_processing import set_seed  # noqa: E402

SEED = 42
MODELS_DIR = REPO_ROOT / "app" / "backend" / "models"


def get_device() -> torch.device:
    if torch.cuda.is_available():
        return torch.device("cuda")
    if torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def _seed_worker(worker_id: int) -> None:
    worker_seed = torch.initial_seed() % 2**32
    import random

    import numpy as np

    np.random.seed(worker_seed)
    random.seed(worker_seed)


def download_and_extract(dataset_dir: Path) -> None:
    """Descarga el dataset surface-crack-detection de Kaggle si no existe."""
    if dataset_dir.exists() and any(dataset_dir.iterdir()):
        print(f"Dataset ya presente en {dataset_dir}")
        return

    print("Descargando dataset desde Kaggle (arunrk7/surface-crack-detection)...")
    import kaggle  # import tardío: requiere credenciales ya configuradas

    dataset_dir.mkdir(parents=True, exist_ok=True)
    kaggle.api.dataset_download_files(
        "arunrk7/surface-crack-detection",
        path=str(REPO_ROOT),
        quiet=False,
    )
    zip_path = REPO_ROOT / "surface-crack-detection.zip"
    print(f"Extrayendo {zip_path} ...")
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(dataset_dir)
    print(f"Dataset listo en {dataset_dir}")


def build_loaders(dataset_dir: Path, batch_size: int = 32, seed: int = SEED):
    """Réplica local de src.data_processing.get_data_loaders (ruta configurable)."""
    set_seed(seed)
    transform_pipeline = transforms.Compose(
        [
            transforms.Resize((224, 224)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.RandomRotation(degrees=15),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )
    dataset = datasets.ImageFolder(root=str(dataset_dir), transform=transform_pipeline)
    print(f"Clases detectadas (orden ImageFolder): {dataset.classes}")
    train_size = int(0.8 * len(dataset))
    test_size = len(dataset) - train_size

    split_gen = torch.Generator().manual_seed(seed)
    train_set, test_set = random_split(dataset, [train_size, test_size], generator=split_gen)

    loader_gen = torch.Generator().manual_seed(seed)
    train_loader = DataLoader(
        train_set, batch_size=batch_size, shuffle=True, num_workers=2,
        worker_init_fn=_seed_worker, generator=loader_gen,
    )
    test_loader = DataLoader(
        test_set, batch_size=batch_size, shuffle=False, num_workers=2,
        worker_init_fn=_seed_worker,
    )
    return train_loader, test_loader


def evaluate(model: nn.Module, loader: DataLoader, criterion, device) -> tuple[float, float]:
    model.eval()
    loss_total, correct, total = 0.0, 0, 0
    with torch.no_grad():
        for imgs, lbls in loader:
            imgs, lbls = imgs.to(device), lbls.to(device)
            out = model(imgs)
            loss = criterion(out, lbls)
            loss_total += loss.item() * imgs.size(0)
            _, pred = out.max(1)
            correct += pred.eq(lbls).sum().item()
            total += lbls.size(0)
    return loss_total / total, 100 * correct / total


def train_model(model, train_loader, test_loader, optimizer, device, epochs: int, nombre: str):
    criterion = nn.CrossEntropyLoss()
    print(f"\n=== Entrenando {nombre} ({epochs} épocas) en {device} ===")
    t0 = time.time()
    for epoch in range(epochs):
        model.train()
        run_loss, correct, total = 0.0, 0, 0
        for imgs, lbls in train_loader:
            imgs, lbls = imgs.to(device), lbls.to(device)
            optimizer.zero_grad()
            out = model(imgs)
            loss = criterion(out, lbls)
            loss.backward()
            optimizer.step()
            run_loss += loss.item() * imgs.size(0)
            _, pred = out.max(1)
            correct += pred.eq(lbls).sum().item()
            total += lbls.size(0)
        tr_loss = run_loss / len(train_loader.dataset)
        tr_acc = 100 * correct / total
        te_loss, te_acc = evaluate(model, test_loader, criterion, device)
        print(
            f"Época {epoch+1}/{epochs}  Train Loss: {tr_loss:.4f}  Train Acc: {tr_acc:.2f}%  "
            f"Test Loss: {te_loss:.4f}  Test Acc: {te_acc:.2f}%"
        )
    print(f"{nombre} entrenado en {time.time()-t0:.1f}s")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--epochs", type=int, default=5)
    ap.add_argument("--dataset", type=str, default=str(REPO_ROOT / "dataset"))
    ap.add_argument("--skip-baseline", action="store_true")
    ap.add_argument("--skip-mobilenet", action="store_true")
    args = ap.parse_args()

    dataset_dir = Path(args.dataset)
    device = get_device()
    MODELS_DIR.mkdir(parents=True, exist_ok=True)

    download_and_extract(dataset_dir)
    train_loader, test_loader = build_loaders(dataset_dir, seed=SEED)

    if not args.skip_baseline:
        set_seed(SEED)
        model = BaselineCNN().to(device)
        optimizer = optim.Adam(model.parameters(), lr=0.001)
        train_model(model, train_loader, test_loader, optimizer, device, args.epochs, "BaselineCNN")
        out = MODELS_DIR / "baseline_cnn.pth"
        torch.save(model.state_dict(), out)
        print(f"✓ Guardado {out}")

    if not args.skip_mobilenet:
        set_seed(SEED)
        model_adv = get_mobilenet_v4().to(device)
        params = filter(lambda p: p.requires_grad, model_adv.parameters())
        optimizer = optim.AdamW(params, lr=1e-5, weight_decay=0.01)
        train_model(model_adv, train_loader, test_loader, optimizer, device, args.epochs, "MobileNetV4 TL")
        out = MODELS_DIR / "mobilenet_v4.pth"
        torch.save(model_adv.state_dict(), out)
        print(f"✓ Guardado {out}")

    print("\nListo. Pesos exportados a app/backend/models/.")


if __name__ == "__main__":
    main()
