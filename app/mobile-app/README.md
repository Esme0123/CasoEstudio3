# FisuraScan — App móvil

Aplicación Flutter para la **detección de grietas en superficies** mediante IA.
Consume el backend FastAPI de `app/backend`, comparando dos modelos (CNN
*Baseline* entrenada desde cero y *MobileNet* por transferencia) y mostrando
explicabilidad con mapas de calor **Grad-CAM**.

## Características

- 📸 **Captura/galería**: toma una foto o elige una imagen de la superficie.
- 🧠 **Selección de modelo**: alterna entre `baseline` y `mobilenet`.
- 🎯 **Resultado visual**: anillo de confianza animado, veredicto y barras de
  probabilidad por clase.
- 🔥 **Grad-CAM**: superposición del mapa de calor con un control deslizante
  para mezclar imagen original / calor.
- 🕓 **Historial local**: tus análisis recientes se guardan en el dispositivo.
- 🩺 **Estado del backend**: pantalla de modelos con `/health` y `/models`,
  dispositivo de cómputo y pesos cargados.
- ⚙️ **Ajustes**: configura la URL del servidor con atajos por entorno.

## Arquitectura del código

```
lib/
├── main.dart                # Arranque + Provider + tema
├── core/
│   ├── theme.dart           # Sistema de diseño (colores, radios, tipografía)
│   └── constants.dart       # URL por defecto, claves de prefs, ids de modelo
├── models/                  # Contrato JSON del backend (Prediction, Health…)
├── services/api_service.dart# Cliente HTTP (predict, gradcam, health, models)
├── state/app_state.dart     # Estado global (ChangeNotifier + persistencia)
├── widgets/                 # Componentes (anillo, tarjetas, barras, logo…)
└── screens/                 # Splash, shell, analizar, resultado, historial,
                             # modelos y ajustes
```

## Requisitos

- Flutter 3.41+ (Dart 3.11+)
- El backend de `app/backend` en ejecución.

## Ejecutar

1. **Arranca el backend** (desde la raíz del repo):

   ```bash
   cd app/backend
   .venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

2. **Instala dependencias y lanza la app**:

   ```bash
   cd app/mobile-app
   flutter pub get
   flutter run
   ```

3. **Configura la URL del servidor** (pestaña *Ajustes*) según tu entorno:

   | Entorno                     | URL                          |
   |-----------------------------|------------------------------|
   | Emulador Android            | `http://10.0.2.2:8000`       |
   | Simulador iOS / Escritorio  | `http://localhost:8000`      |
   | Dispositivo físico (LAN)    | `http://TU_IP_LOCAL:8000`    |

   La app elige un valor por defecto razonable según la plataforma; el
   indicador *En línea / Sin conexión* de la cabecera confirma la conexión.

## Notas

- En desarrollo se permite tráfico HTTP en claro (Android `usesCleartextTraffic`
  e iOS ATS abierto) para apuntar a `localhost`/IP LAN sin TLS.
- Si un modelo no tiene pesos `.pth` cargados en el backend, la app lo advierte
  (los resultados de ese modelo serían poco fiables).
