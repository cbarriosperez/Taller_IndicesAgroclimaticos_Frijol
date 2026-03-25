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


# 4. Procesamiento de ETo ----

## Listar los mapas globales de ETo derivados de AgERA5
rastlist_eto = list.files("ETo/2025", full.names = TRUE, recursive = FALSE)

## Cargar todos los archivos de ETo como un bloque (SpatRaster)
allrasters_eto = terra::rast(rastlist_eto)
windows()
plot(allrasters_eto[[1:3]], main = "ETo Global (mm)")

## Recortar (crop) y enmascarar (mask) los mapas de ETo para Honduras
ETo = crop(allrasters_eto, honduras_map)
ETo = mask(ETo, honduras_map)

windows()
plot(ETo[[1:3]], main = "ETo Honduras (mm)")

# 5. Remuestreo Espacial (Resampling) a 5km ----

## Cargar el mapa de referencia (Precipitación a 5km) para igualar la resolución espacial
reference_5km = terra::rast("Ejercicios/Output/Precipitacion_may-ago_Hnd.tif")

## Remuestrear los mapas de ETo a 5km usando interpolación bilineal
ETo_5km = resample(ETo, reference_5km, method = 'bilinear')

## Verificar si la resolución ahora es idéntica (Debe retornar TRUE)
print("¿Las resoluciones coinciden?")
res(ETo_5km) == res(reference_5km)

windows()
plot(ETo_5km[[1:3]], main = "ETo Remuestreada a 5km (mm)")

# 6. Análisis Temporal y Cálculo de Acumulados ----

## Verificar las capas cargadas (opcional)
# rastlist

## Filtrar las capas para el periodo mayo-agosto de 2025
# (Asumiendo datos diarios: el día 121 es el 1 de mayo y el 243 es el 31 de agosto)
ETo_may_ago = ETo_5km[[121:243]]
plot(ETo_may_ago[[1:5]], main = "ETo Mayo-Agosto (Primeros 5 días)")

## Calcular la ETo total acumulada para ese periodo
Total_ETo = sum(ETo_may_ago, na.rm = TRUE)

## Visualizar el mapa y el histograma de la precipitación total acumulada
plot(Total_ETo, main = "ETo Total Acumulada (May-Ago 2025)")
hist(Total_ETo, main = "Distribución de la ETo Total", xlab = "ETo (mm)", ylab = "Frecuencia")

## Explorar umbrales específicos de lluvia (áreas con menos de 550mm y más de 650mm)
plot(Total_ETo < 550, main = "Áreas con ETo < 550 mm")
plot(Total_ETo > 650, main = "Áreas con ETo > 650 mm")


# 6. Exportar resultados ----

## Guardar el mapa final de la ETo total acumulada
# (Utilizamos una ruta relativa basada en el directorio de trabajo configurado al inicio)
writeRaster(Total_ETo, 
            "Ejercicios/Output/ETo_may-ago_Hnd.tif", 
            overwrite = TRUE)