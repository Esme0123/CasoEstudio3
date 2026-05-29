import os
import random
import zipfile
import numpy as np
import torch
from torchvision import datasets, transforms
from torch.utils.data import DataLoader, random_split

SEED = 42

def set_seed(seed=SEED):
    """Fija todas las fuentes de aleatoriedad para garantizar reproducibilidad."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False

def _seed_worker(worker_id):
    """Semilla determinista para cada worker del DataLoader."""
    worker_seed = torch.initial_seed() % 2**32
    np.random.seed(worker_seed)
    random.seed(worker_seed)

def download_and_extract():
    os.environ['KAGGLE_CONFIG_DIR'] = '/content'
    if not os.path.exists('/content/dataset'):
        print("Descargando dataset desde Kaggle...")
        os.system('kaggle datasets download -d arunrk7/surface-crack-detection')
        with zipfile.ZipFile("surface-crack-detection.zip", 'r') as zip_ref:
            zip_ref.extractall("/content/dataset")
        print("Dataset listo y extraído.")

def get_data_loaders(batch_size=32, seed=SEED):
    # Fijamos las semillas globales para que la partición y el barajado sean reproducibles
    set_seed(seed)

    transform_pipeline = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.RandomHorizontalFlip(p=0.5),
        transforms.RandomRotation(degrees=15),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])

    dataset = datasets.ImageFolder(root='/content/dataset', transform=transform_pipeline)
    train_size = int(0.8 * len(dataset))
    test_size = len(dataset) - train_size

    # Generador con semilla fija: la partición train/test es idéntica en cada ejecución
    split_generator = torch.Generator().manual_seed(seed)
    train_set, test_set = random_split(dataset, [train_size, test_size], generator=split_generator)

    # Generador con semilla fija para el barajado reproducible del train_loader
    loader_generator = torch.Generator().manual_seed(seed)
    train_loader = DataLoader(train_set, batch_size=batch_size, shuffle=True, num_workers=2,
                              worker_init_fn=_seed_worker, generator=loader_generator)
    test_loader = DataLoader(test_set, batch_size=batch_size, shuffle=False, num_workers=2,
                             worker_init_fn=_seed_worker)

    return train_loader, test_loader