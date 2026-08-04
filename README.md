# StructIA

Calculadora de materiales de construcción, basada en tablas prácticas
de ingeniería civil (alineadas a criterios ACI 318 / ACI 211.1).

## Qué hace

- **Concreto y agregados**: sacos de cemento (42.5 kg), arena y grava
  según volumen y resistencia f'c (140 a 280 kg/cm²).
- **Acero de refuerzo**: peso y varillas comerciales necesarias,
  incluyendo traslapes reales (regla de 40 diámetros) cuando un tramo
  supera la varilla comercial (9 m), reaprovechando retazos entre piezas.
- **Columnas**: concreto + acero longitudinal y estribos, con vista
  seccionada y distribución simétrica de varillas.
- **Vigas**: concreto + acero superior, inferior y estribos, con vista
  seccionada y guía conceptual sobre el momento según el tipo de apoyo.
- **Zapatas**: corrida (por metro lineal, con acero longitudinal y
  bastones transversales) o aislada (con cama de varillas en dos
  direcciones y vista en planta).
- Todas las calculadoras de elementos permiten indicar **cantidad de
  unidades iguales** (varias columnas, vigas o zapatas del mismo tipo).
- **Guardar cada cálculo** en "Mis cálculos guardados" para ir armando
  el total de materiales de todo el proyecto, con resumen y exportación
  a PDF.
- Exportar cualquier resultado individual a **PDF** para guardar o
  imprimir.

## Cómo correrlo

```bash
flutter pub get
flutter run
```

## Cómo correr las pruebas

```bash
flutter test
```

## Nota importante

Estas calculadoras cuantifican materiales para el volumen, resistencia
o armado que tú especificas — no diseñan la estructura. Cuánto acero
necesita realmente una columna, viga o zapata depende del análisis
estructural y geotécnico con las cargas reales de la edificación, algo
que debe definir un ingeniero. Confirma siempre con un profesional
antes de construir.
