# Descarga y Procesamiento de Datos Climáticos y de Suelos

En esta sección, aplicamos los conceptos anteriores a bases de datos de clase mundial.

- [**CHIRPS**](https://www.chirps.org/): (Climate Hazards Group InfraRed Precipitation with Station data): Resolución de 0.05° (~5.5 km), combina imágenes satelitales infrarrojas y datos de estaciones in-situ. Ideal para monitoreo de sequías extremas y agricultura.

- [**AgERA5**](https://cds.climate.copernicus.eu/datasets/sis-agrometeorological-indicators?tab=overview): Proveído por el programa Copernicus de la Unión Europea. Datos diarios de variables críticas para la agricultura (ej. temperatura a 2m, velocidad del viento, flujo solar). Requiere configuración previa en la [Plataforma Copernicus](https://cds.climate.copernicus.eu/).

| Variable AgERA5 | Descripción | Unidades |
|--------------------|------------|---------|
| `2m_temperature` | Temperatura a 2m | °C |
| `2m_relative_humidity` | Humedad relativa a 2m | % |
| `srad` | Radiación solar | J m-²/day-1 W/m |


- [**SoilGrids**](https://www.isric.org/soilgrids): Sistema global de información de suelos a 250m de resolución basado en machine learning. Ofrece métricas como carbono orgánico del suelo (SOC), pH, arena, limo y arcilla a múltiples profundidades.

| Variable SoilGrids | Descripción | Unidades |
|--------------------|------------|---------|
| `awcts` | Agua disponible total en el suelo (0–200 cm) | mm/m |
| `bdod` | Densidad aparente | cg/cm³ |
| `clay` | Contenido de arcilla | g/kg |
| `silt` | Contenido de limo | g/kg |
| `sand` | Contenido de arena | g/kg |
| `phh2o` | pH en agua | - |
| `ocs` | Stock de carbono orgánico | t/ha |

