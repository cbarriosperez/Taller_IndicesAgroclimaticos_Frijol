# Estadística Zonal y Tabulaciones

## Agregación de Indicadores por Municipio

La **estadística zonal** permite resumir los indicadores agroclimáticos (expresados como rasters) a unidades administrativas (municipios, departamentos o zonas productoras definidas por el programa de mejoramiento).

```r
# ============================================================
# Script: 06_mapas_tpe.R
# Sesión 4 — Estadística zonal y productos finales
# ============================================================
library(terra)
library(sf)
library(tidyverse)
library(here)
source(here("scripts", "utils.R"))

# ── Cargar indicadores calculados --------------------------
gdd_r      <- rast(here("outputs","mapas","gdd_primera_honduras.tif"))
dttf_r     <- rast(here("outputs","mapas","dttf_floracion_honduras.tif"))
tmin_ll_r  <- rast(here("outputs","mapas","tmin_llenado_honduras.tif"))
etc_r      <- rast(here("outputs","mapas","etc_total_primera_honduras.tif"))
whd_r      <- rast(here("outputs","mapas","whd_total_primera_honduras.tif"))
cdd_r      <- rast(here("outputs","mapas","cdd_mayo_honduras.tif"))

# Stack de todos los indicadores
indicadores_stack <- c(gdd_r, dttf_r, tmin_ll_r, etc_r, whd_r, cdd_r)
names(indicadores_stack) <- c("GDD_primera","DTTF_floracion",
                               "Tmin_llenado","ETc_total",
                               "WHD_total","CDD_mayo")

# ── Cargar polígonos municipales ---------------------------
hon_mun <- vect(here("data","admin","gadm41_HND_2.shp"))

# ── Estadística zonal por municipio -----------------------
fns <- c("mean", "sd", "min", "max")

tabla_zonal <- lapply(fns, function(fn) {
  z <- zonal(indicadores_stack, hon_mun, fun = fn, na.rm = TRUE)
  colnames(z) <- paste0(names(indicadores_stack), "_", fn)
  return(z)
}) |> bind_cols()

# Agregar atributos del municipio
info_mun <- as.data.frame(hon_mun[, c("GID_1","NAME_1","GID_2","NAME_2")])
tabla_final <- bind_cols(info_mun, tabla_zonal) |>
  rename(depto = NAME_1, municipio = NAME_2) |>
  arrange(depto, municipio)

# ── Guardar tabla completa --------------------------------
write.csv(tabla_final, 
          here("outputs","tablas","indicadores_agroclimaticos_municipios_honduras.csv"),
          row.names = FALSE)

cat("Tabla guardada:", nrow(tabla_final), "municipios ×", ncol(tabla_final), "variables\n")
```

---

## Visualización Tabular con `kableExtra`

```r
library(knitr)
library(kableExtra)

# Seleccionar columnas clave para presentación
tabla_resumen <- tabla_final |>
  select(depto, municipio,
         GDD_primera_mean, DTTF_floracion_mean, 
         Tmin_llenado_mean, WHD_total_mean) |>
  mutate(across(where(is.numeric), ~round(.x, 1)))

kable(tabla_resumen,
      col.names = c("Departamento","Municipio",
                    "GDD (°C·día)","DTTF (días)",
                    "Tmin llenado (°C)","WHD (mm)"),
      caption = "Indicadores agroclimáticos por municipio — Ciclo Primera, Honduras") |>
  kable_styling(bootstrap_options = c("striped","hover","condensed"),
                font_size = 12, full_width = FALSE) |>
  column_spec(4, color = ifelse(tabla_resumen$DTTF_floracion_mean > 5, "red", "black"),
              bold = ifelse(tabla_resumen$DTTF_floracion_mean > 5, TRUE, FALSE)) |>
  column_spec(6, color = ifelse(tabla_resumen$WHD_total_mean > 150, "red", "black"))
```

---

## Interpretación de la Tabla de Indicadores

| Indicador | Rango bajo (favorable) | Rango medio (tolerable) | Rango alto (riesgo severo) |
|-----------|------------------------|-------------------------|---------------------------|
| GDD (°C·día) | > 1 200 | 900 – 1 200 | < 900 |
| DTTF (días) | < 3 | 3 – 7 | > 7 |
| Tmin llenado (°C) | < 18 | 18 – 20 | > 20 |
| WHD total (mm) | < 80 | 80 – 150 | > 150 |
| CDD mayo (días) | < 8 | 8 – 14 | > 14 |
