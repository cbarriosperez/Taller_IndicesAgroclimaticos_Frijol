# Construcción de Mapas Agroclimáticos y Clasificación de Ambientes (TPE)

Hasta ahora, hemos aprendido a procesar datos climáticos (CHIRPS/AgERA5) y de suelo (SoilGrids) por separado. Sin embargo, en el mundo real, la variabilidad espacial conjunta de las variables de suelo y clima ofrece la oportunidad de delimitar zonas edafoclimáticas contiguas. Estas zonas son fundamentales para mejorar el manejo de los recursos naturales.

## Mapas de Indicadores Agroclimáticos

La pregunta ahora es: ¿Cómo delimitamos matemáticamente estas zonas (TPEs) en R usando nuestros mapas? Como no sabemos a priori dónde están las fronteras exactas de estos agroecosistemas, estamos frente a un problema clásico de **Aprendizaje No Supervisado (Unsupervised Learning)**.

Para ello, usaremos el algoritmo de [**K-Means Clustering**](https://medium.com/@abhaysingh71711/k-means-clustering-a-deep-dive-into-unsupervised-learning-81213f56cfc9)  Le pediremos a R que tome las capas creadad en Honduras y, basándose en la "distancia matemática" entre sus valores, los agrupe de forma automática en ambientes homogéneos.


```r
# ============================================================
# Zonificación Edafo-Climática
# ============================================================
library(terra)
library(ggplot2)
library(tidyterra)
library(patchwork)
library(here)

hon_pais <- vect(here("data","admin","gadm41_HND_0.shp"))
hon_dep  <- vect(here("data","admin","gadm41_HND_1.shp"))

# Función para crear mapa temático estándar
mapa_indicador <- function(raster, titulo, subtitulo, 
                            leyenda_nombre, paleta = "viridis",
                            vector_pais = hon_pais, 
                            vector_dep  = hon_dep) {
  ggplot() +
    geom_spatraster(data = raster) +
    geom_spatvector(data = vector_dep,  fill = NA, color = "grey50",  linewidth = 0.2) +
    geom_spatvector(data = vector_pais, fill = NA, color = "black",   linewidth = 0.5) +
    scale_fill_viridis_c(name = leyenda_nombre, option = paleta, 
                          na.value = "white", direction = 1) +
    labs(
      title    = titulo,
      subtitle = subtitulo,
      caption  = "Fuente: WorldClim v2.1 (1970–2000) | Procesado en R con terra"
    ) +
    coord_sf(expand = FALSE) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title    = element_text(face = "bold", size = 13),
      plot.subtitle = element_text(size = 9, color = "grey40"),
      plot.caption  = element_text(size = 8, color = "grey50"),
      legend.position = "right",
      panel.background = element_rect(fill = "#d0e4f0", color = NA)
    )
}

# Mapa 1: Déficit Hídrico Total
whd_r <- rast(here("outputs","mapas","whd_total_primera_honduras.tif"))
p_whd <- mapa_indicador(
  whd_r, "Déficit Hídrico Acumulado",
  "Ciclo Primera (May–Sep) — Frijol, Honduras",
  "WHD (mm)", paleta = "YlOrRd"
)

# Mapa 2: GDD
gdd_r <- rast(here("outputs","mapas","gdd_primera_honduras.tif"))
p_gdd <- mapa_indicador(
  gdd_r, "Grados-Día de Crecimiento",
  "Ciclo Primera (May–Sep) — Frijol, Honduras",
  "GDD (°C·día)", paleta = "magma"
)

# Mapa 3: DTTF
dttf_r <- rast(here("outputs","mapas","dttf_floracion_honduras.tif"))
p_dttf <- mapa_indicador(
  dttf_r, "Días c/ Estrés Térmico en Floración",
  "Tmax > 35 °C · Julio — Frijol, Honduras",
  "Días (est.)", paleta = "inferno"
)

# Panel combinado
panel <- (p_gdd | p_whd) / p_dttf +
  plot_annotation(
    title    = "Indicadores Agroclimáticos para el Cultivo de Frijol — Honduras",
    subtitle = "Ciclo de primera siembra (Mayo–Septiembre)",
    theme    = theme(plot.title = element_text(face = "bold", size = 15))
  )

ggsave(here("outputs","mapas","panel_indicadores_agroclimaticos_honduras.png"),
       plot = panel, dpi = 200, width = 14, height = 12)
cat("Panel de mapas guardado.\n")
```

---

## Clasificación de Ambientes Objetivo (TPE)

La **TPE** (*Target Population of Environments*) agrupa zonas productoras con perfiles de estrés similares, permitiendo diseñar estrategias de mejoramiento diferenciadas por tipo de ambiente.

### Método: K-Means sobre Indicadores Agroclimáticos

```r
library(terra)
library(tidyverse)
library(here)

# ── Construir tabla de valores por pixel ──────────────────
indicadores_stack <- c(
  rast(here("outputs","mapas","gdd_primera_honduras.tif")),
  rast(here("outputs","mapas","dttf_floracion_honduras.tif")),
  rast(here("outputs","mapas","tmin_llenado_honduras.tif")),
  rast(here("outputs","mapas","whd_total_primera_honduras.tif")),
  rast(here("outputs","mapas","cdd_mayo_honduras.tif"))
)
names(indicadores_stack) <- c("GDD","DTTF","Tmin_llenado","WHD","CDD")

# Extraer valores como data.frame (excluir NAs)
df_pixels <- as.data.frame(indicadores_stack, na.rm = TRUE, xy = TRUE)
cat("Número de pixels válidos:", nrow(df_pixels), "\n")

# ── Escalar variables (media = 0, sd = 1) ─────────────────
vars_ind <- c("GDD","DTTF","Tmin_llenado","WHD","CDD")
df_scaled <- df_pixels |>
  mutate(across(all_of(vars_ind), scale))

# ── K-Means: determinar número óptimo de clústeres ────────
set.seed(42)
wss <- map_dbl(2:8, function(k) {
  km <- kmeans(df_scaled[, vars_ind], centers = k, nstart = 25, iter.max = 100)
  km$tot.withinss
})

data.frame(k = 2:8, WSS = wss) |>
  ggplot(aes(k, WSS)) +
  geom_line(color = "#2196F3") + geom_point(size = 3) +
  labs(title = "Método del codo — Selección de número de ambientes (TPE)",
       x = "Número de ambientes (k)", y = "Suma de cuadrados intracluster") +
  theme_minimal()

# ── Ajustar K-Means con k = 4 ambientes ───────────────────
km_final <- kmeans(df_scaled[, vars_ind], centers = 4, nstart = 50, iter.max = 200)
df_pixels$TPE <- as.factor(km_final$cluster)

# ── Proyectar clústeres de vuelta al raster ────────────────
tpe_raster <- indicadores_stack[[1]]  # plantilla
tpe_raster[] <- NA

# Asignar clúster a cada pixel (por coordenadas)
idx <- cellFromXY(tpe_raster, df_pixels[, c("x","y")])
tpe_raster[idx] <- as.integer(df_pixels$TPE)

names(tpe_raster) <- "TPE_kmeans_k4"
writeRaster(tpe_raster, here("outputs","mapas","tpe_kmeans_4ambientes_honduras.tif"),
            overwrite = TRUE)

# ── Caracterizar cada ambiente ─────────────────────────────
perfil_tpe <- df_pixels |>
  group_by(TPE) |>
  summarise(across(all_of(vars_ind), mean, na.rm = TRUE, .names = "{col}_mean"),
            n_pixels = n()) |>
  arrange(TPE)

print(perfil_tpe)
write.csv(perfil_tpe, here("outputs","tablas","perfil_ambientes_tpe_honduras.csv"),
          row.names = FALSE)
```

---

## Mapa de TPE

```r
library(tidyterra)

pal_tpe <- c("1" = "#1a9641",  # Ambiente favorable
             "2" = "#a6d96a",  # Estrés moderado
             "3" = "#fdae61",  # Estrés moderado-severo
             "4" = "#d7191c")  # Estrés severo

ggplot() +
  geom_spatraster(data = as.factor(tpe_raster)) +
  geom_spatvector(data = hon_dep,  fill = NA, color = "grey50",  linewidth = 0.2) +
  geom_spatvector(data = hon_pais, fill = NA, color = "black",   linewidth = 0.5) +
  scale_fill_manual(
    values   = pal_tpe,
    na.value = "white",
    name     = "Ambiente\n(TPE)",
    labels   = c("1 — Favorable","2 — Estrés moderado",
                 "3 — Estrés mod.-severo","4 — Estrés severo")
  ) +
  labs(
    title    = "Clasificación de Ambientes Objetivo (TPE) — Honduras",
    subtitle = "K-Means sobre 5 indicadores agroclimáticos del ciclo primera (k=4)",
    caption  = "WorldClim v2.1 | Análisis: R (terra, ggplot2)"
  ) +
  theme_minimal()

ggsave(here("outputs","mapas","mapa_tpe_4ambientes_honduras.png"),
       dpi = 200, width = 10, height = 7)
```
