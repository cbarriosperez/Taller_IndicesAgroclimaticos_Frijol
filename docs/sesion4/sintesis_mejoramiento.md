# Síntesis de Resultados para Mejoramiento Genético

## De los Mapas a las Decisiones

La síntesis final del taller busca **traducir los indicadores agroclimáticos** en información accionable para tres tipos de usuarios:

| Usuario | Pregunta clave | Indicadores relevantes |
|---------|----------------|------------------------|
| **Mejorador genético** | ¿A qué estreses debe resistir la variedad? | DTTF, Tmin_llenado, WHD_total |
| **Técnico en manejo** | ¿Cuándo y dónde sembrar para minimizar riesgos? | GDD, CDD, WHD por mes |
| **Coordinador de red de ensayos** | ¿Qué sitios cubren la variabilidad ambiental de la TPE? | Clasificación TPE |

---

## Recomendaciones por Ambiente (TPE)

A partir del perfil promedio de la clasificación K-Means de 4 ambientes:

### Ambiente 1 — Favorable (verde oscuro)

**Localización típica**: Valles altos del interior (Francisco Morazán, Comayagua > 900 msnm).

| Indicador | Valor típico |
|-----------|-------------|
| GDD primer ciclo | > 1 100 °C·día |
| DTTF floración | < 3 días |
| Tmin llenado | < 18 °C |
| WHD total | < 60 mm |

**Estrategia de mejoramiento**: Variedades de alto potencial de rendimiento con buena arquitectura de planta. La presión de selección puede concentrarse en resistencia a enfermedades (roya, antracnosis) en lugar de tolerancia al calor.

---

### Ambiente 2 — Estrés Térmico Moderado (verde claro)

**Localización típica**: Valles medios (800–1 200 msnm), zona de transición.

| Indicador | Valor típico |
|-----------|-------------|
| GDD primer ciclo | 900 – 1 100 °C·día |
| DTTF floración | 3 – 6 días |
| Tmin llenado | 18 – 20 °C |
| WHD total | 60 – 120 mm |

**Estrategia de mejoramiento**: Combinar potencial de rendimiento con tolerancia moderada al calor. Ciclos medios (~85 días) para escapar parcialmente del estrés terminal.

---

### Ambiente 3 — Estrés Hídrico Moderado-Severo (naranja)

**Localización típica**: Zona sur (Choluteca, Valle, sur de Francisco Morazán).

| Indicador | Valor típico |
|-----------|-------------|
| GDD primer ciclo | 1 000 – 1 200 °C·día |
| DTTF floración | 4 – 8 días |
| WHD total | 120 – 200 mm |
| CDD mayo | 10 – 14 días |

**Estrategia de mejoramiento**: Materiales con eficiencia hídrica, raíces profundas y precocidad para reducir la exposición al estrés terminal. El sistema "apante" (noviembre–febrero) puede ser más estable.

---

### Ambiente 4 — Estrés Severo Combinado (rojo)

**Localización típica**: Zonas bajas del litoral Pacífico y valle del Aguán (< 600 msnm).

| Indicador | Valor típico |
|-----------|-------------|
| DTTF floración | > 8 días |
| Tmin llenado | > 21 °C |
| WHD total | > 200 mm |
| CDD mayo | > 14 días |

**Estrategia de mejoramiento**: Variedades termotolerantes y con mecanismo de escape (ciclo muy corto < 70 días). Explorar mejoramiento específico para el calor nocturno (Tmin).

---

## Selección de Sitios Representativos de Ensayo

```r
# ============================================================
# Selección de sitios de evaluación representativos de la TPE
# ============================================================
library(terra)
library(sf)
library(tidyverse)
library(here)

# Cargar raster TPE y municipios
tpe_r   <- rast(here("outputs","mapas","tpe_kmeans_4ambientes_honduras.tif"))
hon_mun <- vect(here("data","admin","gadm41_HND_2.shp"))

# Estadística modal de TPE por municipio (ambiente dominante)
tpe_mun <- zonal(tpe_r, hon_mun, fun = "modal", na.rm = TRUE)
info_mun <- as.data.frame(hon_mun[, c("NAME_1","NAME_2","HASC_2")])
tpe_mun_df <- bind_cols(info_mun, tpe_ambiente = tpe_mun[, 2])

# Seleccionar 2–3 municipios representativos por ambiente
# (mayor área cubierta por ese ambiente)
tpe_area <- zonal(tpe_r == tpe_r, hon_mun, fun = "sum", na.rm = TRUE)

sitios_repr <- tpe_mun_df |>
  group_by(tpe_ambiente) |>
  slice_max(order_by = tpe_area[, 2], n = 2) |> 
  select(NAME_1, NAME_2, HASC_2, tpe_ambiente) |>
  rename(departamento = NAME_1, municipio = NAME_2, codigo = HASC_2, 
         ambiente_tpe = tpe_ambiente) |>
  arrange(ambiente_tpe)

print(sitios_repr)
write.csv(sitios_repr, 
          here("outputs","tablas","sitios_representativos_tpe_honduras.csv"),
          row.names = FALSE)
```

---

## Próximos Pasos y Extensiones del Análisis

!!! tip "Extensiones recomendadas"
    1. **Series temporales**: Reemplazar WorldClim por datos ERA5-Land (1981–2023) para analizar tendencias.
    2. **Proyecciones de cambio climático**: Usar escenarios CMIP6 (SSP2-4.5, SSP5-8.5) para estimar cómo cambiará el perfil de estrés hacia 2050.
    3. **Validación con datos de estaciones**: Comparar indicadores calculados contra mediciones de estaciones del SMN-Honduras y registros de rendimiento del IHCAFE/Dicta.
    4. **Integración con datos de ensayos**: Correlacionar rendimientos de materiales evaluados en la red de ensayos con los indicadores de sus sitios → **ecofisiología cuantitativa**.
    5. **Dashboard interactivo**: Usar `shiny` + `leaflet` para una visualización interactiva por municipio.
