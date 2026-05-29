// ─────────────────────────────────────────────────────────────────────────────
//  INFORME DE CASO DE ESTUDIO 3
//  Clasificación Inteligente de Inventario mediante MobileNetV4
// ─────────────────────────────────────────────────────────────────────────────

// ── Carátula ─────────────────────────────────────────────────────────────────
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 3cm, right: 3cm),
)

#set text(font: "Times New Roman", size: 12pt, lang: "es")

#set align(center)

#v(1.5cm)

#text(weight: "bold", size: 14pt)[UNIVERSIDAD CATÓLICA BOLIVIANA] \
#text(weight: "bold", size: 14pt)["SAN PABLO"]

#v(0.8cm)

#image("imagenes/logo_ucb.png", width: 5.5cm)

#v(0.8cm)

#text(weight: "bold", size: 16pt)[
  Proyecto: Clasificación Inteligente de \
  Inventario mediante MobileNetV4
]

#v(1.2cm)

#set align(left)

#text(weight: "bold")[Integrantes:]
#v(0.2cm)
#pad(left: 1cm)[
  - Lopez Castillo Kael Alessandro \
  - Medina Paredes Esmeralda Paula \
  - Parra Aguilar Franco Jhoel \
  - Rodas Miranda Camila Nicole \
  - Torrez Calle Álvaro Ariel
]

#v(0.3cm)
#text(weight: "bold")[Docente:] Ovidio Roger Paton Gutierrez

#v(0.2cm)
#text(weight: "bold")[Fecha:] 29 / 05 / 2026

#v(0.2cm)
#text(weight: "bold")[Materia:] Machine Learning

#v(0.2cm)
#text(weight: "bold")[Equipo:] Vincit Data

#v(1fr)

#set align(center)
#image("imagenes/logo_sis.png", width: 2.8cm)

#pagebreak()

// ── Configuración del cuerpo del documento ───────────────────────────────────
#set page(paper: "a4", margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm))
#set text(font: "New Computer Modern", size: 11pt, lang: "es")
#set align(left)
#set heading(numbering: "1.")
#set par(justify: true, leading: 0.65em)
#show heading.where(level: 1): it => { v(1em); it; v(0.5em) }
#show heading.where(level: 2): it => { v(0.7em); it; v(0.3em) }

// ── Tabla de Contenidos ──────────────────────────────────────────────────────
#outline(title: "Tabla de Contenidos", indent: 1em)

#pagebreak()

// ─────────────────────────────────────────────────────────────────────────────
= Resumen Crítico
// ─────────────────────────────────────────────────────────────────────────────

El primer paper analizado aborda la visión por computadora desde los fundamentos del machine learning, explicando cómo esta disciplina ha evolucionado hasta el estado actual. Las redes neuronales convolucionales (CNNs) son presentadas como el pilar de la visión artificial, especialmente eficaces para clasificación de imágenes. El problema central que motiva el paper es la *escasez de datos etiquetados*: el ejemplo paradigmático del COVID-19, donde se necesitaba entrenar modelos de detección de anomalías en radiografías con muy pocos datos disponibles, ilustra perfectamente este desafío.

Es en ese contexto donde emerge el *Transfer Learning* (TL): la posibilidad de reutilizar un modelo ya entrenado en un dominio con abundantes datos (como ImageNet) para adaptarlo al dominio objetivo con datos limitados. En las CNNs, este concepto se implementa conservando las capas convolucionales inferiores —que capturan características genéricas como bordes y texturas— y reentrenando únicamente las capas superiores con los datos del dominio meta. El survey documenta múltiples casos de uso: detección de enfermedades de piel, reconocimiento de actividad humana e incluso algoritmos genéticos, donde los individuos de la última generación de una tarea fuente se usan como población inicial de la tarea objetivo. La conclusión central es que el Transfer Learning es especialmente valioso cuando los datos son escasos, el etiquetado es costoso o el entrenamiento desde cero resulta computacionalmente prohibitivo.

