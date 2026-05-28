import os
import zipfile
from torchvision import datasets, transforms
from torch.utils.data import DataLoader, random_split

def download_and_extract():
    os.environ['KAGGLE_CONFIG_DIR'] = '/content'
    if not os.path.exists('/content/dataset'):
        print("Descargando dataset desde Kaggle...")
        os.system('kaggle datasets download -d arunrk7/surface-crack-detection')
        with zipfile.ZipFile("surface-crack-detection.zip", 'r') as zip_ref:
            zip_ref.extractall("/content/dataset")
        print("Dataset listo y extraído.")

def get_data_loaders(batch_size=32):
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
    
    train_set, test_set = random_split(dataset, [train_size, test_size])
    
    train_loader = DataLoader(train_set, batch_size=batch_size, shuffle=True, num_workers=2)
    test_loader = DataLoader(test_set, batch_size=batch_size, shuffle=False, num_workers=2)
    
    return train_loader, test_loader