# Práctica B: Indicadores Hídricos

## Fundamentos: Balance Hídrico del Frijol

El balance hídrico relaciona la **oferta de agua** (precipitación + almacenamiento del suelo) con la **demanda** del cultivo (evapotranspiración). El déficit hídrico ocurre cuando la demanda supera la oferta, generando estrés.

$$WHD = ETc - P \quad (\text{si } ETc > P)$$

---

## 1. Evapotranspiración de Referencia (ET₀) — Método de Hargreaves

El método de **Hargreaves-Samani** (1985) es la alternativa más usada cuando no se dispone de todos los datos para Penman-Monteith. Solo requiere Tmax, Tmin y Radiación solar extraterrestre (Ra):

$$ET_0 = 0.0023 \times (T_{media} + 17.8) \times \sqrt{T_{max} - T_{min}} \times R_a$$

```r
# ============================================================
# Script: 05_indicadores_hidricos.R
# Práctica B: Indicadores Hídricos para Frijol
# ============================================================
library(terra)
library(here)
source(here("scripts", "utils.R"))

# ── Cargar datos -------------------------------------------
wc_tmax <- rast(here("data","clima","worldclim","tmax_honduras.tif"))
wc_tmin <- rast(here("data","clima","worldclim","tmin_honduras.tif"))
wc_prec <- rast(here("data","clima","worldclim","prec_honduras.tif"))
wc_srad <- rast(here("data","clima","worldclim","srad_honduras.tif"))

meses <- c("ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic")
names(wc_tmax) <- names(wc_tmin) <- names(wc_prec) <- names(wc_srad) <- meses

# ── 1. Cálculo de ET₀ por Hargreaves-Samani ──────────────
# srad en WorldClim viene en kJ m⁻² día⁻¹, convertir a MJ m⁻² día⁻¹
srad_mj <- wc_srad / 1000  

# Ra (radiación solar extraterrestre) ≈ obtenida de latitude + día del año
# Simplificación: Ra ≈ 0.82 × srad (coeficiente de transmisividad media ~0.70)
Ra <- srad_mj / 0.70  

calcular_et0_hargreaves <- function(tmax, tmin, Ra) {
  tmean <- (tmax + tmin) / 2
  et0 <- 0.0023 * (tmean + 17.8) * sqrt(tmax - tmin) * Ra
  et0[et0 < 0] <- 0
  return(et0)
}

# Calcular ET₀ para cada mes
et0_lista <- lapply(meses, function(m) {
  calcular_et0_hargreaves(wc_tmax[[m]], wc_tmin[[m]], Ra[[m]])
})
et0 <- rast(et0_lista)
names(et0) <- paste0("et0_", meses)

guardar_raster(et0, here("outputs","mapas","et0_mensual_honduras.tif"))
```

---

## 2. Evapotranspiración del Cultivo (ETc)

```r
# ── 2. ETc = ET₀ × Kc (FAO-56) ───────────────────────────
# Coeficientes de cultivo (Kc) del frijol por fase/mes
# Para siembra en mayo (ciclo primera):
#   May (ini)=0.35, Jun (dev)=0.75, Jul (mid)=1.15,
#   Ago (mid-late)=0.90, Sep (late)=0.35

kc_frijol <- c(ene=0, feb=0, mar=0, abr=0,
               may=0.35, jun=0.75, jul=1.15,
               ago=0.90, sep=0.35, oct=0, nov=0, dic=0)

# Calcular ETc únicamente para meses del ciclo
ciclo <- c("may","jun","jul","ago","sep")
etc_lista <- lapply(ciclo, function(m) {
  etc_m <- et0[[paste0("et0_", m)]] * kc_frijol[[m]]
  names(etc_m) <- paste0("etc_", m)
  return(etc_m)
})
etc_ciclo <- rast(etc_lista)

# ETc total del ciclo (mm)
etc_total <- sum(etc_ciclo)
names(etc_total) <- "ETc_total_primera"

guardar_raster(etc_total, here("outputs","mapas","etc_total_primera_honduras.tif"))
```

---

## 3. Déficit Hídrico Acumulado (WHD)

