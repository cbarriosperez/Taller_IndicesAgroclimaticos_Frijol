# Sesión 3: Cálculo de Indicadores Agroclimáticos para el Cultivo de Frijol

**Fecha:** Miércoles 18 de marzo · 9:00 – 11:00 am (hora Honduras)  
**Duración:** 2 horas

---

## Material de la Sesión

Todos los archivos de datos, scripts y recursos necesarios para esta sesión están disponibles en Google Drive:

<div style="text-align: center; margin: 24px 0;">
  <a href="https://drive.google.com/drive/folders/1smV5y2yYjVXtYq1HwWYaYO5YzdwIndoy?usp=drive_link"
     target="_blank"
     style="display: inline-flex; align-items: center; gap: 10px;
            background: #1a73e8; color: white; font-weight: 600;
            padding: 14px 28px; border-radius: 8px; text-decoration: none;
            font-size: 1rem; box-shadow: 0 2px 8px rgba(0,0,0,0.18);">
    📁 Acceder al material en Google Drive
  </a>
</div>

---

## 1. Precipitación Total Acumulada — CHIRPS-v3

En esta primera parte, utilizaremos los datos de **CHIRPS-v3** para calcular la precipitación total acumulada durante el periodo crítico del cultivo (mayo a agosto de 2025) en Honduras. CHIRPS combina datos satelitales con observaciones de estaciones para ofrecer una estimación precisa de la lluvia a alta resolución (approx. 5km).

A continuación, se presenta el script para realizar este procesamiento:

```r
#####################################################################################
##                   CÁLCULO DE ÍNDICES AGROCLIMÁTICOS (CHIRPS)                    ##
##                                                                                 ##
## Este script crea mapas diarios de precipitación para Honduras usando            ## 
## CHIRPS-V3-ERA5 para el periodo 1981-2025.                                       ##
##                                                                                 ##
## Creado por: Camilo Barrios-Perez (Ph.D) - c.barrios@cgiar.org                   ##
#####################################################################################

# 1. Cargar librerías ----
library(terra) # Para manejo de rásteres y análisis espacial
library(sp)    # Para trabajar con objetos espaciales heredados
library(sf)    # Para leer y manipular datos vectoriales (shapefiles)

# 2. Configurar el directorio de trabajo ----
# Asegúrate de que esta ruta exista en tu computadora
setwd("D:/OneDrive - CGIAR/Otras Colaboraciones/Proyecto_Parcela Digital_Zamorano/2025/workshops/Indices Agroclimáticos/Sesion 3")

# 3. Procesamiento de datos vectoriales (Shapefile) ----

## Cargar shapefile global 
world_map = st_read("world_shapefile/world_map_projected.shp")

## Extraer el polígono específico de Honduras
honduras_map = world_map[world_map$NAME_0 == "Honduras", ]

# 4. Procesamiento de datos raster (Precipitación CHIRPS) ----

## Listar los archivos globales de precipitación derivados de CHIRPS
rastlist = list.files("Lluvia/2025", pattern = "tif$", full.names = TRUE, recursive = FALSE)

## Cargar todos los archivos de precipitación como un bloque (SpatRaster)
allrasters = terra::rast(rastlist)

## Recortar (crop) y enmascarar (mask) los datos para Honduras
precipitacion_Hn = crop(allrasters, honduras_map)
precipitacion_Hn = ifel(precipitacion_Hn < 0, NA, precipitacion_Hn)
precipitacion_Hn = mask(precipitacion_Hn, honduras_map)

# 5. Análisis Temporal y Cálculo de Acumulados ----

## Filtrar las capas para el periodo mayo-agosto de 2025
# (Día 121: 1 de mayo al Día 243: 31 de agosto)
Prec_may_ago = precipitacion_Hn[[121:243]]

## Calcular la precipitación total acumulada
Total_Prec = sum(Prec_may_ago, na.rm = TRUE)

# 6. Exportar resultados ----
writeRaster(Total_Prec, 
            "Ejercicios/Output/Precipitacion_may-ago_Hnd.tif", 
            overwrite = TRUE)
```

---

## 2. Evapotranspiración de Referencia (ET₀) — AgERA5

Posteriormente, obtendremos la **ET₀ total** para Honduras para el mismo periodo (Mayo-Agosto 2025) utilizando datos de **AgERA5**. Para asegurar la consistencia con los datos de precipitación, llevaremos la resolución de estos datos a **5km**.

