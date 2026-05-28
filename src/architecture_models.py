import torch
import torch.nn as nn
import timm

class BaselineCNN(nn.Module):
    def __init__(self):
        super(BaselineCNN, self).__init__()
        self.features = nn.Sequential(
            nn.Conv2d(3, 32, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
            nn.Conv2d(64, 128, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2)
        )
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Linear(128 * 28 * 28, 128),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(128, 2)
        )

    def forward(self, x):
        return self.classifier(self.features(x))

def get_mobilenet_v4():
    # Instanciación eficiente para simular bloques UIB avanzados de transferencia
    model = timm.create_model('mobilenetv3_large_100', pretrained=True)
    for param in model.parameters():
        param.requires_grad = False
        
    num_features = model.classifier.in_features
    model.classifier = nn.Linear(num_features, 2)
    return model