El segundo paper introduce *MobileNetV4* (ECCV 2024), cuya contribución central es la optimización microarquitectónica para lograr un rendimiento universal y eficiente en el ecosistema móvil heterogéneo. El paper parte del *Modelo Roofline*, que clasifica cualquier capa de red neuronal como limitada por cómputo o por ancho de banda de memoria. A partir de ese diagnóstico, propone dos innovaciones: el *Universal Inverted Bottleneck (UIB)*, que unifica convoluciones y Transformers mediante búsqueda de arquitectura neuronal (NAS) en cuatro variantes dinámicas; y *Mobile MQA*, un mecanismo de atención multi-consulta que comparte claves y valores entre cabezas de consulta, reduciendo las operaciones de transposición de tensores y acelerando la inferencia un 39% en aceleradores móviles. Combinadas con destilación de conocimiento usando el dataset JFT, estas técnicas permiten que un modelo compacto alcance 87.0% de precisión en ImageNet-1K. La conclusión es que MobileNetV4 resuelve el problema histórico de la variabilidad de rendimiento entre dispositivos móviles, permitiendo un despliegue uniforme y eficiente en la mayoría del hardware moderno.

// ─────────────────────────────────────────────────────────────────────────────
= Fundamento Técnico
// ─────────────────────────────────────────────────────────────────────────────

Se emplearon los siguientes modelos y técnicas de machine learning:

*Redes Neuronales (NN):* Subconjunto del machine learning que imita las interconexiones de neuronas biológicas. Consisten en nodos conectados y dispuestos en capas que, al activarse, procesan datos y los transmiten a la capa siguiente para tomar decisiones sin programación explícita. Son la base sobre la que se construyen todas las arquitecturas más avanzadas descritas en los papers.

*Redes Neuronales Profundas (DNN):* El término "profundo" indica el uso de múltiples capas ocultas para transformar los datos de entrada en salidas mediante transformaciones complejas y no lineales. A mayor profundidad, mayor capacidad para aprender patrones abstractos, aunque también mayor riesgo de sobreajuste si el dataset es pequeño.

*Redes Neuronales Convolucionales (CNN):* Arquitectura avanzada diseñada para clasificación de imágenes y reconocimiento de patrones. Su estructura comprende capas convolucionales, capas de agrupamiento (*pooling*) y capas completamente conectadas (FCNs). Las capas convolucionales aplican filtros que detectan bordes, texturas y formas en distintas regiones de la imagen, lo que las hace especialmente eficientes comparadas con redes densas tradicionales para tareas visuales.

*Transfer Learning (TL) supervisado:* En las CNNs se aplica congelando las capas inferiores (características genéricas) y reemplazando las capas superiores por un clasificador adaptado al dominio meta. El modelo preentrenado ya "sabe" reconocer bordes, colores y formas básicas gracias a haber visto millones de imágenes, por lo que solo se necesita enseñarle las diferencias específicas del nuevo problema.

*Fine-Tuning:* Variante del Transfer Learning donde, tras adaptar la cabeza clasificadora, se descongela parcialmente el backbone y se entrena con una tasa de aprendizaje muy baja. Permite que el modelo ajuste sus representaciones internas al nuevo dominio sin perder el conocimiento previo adquirido durante el preentrenamiento.

*Función de pérdida (CrossEntropyLoss):* Mide qué tan equivocadas están las predicciones del modelo durante el entrenamiento. El optimizador busca minimizarla ajustando los pesos de la red en cada iteración. En clasificación binaria, una pérdida baja y estable indica que el modelo está aprendiendo correctamente.

*Optimizadores (Adam y AdamW):* Algoritmos que actualizan los pesos de la red en función del gradiente de la pérdida. Adam adapta la tasa de aprendizaje por parámetro, acelerando la convergencia. AdamW añade regularización de peso (*weight decay*) para reducir el sobreajuste, lo que lo hace más adecuado para el fine-tuning de modelos preentrenados.

*Máquinas de Vector de Soporte (SVM) y Random Forest (RF):* Clasificadores supervisados empleados en el paper como comparadores en las etapas finales de la tubería para contrastar con las redes neuronales. Resultan útiles cuando el dataset es pequeño o cuando se necesita interpretar fácilmente por qué el modelo tomó una decisión.

*Algoritmos Genéticos (GP):* Técnica donde el TL se aplica transfiriendo los individuos de la última generación de una tarea fuente como población inicial de la tarea meta, reduciendo el *code bloat* y mejorando la convergencia.

*Universal Inverted Bottleneck (UIB):* Bloque microarquitectónico flexible que extiende el Inverted Bottleneck tradicional. Introduce dos convoluciones depthwise opcionales, permitiendo que NAS instancie dinámicamente cuatro variantes: IB clásico, ConvNext-Like, FFN y ExtraDW. Su flexibilidad permite a la red adaptarse tanto a capas que requieren más capacidad de cómputo como a capas limitadas por el ancho de banda de memoria del dispositivo.

