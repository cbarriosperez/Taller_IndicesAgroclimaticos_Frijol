# Configuración del Entorno de Trabajo en R

## Estructura del Proyecto

La organización reproducible de archivos es fundamental para un flujo de trabajo colaborativo. Se recomienda la siguiente estructura:

```
Taller_IndicesAgroclimaticos_Frijol/
├── data/
│   ├── clima/
│   │   ├── worldclim/         # Rasters mensuales de WorldClim 2.1
│   │   ├── chirps/            # Precipitación diaria/mensual CHIRPS
│   │   └── era5/              # Variables diarias ERA5-Land
│   ├── suelos/
│   │   └── soilgrids/         # AWC, profundidad, textura (250 m)
│   └── admin/
│       ├── honduras_mun.shp   # Municipios de Honduras
│       └── zonas_frijol.shp   # Zonas productoras de frijol
├── scripts/
│   ├── 01_setup.R
│   ├── 02_datos_clima.R
│   ├── 03_datos_suelos.R
│   ├── 04_indicadores_termicos.R
│   ├── 05_indicadores_hidricos.R
│   └── 06_mapas_tpe.R
├── outputs/
│   ├── mapas/
│   └── tablas/
└── mkdocs.yml
```

---

## Instalación de Paquetes

Ejecute el siguiente bloque al inicio de la primera sesión. Solo se instalan los paquetes que no estén aún disponibles:

```r
# ============================================================
# Script: 01_setup.R
# Taller Indicadores Agroclimáticos - Frijol Honduras
# Facilitadores: C. Barrios-Pérez & A. Aguilar
# ============================================================

paquetes_requeridos <- c(
  # Manipulación de datos
  "tidyverse",     # dplyr, ggplot2, tidyr, readr, purrr
  "data.table",    # Manipulación eficiente de tablas grandes
  "lubridate",     # Manejo de fechas
  
  # Datos espaciales - rasters
  "terra",         # Sucesor moderno de raster; lectura/escritura GeoTIFF
  "sf",            # Datos vectoriales (shapefiles, GeoJSON)
  "stars",         # Arrays espacio-temporales
  
  # Visualización espacial
  "ggplot2",       # Gráficos
  "tidyterra",     # Compatibilidad terra + ggplot2
  "tmap",          # Mapas temáticos
  "RColorBrewer",  # Paletas de color
  "viridis",       # Paletas perceptualmente uniformes
  
  # Descarga de datos climáticos
  "geodata",       # WorldClim, CHELSA, GADM (requiere terra)
  "climateR",      # Acceso a ERA5, CHIRPS, PRISM, etc.
  
  # Indicadores agroclimáticos
  "SPEI",          # Cálculo de SPI y SPEI
  "Evapotranspiration", # Métodos de ET (Penman-Monteith, Hargreaves)
  
  # Reportes y tablas
  "knitr",
  "kableExtra",
  "flextable"
)

# Instalar los que faltan
paquetes_faltantes <- paquetes_requeridos[
  !paquetes_requeridos %in% installed.packages()[, "Package"]
]

if (length(paquetes_faltantes) > 0) {
  cat("Instalando:", paste(paquetes_faltantes, collapse = ", "), "\n")
  install.packages(paquetes_faltantes, dependencies = TRUE)
} else {
  cat("Todos los paquetes están instalados.\n")
}

# Cargar todos los paquetes
invisible(lapply(paquetes_requeridos, library, character.only = TRUE))
cat("Entorno de trabajo listo.\n")
```

---

## Configuración del Proyecto RStudio

### Crear el proyecto

En RStudio, vaya a **File → New Project → Existing Directory** y seleccione la carpeta del taller. Esto crea un archivo `.Rproj` que establece el directorio de trabajo automáticamente.

Alternativamente, desde la consola de R:

```r
# Crear estructura de carpetas del proyecto
carpetas <- c(
  "data/clima/worldclim",
  "data/clima/chirps",
  "data/clima/era5",
  "data/suelos/soilgrids",
  "data/admin",
  "scripts",
  "outputs/mapas",
  "outputs/tablas"
)

for (carpeta in carpetas) {
  if (!dir.exists(carpeta)) {
    dir.create(carpeta, recursive = TRUE)
    cat("Creada:", carpeta, "\n")
  }
}
```

---

## Verificación del Entorno

Ejecute las siguientes comprobaciones para confirmar que el entorno está correcto:

```r
# 1. Versión de R (debe ser >= 4.3.0)
cat("Versión de R:", as.character(getRversion()), "\n")

# 2. Verificar paquetes críticos
paquetes_criticos <- c("terra", "sf", "tidyverse", "SPEI", "geodata")
versiones <- sapply(paquetes_criticos, function(p) {
  if (requireNamespace(p, quietly = TRUE)) {
    as.character(packageVersion(p))
  } else {
    "NO INSTALADO"
  }
})
print(data.frame(Paquete = names(versiones), Versión = versiones, 
                 row.names = NULL))

# 3. Verificar lectura de raster (terra)
library(terra)
r_test <- rast(nrows = 10, ncols = 10, 
               xmin = -90, xmax = -83, 
               ymin = 13,  ymax = 16)
values(r_test) <- runif(ncell(r_test), 20, 35)
cat("terra funcional. CRS por defecto:", crs(r_test, describe = TRUE)$code, "\n")

# 4. Verificar lectura vectorial (sf)
library(sf)
poly_test <- st_sfc(st_polygon(list(
  matrix(c(-90,13, -83,13, -83,16, -90,16, -90,13), ncol = 2, byrow = TRUE)
)), crs = 4326)
cat("sf funcional. EPSG:", st_crs(poly_test)$epsg, "\n")
```

!!! success "Resultado esperado"
    Si todos los paquetes están instalados correctamente, la última verificación mostrará:
    ```
    terra funcional. CRS por defecto: 4326
    sf funcional. EPSG: 4326
    ```

---

## Descarga Inicial de Datos de Prueba

Como primer ejercicio, descargue los datos de Honduras desde WorldClim y GADM:

```r
library(geodata)
library(terra)

# Definir carpeta de destino
dir_worldclim <- "data/clima/worldclim"

# Descargar variables bioclimáticas WorldClim 2.1 (resolución 2.5 min ≈ 4.5 km)
# Variable: tmax (temperatura máxima mensual) y prec (precipitación mensual)
wc_tmax <- worldclim_country(
  country = "Honduras", 
  var     = "tmax",       # tmin, tmax, tavg, prec, wind, vapr, srad
  res     = 2.5,          # resolución: 0.5, 2.5, 5, 10 minutos de arco
  path    = dir_worldclim
)

wc_prec <- worldclim_country(
  country = "Honduras", 
  var     = "prec",
  res     = 2.5,
  path    = dir_worldclim
)

# Descargar límite administrativo de Honduras (nivel 2 = municipios)
hon_mun <- gadm(country = "HND", level = 2, path = "data/admin")

# Vista rápida
print(wc_tmax)       # SpatRaster con 12 capas (ene–dic)
plot(wc_tmax[[6]])   # Temperatura máxima de junio
plot(hon_mun, add = TRUE, col = NA, border = "black")
```

!!! note "Tamaño de los archivos"
    Los datos de WorldClim a 2.5 min para Honduras ocupan aproximadamente **15–30 MB** por variable. La descarga requiere conexión a internet y puede tardar 1–5 minutos dependiendo de la velocidad de conexión.
