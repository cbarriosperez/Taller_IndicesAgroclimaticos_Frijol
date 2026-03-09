# Sesión 2: Procesamiento Inicial de Datos Climáticos y de Suelos en R

En esta sesión aprenderán a obtener, leer y preparar en R las tres bases de datos geoespaciales que usaremos a lo largo del taller: datos climáticos de **WorldClim**, datos agrometeorológicos de **AgERA5 / CHIRPS** y datos de suelos de **SoilGrids**. Al finalizar, cada participante tendrá un conjunto de capas raster limpias, recortadas al territorio de Honduras y listas para calcular indicadores agroclimáticos.

---

## 🎯 Objetivos de la sesión

Al concluir esta sesión, los participantes serán capaces de:

1. Comprender los principios básicos de los datos espaciales (CRS, raster, vector).
2. Descargar y leer datos climáticos y edáficos globales en R.
3. Recortar, enmascarar y reproyectar capas raster al área de estudio.
4. Organizar un pipeline reproducible de preparación de datos.

---

## 📋 Contenidos

| # | Tema | Descripción |
|---|------|-------------|
| 1 | [Datos Climáticos y de Suelos](clima_suelo.md) | Fuentes de datos: CHIRPS, AgERA5 y SoilGrids |
| 2 | [Análisis Espacial en R](lectura_datos.md) | Manejo de rasters (`terra`) y vectores (`sf`) |
| 3 | [Recorte y Organización Espacial](recorte_organizacion.md) | Crop, mask, reproyección y estadísticas zonales |
| 4 | [Pipeline Reproducible](pipeline.md) | Scripts numerados, rutas portables con `here` |

---

## ⏱️ Duración estimada

**3 horas** (incluyendo ejercicios prácticos)

---

## ✅ Prerrequisitos

- Haber completado la [Sesión 1](../sesion1/index.md) (entorno R configurado con los paquetes instalados).
- Tener acceso a internet para descargar datos durante la sesión.
