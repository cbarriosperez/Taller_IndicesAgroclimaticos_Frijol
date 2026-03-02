# Práctica A: Indicadores Térmicos

## Estrategia de Cálculo Espacial

Los indicadores térmicos se calculan con datos **WorldClim mensuales**. Dado que WorldClim provee temperaturas medias mensuales (Tmax, Tmin), adoptamos la ventana fenológica a nivel mensual: meses que corresponden a la floración y el llenado de grano según la fecha de siembra regional.

!!! info "Supuesto sobre ventanas fenológicas"
    Para Honduras, la siembra de primera ocurre generalmente en **mayo–junio**. Bajo este esquema:

    - **Floración** (R1–R2): ~julio (mes 7)
    - **Llenado de grano** (R6–R7): ~agosto–septiembre (meses 8–9)
    
    Estos meses se usarán como ventanas de referencia en el script. Ajustar según la zona productora.

---

## 1. Grados-Día de Crecimiento (GDD)

```r
# ============================================================
# Script: 04_indicadores_termicos.R
# Práctica A: Indicadores Térmicos para Frijol
# ============================================================
library(terra)
here::i_am("scripts/04_indicadores_termicos.R")
library(here)
source(here("scripts", "utils.R"))

# ── Cargar datos -------------------------------------------
wc_tmax <- rast(here("data","clima","worldclim","tmax_honduras.tif"))
wc_tmin <- rast(here("data","clima","worldclim","tmin_honduras.tif"))

meses <- c("ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic")
names(wc_tmax) <- meses
names(wc_tmin) <- meses

# ── Parámetros del cultivo ---------------------------------
Tb  <- 10   # Temperatura base del frijol (°C)
Topt <- 28  # Temperatura óptima (°C), opcional para GDD truncado
Tcrit <- 35 # Temperatura crítica superior (°C)

# ── Función: GDD para una ventana de meses ──────────────
calcular_gdd <- function(tmax_sr, tmin_sr, meses_ventana, Tb = 10) {
  tmean <- (tmax_sr[[meses_ventana]] + tmin_sr[[meses_ventana]]) / 2
  gdd_diario <- tmean - Tb
  gdd_diario[gdd_diario < 0] <- 0
  # Multiplicar por aprox. días del mes (usando 30.4 días/mes)
  gdd_mensual <- gdd_diario * 30.4
  return(sum(gdd_mensual))
}

# GDD acumulados durante el ciclo completo (mayo–septiembre)
ciclo_primera <- c("may","jun","jul","ago","sep")
gdd_primera <- calcular_gdd(wc_tmax, wc_tmin, ciclo_primera, Tb = 10)
names(gdd_primera) <- "GDD_primera"

guardar_raster(gdd_primera, here("outputs","mapas","gdd_primera_honduras.tif"))
```

---

## 2. Días con Estrés Térmico en Floración (DTTF)

Los días con Tmax > 35 °C durante la floración reducen drásticamente el cuajado de vainas en frijol. Se estiman a partir de la relación entre la temperatura media y la variabilidad diaria asumida.

```r
# ── Días con calor extremo en floración ───────────────────
# Mes de floración: julio (mes 7)
tmax_jul <- wc_tmax[["jul"]]

# Estimación de días con Tmax > 35 °C en el mes
# Asumiendo distribución normal diaria con sd ≈ 3 °C (estimación conservadora)
# P(Tmax_dia > 35) ≈ pnorm(35, mean = tmax_mensual, sd = 3, lower.tail = FALSE)
# DTTF = P(Tmax > 35) × 31 días (julio)

library(terra)
calcular_dttf <- function(tmax_mensual, umbral = 35, sd_dia = 3, n_dias = 31) {
  prob_calor <- app(tmax_mensual, function(x) {
    pnorm(umbral, mean = x, sd = sd_dia, lower.tail = FALSE)
  })
  dttf <- prob_calor * n_dias
  return(dttf)
}

dttf_floracion <- calcular_dttf(tmax_jul, umbral = 35)
names(dttf_floracion) <- "DTTF_floracion"

guardar_raster(dttf_floracion, here("outputs","mapas","dttf_floracion_honduras.tif"))
```

---

## 3. Temperatura Nocturna en Llenado de Grano

```r
# ── Temperatura mínima media durante llenado de grano ─────
# Fase de llenado: agosto–septiembre (meses 8–9)
tmin_llenado <- mean(wc_tmin[[c("ago","sep")]])
names(tmin_llenado) <- "Tmin_llenado"

# Riesgo de calor nocturno (Tmin > 20 °C afecta llenado)
riesgo_tnocturna <- tmin_llenado > 20
names(riesgo_tnocturna) <- "Riesgo_Tnocturna_llenado"

guardar_raster(tmin_llenado,    here("outputs","mapas","tmin_llenado_honduras.tif"))
guardar_raster(riesgo_tnocturna, here("outputs","mapas","riesgo_tnocturna_honduras.tif"))
```

---

## 4. Visualización de Indicadores Térmicos

```r
library(ggplot2)
library(tidyterra)
library(patchwork)

hon_pais <- vect(here("data","admin","gadm41_HND_0.shp"))

# Mapa 1: GDD acumulados
p1 <- ggplot() +
  geom_spatraster(data = gdd_primera) +
  geom_spatvector(data = hon_pais, fill = NA, color = "black", linewidth = 0.3) +
  scale_fill_viridis_c(name = "GDD (°C·día)", option = "magma", na.value = "white") +
  labs(title = "Grados-Día de Crecimiento", subtitle = "Ciclo primera (May–Sep)") +
  theme_minimal()

# Mapa 2: Días con estrés térmico en floración
p2 <- ggplot() +
  geom_spatraster(data = dttf_floracion) +
  geom_spatvector(data = hon_pais, fill = NA, color = "black", linewidth = 0.3) +
  scale_fill_gradient(
    name   = "Días (est.)",
    low    = "#ffffcc", 
    high   = "#d73027",
    na.value = "white"
  ) +
  labs(title = "Días con Estrés Térmico en Floración", subtitle = "Tmax > 35 °C · Julio") +
  theme_minimal()

# Combinar los dos mapas
p1 + p2 + plot_layout(ncol = 2)
ggsave(here("outputs","mapas","indicadores_termicos_panel.png"), dpi = 200, width = 14, height = 6)
```

---

## Resumen de Indicadores Térmicos Calculados

| Indicador | Archivo de salida | Interpretación |
|-----------|-------------------|---------------|
| GDD_primera | `gdd_primera_honduras.tif` | Acumulación térmica del ciclo. Zonas < 800 GDD son marginales para frijol. |
| DTTF_floracion | `dttf_floracion_honduras.tif` | > 5 días estimados con Tmax > 35 °C en floración = riesgo alto de aborto. |
| Tmin_llenado | `tmin_llenado_honduras.tif` | > 20 °C media en llenado = riesgo de reducción de rendimiento por calor nocturno. |
| Riesgo_Tnocturna | `riesgo_tnocturna_honduras.tif` | Mapa binario (0/1) de zonas con calor nocturno crónico. |
