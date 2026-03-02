# Recorte y Organización Espacial de Datos

## Operaciones Espaciales Fundamentales

Antes de calcular indicadores, los datos deben estar en el **mismo sistema de referencia de coordenadas (CRS)**, resolución y extensión. Esta sección describe el flujo estándar de preparación espacial.

```r
# ============================================================
# Recorte, reproyección y organización de rasters
# ============================================================
library(terra)
library(sf)

# Cargar límite de Honduras (ya descargado en sesión anterior)
hon_pais <- vect("data/admin/gadm41_HND_0.shp")  # SpatVector (terra)

# ── 1. Verificar y alinear CRS ────────────────────────────
cat("CRS raster (wc_tmax):", crs(wc_tmax, describe=TRUE)$code, "\n")
cat("CRS vector (hon_pais):", crs(hon_pais, describe=TRUE)$code, "\n")

# Si los CRS no coinciden, reproyectar el vector (más rápido que reproyectar rasters grandes)
if (crs(wc_tmax) != crs(hon_pais)) {
  hon_pais <- project(hon_pais, crs(wc_tmax))
}

# ── 2. Recortar (crop) al bounding box de Honduras ────────
wc_tmax_crop <- crop(wc_tmax, hon_pais)
wc_tmin_crop <- crop(wc_tmin, hon_pais)
wc_prec_crop <- crop(wc_prec, hon_pais)
wc_srad_crop <- crop(wc_srad, hon_pais)
wc_vapr_crop <- crop(wc_vapr, hon_pais)
wc_wind_crop <- crop(wc_wind, hon_pais)

# ── 3. Enmascarar (mask) a la forma exacta del país ───────
wc_tmax_hon <- mask(wc_tmax_crop, hon_pais)
wc_tmin_hon <- mask(wc_tmin_crop, hon_pais)
wc_prec_hon <- mask(wc_prec_crop, hon_pais)
wc_srad_hon <- mask(wc_srad_crop, hon_pais)
wc_vapr_hon <- mask(wc_vapr_crop, hon_pais)
wc_wind_hon <- mask(wc_wind_crop, hon_pais)

# ── 4. Guardar en disco como GeoTIFF ──────────────────────
writeRaster(wc_tmax_hon, "data/clima/worldclim/tmax_honduras.tif", overwrite = TRUE)
writeRaster(wc_tmin_hon, "data/clima/worldclim/tmin_honduras.tif", overwrite = TRUE)
writeRaster(wc_prec_hon, "data/clima/worldclim/prec_honduras.tif", overwrite = TRUE)
writeRaster(wc_srad_hon, "data/clima/worldclim/srad_honduras.tif", overwrite = TRUE)
writeRaster(wc_vapr_hon, "data/clima/worldclim/vapr_honduras.tif", overwrite = TRUE)
writeRaster(wc_wind_hon, "data/clima/worldclim/wind_honduras.tif", overwrite = TRUE)

cat("Datos climáticos recortados y guardados.\n")
```

---

## Remuestreo y Alineación de Resoluciones

Cuando los datos de suelos (250 m) y clima (≈4.5 km) tienen resoluciones distintas, es necesario **remuestrear** uno de ellos para que coincidan en la misma grilla:

```r
# ── 5. Remuestrear suelos a la resolución de WorldClim ────
# (Asumiendo que awc ya fue leída como SpatRaster)

# Opción A: Remuestrear suelos a la resolución del clima (2.5 min ≈ 4.5 km)
awc_hon_resamp <- resample(
  x      = awc,          # raster a remuestrear
  y      = wc_tmax_hon,  # raster de referencia (resolución objetivo)
  method = "bilinear"    # interpolación bilineal (continua)
)

# Opción B: Remuestrear clima a la resolución de suelos (250 m)
# Más pesado computacionalmente pero preserva detalle del suelo
wc_tmax_fine <- resample(wc_tmax_hon, awc, method = "bilinear")

# Guardar la versión remuestreada
writeRaster(awc_hon_resamp, "data/suelos/soilgrids/awc_honduras_2-5min.tif", overwrite = TRUE)
```

!!! note "¿Qué resolución elegir?"
    Para este taller trabajaremos a **2.5 minutos de arco** (~4.5 km), que es un buen balance entre detalle espacial y costo computacional para análisis a escala nacional.

---

## Visualización Rápida de los Datos Preparados

```r
library(tidyterra)
library(ggplot2)

# Mapa de temperatura máxima media anual
tmax_anual <- mean(wc_tmax_hon)

ggplot() +
  geom_spatraster(data = tmax_anual) +
  geom_spatvector(data = hon_pais, fill = NA, color = "black", linewidth = 0.4) +
  scale_fill_viridis_c(
    name    = "Tmax (°C)",
    option  = "inferno",
    na.value = "white"
  ) +
  labs(
    title    = "Temperatura Máxima Media Anual — Honduras",
    subtitle = "WorldClim v2.1 (1970–2000) · Promedio de 12 meses",
    caption  = "Fuente: worldclim.org | Procesado con terra + ggplot2"
  ) +
  theme_minimal() +
  theme(
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10),
    legend.position = "right"
  )

ggsave("outputs/mapas/tmax_anual_honduras.png", dpi = 200, width = 10, height = 6)
```

---

## Extracción por Zonas Administrativas

Para obtener estadísticas tabulares por municipio:

```r
library(terra)
library(sf)
library(tidyverse)

# Extraer estadísticas zonales de Tmax promedio anual por municipio
hon_mun_v <- vect(hon_mun)  # convertir a SpatVector si está como sf

stats_mun <- zonal(
  x   = tmax_anual,         # raster de entrada
  z   = hon_mun_v,          # zonas (polígonos municipales)
  fun = "mean",             # función de agregación
  na.rm = TRUE
)

# Unir con atributos del municipio
tabla_mun <- cbind(
  as.data.frame(hon_mun_v[, c("NAME_1", "NAME_2")]),  # dep y municipio
  tmax_media = round(stats_mun[, 2], 2)
)

print(head(tabla_mun, 10))

# Guardar tabla
write.csv(tabla_mun, "outputs/tablas/tmax_media_municipios_honduras.csv", row.names = FALSE)
```



## Datos de Suelos con SoilGrids (ISRIC)

Los datos de suelos se obtienen de **SoilGrids** a 250 m de resolución. Las variables de interés para el balance hídrico son:


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
