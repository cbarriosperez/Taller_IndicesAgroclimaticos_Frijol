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
# Cargar librerías
library(sf)
library(ggplot2)

# 1. CREACIÓN Y LECTURA DE DATOS VECTORIALES
# (En un caso real se usaría st_read("ruta/al/archivo.shp"))
# Simularemos dos polígonos de áreas de estudio que se solapan parcialmente
poly1 <- st_polygon(list(matrix(c(0,0, 2,0, 2,2, 0,2, 0,0), ncol=2, byrow=TRUE)))
poly2 <- st_polygon(list(matrix(c(1,1, 3,1, 3,3, 1,3, 1,1), ncol=2, byrow=TRUE)))

# Convertimos las geometrías en Simple Features (sf) asignándoles el CRS WGS84 (4326)
cuenca_A <- st_sf(nombre = "Cuenca A", geometry = st_sfc(poly1, crs = 4326))
cuenca_B <- st_sf(nombre = "Cuenca B", geometry = st_sfc(poly2, crs = 4326))

# 2. TRANSFORMACIÓN DE CRS (Reproyección)
# Transformamos a un sistema proyectado (ej. UTM Zona 18N - EPSG 32618)
# Fundamental antes de calcular áreas o distancias métricas
cuenca_A_utm <- st_transform(cuenca_A, crs = 32618)

# 3. OPERACIONES ESPACIALES
# Intersección: Área donde ambas cuencas se solapan
interseccion <- st_intersection(cuenca_A, cuenca_B)

# Unión: El área total combinada de ambas cuencas
union_espacial <- st_union(cuenca_A, cuenca_B)

# Diferencia: Área exclusiva de la Cuenca A (que no pertenece a la B)
diferencia <- st_difference(cuenca_A, cuenca_B)

# Visualización rápida de la intersección usando ggplot2
ggplot() +
  geom_sf(data = cuenca_A, fill = "blue", alpha = 0.3) +
  geom_sf(data = cuenca_B, fill = "red", alpha = 0.3) +
  geom_sf(data = interseccion, fill = "purple", size = 1.2) +
  labs(title = "Intersección Espacial de Polígonos con sf",
       subtitle = "La zona púrpura representa el área compartida") +
  theme_minimal()
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
# Cargar librería para datos raster
library(terra)

# 1. CREACIÓN / CARGA DE RASTER
# Simulamos dos rasters que representan la precipitación mensual (Enero y Febrero)
# En la práctica se usa: rast("ruta/al/archivo.tif")
r_ene <- rast(nrows=100, ncols=100, xmin=-76, xmax=-74, ymin=3, ymax=5, crs="EPSG:4326")
values(r_ene) <- runif(ncell(r_ene), min=50, max=150) # Lluvia simulada en mm

r_feb <- rast(nrows=100, ncols=100, xmin=-76, xmax=-74, ymin=3, ymax=5, crs="EPSG:4326")
values(r_feb) <- runif(ncell(r_feb), min=40, max=120)

# 2. STACK / MULTILAYER
# Apilamos las capas para formar un único objeto SpatRaster con múltiples bandas
precip_stack <- c(r_ene, r_feb)
names(precip_stack) <- c("Precip_Ene", "Precip_Feb")

# 3. OPERACIONES MATEMÁTICAS (Álgebra de Mapas)
# Calcular la precipitación acumulada del bimestre (Suma píxel a píxel)
precip_acumulada <- sum(precip_stack)

# Multiplicación escalar (Ej. aplicar un factor de corrección del 5%)
precip_corregida <- precip_acumulada * 1.05

# 4. RECORTE (Crop) por Extensión
# Definimos una extensión (xmin, xmax, ymin, ymax)
ext_estudio <- ext(-75.5, -74.5, 3.5, 4.5)
precip_recortada <- crop(precip_acumulada, ext_estudio)

# 5. REPROYECCIÓN (Cambio de CRS)
# Reproyectamos a UTM. Usamos el método bilineal porque la precipitación es continua
precip_utm <- project(precip_recortada, "EPSG:32618", method = "bilinear")

# Visualización simple con base R plot para terra
plot(precip_recortada, main="Precipitación Acumulada Recortada (mm)", col=mapa.colors(50))
```

### Manejo de datos combinando raster y vector

En un flujo de trabajo típico, tenemos una variable continua global (raster) y necesitamos extraer métricas específicas para nuestras unidades administrativas o parcelas experimentales (vectores).

1. **Crop (Recorte Rectangular)**: Se usa la extensión (Bounding Box) del polígono para recortar la matriz raster. Esto elimina datos innecesarios a nivel global/nacional y acelera los procesos subsecuentes.
2. **Mask (Enmascaramiento)**: El crop mantiene un rectángulo, pero los polígonos suelen ser irregulares (ej. un departamento). El mask convierte en `NA` (valores nulos) todos los píxeles que caen fuera de la geometría estricta del polígono.
3. **Extracción Zonal (`extract`)**: Resume los píxeles que caen dentro del polígono utilizando una función estadística (media, mediana, suma). El resultado es un formato tabular listo para el análisis estadístico o visual.

```r
# Creamos un polígono simulado (representando un municipio) dentro del área del raster
poly_muni <- st_polygon(list(matrix(c(-75.2, 3.8, -74.8, 3.8, -74.8, 4.2, -75.2, 4.2, -75.2, 3.8), ncol=2, byrow=TRUE)))
sf_municipio <- st_sf(Muni_ID = "Mun_01", geometry = st_sfc(poly_muni, crs = 4326))

# Para usar el vector de sf en funciones de terra, lo convertimos a SpatVector
vect_municipio <- vect(sf_municipio)

# 1. CROP: Corta el raster a la caja delimitadora del municipio
precip_muni_crop <- crop(precip_acumulada, vect_municipio)

# 2. MASK: Asigna NA a los píxeles fuera de la forma exacta del municipio
precip_muni_mask <- mask(precip_muni_crop, vect_municipio)

# 3. EXTRACCIÓN ZONAL: Calcular la precipitación media en el municipio
# na.rm = TRUE es vital para ignorar los valores NA generados por el mask
metricas_zonal <- extract(precip_muni_mask, vect_municipio, fun = mean, na.rm = TRUE)

# Incorporamos el resultado al objeto sf original para mapeo o exportación
sf_municipio$precip_media <- metricas_zonal[, 2] # Columna 2 contiene el cálculo
print(sf_municipio)
```