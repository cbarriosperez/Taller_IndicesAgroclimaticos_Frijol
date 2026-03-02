# Lectura y Preparación de Datos Climáticos y de Suelos

## Datos Climáticos con WorldClim

WorldClim v2.1 provee datos climáticos mensuales interpolados (1970–2000) a múltiples resoluciones. El paquete `geodata` permite descargarlos directamente desde R.

```r
# ============================================================
# Script: 02_datos_clima.R
# Sesión 2 — Lectura y preparación de datos climáticos
# ============================================================
library(terra)
library(sf)
library(geodata)
library(tidyverse)

# --- 1. Límite administrativo de Honduras ------------------
hon_pais <- gadm(country = "HND", level = 0, path = "data/admin")
hon_dep  <- gadm(country = "HND", level = 1, path = "data/admin")
hon_mun  <- gadm(country = "HND", level = 2, path = "data/admin")

# Sistema de coordenadas (EPSG:4326 = WGS84 geográfico)
cat("CRS de hon_mun:", crs(hon_mun, describe = TRUE)$code, "\n")

# --- 2. Temperatura máxima y mínima mensual (WorldClim) ----
wc_tmax <- worldclim_country("Honduras", "tmax", res = 2.5, path = "data/clima/worldclim")
wc_tmin <- worldclim_country("Honduras", "tmin", res = 2.5, path = "data/clima/worldclim")
wc_prec <- worldclim_country("Honduras", "prec", res = 2.5, path = "data/clima/worldclim")
wc_srad <- worldclim_country("Honduras", "srad", res = 2.5, path = "data/clima/worldclim")
wc_vapr <- worldclim_country("Honduras", "vapr", res = 2.5, path = "data/clima/worldclim")
wc_wind <- worldclim_country("Honduras", "wind", res = 2.5, path = "data/clima/worldclim")

# Nombrar capas por mes
meses <- c("ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic")
names(wc_tmax) <- meses
names(wc_tmin) <- meses
names(wc_prec) <- meses

# --- 3. Inspección rápida de los datos --------------------
print(wc_tmax)
# Estadísticas descriptivas globales
global(wc_tmax, fun = c("mean", "sd", "min", "max"), na.rm = TRUE)
```

---

## Datos de Suelos con SoilGrids (ISRIC)

Los datos de suelos se obtienen de **SoilGrids** a 250 m de resolución. Las variables de interés para el balance hídrico son:

| Variable SoilGrids | Descripción | Unidades |
|--------------------|------------|---------|
| `awcts` | Agua disponible total en el suelo (0–200 cm) | mm/m |
| `bdod` | Densidad aparente | cg/cm³ |
| `clay` | Contenido de arcilla | g/kg |
| `silt` | Contenido de limo | g/kg |
| `sand` | Contenido de arena | g/kg |
| `phh2o` | pH en agua | - |
| `ocs` | Stock de carbono orgánico | t/ha |

```r
# ============================================================
# Script: 03_datos_suelos.R  
# Sesión 2 — Lectura y preparación de datos de suelos
# ============================================================
library(terra)
library(sf)

# Descargar datos de capacidad de agua disponible
# Nota: SoilGrids se accede vía WCS o archivos descargados manualmente.
# Aquí se asume que los archivos GeoTIFF están en data/suelos/soilgrids/

# Leer AWC (si los archivos ya están descargados)
awc_file <- "data/suelos/soilgrids/awcts_mean_0-200cm_250m.tif"

if (file.exists(awc_file)) {
  awc <- rast(awc_file)
  cat("AWC leído correctamente. Resolución:", res(awc), "\n")
} else {
  cat("Archivo no encontrado. Descargue desde: https://soilgrids.org\n")
  # Alternativamente, usar una estimación simplificada por textura:
  # AWC (mm/m) ≈ 200 * (FC - PWP)
  # para suelo franco: FC ≈ 0.30, PWP ≈ 0.14 → AWC ≈ 32 mm/m
}

# --- Alternativa: Estimación de AWC a partir de textura ----
# Ecuaciones de pedotransferencia (Saxton & Rawls 2006)
estimar_awc <- function(arena_pct, arcilla_pct, mo_pct = 1.5) {
  # arena, arcilla en porcentaje (0–100); mo = materia orgánica %
  S   <- arena_pct / 100
  C   <- arcilla_pct / 100
  OM  <- mo_pct / 100
  
  theta_FC  <- 0.299 - 0.251*S + 0.195*C + 0.011*OM + 0.006*(S*OM) - 0.027*(C*OM) + 0.452*(S*C) + 0.299
  theta_PWP <- 0.031 - 0.024*S + 0.487*C + 0.006*OM + 0.005*(S*OM) - 0.013*(C*OM) + 0.068*(S*C) + 0.031
  
  awc_mm_m <- (theta_FC - theta_PWP) * 1000  # mm por metro de suelo
  return(awc_mm_m)
}

# Ejemplo: suelo franco-arcilloso (30% arcilla, 40% arena, OM 2%)
awc_ejemplo <- estimar_awc(arena_pct = 40, arcilla_pct = 30, mo_pct = 2)
cat("AWC estimada:", round(awc_ejemplo, 1), "mm/m\n")
```
