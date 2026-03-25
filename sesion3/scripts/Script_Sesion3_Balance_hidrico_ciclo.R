################################################################################
#                   CÁLCULO DE ÍNDICES AGROCLIMÁTICOS HÍDRICOS                 #
#------------------------------------------------------------------------------#
# Propósito: Calcular y visualizar el mapa del Balance Hídrico Climático (WB)  #
#            para Honduras durante el ciclo de cultivo (mayo - agosto 2025).   #
#                                                                              #
# Entradas:  - Ráster de Precipitación total acumulada (mm)                    #
#            - Ráster de Evapotranspiración de Referencia (ETo) total (mm)     #
# Salidas:   - Ráster del Balance Hídrico (wb_may-ago_Hnd.tif)                 #
#                                                                              #
# Autor:     Camilo Barrios-Perez (Ph.D) - c.barrios@cgiar.org                 #
# Fecha:     Marzo 2026 (Actualizado)                                          #
################################################################################

# 1. Cargar librerías ----------------------------------------------------------
# terra: Paquete moderno y eficiente para el manejo y álgebra de datos ráster
library(terra) 
# sp y sf: Paquetes para la manipulación de datos espaciales y vectoriales
library(sp)    
library(sf)    

# 2. Configurar el directorio de trabajo ---------------------------------------
# Nota: Esta ruta es local. Si se comparte el script, se recomienda usar 
# proyectos de RStudio (.Rproj) o el paquete 'here' para rutas relativas.
setwd("D:/OneDrive - CGIAR/Otras Colaboraciones/Proyecto_Parcela Digital_Zamorano/2025/workshops/Indices Agroclimáticos/Sesion 3")

# 3. Importar y visualizar Precipitación ---------------------------------------
# Cargar la precipitación total acumulada durante el periodo evaluado
precipitacion = terra::rast("Ejercicios/Output/Precipitacion_may-ago_Hnd.tif")

# Abrir ventana gráfica externa (nota: windows() es específico para SO Windows)
windows() 
plot(precipitacion, main = "Precipitación Total Acumulada (mm)\nMayo - Agosto 2025")

# 4. Importar y visualizar Evapotranspiración (ETo) ----------------------------
# Cargar la ETo total acumulada durante el mismo ciclo
ETo = terra::rast("Ejercicios/Output/ETo_may-ago_Hnd.tif")

windows()
plot(ETo, main = "Evapotranspiración de Referencia (ETo) Total (mm)\nMayo - Agosto 2025")

# 5. Cálculo del Balance Hídrico Climático -------------------------------------
# Fórmula: Balance = Precipitación - ETo
# Valores positivos indican exceso de agua; valores negativos indican déficit.
wb = precipitacion - ETo

windows()
plot(wb, main = "Balance Hídrico Climático Total (mm)\nMayo - Agosto 2025")

# Análisis de déficit: 
# Generar un mapa (Verdadero/Falso) donde el balance es menor a 0.
windows()
plot(wb < 0, main = "Áreas con Déficit Hídrico (WB < 0)\n(1 = Déficit, 0 = Sin Déficit)")

# 6. Exportar resultados -------------------------------------------------------
# Guardar el ráster final del Balance Hídrico en formato TIFF.
# Se utiliza overwrite = TRUE para sobrescribir el archivo si ya existe.
writeRaster(wb, 
            filename = "Ejercicios/Output/wb_may-ago_Hnd.tif", 
            overwrite = TRUE)
