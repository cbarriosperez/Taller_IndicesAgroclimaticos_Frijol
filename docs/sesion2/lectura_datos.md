# Análisis Espacial de Datos Climáticos y Edáficos en R

El estudio de las dinámicas ambientales, agroclimáticas y ecosistémicas requiere la integración de múltiples fuentes de información espacial. Variables como la precipitación, la temperatura y las propiedades fisicoquímicas del suelo no se distribuyen de manera uniforme en el territorio; presentan gradientes espaciales continuos y variaciones temporales complejas.

Este documento técnico constituye una guía profunda para profesionales e investigadores que buscan dominar el flujo de trabajo completo del análisis espacial en R, integrando bases de datos de vanguardia mundial: CHIRPS (clima), AgERA5 (clima agrícola) y SoilGrids (edafología).

## 1. Introducción a los Datos Espaciales Digitales

Los datos geoespaciales constituyen la representación digital de la cartografía del mundo real. Su función principal es vincular variables continuas o discretas (como la precipitación, la temperatura o el tipo de suelo) con una ubicación geométrica exacta en la superficie terrestre, permitiendo modelar dinámicas ambientales complejas.

### Sistemas de Referencia de Coordenadas (CRS)

El CRS (Coordinate Reference System) es la combinación de un Datum y, si aplica, una proyección cartográfica. Para facilitar la interoperabilidad entre software GIS, los CRS se estandarizan mediante códigos numéricos conocidos como EPSG.