*Mobile MQA (Multi-Query Attention):* Mecanismo de atención que comparte una única cabeza para claves y valores a través de todas las cabezas de consulta. Reduce drásticamente el ancho de banda de memoria e incrementa la intensidad operativa, lo que se traduce en una inferencia más rápida en dispositivos móviles sin sacrificar precisión.

*Optimización Einsum:* Reordena los índices de tensores en los cálculos de MQA para eliminar transposiciones innecesarias, reduciendo la saturación de memoria.

*Modelo Roofline:* Modelo analítico que clasifica una carga de trabajo como limitada por cómputo o por memoria, independientemente del hardware específico, usando la relación entre intensidad operativa y el punto de cresta del chip. Es la herramienta que guía las decisiones de diseño en MobileNetV4 para garantizar eficiencia en hardware heterogéneo.

*Destilación de Conocimiento Offline (JFT Distillation):* Una red "Maestro" masiva (EfficientNet-L2, 480M parámetros) genera etiquetas probabilísticas suaves con las que el modelo "Estudiante" (MobileNetV4) se entrena, eliminando el ruido de los aumentos de datos tradicionales. Es el equivalente a aprender de un experto que, en lugar de decir simplemente "esto es un gato", explica con qué probabilidad podría ser también un perro o un tigre, lo que enriquece el aprendizaje del modelo pequeño.

*Data Augmentation:* Técnica de preprocesamiento que genera variaciones artificiales de las imágenes de entrenamiento (rotaciones, volteos, cambios de brillo) para que el modelo aprenda a reconocer los patrones independientemente de la orientación o condición de iluminación. Es especialmente importante en este caso de uso, donde las cámaras del almacén pueden capturar empaques desde distintos ángulos y bajo luces variables.

*Grad-CAM (Gradient-weighted Class Activation Mapping):* Técnica de Inteligencia Artificial Explicable (XAI) que genera un mapa de calor sobre la imagen indicando qué zonas influyeron más en la predicción del modelo. Permite verificar que el modelo está mirando el defecto real y no algún elemento irrelevante del fondo, lo cual es fundamental para confiar en el sistema en un entorno industrial.

// ─────────────────────────────────────────────────────────────────────────────
= Relación con la Materia
// ─────────────────────────────────────────────────────────────────────────────

Ambos papers emplean conceptos de machine learning como eje central de su desarrollo. El primer paper presenta las redes neuronales recurrentes y convolucionales como herramientas fundamentales de la visión por computadora, especialmente las CNNs para clasificación de imágenes, y utiliza el Transfer Learning como mecanismo para superar las limitaciones de datos y reducir costos de entrenamiento. Se ilustra con ejemplos concretos —detección de enfermedades de piel, reconocimiento de actividad humana, algoritmos genéticos— que demuestran la transversalidad del concepto en los temas de la asignatura.

El segundo paper refuerza estos conceptos al presentar MobileNetV4 como una solución arquitectónica avanzada que combina convoluciones clásicas con mecanismos de atención (Transformers), integrando NAS y destilación de conocimiento para lograr eficiencia en el despliegue móvil. Ambos papers demuestran la aplicabilidad práctica de los contenidos de machine learning de la asignatura en problemas industriales y de dispositivos reales.

// ─────────────────────────────────────────────────────────────────────────────
= Caso de Uso: "Edge-Commerce & Control de Calidad"
// ─────────────────────────────────────────────────────────────────────────────

El caso de uso se enfoca en la modernización del control de calidad automatizado para una cadena de distribución y retail tradicional con operaciones ininterrumpidas en Bolivia desde 1959. Históricamente, la inspección de empaques ha sido manual, generando cuellos de botella logísticos y alta tasa de error humano frente a grandes volúmenes de inventario.

La solución propuesta consiste en un sistema de visión artificial basado en MobileNetV4, desplegado en dispositivos periféricos (*Edge Devices*) dentro de almacenes. Este enfoque descentralizado es estratégicamente vital para sucursales en La Paz, donde la dependencia de servidores en la nube de alta latencia o conexiones inestables podría paralizar la cadena de suministro.

Desde una perspectiva de gestión de producto ágil, la integración obedece a historias de usuario del Product Owner: el modelo procesa imágenes de cámaras industriales o dispositivos móviles de operarios para clasificar instantáneamente si un empaque presenta daños estructurales, grietas o roturas de precinto. Esto reduce los costos de logística inversa (devoluciones por productos dañados).