```r
#####################################################################################
##                   CÁLCULO DE ÍNDICES AGROCLIMÁTICOS HÍDRICOS                    ##
##                                                                                 ##
## Este script crea mapas diarios de ETo para Honduras usando AgERA5 y             ## 
## genera índices agroclimáticos térmicos (Grados Día) para el cultivo de frijol   ##
## durante el año 2025.                                                            ##
##                                                                                 ##
## Creado por: Camilo Barrios-Perez (Ph.D) - c.barrios@cgiar.org                   ##
#####################################################################################

# 1. Cargar librerías ----
library(terra)
library(sf)

# 2. Configurar el directorio de trabajo ----
setwd("D:/OneDrive - CGIAR/Otras Colaboraciones/Proyecto_Parcela Digital_Zamorano/2025/workshops/Indices Agroclimáticos/Sesion 3")

# 3. Procesamiento de datos vectoriales (Honduras) ----
world_map = st_read("world_shapefile/world_map_projected.shp")
honduras_map = world_map[world_map$NAME_0 == "Honduras", ]

# 4. Procesamiento de ETo ----
rastlist_eto = list.files("ETo/2025", full.names = TRUE, recursive = FALSE)
allrasters_eto = terra::rast(rastlist_eto)

## Recortar y enmascarar para Honduras
ETo = crop(allrasters_eto, honduras_map)
ETo = mask(ETo, honduras_map)

# 5. Remuestreo Espacial (Resampling) a 5km ----
# Usamos el mapa de precipitación previo como referencia
reference_5km = terra::rast("Ejercicios/Output/Precipitacion_may-ago_Hnd.tif")
ETo_5km = resample(ETo, reference_5km, method = 'bilinear')

# 6. Análisis Temporal y Cálculo de Acumulados ----
ETo_may_ago = ETo_5km[[121:243]]
Total_ETo = sum(ETo_may_ago, na.rm = TRUE)

# 7. Exportar resultados ----
writeRaster(Total_ETo, 
            "Ejercicios/Output/ETo_may-ago_Hnd.tif", 
            overwrite = TRUE)
```

---

## 3. Balance Hídrico Climático

Una vez obtenidos los acumulados de precipitación y ETo, calcularemos el **Balance Hídrico Climático** para identificar las zonas con déficit de agua durante el ciclo de cultivo.

```r
################################################################################
#                   CÁLCULO DE ÍNDICES AGROCLIMÁTICOS HÍDRICOS                 #
#------------------------------------------------------------------------------#
# Propósito: Calcular el Balance Hídrico Climático (WB = P - ETo)              #
#            para Honduras (Mayo - Agosto 2025).                               #
#                                                                              #
# Autor:     Camilo Barrios-Perez (Ph.D) - c.barrios@cgiar.org                 #
################################################################################

library(terra)

setwd("D:/OneDrive - CGIAR/Otras Colaboraciones/Proyecto_Parcela Digital_Zamorano/2025/workshops/Indices Agroclimáticos/Sesion 3")

# 1. Importar insumos ----
precipitacion = terra::rast("Ejercicios/Output/Precipitacion_may-ago_Hnd.tif")
ETo = terra::rast("Ejercicios/Output/ETo_may-ago_Hnd.tif")

# 2. Cálculo del Balance Hídrico ----
# Valores negativos indican déficit; positivos indican exceso.
wb = precipitacion - ETo

# 3. Visualización y Exportación ----
plot(wb, main = "Balance Hídrico Climático (mm) - Mayo-Agosto 2025")
plot(wb < 0, main = "Áreas con Déficit Hídrico (WB < 0)")

writeRaster(wb, 
            filename = "Ejercicios/Output/wb_may-ago_Hnd.tif", 
            overwrite = TRUE)
```

---

## 4. Indicadores Térmicos: Grados Día Acumulados (GDA)

Finalmente, calcularemos los **Grados Día Acumulados (GDA)** o Unidades Térmicas para el cultivo de frijol, utilizando datos de temperatura de AgERA5. Estos indicadores nos permiten estimar el desarrollo fenológico del cultivo y la aptitud térmica de las zonas de estudio.

```r
#####################################################################################
##                   CÁLCULO DE ÍNDICES AGROCLIMÁTICOS TÉRMICOS                    ##
##                                                                                 ##
## Este script genera mapas de Grados Día (GDD) para el cultivo de frijol          ##
## durante el periodo mayo-agosto 2025.                                            ##
##                                                                                 ##
## Creado por: Camilo Barrios-Perez (Ph.D) - c.barrios@cgiar.org                   ##
#####################################################################################

library(terra)
library(sf)

setwd("D:/OneDrive - CGIAR/Otras Colaboraciones/Proyecto_Parcela Digital_Zamorano/2025/workshops/Indices Agroclimáticos/Sesion 3")

# 1. Cargar límites y referencia ----
world_map = st_read("world_shapefile/world_map_projected.shp")
honduras_map = world_map[world_map$NAME_0 == "Honduras", ]
reference_5km = terra::rast("Ejercicios/Output/Precipitacion_may-ago_Hnd.tif")

# 2. Procesamiento de Temperaturas (AgERA5) ----
# Tmax
rastlist_tmax = list.files("Tmax/2025", full.names = TRUE, recursive = FALSE)
T_max_C = (mask(crop(terra::rast(rastlist_tmax), honduras_map), honduras_map) - 273.15)

# Tmin
rastlist_tmin = list.files("Tmin/2025", full.names = TRUE, recursive = FALSE)
T_min_C = (mask(crop(terra::rast(rastlist_tmin), honduras_map), honduras_map) - 273.15)

# 3. Remuestreo a 5km ----
Tmax_5km = resample(T_max_C, reference_5km, method = 'bilinear')
Tmin_5km = resample(T_min_C, reference_5km, method = 'bilinear')

# 4. Cálculo de GDA ----
Tb = 10   # Temperatura base del frijol (°C)
ciclo_idx = 121:243 # Mayo a Agosto

Tmean_ciclo = (Tmax_5km[[ciclo_idx]] + Tmin_5km[[ciclo_idx]]) / 2
gdd_diario = ifel(Tmean_ciclo - Tb < 0, 0, Tmean_ciclo - Tb)
gdd_total = sum(gdd_diario, na.rm = TRUE)

# 5. Exportar resultados ----
writeRaster(gdd_total, 
            "Ejercicios/Output/GDD_may-ago_Hnd.tif", 
            overwrite = TRUE)
```
