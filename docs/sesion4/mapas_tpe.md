# Construcción de Mapas Agroclimáticos y Clasificación de Ambientes (TPE)

Hasta ahora, hemos aprendido a procesar datos climáticos (CHIRPS/AgERA5) y de suelo (SoilGrids) por separado. Sin embargo, en el mundo real, la variabilidad espacial conjunta de las variables de suelo y clima ofrece la oportunidad de delimitar zonas edafoclimáticas contiguas. Estas zonas son fundamentales para mejorar el manejo de los recursos naturales.

## Mapas de Indicadores Agroclimáticos

La pregunta ahora es: ¿Cómo delimitamos matemáticamente estas zonas (TPEs) en R usando nuestros mapas? Como no sabemos a priori dónde están las fronteras exactas de estos agroecosistemas, estamos frente a un problema clásico de **Aprendizaje No Supervisado (Unsupervised Learning)**.

Para ello, usaremos el algoritmo de [**K-Means Clustering**](https://medium.com/@abhaysingh71711/k-means-clustering-a-deep-dive-into-unsupervised-learning-81213f56cfc9)  Le pediremos a R que tome las capas creadad en Honduras y, basándose en la "distancia matemática" entre sus valores, los agrupe de forma automática en ambientes homogéneos.


```r
# ==============================================================================
# TALLER: ZONIFICACIÓN AGROCLIMÁTICA Y POBLACIÓN OBJETIVO DE ENTORNOS (TPE)
# Objetivo: Clasificación no supervisada para definir mega-ambientes en Honduras
# ==============================================================================

# --- 1. CONFIGURACIÓN DEL ENTORNO ---

# Limpiar el espacio de trabajo
rm(list = ls())

# Cargar funciones externas desde GitHub (Pipeline reproducible)
source(
  paste0(
    "https://raw.githubusercontent.com/cbarriosperez/Taller_IndicesAgroclimaticos_Frijol/main/scripts//", 
    "main_session2.R"
  )
)

# Instalación y carga de librerías necesarias
# factoextra: Visualización de algoritmos de clustering
# NbClust: Determinación del número óptimo de clústeres
# sf: Manejo de datos vectoriales
# terra: Motor de procesamiento raster de alto rendimiento
if(!require(factoextra)) install.packages(c("factoextra", "NbClust"))
library(sf)
library(terra)
library(factoextra)
library(tidyverse)

# --- 2. LECTURA Y PREPARACIÓN DE DATOS ---

# Cargar indicadores climáticos (NetCDF)
indicadores = rast(c("data/indicadores/ETo_may-ago_Hnd.tif",
                     "data/indicadores/GDD_may-ago_Hnd.tif",
                     "data/indicadores/Precipitacion_may-ago_Hnd.tif",
                     "data/indicadores/wb_may-ago_Hnd.tif"))
names(indicadores) = c('ETo','GDD', 'Precipitacion', 'wb')
# Cargar variables de suelo (SoilGrids) desde archivos GeoTIFF
# wv1500/wv0033 corresponden a puntos de marchitez y capacidad de campo
suelo = rast(c("data/suelo/clay_hnd.tif",
               "data/suelo/sand_hnd.tif",
               "data/suelo/nitrogen_hnd.tif",
               "data/suelo/ph_hnd.tif",
               "data/suelo/wv1500_hnd.tif",
               "data/suelo/wv0033_hnd.tif"))

# Renombrar capas de suelo para facilitar la interpretación
#unidades = clay -> g/kg;  wv1500 -> (10−2 cm3 cm−3)*10; nitrogen -> cg/kg (soilgrids)
names(suelo) = c('arcilla','arena','nitrogeno','ph', 'pmm','cc')

# --- 3. ALINEACIÓN ESPACIAL (RESAMPLING) ---

# Importante: Las variables climáticas y de suelo tienen resoluciones distintas.
# Se remuestrea los indicadores para que coincida con la rejilla (grid) de suelo.
# Método "near" (vecino más cercano) para preservar valores originales.
plot(indicadores)
plot(suelo)

indicadores_re_nearest = resample(indicadores, suelo[[1]], method = "near")
indicadores_re_bilinear = resample(indicadores, suelo[[1]], method = "bilinear")

plot(c(indicadores_re_nearest$wb,indicadores_re_bilinear$wb))
# Crear el stack edafoclimático unificado (Suelo + Clima)
edafoclimatica = c(suelo, indicadores_re_bilinear)
names(edafoclimatica)
# --- 4. EXTRACCIÓN DEL ÁREA DE INTERÉS (AOI) ---

# Definir departamento de estudio (Olancho como ejemplo)
departamento = 'Olancho'

# Leer límites administrativos de Honduras
hnd_departamentos = st_read('data/admin/geoBoundaries-HND-ADM1.shp')
plot(hnd_departamentos['shapeName'])
# Filtrar el vector por el nombre del departamento
dep_vector = hnd_departamentos[hnd_departamentos$shapeName == departamento,]

# Recortar (crop) y enmascarar (mask) el stack a la silueta de Olancho
dep_cov = cortar_raster_usando_vector(edafoclimatica, dep_vector, mask = T)
plot(dep_cov)
# Guardar usando writeCDF 
dep_cov_sds <- sds(as.list(dep_cov))
names(dep_cov_sds) = names(dep_cov)

terra::writeCDF(dep_cov_sds, 
                filename = "outputs/suelo_indicadores_olancho.nc", 
                overwrite = TRUE)


# --- 5. REDUCCIÓN DE DIMENSIONALIDAD (PCA) ---

set.seed(42)

# Escalar datos: Paso obligatorio para Machine Learning (Media 0, Desviación Estándar 1)
# Evita que variables con unidades grandes (Precipitación) dominen sobre otras (pH)
stack_escalado = terra::scale(dep_cov)

# Análisis de Componentes Principales (PCA)
# Útil para eliminar la correlación entre variables y reducir ruido
pcaterra = terra::prcomp(stack_escalado, rank = 7)
summary(pcaterra) # Ver varianza explicada por cada componente

# Generar mapas de los componentes principales (Transformación espacial)
stack_escalado_pca = terra::predict(stack_escalado, pcaterra)
plot(stack_escalado_pca)

# --- 6. OPTIMIZACIÓN DEL NÚMERO DE CLÚSTERES (K) ---

# Muestreo aleatorio de píxeles para análisis estadístico (optimiza uso de memoria)
set.seed(42)
muestra_pixeles = spatSample(x = stack_escalado_pca, 
                             size = 5000, 
                             method = "random", 
                             na.rm = TRUE, 
                             as.df = TRUE) 

# Método 1: Gráfico del Codo (Elbow) - Busca el punto donde la curva se estabiliza
grafico_codo = fviz_nbclust(x = muestra_pixeles, 
                            FUNcluster = kmeans, 
                            method = "wss", 
                            k.max = 10) +
  labs(title = "Método del Codo (Elbow) para determinar TPEs",
       subtitle = "Buscamos el punto donde la línea se dobla") +
  theme_minimal()
print(grafico_codo)

# Método 2: Coeficiente de Silueta - Busca el valor máximo (separación óptima)
grafico_silueta <- fviz_nbclust(x = muestra_pixeles, 
                                FUNcluster = kmeans, 
                                method = "silhouette", 
                                k.max = 10) +
  labs(title = "Análisis de Silueta para determinar TPEs",
       subtitle = "Buscamos el valor máximo (K óptimo)") +
  theme_minimal()
print(grafico_silueta)

# --- 7. CLASIFICACIÓN NO SUPERVISADA (K-MEANS) ---

# Ejecución de K-means en la muestra para visualización previa
modelo_kmeans_sample = kmeans(x = muestra_pixeles, centers = 4, iter.max = 100)
muestra_pixeles$cluster = as.factor(unname(modelo_kmeans_sample$cluster))

# Gráfico de dispersión en espacio PCA (PC1 vs PC2)
ggplot(muestra_pixeles, aes(PC1, PC2, color= cluster))+
  geom_point()+
  labs(title = 'Agrupamiento K-Means en Espacio PCA')+
  theme_minimal()

# --- 8. MAPEO ESPACIAL DE LOS CLÚSTERES (TPE) ---

# Extraer todos los valores del raster PCA
valores_pixeles = values(stack_escalado_pca)
indices_validos = which(complete.cases(valores_pixeles)) # Omitir píxeles con NAs
datos_limpios = valores_pixeles[indices_validos, ]

# Ejecutar K-means en la población completa de píxeles
modelo_kmeans_full = kmeans(x = datos_limpios, centers = 4, iter.max = 100)

# Reconstruir el mapa de clústeres
mapa_cluster = stack_escalado_pca[[1]] # Usar una capa como plantilla
values(mapa_cluster) = NA
names(mapa_cluster) = 'cluster'
mapa_cluster[indices_validos] = modelo_kmeans_full$cluster

# Visualización del mapa final de TPEs
plot(mapa_cluster, main = "Zonificación Agroclimática Final (4 Clústeres)")

# Exportar resultado
dir.create('outputs', showWarnings = F)
writeRaster(mapa_cluster, 'outputs/cluster_4_olancho.tif', overwrite = TRUE)


```
