# Estadística Zonal y Tabulaciones

## Agregación de Indicadores por Municipio

La **estadística zonal** permite resumir los indicadores agroclimáticos (expresados como rasters) a unidades administrativas (municipios, departamentos o zonas productoras definidas por el programa de mejoramiento).

```r
# ==============================================================================
# MÓDULO: CARACTERIZACIÓN Y SÍNTESIS DE AMBIENTES (TPE)
# Objetivo: Analizar estadísticamente y visualizar las diferencias entre los
#           clústeres generados para definir la Población Objetivo de Entornos.
# ==============================================================================

# --- 1. CONFIGURACIÓN INICIAL ---

# Limpiar memoria para asegurar una ejecución desde cero
rm(list = ls())

# Cargar funciones auxiliares desde GitHub (Pipeline reproducible)

# Cargar funciones auxiliares desde GitHub (Pipeline reproducible)
source(
  paste0(
    "https://raw.githubusercontent.com/cbarriosperez/Taller_IndicesAgroclimaticos_Frijol/main/scripts//", 
    "main_session2.R"
  )
)

# Cargar librerías esenciales
library(sf)         # Manejo de vectores
library(terra)      # Procesamiento raster (clima y suelo)
library(factoextra) # Visualización de algoritmos de clustering
library(tidyverse)  # Manipulación de datos y visualización (ggplot2)

# --- 2. CARGA DE RESULTADOS PREVIOS ---

# Leer el stack edafoclimático procesado (NetCDF guardado en pasos anteriores)
dep_cov = rast("outputs/suelo_indicadores_olancho.nc")

# Leer el mapa de clústeres generado (Zonificación final)
mapa_cluster = rast("outputs/cluster_4_olancho.tif")

# --- 3. ESTADÍSTICA ZONAL: CARACTERIZACIÓN DE LOS TPE ---

# Calcular el valor promedio de cada variable original para cada clúster
# Esto nos permite saber "qué significa" cada número de clúster (ej. seco vs húmedo)
perfil_tpe <- zonal(x = dep_cov, 
                    z = mapa_cluster, 
                    fun = "mean", 
                    na.rm = TRUE)

print(perfil_tpe)

# --- 4. PREPARACIÓN DE DATOS PARA VISUALIZACIÓN ---

# Convertir tabla de formato ancho (wide) a largo (long) para facilitar el uso de ggplot2
perfil_long <- perfil_tpe %>%
  as.data.frame() %>%
  pivot_longer(cols = -cluster,      # Mantener columna cluster
               names_to = "Variable", 
               values_to = "Valor") %>%
  mutate(TPE_Cluster = as.factor(cluster))

# --- 5. GRÁFICO 1: PERFILES PROMEDIO POR CLÚSTER ---

# Este gráfico permite comparar la "firma" de cada ambiente en todas las variables
ggplot(perfil_long, aes(x = TPE_Cluster, y = Valor, fill = TPE_Cluster)) +
  geom_col(alpha = 0.8, color = "black") +
  # Usar escalas independientes (free_y) ya que pH, Arcilla y Lluvia tienen unidades distintas
  facet_wrap(~Variable, scales = "free_y") + 
  scale_fill_brewer(palette = "Set2") +
  theme_minimal() +
  labs(title = "Perfil Ambiental por Clúster (TPE)",
       subtitle = "Promedios zonales de variables climáticas y de suelo",
       x = "Clúster",
       y = "Valor Promedio") +
  theme(legend.position = "none",
        strip.text = element_text(face = "bold", size = 12))

# --- 6. GRÁFICO 2: ANÁLISIS DE VARIABILIDAD INTERNA (BOXPLOTS) ---

# Extraer una muestra aleatoria de 1,000 píxeles para visualizar la dispersión real
# Útil para ver qué tan "puros" o variables son nuestros clústeres
puntos_muestreados <- spatSample(c(dep_cov, mapa_cluster), 
                                 size = 1000, 
                                 method = "random", 
                                 na.rm = TRUE, 
                                 as.df = TRUE) %>%
  rename(TPE = cluster) %>% # Cambiar nombre para claridad visual
  pivot_longer(cols = -TPE)

ggplot(puntos_muestreados, aes(x = as.factor(TPE), y = value, fill = as.factor(TPE))) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA) + # Ocultar outliers para limpiar visual
  geom_jitter(width = 0.2, alpha = 0.1, size = 0.5) + # Añadir puntos para ver densidad
  facet_wrap(~name, scales = "free_y") +
  scale_fill_viridis_d(option = "mako", name = "TPE") +
  theme_bw() +
  labs(title = "Variabilidad Interna de los Mega-Ambientes (TPE)",
       subtitle = "Análisis de distribución de píxeles por clúster (Muestra n=5000)",
       x = "Clúster", y = "Valor de la Variable")


```