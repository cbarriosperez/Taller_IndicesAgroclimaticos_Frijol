# Pipeline Reproducible de Preparación de Datos

## Concepto de Pipeline Reproducible

Un pipeline reproducible garantiza que **cualquier colaborador** pueda ejecutar el mismo flujo y obtener los mismos resultados, independientemente del sistema operativo o la máquina.


---

## Script:

```r
# ============================================================
# run_all.R — Ejecuta el pipeline completo del taller
# ============================================================
# Camilo Barrios-Pérez & Andres Aguilar
# Taller Indicadores Agroclimáticos — Frijol Honduras 2025
# ============================================================

cat("=== Iniciando pipeline agroclimático ===\n")
cat("Fecha y hora:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# 1. Instalar y cargar paquetes
cat("[1/5] Configuración del entorno...\n")
source("scripts/01_setup.R")

# 2. Descargar y preparar datos climáticos
cat("[2/5] Procesando datos climáticos...\n")
source("scripts/02_datos_clima.R")

# 3. Descargar y preparar datos de suelos
cat("[3/5] Procesando datos de suelos...\n")
source("scripts/03_datos_suelos.R")

# 4. Calcular indicadores agroclimáticos
cat("[4/5] Calculando indicadores agroclimáticos...\n")
source("scripts/04_indicadores_termicos.R")
source("scripts/05_indicadores_hidricos.R")

# 5. Generar mapas y tablas finales
cat("[5/5] Generando productos finales...\n")
source("scripts/06_mapas_tpe.R")

cat("\n=== Pipeline completado exitosamente ===\n")
```

---

## Funciones Auxiliares Reutilizables

Se recomienda centralizar las funciones comunes en un archivo `scripts/utils.R`:

```r
# ============================================================
# utils.R — Funciones auxiliares del taller
# ============================================================

#' Recortar y enmascarar un raster al límite de Honduras
#'
#' @param raster_entrada SpatRaster de entrada
#' @param limite SpatVector del límite de recorte
#' @return SpatRaster recortado y enmascarado
recortar_honduras <- function(raster_entrada, limite) {
  r_crop <- terra::crop(raster_entrada, limite)
  r_mask <- terra::mask(r_crop, limite)
  return(r_mask)
}

#' Guardar un raster y reportar en consola
#'
#' @param raster SpatRaster de salida
#' @param ruta Ruta del archivo de salida (.tif)
guardar_raster <- function(raster, ruta) {
  terra::writeRaster(raster, ruta, overwrite = TRUE)
  cat("  ✓ Guardado:", ruta, 
      paste0("(", round(file.size(ruta)/1e6, 1), " MB)\n"))
}

#' Calcular estadísticas zonales y devolver data.frame ordenado
#'
#' @param raster SpatRaster de valores
#' @param zonas SpatVector de polígonos con atributo NAME_2 (municipio)
#' @param campo_nombre Nombre del campo en zonas para el municipio
#' @return data.frame con estadísticas por municipio
estadisticas_municipio <- function(raster, zonas, campo_nombre = "NAME_2") {
  fns  <- c("mean", "sd", "min", "max")
  tabs <- lapply(fns, function(fn) {
    z <- terra::zonal(raster, zonas, fun = fn, na.rm = TRUE)
    colnames(z)[-1] <- paste0(names(raster), "_", fn)
    return(z)
  })
  
  resultado <- Reduce(function(a, b) cbind(a, b[,-1]), tabs)
  resultado <- cbind(
    municipio = as.data.frame(zonas)[, campo_nombre],
    resultado[, -1]
  )
  return(resultado[order(resultado$municipio), ])
}
```

---

## Uso de `here` para Rutas Portables

```r
library(here)

# here() devuelve la raíz del proyecto (donde está el .Rproj)
# Sin importar el directorio de trabajo actual del usuario

ruta_tmax <- here("data", "clima", "worldclim", "tmax_honduras.tif")
cat("Ruta al archivo tmax:", ruta_tmax, "\n")

wc_tmax_hon <- rast(ruta_tmax)
```

!!! tip "Buena práctica"
    Nunca usar rutas absolutas como `C:/Users/cbarrios/...` en los scripts del proyecto. Usar siempre `here::here()` o rutas relativas al proyecto para que el código funcione en cualquier computadora.
