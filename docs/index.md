# Taller práctico en R: Indicadores Agroclimáticos para Frijol en Honduras

## Acceso Virtual — Microsoft Teams

!!! tip "Enlace para unirse al taller"
    [:fontawesome-brands-microsoft: **Unirse a la reunión en Teams**](https://teams.microsoft.com/meet/21094003872360?p=qWIKDbnChROKZmeYlw){ .md-button .md-button--primary target="_blank" }

| Campo | Información |
|-------|-------------|
| **Enlace directo** | [https://teams.microsoft.com/meet/21094003872360](https://teams.microsoft.com/meet/21094003872360?p=qWIKDbnChROKZmeYlw) |
| **Meeting ID** | `210 940 038 723 60` |
| **Passcode** | `hH28FE3m` |
| **Horario** | Miércoles · 9:00 – 11:00 am (hora Honduras, UTC–6) |

---

## Descripción del Taller

La productividad del frijol (*Phaseolus vulgaris* L.) en Honduras depende fuertemente de la **variabilidad climática** y de las **condiciones del suelo**. Este taller introduce un flujo de trabajo reproducible en R para integrar información espacial de:

- **Clima**: precipitación, temperatura, radiación solar, humedad relativa, velocidad del viento.
- **Suelos**: capacidad de agua disponible (AWC), profundidad efectiva, textura y carbono orgánico.

con el fin de calcular **indicadores agroclimáticos** relevantes para el cultivo y sintetizarlos en mapas y tablas interpretables por zona productora.

!!! info "Enfoque del taller"
    El taller conecta la modelación agroclimática con necesidades concretas de mejoramiento y manejo:

    - Identificación de **ambientes objetivo** (Target Population of Environments, TPE).
    - Estimación de **riesgos de estrés** térmico e hídrico.
    - Soporte a decisiones de **ventanas de siembra** y **selección de sitios** de evaluación.

---

## Facilitadores

| Nombre | Institución | Formación |
|--------|-------------|-----------|
| **Camilo Barrios-Pérez** | Alliance of Bioversity & CIAT / CGIAR | MSc, PhD |
| **Andres Aguilar** | Alliance of Bioversity & CIAT / CGIAR | MSc, PhD |

**Institución anfitriona:** Universidad Zamorano, Honduras.

---

## Objetivo General

> Fortalecer capacidades para **diseñar, calcular e interpretar indicadores agroclimáticos del frijol** a partir de datos climáticos y de suelos espaciales en R, generando insumos accionables para mejoramiento genético y manejo del cultivo en Honduras.

---

## Objetivos Específicos

1. **Estandarizar** un flujo de trabajo reproducible en R para integrar datos climáticos y edáficos a nivel nacional.
2. **Calcular** indicadores térmicos e hídricos clave (GDD, días de calor en floración/llenado, ET₀/ETc, déficit hídrico, CDD, SPEI) en ventanas fenológicas del frijol.
3. **Generar** productos espaciales (mapas GeoTIFF) y resúmenes tabulares por municipio/zona productora para priorización de ambientes (TPE).
4. **Interpretar** los indicadores para recomendaciones preliminares de ventanas de siembra, selección de sitios de ensayo y rasgos de interés para mejoramiento.

---

## Agenda del Taller

| Fecha | Sesión | Contenido Principal |
|-------|--------|---------------------|
| **Marzo 4** | [Sesión 1](sesion1/index.md) | Fundamentos agroclimáticos y configuración del entorno de trabajo en R |
| **Marzo 11** | [Sesión 2](sesion2/index.md) | Procesamiento inicial de datos climáticos y de suelos en R |
| **Marzo 18** | [Sesión 3](sesion3/index.md) | Cálculo de indicadores agroclimáticos para el cultivo de frijol |
| **Marzo 25** | [Sesión 4](sesion4/index.md) | Generación de mapas, zonificación agroclimática y definición de ambientes (TPE) |

---

## Requisitos Previos

!!! warning "Requisitos técnicos"
    Para sacar el máximo provecho del taller se recomienda:

    - R ≥ 4.3.0 y RStudio ≥ 2023.x instalados.
    - Conexión a internet estable (sesiones virtuales).
    - Familiaridad básica con R (importar datos, funciones básicas, ggplot2).
    - ~5 GB de espacio libre en disco para datos climáticos y resultados.

---

## Estructura de Archivos del Proyecto

```
Taller_IndicesAgroclimaticos_Frijol/
├── data/
│   ├── clima/          # Rasters de WorldClim, CHIRPS, ERA5, etc.
│   ├── suelos/         # SoilGrids o ISRIC (AWC, profundidad, textura)
│   └── admin/          # Límites administrativos de Honduras (shapefile)
├── scripts/
│   ├── 01_setup.R
│   ├── 02_datos_clima.R
│   ├── 03_datos_suelos.R
│   ├── 04_indicadores_termicos.R
│   ├── 05_indicadores_hidricos.R
│   └── 06_mapas_tpe.R
├── outputs/
│   ├── mapas/          # GeoTIFF resultantes
│   └── tablas/         # Resúmenes por municipio/zona
├── docs/               # Esta documentación MkDocs
└── mkdocs.yml
```

---

*Este sitio es generado automáticamente con [MkDocs](https://www.mkdocs.org/) y el tema [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).*