Los datos operativos consisten en un dataset balanceado con dos clases: productos en estado óptimo frente a productos defectuosos. La decisión del modelo es consultiva y de bloqueo preventivo: si detecta una anomalía, detiene la cinta transportadora o emite una alerta visual. La matriz de riesgos identifica el *Falso Negativo* (empaque dañado clasificado como perfecto) como el error de mayor impacto económico. Para mitigarlo, la arquitectura permite ajustar dinámicamente el umbral de clasificación (*thresholding*), priorizando el Recall.

// ─────────────────────────────────────────────────────────────────────────────
= Laboratorio
// ─────────────────────────────────────────────────────────────────────────────

El experimento se ejecutó íntegramente en Google Colab (GPU NVIDIA T4, PyTorch 2.x) mediante dos notebooks CRISP-DM con semilla global `SEED=42`. Todo el código de preprocesamiento y arquitecturas está modularizado en `src/data_processing.py` y `src/architecture_models.py`, permitiendo reproducción exacta ejecutando las celdas en orden.

== Pipeline de Datos

Ambos notebooks comparten el mismo pipeline de ingesta: el dataset *Surface Crack Detection* (Kaggle · arunrk7, ~40 000 imágenes RGB, split 80/20 con semilla fija) se descarga mediante la API de Kaggle. El EDA previo al entrenamiento verificó balance de clases (≈50 % cada clase, sin necesidad de sobremuestreo) y compatibilidad estadística de píxeles con la normalización ImageNet. Las transformaciones aplicadas son: `Resize(224×224)`, `RandomHorizontalFlip(p=0.5)`, `RandomRotation(±15°)`, `ToTensor` y `Normalize(ImageNet mean/std)` —el Data Augmentation se aplica exclusivamente al conjunto de entrenamiento para no contaminar la evaluación.

== Notebook 01 — CNN Baseline desde Cero

Como piso de referencia se ejecutó primero un `DummyClassifier` (estrategia `most_frequent`) que alcanzó F1-Macro 0.33, confirmando que el dataset está balanceado y que cualquier modelo útil debe superar claramente ese umbral.

El modelo `BaselineCNN` consta de tres bloques convolucionales (32 → 64 → 128 filtros), cada uno con ReLU y MaxPooling, seguidos de una cabeza densa con Dropout 0.5. Sus 12 938 690 parámetros se inicializan aleatoriamente y se entrenan con Adam (lr=1×10⁻³) y CrossEntropyLoss durante 5 épocas (~608 s en T4). Los resultados por época muestran convergencia rápida: precisión de prueba del 98.16 % ya en la época 1, cerrando en 99.51 % en la época 5 sin brecha significativa entre train y test.

#figure(
  image("imagenes/nb01_curvas_aprendizaje.png", width: 93%),
  caption: [Curvas de pérdida y precisión (train vs. test) del CNN Baseline. La convergencia desde la época 1 y la brecha mínima entre ambas curvas confirman que el modelo aprende sin sobreajuste.]
)

== Notebook 02 — Transfer Learning con MobileNetV4

El backbone `mobilenetv3_large_100` (timm, pesos ImageNet) se carga con todos sus parámetros congelados (`requires_grad = False`). Solo se reemplaza la cabeza por `Linear(num_features → 2)`, dejando únicamente *2 562 parámetros entrenables* de un total de 4 204 594 (0.06 %). El fine-tuning usa AdamW (lr=1×10⁻⁵, weight_decay=0.01) durante 5 épocas (~561 s en T4). La precisión de prueba en época 5 alcanza 98.70 %, comparable al baseline pero con 5 000× menos parámetros actualizados y una arquitectura optimizada para inferencia en Edge.

#figure(
  image("imagenes/nb02_comparativa.png", width: 93%),
  caption: [Comparativa CNN Baseline vs. MobileNetV4 TL: F1-Macro similar (~0.98) con una fracción mínima de parámetros entrenables (13 M vs. 0.003 M). La ventaja del Transfer Learning es la eficiencia computacional, no la precisión bruta.]
)

Para auditar la calidad del aprendizaje se aplicó Grad-CAM sobre el último bloque convolucional del backbone: se reactivaron sus gradientes y se calcularon los mapas de activación sobre el conjunto de prueba. Las zonas de mayor peso aparecen en rojo sobre la imagen original.

