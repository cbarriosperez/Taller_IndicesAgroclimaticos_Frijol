# Descarga y Procesamiento de Datos Climáticos y de Suelos

En esta sección, aplicamos los conceptos anteriores a bases de datos de clase mundial.

- [**CHIRPS**](https://www.chc.ucsb.edu/data/chirps): (Climate Hazards Group InfraRed Precipitation with Station data): Resolución de 0.05° (~5.5 km), combina imágenes satelitales infrarrojas y datos de estaciones in-situ. Ideal para monitoreo de sequías extremas y agricultura.

- [**AgERA5**](https://cds.climate.copernicus.eu/datasets/sis-agrometeorological-indicators?tab=overview): Proveído por el programa Copernicus de la Unión Europea. Datos diarios de variables críticas para la agricultura (ej. temperatura a 2m, velocidad del viento, flujo solar). Requiere configuración previa en la [Plataforma Copernicus](https://cds.climate.copernicus.eu/).

| Variable AgERA5 | Descripción | Unidades |
|--------------------|------------|---------|
| `2m_temperature` | Temperatura a 2m | °C |
| `2m_relative_humidity` | Humedad relativa a 2m | % |
| `srad` | Radiación solar | J m-²/day-1 W/m |


- [**SoilGrids**](https://soilgrids.org/): Sistema global de información de suelos a 250m de resolución basado en machine learning. Ofrece métricas como carbono orgánico del suelo (SOC), pH, arena, limo y arcilla a múltiples profundidades.

| Variable SoilGrids | Descripción | Unidades |
|--------------------|------------|---------|
| `awcts` | Agua disponible total en el suelo (0–200 cm) | mm/m |
| `bdod` | Densidad aparente | cg/cm³ |
| `clay` | Contenido de arcilla | g/kg |
| `silt` | Contenido de limo | g/kg |
| `sand` | Contenido de arena | g/kg |
| `phh2o` | pH en agua | - |
| `ocs` | Stock de carbono orgánico | t/ha |


# Descarga de datos codigo en R


## 1. Descarga de CHIRPS


```r

source(
  paste0(
    "https://raw.githubusercontent.com/cbarriosperez/Taller_IndicesAgroclimaticos_Frijol/main/scripts//", 
    "main_session2.R"
  )
)


# Cargar librerías necesarias
library(chirps) # Para descargar precipitación
library(sf) # Para manejo de datos vectoriales
library(terra) # Para manejo de datos raster
library(tidyverse) # Para manejo de datos
# Leer el polígono del país creado anteriormente
pais = st_read(dsn = 'outputs/hnd.shp')

# Inspeccionar la extensión espacial (bounding box) del polígono
ext(pais)

## Definir las fechas de análisis
fechas =  c("2024-01-01","2024-12-31")
# Convertir objeto sf a un vector de tipo terra (SpatVector), necesario para el paquete CHIRPS

# Obtener los datos CHIRPS v3 de precipitación para la zona y periodo dado
prec_2024 = descarga_chirps_v3(fechas,extent_to_crop = ext(pais), output_dir = "outputs/chirps", parallelize = TRUE, ncores = 3)

# leer archivos comprimidos
contenido = unzip(zipfile = "outputs/chirps.zip", exdir = "outputs")
contenido = list.files('outputs/chirps', pattern = '\\.tif', full.names = T)
#
prec_2024 = terra::rast(contenido)

names(prec_2024) # Ver los nombres descargados

# Asignar atributos de tiempo y nombres limpios a las capas del raster usando nuestra función
time(prec_2024) = limpiar_fecha_chirps(names(prec_2024))
names(prec_2024) = limpiar_fecha_chirps(names(prec_2024))
# Graficar las primeras 5 capas
plot(prec_2024[[1:5]])
# Eliminar valores negativos (errores del sensor) asignándolos como "Sin Datos" (NA)
prec_2024[prec_2024<0] = NA
plot(prec_2024[[1:5]])



### Extraer datos usando puntos muestrales

# Cargar puntos anteriormente guardados
coordenadas = st_read("outputs/coordenadas_ejemplo_wgs84.shp")

# Extraer los datos de precipitación correspondientes a cada coordenada y pivotarlos en formato largo ("tidy data")
prec_df = terra::extract(x = prec_2024, y = coordenadas)%>%
  pivot_longer(cols = -ID,names_to = 'date', values_to = 'precipitacion')%>%
  left_join(coordenadas%>%rename(ID = idp), by = 'ID')

# Asegurarse de que date sea reconocido numéricamente como fecha
prec_df$date = as.Date(prec_df$date)
prec_df
# Crear un gráfico interactivo mostrando la precipitación por cada coordenada en el transcurso del tiempo
ggplot(data = prec_df, aes(date, precipitacion, color = as.factor(nombre))) + 
  geom_line(size = 1, alpha = 0.5) + 
  geom_point(size = 2) +
  facet_grid(nombre~.)+ # Crear un panel (faceta) para cada punto de muestreo ID
  theme_bw()

### Extraer raster para un polígono específico de los departamentos (Ejemplo: Colón)

# Leer nuevamente los límites de los departamentos de Honduras
hnd_departamentos = st_read("data/admin/geoBoundaries-HND-ADM1.shp")

# Filtrar unicamente el departamento de Colón en el sf dataframe
colon_geometry = hnd_departamentos%>%
  filter(shapeName == 'Colón')

# Recortar y enmascarar los datos CHIRPS exclusivamente para la silueta del departamento de Colón
prec_data_colon = cortar_raster_usando_vector(prec_2024, colon_geometry, mask = T)
# Graficar para comprobar la máscara extraída en las primeras 5 capas
plot(prec_data_colon[[1:5]])

colon_data = terra::global(prec_data_colon,
     fun = mean,
     na.rm = TRUE)

comayagua_geometry = hnd_departamentos%>%
  filter(shapeName == 'Comayagua')

prec_data_comayagua = cortar_raster_usando_vector(prec_2024, comayagua_geometry, mask = T)
plot(prec_data_comayagua[[1:5]])

comayagua_data = terra::global(prec_data_comayagua,
                           fun = mean,
                           na.rm = TRUE)

colon_data['departamento'] = 'colon'
comayagua_data['departamento'] = 'comayagua'

datos_unidos = rbind(colon_data, comayagua_data)%>%
  rownames_to_column(var = 'date')

ggplot(data = datos_unidos, aes(as.Date(date), mean, color = departamento)) + 
  geom_line(size = 1, alpha = 0.5) + 
  geom_point(size = 2) +
  theme_bw()

ggplot(data = datos_unidos, aes(as.Date(date), mean, color = departamento)) + 
  geom_bar(size = 1, alpha = 0.5, stat = 'identity')+
  theme_bw()


### Agrupar temporalmente datos (Agregación mensual)

# Sumar la precipitación diaria agrupada a nivel de mes usando 'tapp' (terra aggregation)
prec_mensual_2024 = tapp(prec_2024,
     index = 'months',
     fun = sum,
     na.rm = TRUE)

# Nombrar las capas usando el formato abreviado (Ej: "Ene", "Feb") basado en el tiempo original
names(prec_mensual_2024) = unique(format(time(prec_2024), format = '%b'))

# Extraer la precipitación mensual para los puntos seleccionados
prec_df = terra::extract(x = prec_mensual_2024, y = coordenadas)%>%
  pivot_longer(cols = -ID,names_to = 'mes', values_to = 'precipitacion')


# Graficar la tendencia de precipitación mensual por área de muestreo
ggplot(data = prec_df, aes(mes, precipitacion, color = as.factor(ID))) + 
  geom_line(size = 1, alpha = 0.5) + 
  geom_point(size = 2) +
  facet_grid(ID~.)+
  theme_bw()

ggplot(data = prec_df, aes(mes, precipitacion, fill = as.factor(ID))) + 
  geom_bar(stat = 'identity', alpha = 0.8)+
  facet_grid(ID~.)+
  theme_bw()

## Exportar el set de datos final a archivo tipo netCDF, útil en clima
#install.packages("ncdf4") # Instalar herramienta para netCDF si no existe

# Guardar la precipitación diaria en un cubo de datos multitemporal (.nc)
writeCDF(prec_2024, 
            filename = "outputs/prec_diaria_2024.nc",
            varname = 'precipitacion', # Nombre descriptivo de la variable principal
            unit = 'mm', # Unidad de medida
            zname = 'time',
         overwrite = T) # Nombre lógico de la dimensión Z (tiempo)

```

## 2. Descarga de AgERA5

```r

source(
  paste0(
    "https://raw.githubusercontent.com/cbarriosperez/Taller_IndicesAgroclimaticos_Frijol/main/scripts//", 
    "main_session2.R"
  )
)

library(sf)
library(terra)

# Instalar paquete 'ecmwfr' para acceder a datos climáticos del ECMWF (Copernicus)
# install.packages("ecmwfr")
library(ecmwfr)

## Obtener la extensión espacial del área de interés
pais = st_read("outputs/hnd.shp")


# Definir las credenciales de la API de Copernicus (CDS: Climate Data Store)
credenciales = list(
  email = 'andres.aguilar@cgiar.org', # Correo registrado
  key = '', # API Key personal requerida
  url = 'https://cds.climate.copernicus.eu/api'
)

# Configurar localmente la llave de acceso a la API
wf_set_key(user = credenciales$email,
           key = credenciales$key)

# Redondear la extensión para la solicitud a la API a dos decimales
extension_pais = round(ext(pais), 2)

# Crear la lista de parámetros para la petición de datos (Temperatura media diaria a 2m)
tmpera5_request = list(
  dataset_short_name = "sis-agrometeorological-indicators",
  variable = "2m_temperature", # Descargando Temperatura a 2m
  statistic = c("24_hour_mean"), # Promedio de 24 horas
  year = c("2024"),
  month = c("01","02","03","04","05","06"), # Primeros 6 meses del año
  day = c("01", "02", "03", # Todos los días posibles
          "04", "05", "06",
          "07", "08", "09",
          "10", "11", "12",
          "13", "14", "15",
          "16", "17", "18",
          "19", "20", "21",
          "22", "23", "24",
          "25", "26", "27",
          "28", "29", "30",
          "31"),
  version = '2_0',
  # Definir el Bounding box (Lat Max, Long Min, Lat Min, Long Max)
  area = c(extension_pais[4],extension_pais[1],extension_pais[3],extension_pais[2]),
  format = "zip",
  target = 'temp_mean_agera5_hnd.zip' # Nombre de archivo final a guardar
)


# Solicitar y descargar los datos a través del servicio CDS de Copernicus
wf_request(user = credenciales$email, 
                       request = tmpera5_request, 
                       transfer = TRUE, 
                       path = "outputs")


## Extraer y descomprimir datos descargados
agera_salida = 'outputs/temp_mean_agera5_hnd.zip'
agera_archivos = "outputs/temp_mean_hnd"

## Crear carpeta de destino temporal
dir.create(agera_archivos)


# Descomprimir el archivo zip dentro de la carpeta
contenido = unzip(zipfile = agera_salida, exdir = agera_archivos)

## Procesamiento del stack de rasters

# Leer todos los archivos descomprimidos como un stack continuo en terra (SpatRaster)
temp_meandata = terra::rast(contenido)

# Asignar nombres y fechas reales
names(temp_meandata) = limpiar_fecha_agera(contenido)
time(temp_meandata) = limpiar_fecha_agera(contenido)

# Visualizar las primeras 5 capas
plot(temp_meandata[[1:5]])

## Conversión de escala a grados Celsius
# (Los datos vienen en grados Kelvin por defecto)
temp_meandata = temp_meandata - 273.15

# Visualizar la temperatura en Celsius
plot(temp_meandata[[1:5]])

### Extraer serie usando puntos de muestreo

coordenadas = st_read("outputs/coordenadas_ejemplo_wgs84.shp")

# Extraer panel de temperatura usando los puntos
temp_df = terra::extract(x = temp_meandata, y = coordenadas)%>%
  pivot_longer(cols = -ID,names_to = 'date', values_to = 'temperatura')

# Asegurar su tipo date
temp_df$date = as.Date(temp_df$date)

# Crear gráfico por lugar de análisis
ggplot(data = temp_df, aes(date, temperatura, color = as.factor(ID))) + 
  geom_line(size = 1, alpha = 0.5) + 
  geom_point(size = 2) +
  facet_grid(ID~.)+
  theme_bw()

```

## 3. Descarga de SoilGrids

```r
## Base de datos de suelos Global - SoilGrids

source(
  paste0(
    "https://raw.githubusercontent.com/cbarriosperez/Taller_IndicesAgroclimaticos_Frijol/main/scripts//", 
    "main_session2.R"
  )
)

library(sf)
library(terra)

# Lista de variables y propiedades de suelo disponibles en SoilGrids
soilgrids_propiedades_disponibles = c("cec", "bdod", "cfvo", "clay", "sand", "silt", "nitrogen", "phh2o", "ocs", "wv1500", "wv0033", "wv0010")

# Lista estándar de intervalos de profundidad de suelo
soilgrids_profundidades = c("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")

# Leer el límite nacional del área de interés
pais = st_read("outputs/hnd.shp")

# Descargar datos usando nuestra función (ejemplo: 'bdod' a '5-15cm')
propiedad = descarga_soilgrids(pais, variable = 'phh2o', depth = '5-15cm', output_dir = 'outputs')

plot(propiedad)
### Recorte y extracción de datos
# Utilizando la función `cortar_raster_usando_vector` definida en `funciones_taller.R`
# para extraer y enmascarar los datos de suelo usando el contorno de Honduras ("pais")
propiedad_hnd = cortar_raster_usando_vector(raster_src = propiedad, sfvector = pais, mask = TRUE)

# Visualizar el resultado recortado
plot(propiedad_hnd, main = "pH")


### Remuestreo de imágenes raster (Resampling)
# Se usará la capa de precipitación CHIRPS diaria (creada en 3_chirps.R) como plantilla 
# de referencia para igualar su resolución espacial.

# 1. Cargar el archivo NetCDF generado en el script 3_chirps.R
referencia_chirps = rast("outputs/prec_diaria_2024.nc")

# 2. Tomar únicamente la primera capa de precipitación como plantilla geométrica
capa_referencia = referencia_chirps[[1]]

# 3. Aplicar el remuestreo a la capa de SoilGrids
# (El método "bilinear" es ideal en datos continuos como variables de suelo. Para clases/categorías se usaría "near")
propiedad_remuestreada = resample(propiedad_hnd, capa_referencia, method = "near")

# Comparar resoluciones en la consola
print(paste("Resolución original de SoilGrids:", paste(res(propiedad_hnd), collapse = " ")))
print(paste("Resolución objetivo desde CHIRPS:", paste(res(capa_referencia), collapse = " ")))

# Visualizar la nueva versión remuestreada del Raster
plot(propiedad_remuestreada, main = "SoilGrids Remuestreado a escala CHIRPS")

plot(c(propiedad_remuestreada, cortar_raster_usando_vector(raster_src = capa_referencia, sfvector = pais, mask = TRUE)))

```

## Funciones Auxiliares Reutilizables

Se recomienda centralizar las funciones comunes en un archivo `scripts/main_session2.R`:



```r
# ============================================================
# main_session2.R — Funciones auxiliares del taller
# ============================================================
# Camilo Barrios-Pérez & Andres Aguilar
# Taller Indicadores Agroclimáticos — Frijol Honduras 2025
# ============================================================

# Función para limpiar la fecha del formato AgERA5
limpiar_fecha_agera <- function(layer_names) {
  
  # Extraer fechas con formato AAAAMMDD usando expresiones regulares
  clean_strings <- gsub(".*(\\d{8}).*", "\\1", layer_names)
  
  # Convertir cadena de texto a un objeto formal de fecha
  final_dates <- as.Date(clean_strings, format = "%Y%m%d")
  
  return(final_dates)
}

# Función para limpiar y extraer fechas de los nombres de capas de CHIRPS
limpiar_fecha_chirps <- function(layer_names) {
  
  # Extraer la fecha (AAAA.MM.DD) usando expresiones regulares
  clean_strings <- gsub(".*(\\d{4}\\.\\d{2}\\.\\d{2}).*", "\\1", layer_names)
  
  # Convertir la cadena extraída al formato Date
  final_dates <- as.Date(clean_strings, format = "%Y.%m.%d")
  
  return(final_dates)
}

# Función auxiliar para recortar (crop) y enmascarar (mask) un raster con un vector espacial
cortar_raster_usando_vector <- function(raster_src, sfvector, mask = FALSE){
  
  # Asegurar de que ambos datos tengan el mismo CRS (sistema de coordenadas)
  if(crs(raster_src) != crs(sfvector)){
    vector_c = st_transform(sfvector, crs(raster_src))
  }else{
    vector_c = sfvector
  }
  
  # Recortar el raster a la extensión del vector
  raster_cr = terra::crop(raster_src, vector_c)
  # Aplicar un enmascarado si el parámetro está activado
  if(mask){
    raster_cr = terra::mask(raster_cr, vector_c)
  }
  
  return(raster_cr)
}


# Función automatizada para descargar datos de SoilGrids vía WCS (Web Coverage Service)
descarga_soilgrids <- function(aoi_sf, variable = "clay", depth = "0-5cm", init_name = "", output_dir = "") {
  
  # Asegurar que el sistema de coordenadas sea WGS84 (EPSG:4326), necesario para la API
  if(st_crs(aoi_sf)$epsg != 4326) {
    aoi_sf <- st_transform(aoi_sf, 4326)
  }
  
  # Obtener el recuadro delimitador (Bounding Box) del área de interés
  bbox <- st_bbox(aoi_sf)
  
  # Formar la URL base del servidor WCS de mapas ISRIC
  base_url <- paste0("https://maps.isric.org/mapserv?map=/map/", variable, ".map")
  
  # Construir la consulta completa concatenando los parámetros necesarios
  wcs_query <- paste0(
    base_url,
    "&SERVICE=WCS&VERSION=2.0.1&REQUEST=GetCoverage",
    "&COVERAGEID=", variable, "_", depth, "_mean", # Combinar variable y profundidad
    "&FORMAT=image/tiff", # Formato de salida GeoTIFF
    "&SUBSET=long(", bbox["xmin"], ",", bbox["xmax"], ")", # Definir límites longitudinales
    "&SUBSET=lat(", bbox["ymin"], ",", bbox["ymax"], ")",   # Definir límites latitudinales
    "&SUBSETTINGCRS=http://www.opengis.net/def/crs/EPSG/0/4326",
    "&OUTPUTCRS=http://www.opengis.net/def/crs/EPSG/0/4326"
  )
  
  # Determinar nombre de archivo de salida
  if(init_name != ""){
    file_name <- paste0(init_name,"_", variable, "_", depth, ".tif")  
  }else{
    file_name <- paste0(variable, "_", depth, ".tif")  
  }
  
  # Imprimir mensaje de progreso
  message("Descargando ", variable, " (", depth, ") de SoilGrids... Puede tomar un minuto")
  if(output_dir != ""){
    file_name = file.path(output_dir,file_name)
  }
  
  # Ejecutar la descarga del archivo TIFF a través de la URL formada
  download.file(url = wcs_query, destfile = file_name, mode = "wb", quiet = FALSE)
  
  # Cargar el archivo descargado como objeto raster (SpatRaster)
  raster_out <- rast(file_name)
  message("Descarga completa! archivo guardado en: ", file_name)
  
  return(raster_out) # Retornar el SpatRaster resultado
}

## parametros

# Lista de variables y propiedades de suelo disponibles en SoilGrids
soilgrids_propiedades_disponibles = c("cec", "bdod", "cfvo", "clay", "sand", "silt", "nitrogen", "phh2o", "ocs", "wv1500", "wv0033", "wv0010")

# Lista estándar de intervalos de profundidad de suelo
soilgrids_profundidades = c("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")

# Función para descargar datos de precipitación CHIRPS versión 3.0
descarga_chirps_v3 <- function(fechas, resolucion = "daily", extent_to_crop = NULL, output_dir = "outputs", parallelize = FALSE, ncores = 3) {
  
  # Crear directorio de salida si no existe
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Convertir extent_to_crop a vector numérico seguro para paralelización
  ext_num <- NULL
  if (!is.null(extent_to_crop)) {
    if (inherits(extent_to_crop, "SpatExtent")) {
      ext_num <- as.vector(extent_to_crop)
    } else if (inherits(extent_to_crop, c("sf", "sfc", "bbox"))) {
      if (!requireNamespace("sf", quietly = TRUE)) stop("El paquete 'sf' es necesario para manejar objetos bbox vectoriales.")
      bb <- sf::st_bbox(extent_to_crop)
      ext_num <- c(bb["xmin"], bb["xmax"], bb["ymin"], bb["ymax"])
    } else if (is.numeric(extent_to_crop) && length(extent_to_crop) >= 4) {
      ext_num <- extent_to_crop[1:4]
    } else {
      warning("Formato de extent_to_crop no reconocido. Se ignorará el recorte.")
    }
  }
  
  # Asegurar que las fechas estén en formato Date
  fechas <- as.Date(fechas)
  
  # Generar secuencia si se proporciona un rango (2 fechas)
  if (length(fechas) == 2) {
    if (resolucion == "daily") {
      fechas_seq <- seq(fechas[1], fechas[2], by = "day")
    } else if (resolucion == "monthly") {
      fechas_seq <- seq(fechas[1], fechas[2], by = "month")
    } else {
      stop("La resolución debe ser 'daily' o 'monthly'")
    }
  } else {
    fechas_seq <- fechas
  }
  
  # Formatear URLs y nombres de archivo destino
  urls <- character(length(fechas_seq))
  dest_files <- character(length(fechas_seq))
  
  for (i in seq_along(fechas_seq)) {
    fecha <- fechas_seq[i]
    year <- format(fecha, "%Y")
    month <- format(fecha, "%m")
    day <- format(fecha, "%d")
    
    if (resolucion == "daily") {
      file_name <- paste0("chirp-v3.0.", year, ".", month, ".", day, ".tif")
      url <- paste0("https://data.chc.ucsb.edu/products/CHIRP-v3.0/daily/global/tifs/", year, "/", file_name)
    } else if (resolucion == "monthly") {
      file_name <- paste0("chirp-v3.0.", year, ".", month, ".tif")
      url <- paste0("https://data.chc.ucsb.edu/products/CHIRP-v3.0/monthly/global/tifs/", file_name)
    }
    
    urls[i] <- url
    dest_files[i] <- file.path(output_dir, file_name)
  }
  
  # Función auxiliar de descarga segura y recorte
  process_file <- function(url, dest, ext_vec) {
    exito_descarga <- FALSE
    if (!file.exists(dest)) {
      tryCatch({
        download.file(url, dest, mode = "wb", quiet = TRUE)
        exito_descarga <- TRUE
      }, error = function(e) {
        warning(paste("Error al descargar:", url))
        exito_descarga <- FALSE
      })
    } else {
      exito_descarga <- TRUE # Ya existe
    }
    
    # Recortar raster si se descargó/existe y hay un extent definido
    if (exito_descarga && !is.null(ext_vec) && requireNamespace("terra", quietly = TRUE)) {
      tryCatch({
        r <- terra::rast(dest)
        ext_obj <- terra::ext(ext_vec[1], ext_vec[2], ext_vec[3], ext_vec[4])
        
        # Evaluar groseramente si ya se encuentra recortado comparando tamaños de extensión
        if (!isTRUE(all.equal(as.vector(terra::ext(r)), as.vector(ext_obj)))) {
          r_crop <- terra::crop(r, ext_obj)
          temp_dest <- paste0(dest, ".tmp.tif")
          terra::writeRaster(r_crop, temp_dest, overwrite = TRUE)
          
          # Liberar recursos para evitar bloqueos de archivo en Windows
          rm(r, r_crop)
          gc()
          
          if (file.exists(dest)) file.remove(dest)
          file.rename(temp_dest, dest)
        }
      }, error = function(e) {
        warning(paste("Error al recortar archivo:", dest, "-", e$message))
      })
    }
    return(exito_descarga)
  }
  
  message(sprintf("Descargando y procesando %d archivos CHIRPS v3.0 (%s)... Puede tomar un momento.", length(urls), resolucion))
  
  # Ejecutar patrón de procesamiento (descarga + recorte)
  if (parallelize) {
    if (!requireNamespace("parallel", quietly = TRUE)) {
      message("Paquete 'parallel' no instalado. Realizando procesamiento de forma secuencial.")
      resultados <- mapply(process_file, urls, dest_files, MoreArgs = list(ext_vec = ext_num))
    } else {
      cores_to_use <- max(1, ncores )
      cl <- parallel::makeCluster(cores_to_use)
      message(sprintf("Procesando en paralelo usando %d núcleos...", cores_to_use))
      resultados <- parallel::clusterMap(cl, process_file, urls, dest_files, MoreArgs = list(ext_vec = ext_num), SIMPLIFY = TRUE)
      parallel::stopCluster(cl)
    }
  } else {
    resultados <- mapply(process_file, urls, dest_files, MoreArgs = list(ext_vec = ext_num))
  }
  
  message("Descarga completada con éxito.")
  
  # Filtrar rutas de archivos exitosos
  archivos_exitosos <- dest_files[unlist(resultados)]
  
  # Retornar como SpatRaster si la librería terra está en uso, sino devolver los archivos
  if (requireNamespace("terra", quietly = TRUE) && length(archivos_exitosos) > 0) {
    return(terra::rast(archivos_exitosos))
  } else {
    return(archivos_exitosos)
  }
}

```