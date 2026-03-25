#####################################################################################
##                   CÁLCULO DE ÍNDICES AGROCLIMÁTICOS (CHIRPS)                    ##
##                                                                                 ##
## Este script crea mapas diarios de precipitación para Honduras usando            ## 
## CHIRPS-V3-ERA5 para el a 2025, y calcula el acumulado de lluvia para el ciclo
## del frijol.                                                                     ##
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
# (Nota: al usar setwd, no es necesario usar getwd() de nuevo)
world_map = st_read("world_shapefile/world_map_projected.shp")
plot(world_map[1], main = "Mapa Global")

## Mostrar la lista de países disponibles en el shapefile
world_map$NAME_0

## Extraer el polígono específico de Honduras
honduras_map = world_map[world_map$NAME_0 == "Honduras", ]

## Graficar el polígono de Honduras para verificar
plot(honduras_map[1], main = "Polígono de Honduras")


# 4. Procesamiento de datos raster (Precipitación CHIRPS) ----

## Listar los archivos globales de precipitación derivados de CHIRPS
rastlist = list.files("Lluvia/2025", pattern = "tif$", full.names = TRUE, recursive = FALSE)

## Cargar todos los archivos de precipitación como un bloque (SpatRaster)
allrasters = terra::rast(rastlist)

## Abrir una nueva ventana de gráficos (solo en Windows) y visualizar la primera capa
windows()
plot(allrasters[[1]], main = "Precipitación Global (Día 1)")

## Recortar (crop) los datos de precipitación a la extensión rectangular de Honduras
precipitacion_Hn = crop(allrasters, honduras_map)
plot(precipitacion_Hn[[1:5]], main = "Recorte rectangular de Honduras (Días 1-5)")

## Eliminar valores negativos (Los datos CHIRPS suelen usar -9999 para celdas sin datos / NoData)
precipitacion_Hn = ifel(precipitacion_Hn < 0, NA, precipitacion_Hn)
plot(precipitacion_Hn[[1:5]], main = "Datos sin valores negativos")

## Aplicar máscara (mask) para mantener los datos exactos dentro de las fronteras del polígono
precipitacion_Hn = mask(precipitacion_Hn, honduras_map)
plot(precipitacion_Hn[[1:5]], main = "Máscara exacta de Honduras (Días 1-5)")


# 5. Análisis Temporal y Cálculo de Acumulados ----

## Verificar las capas cargadas (opcional)
# rastlist

## Filtrar las capas para el periodo mayo-agosto de 2025
# (Asumiendo datos diarios: el día 121 es el 1 de mayo y el 243 es el 31 de agosto)
Prec_may_ago = precipitacion_Hn[[121:243]]
plot(Prec_may_ago[[1:5]], main = "Precipitación Mayo-Agosto (Primeros 5 días)")

## Calcular la precipitación total acumulada para ese periodo
Total_Prec = sum(Prec_may_ago, na.rm = TRUE)

## Visualizar el mapa y el histograma de la precipitación total acumulada
plot(Total_Prec, main = "Precipitación Total Acumulada (May-Ago 2025)")
hist(Total_Prec, main = "Distribución de la Precipitación Total", xlab = "Precipitación (mm)", ylab = "Frecuencia")

## Explorar umbrales específicos de lluvia (áreas con menos de 600mm y más de 1700mm)
plot(Total_Prec < 600, main = "Áreas con precipitación < 600 mm")
plot(Total_Prec > 1700, main = "Áreas con precipitación > 1700 mm")


# 6. Exportar resultados ----

## Guardar el mapa final de la precipitación total acumulada
# (Utilizamos una ruta relativa basada en el directorio de trabajo configurado al inicio)
writeRaster(Total_Prec, 
            "Ejercicios/Output/Precipitacion_may-ago_Hnd.tif", 
            overwrite = TRUE)