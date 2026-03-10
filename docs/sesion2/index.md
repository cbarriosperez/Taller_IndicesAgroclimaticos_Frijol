# Sesión 2: Procesamiento Inicial de Datos Climáticos y de Suelos en R

**Fecha:** Miércoles 11 de marzo · 9:00 – 11:00 am (hora Honduras)  
**Duración:** 2 horas

---

## Descripción General

En esta sesión los participantes aprenderán a leer, limpiar, cortar y organizar datos climáticos raster y datos de suelos para Honduras. El resultado será un **pipeline reproducible** que deja los datos listos para calcular los indicadores en la Sesión 3.

## Agenda (120 minutos)

| Duración | Componente |
|----------|-----------|
| 30 min | [Introducción de conceptos de datos geoespaciales](lectura_datos.md) |
| 30 min | [Descarga de datos climáticos y de suelos](clima_suelo.md) |
| 60 min | Práctica |

## Resultados de Aprendizaje

Al finalizar esta sesión, los participantes serán capaces de:

- Leer rasters climáticos (WorldClim, CHIRPS, ERA5) y datos vectoriales en R usando `terra` y `sf`.
- Reproyectar, recortar y enmascarar rasters al área de estudio (Honduras).
- Organizar y guardar datos procesados en formato GeoTIFF estándar.
- Construir un pipeline de R reproducible para la preparación de datos.


## Requisitos Previos

!!! warning "Requisitos técnicos"
    Para sacar el máximo provecho del taller se recomienda:

    - Cuenta creada en [Copernicus Data Store](https://cds.climate.copernicus.eu/datasets/sis-agrometeorological-indicators?tab=overview)
    - Descarga de insumos de la [sesion 2 ](https://drive.google.com/drive/folders/1U_lgC-TuKmmhJJCfv7ThsWzlur4fT9As?usp=drive_link)
    - Descarga de [QGIS](https://qgis.org/download/) 

---
