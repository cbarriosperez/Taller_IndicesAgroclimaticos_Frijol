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