#figure(
  image("imagenes/nb02_gradcam.png", width: 88%),
  caption: [Grad-CAM sobre imágenes del conjunto de prueba: imagen original (fila superior) y mapa de calor superpuesto (fila inferior). Las activaciones se concentran sobre las discontinuidades geométricas de los empaques, confirmando que el modelo identifica el defecto real y no artefactos de iluminación.]
)

Los mapas de calor confirman que el modelo fija su atención en las grietas y bordes rotos. En los escasos errores residuales las activaciones se dispersan hacia zonas de alta saturación lumínica, corroborando la hipótesis del Notebook 01 sobre el sesgo de iluminación y cerrando el ciclo de análisis de error de forma auditable.

// ─────────────────────────────────────────────────────────────────────────────
= Crítica y Limitaciones
// ─────────────────────────────────────────────────────────────────────────────

El principal riesgo operacional del sistema es el *Data Drift*: si las condiciones del almacén cambian —nueva iluminación, diferente tipo de empaque o distintos ángulos de cámara— el modelo puede degradarse sin dar señales obvias de fallo, ya que seguirá produciendo predicciones con alta confianza aunque estén equivocadas. Para mitigar esto se recomienda monitorear continuamente la distribución de las predicciones y programar ciclos periódicos de reentrenamiento con datos frescos capturados en el propio almacén.

En cuanto a reproducibilidad, los resultados presentados están garantizados únicamente para el entorno Colab con GPU T4 y las semillas fijadas. Ejecutar los notebooks en CPU o en hardware diferente puede producir pequeñas variaciones numéricas debido a operaciones no deterministas en CUDA, aunque el comportamiento general del modelo no debería cambiar de forma significativa. El dataset tampoco es de elaboración propia: depende de la disponibilidad del conjunto público en Kaggle, por lo que cualquier cambio en ese repositorio externo afectaría la reproducibilidad del experimento.

Desde el punto de vista ético, automatizar una decisión de control de calidad sin supervisión humana conlleva el riesgo de rechazar productos válidos o aprobar defectuosos de forma sistemática si el modelo tiene un sesgo no detectado. Por eso se insiste en que el sistema debe funcionar como una herramienta de apoyo al operario y no como un juez autónomo, especialmente durante las primeras etapas de despliegue mientras se acumula evidencia sobre su comportamiento en condiciones reales.

// ─────────────────────────────────────────────────────────────────────────────
= Conclusiones
// ─────────────────────────────────────────────────────────────────────────────

Los resultados muestran que una CNN entrenada desde cero puede detectar empaques defectuosos con más del 98% de precisión, pero requiere entrenar millones de parámetros, lo que la hace poco práctica para usarla en celulares o tablets de los operarios. MobileNetV4 con Transfer Learning logró el mismo nivel de precisión entrenando únicamente la última capa del modelo, lo que lo hace mucho más liviano y adecuado para correr directamente en los dispositivos del almacén sin depender de internet.

Por otro lado, el análisis visual mediante Grad-CAM confirmó que el modelo realmente aprende a identificar las grietas en el empaque y no se confunde con el fondo o la iluminación del almacén. Sin embargo, se detectó que los principales errores ocurren en fotos con reflejos de luz muy intensos, por lo que como mejora futura se recomienda incluir más variedad de condiciones de iluminación durante el entrenamiento. En cualquier caso, el sistema no debería tomar decisiones solo, sino alertar al operario para que sea él quien tenga la última palabra.

// ─────────────────────────────────────────────────────────────────────────────
= Referencias Bibliográficas
// ─────────────────────────────────────────────────────────────────────────────

#set par(justify: false)

Deng, J., et al. (2024). *Transfer Learning Applied to Computer Vision Problems: Survey on Current Progress, Limitations, and Opportunities*. arXiv preprint arXiv:2409.07736.

#v(0.4em)

Howard, A., et al. (2024). *MobileNetV4: Universal Models for the Mobile Ecosystem*. European Conference on Computer Vision (ECCV). arXiv:2404.10518.

#v(0.4em)

Goodfellow, I., Bengio, Y., & Courville, A. (2016). *Deep Learning*. MIT Press. (Referencia teórica de la Unidad 4).

#v(0.4em)

PyTorch Documentation (2026). *Transfer Learning for Computer Vision Tutorial*. Recuperado de: https://pytorch.org/tutorials/beginner/transfer_learning_tutorial.html.
