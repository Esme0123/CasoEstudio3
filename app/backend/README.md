# Backend de Clasificación de Grietas (FastAPI)

API de inferencia para el proyecto de detección de grietas en superficies.
Sirve dos modelos: una **CNN entrenada desde cero** (`baseline`) y un modelo de
**transferencia basado en MobileNet** (`mobilenet`). Pensado para consumirse
desde la app Flutter en `app/mobile-app`.

## Estructura

```
app/backend/
├── app/
│   ├── main.py            # App FastAPI + CORS + carga de modelos al arrancar
│   ├── config.py          # Configuración (rutas de pesos, clases, normalización)
│   ├── schemas.py         # Modelos de respuesta (contrato JSON)
│   ├── ml/
│   │   ├── models.py      # Arquitecturas + registro + carga de pesos
│   │   ├── inference.py   # Preprocesamiento e inferencia
│   │   └── gradcam.py     # Mapas de calor Grad-CAM
│   └── routers/
│       ├── health.py      # /health, /models
│       └── predict.py     # /predict, /predict/gradcam
├── models/                # Coloca aquí los pesos .pth (ver abajo)
└── requirements.txt
```

## Instalación

```bash
cd app/backend
.venv/bin/pip install -r requirements.txt
```

## Pesos entrenados

Coloca tus pesos en `models/` con estos nombres (configurables en `config.py`):

| Modelo      | Archivo esperado    |
|-------------|---------------------|
| `baseline`  | `baseline_cnn.pth`  |
| `mobilenet` | `mobilenet_v4.pth`  |

Se admite tanto un `state_dict` como un modelo completo guardado con
`torch.save`. Si falta un archivo, ese modelo arranca **sin entrenar**
(MobileNet conserva el backbone preentrenado) y `/health` lo reporta con
`weights_loaded: false`.

Para exportar desde el notebook:

```python
torch.save(model.state_dict(), "baseline_cnn.pth")
```

## Ejecutar

```bash
cd app/backend
.venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Documentación interactiva (Swagger): http://localhost:8000/docs
- `--host 0.0.0.0` permite que el móvil físico acceda por la IP de tu máquina.

## Endpoints

| Método | Ruta               | Descripción |
|--------|--------------------|-------------|
| GET    | `/`                | Info básica del servicio |
| GET    | `/health`          | Estado, dispositivo y pesos cargados |
| GET    | `/models`          | Modelos disponibles y modelo por defecto |
| POST   | `/predict`         | Clasifica una imagen (multipart `file`) |
| POST   | `/predict/gradcam` | Clasifica y devuelve el mapa de calor Grad-CAM |

Parámetro opcional `?model=baseline|mobilenet` en los endpoints de inferencia
(por defecto `mobilenet`).

### Ejemplo

```bash
curl -F "file=@superficie.jpg" "http://localhost:8000/predict?model=mobilenet"
```

```json
{
  "model": "mobilenet",
  "label": "Positive",
  "label_es": "Con grieta",
  "confidence": 0.97,
  "probabilities": [
    {"label": "Negative", "label_es": "Sin grieta", "probability": 0.03},
    {"label": "Positive", "label_es": "Con grieta", "probability": 0.97}
  ],
  "weights_loaded": true
}
```

`/predict/gradcam` devuelve además `gradcam_image` como data URI PNG
(`data:image/png;base64,...`), listo para mostrar en Flutter con
`Image.memory(base64Decode(...))`.

## Consumo desde Flutter

```dart
final uri = Uri.parse('http://10.0.2.2:8000/predict'); // emulador Android
final req = http.MultipartRequest('POST', uri)
  ..files.add(await http.MultipartFile.fromPath('file', imagePath));
final res = await http.Response.fromStream(await req.send());
final data = jsonDecode(res.body);
```

> En emulador Android usa `10.0.2.2` para apuntar al `localhost` del host.
> En iOS simulator usa `localhost`. En dispositivo físico, la IP LAN de tu PC.

## Configuración por variables de entorno (prefijo `APP_`)

| Variable               | Por defecto         |
|------------------------|---------------------|
| `APP_MODELS_DIR`       | `./models`          |
| `APP_DEFAULT_MODEL`    | `mobilenet`         |
| `APP_BASELINE_WEIGHTS` | `baseline_cnn.pth`  |
| `APP_MOBILENET_WEIGHTS`| `mobilenet_v4.pth`  |