Para que esta ubicación espacial sea matemáticamente precisa y los datos provenientes de distintas fuentes puedan superponerse sin errores de alineación, los Sistemas de Información Geográfica (SIG) dependen de los **Sistemas de Referencia de Coordenadas (CRS)**. Un CRS define cómo se interpreta la geometría terrestre combinando un modelo tridimensional de la Tierra (Datum) y, cuando es necesario realizar cálculos de área o distancia, un método de proyección cartográfica a un plano 2D ([QGIS Documentation, 2024](https://docs.qgis.org/latest/es/docs/gentle_gis_introduction/coordinate_reference_systems.html)).

Para garantizar la interoperabilidad y evitar ambigüedades entre lenguajes de programación y software GIS, los CRS se estandarizan a nivel global mediante códigos numéricos conocidos como **EPSG**, un registro oficial mantenido actualmente por la[IOGP (Asociación Internacional de Productores de Petróleo y Gas)](https://epsg.org/).

En el flujo de trabajo de análisis espacial, frecuentemente transitamos entre dos de los códigos más utilizados:

*   **[EPSG:4326 (WGS 84)](https://epsg.io/4326):** Coordenadas geográficas estándar (WGS84). Usado comúnmente para almacenar y compartir datos globales. Es un sistema de coordenadas geográficas (no proyectadas) que utiliza latitud y longitud. Es el estándar global empleado por la red GPS y el formato por defecto en el que se distribuyen las bases de datos climáticas mundiales como CHIRPS o AgERA5.
*   **[EPSG:32616 (UTM Zona 16 Norte)](https://epsg.io/32616):** Coordenadas proyectadas UTM Zona 16 Norte (usado ampliamente en Centroamérica, cubriendo la mayor parte de Honduras). Es un sistema de coordenadas proyectadas basado en la proyección Transversal de Mercator. Al expresar las coordenadas en metros, minimiza la distorsión geométrica a nivel local, siendo indispensable para realizar mediciones precisas de áreas y distancias en proyectos geoespaciales dentro del territorio hondureño.

## 2. Tipos de datos Geoespaciales

Los Sistemas de Información Geográfica (SIG) utilizan dos arquitecturas principales para almacenar datos espaciales:

| Característica | Modelo Vectorial | Modelo Raster |
| :--- | :--- | :--- |
| **Definición** | Representación discreta mediante geometrías (puntos, líneas, polígonos). | Representación continua mediante una matriz de celdas (píxeles). |
| **Casos de uso** | Estaciones meteorológicas, límites departamentales, cuencas, ríos. | Precipitación (CHIRPS), Temperatura (AgERA5), Carbono Orgánico (SoilGrids). |
| **Ventajas** | Precisión geométrica, menor peso de archivo, excelente para topología. | Ideal para gradientes continuos, álgebra de mapas, operaciones matemáticas rápidas. |

## 3. Sistemas de información geográfica (SIG)

El almacenamiento y análisis de datos espaciales se realiza tradicionalmente en los Sistemas de Información Geográfica (SIG). Según la definición basada en herramientas de Burrough y McDonnell (1998, p. 11), un SIG es «…un potente conjunto de herramientas para recopilar, almacenar, recuperar a voluntad, transformar y visualizar datos espaciales del mundo real para un conjunto particular de propósitos».

Existen diversas plataformas de software SIG, tanto comerciales como de código abierto, que facilitan estas tareas mediante interfaces gráficas de usuario (GUI). Algunas de las más destacadas a nivel mundial incluyen:

*   **[QGIS](https://qgis.org/):** El software SIG de código abierto y multiplataforma más utilizado del mundo. Respaldado por la fundación OSGeo, cuenta con una inmensa comunidad que expande sus capacidades constantemente mediante complementos (plugins).
*   **[ArcGIS](https://www.esri.com/es-es/arcgis/about-arcgis/overview):** Desarrollado por la empresa Esri, es la plataforma comercial y corporativa líder en la industria geoespacial, ofreciendo un ecosistema robusto de aplicaciones de escritorio (ArcGIS Pro) y servicios en la nube (ArcGIS Online).
*   **[GRASS GIS](https://grass.osgeo.org/):** Un sistema de información geográfica fundacional, gratuito y de código abierto. Es excepcionalmente potente para el análisis de redes, modelado ambiental y procesamiento complejo de datos raster y vectoriales.
*   **[Google Earth Engine (GEE)](https://earthengine.google.com/):** Una plataforma en la nube diseñada específicamente para el análisis geoespacial a escala planetaria. Permite procesar petabytes de imágenes satelitales e información climática sin depender del hardware local.

### R y Python en el Análisis Espacial

Más allá del software tradicional de escritorio, la evolución contemporánea del análisis de datos espaciales ha migrado fuertemente hacia entornos de programación científica. Lenguajes de código abierto como **[R](https://www.r-project.org/)** y **[Python](https://www.python.org/)** han democratizado y revolucionado la disciplina.

Estos lenguajes han permitido a la comunidad científica desarrollar **librerías especializadas** que superan las limitaciones de la interfaz de usuario manual, introduciendo ventajas críticas como la automatización masiva, el procesamiento *Out-of-Core* (archivos más grandes que la memoria RAM) y, sobre todo, la **reproducibilidad científica**.

*   **El ecosistema espacial en [R](https://www.r-project.org/):** Se ha consolidado como el estándar para el cruce de datos espaciales con modelado estadístico rigoroso. Paquetes modernos como **[`sf` (Simple Features)](https://r-spatial.github.io/sf/)** para datos vectoriales y **[`terra`](https://rspatial.org/)** para álgebra de mapas raster, permiten analizar la geografía con la misma fluidez con la que se manipulan tablas de datos tradicionales.
*   **El ecosistema espacial en [Python](https://www.python.org/):** Ha ganado un terreno inmenso gracias a su sinergia con la Inteligencia Artificial y el Machine Learning. Herramientas como **[`GeoPandas`](https://geopandas.org/)** (manipulación vectorial) y **[`Rasterio`](https://rasterio.readthedocs.io/)** (lectura y escritura eficiente de imágenes satelitales) son la columna vertebral de los flujos de trabajo en ciencia de datos moderna.

## 4. Análisis de datos espaciales en R

### Datos Vectoriales con sf

El procesamiento vectorial implica manipular geometrías y sus atributos tabulares. Las operaciones espaciales a menudo requieren que las capas interactúen para definir nuevas áreas de estudio o resolver superposiciones.

#### Operaciones Topológicas Fundamentales

Las operaciones espaciales entre geometrías generan nuevas formas basadas en la lógica de conjuntos:

- **Unión espacial (`st_union`)**: Fusiona múltiples polígonos en uno solo, disolviendo los límites internos.
- **Intersección (`st_intersection`)**: Retiene únicamente las porciones de espacio que son comunes a ambas capas.
- **Diferencia (`st_difference`)**: Extrae la porción de un polígono que no se superpone con otro (resta espacial).

A continuación, implementaremos estas operaciones conceptuales en R.

```r


# 1. CREACIÓN Y LECTURA DE DATOS VECTORIALES

## Trabajar con geometrías de polígonos

# Leer el shapefile de los departamentos de Honduras
hnd_departamentos = st_read("datos_espaciales/geoBoundaries-HND-ADM1.shp")

hnd_departamentos

# Graficar el mapa mostrando los nombres de los departamentos
plot(hnd_departamentos['shapeName'])


## Interacción entre puntos y polígonos

# Realizar una intersección espacial: asignar la información del departamento a cada punto
puntos_con_depto = st_intersection(puntos_sf, hnd_departamentos)

# Guardar los puntos con la información del departamento en un GeoPackage
st_write(puntos_con_depto, dsn = 'salidas/multiple_coordenadas_ejemplo_wgs84.gpkg', delete_layer = TRUE)

# Cargar librería para visualización avanzada
library(ggplot2)

# Crear un mapa estético de Honduras con los puntos superpuestos
ggplot() +
  geom_sf(data = hnd_departamentos, fill = "white", color = "gray50") + # Capa base: departamentos
  geom_sf(data = puntos_con_depto, aes(color = shapeName), size = 3) + # Capa superior: puntos extraídos
  theme_minimal() + # Estilo limpio
  labs(title = "Puntos extraídos por Departamento", # Título
       color = "Departamento") # Leyenda


## Operaciones con polígonos

# Unir todos los polígonos de los departamentos en un solo polígono del país (disolver límites)
pais = st_union(hnd_departamentos)

# Exportar el nuevo polígono nacional como shapefile
pais%>%
  st_write('salidas/hnd.shp')
# Graficar el límite nacional resultante
plot(pais)

```



### Datos Raster con terra

El manejo de raster implica tratar con matrices espaciales. En los datos climáticos y edáficos, es común trabajar con conjuntos de múltiples capas.

#### Conceptos Clave de Operaciones Raster

- **Stack / Multilayer (`c()`)**: Apilar rasters que comparten la misma extensión y resolución. Es la base de las series temporales (ej. 12 capas para los meses del año).
- **Álgebra de mapas**: Realizar operaciones matemáticas píxel a píxel. Por ejemplo, multiplicar un raster de lluvia por 0.1 para cambiar unidades, o promediar todas las capas para obtener la climatología histórica.
- **Recorte (`crop`)**: Reducir la extensión rectangular (Bounding Box) de un raster gigante a un área de interés pequeña para ahorrar memoria.
- **Reproyección (`project`)**: Cambiar el CRS de un raster. 

!!! warning "Precaución con la reproyección"
    La reproyección de un raster implica remuestrear los píxeles (crear nuevos valores basados en vecinos). En datos continuos (como la temperatura) se usa interpolación bilineal, mientras que en datos categóricos (tipo de suelo) se usa el vecino más cercano.

```r
# 2. CREACIÓN DE RASTER
# Generar simulaciones de precipitación (distribución gamma) para 100 valores
prec_sim1 = rgamma(100, 2, scale = 3)
prec_sim2 = rgamma(100, 2, scale = 1)

# Convertir los valores simulados en matrices de 10x10
prec_sim1_matrix = matrix(prec_sim1, nrow = 10, ncol = 10)
prec_sim2_matrix = matrix(prec_sim2, nrow = 10, ncol = 10)

## Crear objetos raster
library(terra) # Cargar el paquete terra para manejo de datos raster

# Crear el primer raster a partir de la matriz 1
rast_prec1 = rast(prec_sim1_matrix)
plot(rast_prec1) # Visualizar

# Crear el segundo raster a partir de la matriz 2
rast_prec2 = rast(prec_sim2_matrix)
plot(rast_prec2) # Visualizar

## Asignación de extensión espacial y coordenadas

# Definir la resolución espacial en metros (ej. 1 km = 1000m)
resolucion_espacial = 1000
resolucion_espacial_x = 1000*10 # Tamaño total en X (10 celdas)
resolucion_espacial_y = 1000*10 # Tamaño total en Y (10 celdas)

## Propiedades espaciales

# Definir la extensión (Bounding Box) usando formato c(xmin, xmax, ymin, ymax)
# Origen hipotético: X=490000, Y=1546000

# Asignar la extensión calculada a los rasters
ext(rast_prec1) = c(490000, 490000+resolucion_espacial_x, 1546000, 1546000 +resolucion_espacial_y)
ext(rast_prec2) = c(490000, 490000+resolucion_espacial_x, 1546000, 1546000 +resolucion_espacial_y)

# Asignar el sistema de coordenadas (CRS EPSG:32616, correspondiente a UTM Zona 16N)
crs(rast_prec1) = "EPSG:32616"
crs(rast_prec2) = "EPSG:32616"

# Asignar atributos de tiempo a cada raster
time(rast_prec1) <- as.Date("2026-04-01")
time(rast_prec2) <- as.Date("2026-01-01")


# Apilar (juntar) los rasters en un solo objeto con múltiples capas
rast_unidos = c(rast_prec1, rast_prec2)
rast_unidos # Inspeccionar el objeto apilado

# Renombrar las capas del raster
names(rast_unidos) = c('prec_abril', 'prec_enero')

# Visualizar el stack completo
plot(rast_unidos)

# Operaciones matemáticas (Álgebra de mapas)
# Calcular el promedio entre las capas
rast_unidos[['promedio']] = mean(rast_unidos)
# Calcular el valor acumulado (suma) de las capas
rast_unidos[['acumulado']] = sum(rast_unidos)

# Visualizar los resultados incluyendo las nuevas capas calculadas
plot(rast_unidos)

# Guardar el raster resultante en el disco (en formato .tif)
terra::writeRaster(rast_unidos, 'salidas/raster_ejemplo.tif')

```

### Manejo de datos combinando raster y vector

En un flujo de trabajo típico, tenemos una variable continua global (raster) y necesitamos extraer métricas específicas para nuestras unidades administrativas o parcelas experimentales (vectores).

1. **Crop (Recorte Rectangular)**: Se usa la extensión (Bounding Box) del polígono para recortar la matriz raster. Esto elimina datos innecesarios a nivel global/nacional y acelera los procesos subsecuentes.
2. **Mask (Enmascaramiento)**: El crop mantiene un rectángulo, pero los polígonos suelen ser irregulares (ej. un departamento). El mask convierte en `NA` (valores nulos) todos los píxeles que caen fuera de la geometría estricta del polígono.
3. **Extracción Zonal (`extract`)**: Resume los píxeles que caen dentro del polígono utilizando una función estadística (media, mediana, suma). El resultado es un formato tabular listo para el análisis estadístico o visual.

```r

rast_unidos = rast('outputs/raster_ejemplo.tif')
puntos_con_depto = st_read('outputs/coordenadas_ejemplo_wgs84.shp')

terra::extract(rast_unidos, puntos_con_depto) ## warning

puntos_con_depto_planar = st_transform(puntos_con_depto, crs(rast_unidos))

terra::extract(rast_unidos, puntos_con_depto_planar) 

```