```r
# ── 3. Déficit Hídrico = ETc - Precipitación ─────────────
prec_ciclo <- wc_prec[[ciclo]]
deficit_lista <- lapply(ciclo, function(m) {
  d <- etc_ciclo[[paste0("etc_", m)]] - prec_ciclo[[m]]
  d[d < 0] <- 0   # El exceso de lluvia no es "déficit"
  names(d) <- paste0("deficit_", m)
  return(d)
})
deficit_ciclo <- rast(deficit_lista)

whd_total <- sum(deficit_ciclo)
names(whd_total) <- "WHD_total_primera_mm"

guardar_raster(whd_total, here("outputs","mapas","whd_total_primera_honduras.tif"))
```

---

## 4. Días Secos Consecutivos (CDD)

El CDD se estima a partir de la **precipitación mensual** asumiendo una distribución geométrica negativa de días secos. Una aproximación práctica:

```r
# ── 4. CDD aproximado a partir de días secos del mes ─────
# Probabilidad de día seco: ps ≈ 1 - (prec_mensual / (30.4 × 1 mm × n_dias_lluvia))
# Aproximación empírica: CDD ≈ 1 / (1 - ps) donde ps depende de la lluvia mensual

calcular_cdd_aprox <- function(prec_mensual, n_dias = 30) {
  # Fracción de días con < 1 mm de lluvia
  ps <- 1 - (prec_mensual / (n_dias * 2))  # 2 mm/día promedio en días lluviosos
  ps[ps < 0] <- 0
  ps[ps > 0.98] <- 0.98   # Evitar división por cero
  cdd_aprox <- 1 / (1 - ps)  # Longitud media de rachas secas
  return(round(cdd_aprox, 1))
}

# CDD estimado para el mes más seco del ciclo (mayo)
cdd_may <- calcular_cdd_aprox(wc_prec[["may"]])
names(cdd_may) <- "CDD_mayo_diagnostico"

guardar_raster(cdd_may, here("outputs","mapas","cdd_mayo_honduras.tif"))
```

---

## 5. Índice SPEI

El SPEI (*Standardized Precipitation-Evapotranspiration Index*) requiere datos históricos para estandarizar. Con WorldClim (solo un punto temporal) se calcula como una estimación del déficit normalizado:

```r
# ── 5. SPEI simplificado (balance hídrico normalizado) ────
# Balance hídrico mensual = Precipitación - ET₀
library(SPEI)

# Extraer series de valores para un punto de ejemplo
punto_ejemplo <- vect(cbind(-87.2, 14.1), crs = "EPSG:4326")

prec_punto <- extract(wc_prec, punto_ejemplo)[, -1]
et0_punto  <- extract(et0, punto_ejemplo)[, -1]

balance_punto <- as.numeric(prec_punto) - as.numeric(et0_punto)
names(balance_punto) <- meses

# Calcular SPEI a escala de 3 meses
# Nota: para series cortas es solo ilustrativo; SPEI requiere >= 30 años
spei_3 <- spei(ts(balance_punto, frequency = 12), scale = 3)

# Visualizar
plot(spei_3, main = "SPEI-3 — Honduras (punto de ejemplo)")
```

!!! warning "SPEI con series largas"
    El SPEI es estadísticamente significativo solo con series de **al menos 30 años** de datos mensuales. Para este ejercicio se usa como ilustración metodológica. Para análisis reales, usar datos **CHIRPS** (1981–presente) o **ERA5** con series históricas completas.

---

## Resumen de Indicadores Hídricos Calculados

| Indicador | Archivo | Interpretación |
|-----------|---------|---------------|
| ET₀ mensual | `et0_mensual_honduras.tif` | Demanda evaporativa de la atmósfera (12 capas, mm/día) |
| ETc total ciclo | `etc_total_primera_honduras.tif` | Agua total que el cultivo necesita en el ciclo primera |
| WHD total | `whd_total_primera_honduras.tif` | Déficit hídrico acumulado del ciclo. > 150 mm = riesgo severo |
| CDD mayo | `cdd_mayo_honduras.tif` | Días secos consecutivos estimados en el mes de siembra |
