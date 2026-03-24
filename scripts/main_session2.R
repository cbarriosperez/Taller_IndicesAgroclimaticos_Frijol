

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


crear_capa_promedio_de_profundidad = function(propiedad, 
                                              sfvector, 
                                              profundidad_max = '30cm', 
                                              output_dir = 'data/suelo', 
                                              mask = TRUE) {
  
  # 1. Definir los espesores (weights) de las capas estándar de SoilGrids en cm
  # (0-5, 5-15, 15-30, 30-60, 60-100, 100-200)
  depths = c(5, 10, 15, 30, 40, 100)
  soilgrids_profundidades = c("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")

  # 2. Encontrar el índice 'n' que corresponde a la profundidad máxima deseada
  # Se usa which() combinado con str_detect() para hacerlo más robusto y rápido que el lapply original
  n = which(stringr::str_detect(soilgrids_profundidades, profundidad_max))
  
  # 3. Descargar y ponderar las capas
  # Descargamos desde la capa 1 hasta la capa 'n', multiplicando cada raster por su espesor
  data_layers = lapply(1:n, function(x) {
    raster_descargado = descarga_soilgrids(
      sfvector, 
      variable = propiedad, 
      depth = soilgrids_profundidades[x], 
      output_dir = output_dir  # Corregido: Ahora usa el argumento
    )
    
    # Ponderación: Multiplicamos el raster por el grosor de esa capa específica
    return(raster_descargado * depths[x])
  })
  

  # 4. Calcular el promedio ponderado final
  # Sumamos todas las capas ponderadas y dividimos por la suma total de los espesores
  raster_sumado = sum(terra::rast(data_layers), na.rm = TRUE)
  profundidad_total = sum(depths[1:n])
  
  raster_promedio = raster_sumado / profundidad_total
  
  # 5. Aplicar máscara si el usuario lo requiere
  if (mask) {
    raster_promedio = cortar_raster_usando_vector(
      raster_src = raster_promedio, 
      sfvector = sfvector, 
      mask = TRUE
    )
  }
  
  return(raster_promedio)
}