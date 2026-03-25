#####################################################################################
##                   CÁLCULO DE ÍNDICES AGROCLIMÁTICOS TÉRMICOS                    ##
##                                                                                 ##
## Este script crea mapas diarios de Tmax y Tmin para Honduras usando AgERA5 y     ## 
## genera índices agroclimáticos térmicos (Grados Día) para el cultivo de frijol   ##
## durante el periodo 1981-2025.                                                   ##
##                                                                                 ##
## Creado por: Camilo Barrios-Perez (Ph.D) - c.barrios@cgiar.org                   ##
#####################################################################################

# 1. Cargar librerías ----
library(terra) # Para manejo de rásteres y análisis espacial
library(sp)    # Para trabajar con objetos espaciales heredados
library(sf)    # Para leer y manipular datos vectoriales (shapefiles)

# 2. Configurar el directorio de trabajo ----
setwd("D:/OneDrive - CGIAR/Otras Colaboraciones/Proyecto_Parcela Digital_Zamorano/2025/workshops/Indices Agroclimáticos/Sesion 3")


# 3. Procesamiento de datos vectoriales (Shapefile) ----

## Importar el mapa global 
world_map = st_read("world_shapefile/world_map_projected.shp")

## Extraer el polígono específico de Honduras
honduras_map = world_map[world_map$NAME_0 == "Honduras", ]
plot(honduras_map[1], main = "Polígono de Honduras")

## Exportar el mapa de Honduras en formato shapefile
st_write(honduras_map, 
         "Ejercicios/Output/honduras_map.shp", 
         driver = "ESRI Shapefile",
         overwrite = TRUE)


# 4. Procesamiento de Temperatura Máxima (Tmax) ----

## Listar los mapas globales de Tmax derivados de AgERA5
rastlist_tmax = list.files("Tmax/2025", full.names = TRUE, recursive = FALSE)

## Cargar todos los archivos de Tmax como un bloque (SpatRaster)
allrasters_tmax = terra::rast(rastlist_tmax)
windows()
plot(allrasters_tmax[[1:3]], main = "Tmax Global (Kelvin)")

## Recortar (crop) y enmascarar (mask) los mapas de Tmax para Honduras
Tmax = crop(allrasters_tmax, honduras_map)
Tmax = mask(Tmax, honduras_map)

windows()
plot(Tmax[[1:3]], main = "Tmax Honduras (Kelvin)")

## Convertir mapas de Tmax de Kelvin a Grados Celsius (°C)
T_max_C = (Tmax - 273.15)


# 5. Procesamiento de Temperatura Mínima (Tmin) ----

## Listar los mapas globales de Tmin derivados de AgERA5
rastlist_tmin = list.files("Tmin/2025", full.names = TRUE, recursive = FALSE)

## Cargar todos los archivos de Tmin como un bloque (SpatRaster)
allrasters_tmin = terra::rast(rastlist_tmin)
windows()
plot(allrasters_tmin[[1:3]], main = "Tmin Global (Kelvin)")

## Recortar (crop) y enmascarar (mask) los mapas de Tmin para Honduras
Tmin = crop(allrasters_tmin, honduras_map)
Tmin = mask(Tmin, honduras_map)

windows()
plot(Tmin[[1:3]], main = "Tmin Honduras (Kelvin)")

## Convertir mapas de Tmin de Kelvin a Grados Celsius (°C)
T_min_C = (Tmin - 273.15)
plot(T_min_C[[1:3]], main = "Tmin Honduras (°C)")


# 6. Remuestreo Espacial (Resampling) a 5km ----

## Cargar el mapa de referencia (Precipitación a 5km) para igualar la resolución espacial
reference_5km = terra::rast("Ejercicios/Output/Precipitacion_may-ago_Hnd.tif")

## Remuestrear los mapas de Tmax y Tmin a 5km usando interpolación bilineal
Tmax_5km = resample(T_max_C, reference_5km, method = 'bilinear')
Tmin_5km = resample(T_min_C, reference_5km, method = 'bilinear')

## Verificar si la resolución ahora es idéntica (Debe retornar TRUE)
print("¿Las resoluciones coinciden?")
res(Tmax_5km) == res(reference_5km)

windows()
plot(Tmax_5km[[1:3]], main = "Tmax Remuestreada a 5km (°C)")


# 7. Cálculo del Índice Térmico: Grados Día Acumulados (GDA) ----

## Parámetros del cultivo de frijol
Tb = 10   # Temperatura base del frijol (°C)

## Filtrar Tmax y Tmin para el ciclo de cultivo (Mayo a Agosto: días julianos 121 a 243)
Tmax_5km_may_ago = Tmax_5km[[121:243]]
Tmin_5km_may_ago = Tmin_5km[[121:243]]

## Calcular la temperatura media diaria durante el periodo Mayo - Agosto
Tmean_5km_may_ago = (Tmax_5km_may_ago + Tmin_5km_may_ago) / 2

## Calcular los Grados Día diarios (Temperatura media - Temperatura base)
gdd_diario = Tmean_5km_may_ago - Tb

## Reemplazar valores negativos por 0 (Los días con temperatura < Tb no acumulan unidades térmicas)
gdd_diario = ifel(gdd_diario < 0, 0, gdd_diario)

## Calcular los Grados Día Acumulados (GDA) totales durante el ciclo de cultivo
gdd_total_ciclo = sum(gdd_diario, na.rm = TRUE)

windows()
plot(gdd_total_ciclo, main = "Grados Día Acumulados (May-Ago)")


# 8. Visualización de Áreas Óptimas y Exportación ----

## Graficar áreas con GDA aptos para el cultivo (entre 1000 y 1500 grados día)
# 1 = Cumple la condición (Verde), 0 = No la cumple (Gris)
areas_aptas = (gdd_total_ciclo >= 1000) & (gdd_total_ciclo <= 1500)

windows()
plot(areas_aptas, main = "Áreas con GDA entre 1000 y 1500 (1=Apto, 0=No apto)")

## Guardar el mapa final de los Grados Día Acumulados
writeRaster(gdd_total_ciclo, 
            "Ejercicios/Output/GDD_may-ago_Hnd.tif", 
            overwrite = TRUE)