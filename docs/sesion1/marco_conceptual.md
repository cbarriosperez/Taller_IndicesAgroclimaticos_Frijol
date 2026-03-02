# Marco Conceptual Agroclimático Aplicado al Cultivo de Frijol

## ¿Por qué importa el clima en el frijol?

El frijol (*Phaseolus vulgaris* L.) es el cultivo de grano alimenticio más importante en América Central y el Caribe. En Honduras, su producción se concentra en los departamentos de El Paraíso, Olancho, Choluteca, Francisco Morazán y La Paz, bajo sistemas de secano altamente dependientes de la lluvia estacional.

La productividad del frijol es sensible a:

- **Temperatura**: determina la velocidad de desarrollo fenológico y el cuajado de vainas.
- **Precipitación y balance hídrico**: controla el estrés hídrico durante siembra, floración y llenado de grano.
- **Radiación solar**: afecta la biomasa acumulada y la eficiencia en el uso de radiación.
- **Humedad relativa**: incide en enfermedades fúngicas (roya, antracnosis, mancha angular).

---

## El Continuum Climático–Planta–Decisión

```
Datos climáticos y de suelo
        │
        ▼
Indicadores agroclimáticos
        │
        ▼
Caracterización de ambientes (TPE)
        │
        ├──► Selección de sitios de evaluación
        ├──► Ventanas de siembra óptimas
        └──► Rasgos de interés para mejoramiento
```

Este flujo de trabajo permite pasar de información **observada** (datos climáticos históricos) a información **accionable** (recomendaciones de manejo y mejoramiento).

---

## Variabilidad Climática en Honduras

Honduras presenta una heterogeneidad climática marcada:

| Región | Precipitación anual (mm) | Temperatura media (°C) | Sistema de siembra |
|--------|--------------------------|------------------------|-------------------|
| Sur (Choluteca) | 800 – 1 200 | 26 – 30 | Apante (Nov–Feb) |
| Centro-norte (Francisco Morazán) | 1 200 – 1 800 | 18 – 24 | Primera (May–Jul) |
| Este (Olancho) | 1 400 – 2 200 | 20 – 26 | Primera y Postrera |
| Occidente (Lempira) | 1 000 – 1 600 | 16 – 22 | Primera y Postrera |

Esta variabilidad justifica la necesidad de **caracterizar ambientalmente** las zonas para adaptar materiales y prácticas de manejo.

---

## Fenología del Frijol y Ventanas Críticas

Las fases fenológicas del frijol definen las **ventanas temporales** en las que los indicadores agroclimáticos son más relevantes:

| Fase | Código | Duración aprox. (días) | Variable climática crítica |
|------|--------|------------------------|---------------------------|
| Siembra – Emergencia | V0 – V1 | 5 – 10 | Temperatura del suelo, humedad |
| Desarrollo vegetativo | V2 – V4 | 15 – 25 | Temperatura, radiación |
| **Floración** | R1 – R2 | 10 – 20 | **Temperatura máx. (> 35 °C limita cuajado)** |
| Formación de vainas | R3 – R5 | 20 – 30 | Déficit hídrico crítico |
| **Llenado de grano** | R6 – R7 | 15 – 25 | **Temperatura nocturna, radiación** |
| Madurez y cosecha | R8 – R9 | 10 – 15 | Precipitación (cosecha en seco) |

!!! warning "Estrés térmico en floración"
    Temperaturas nocturnas superiores a **20 °C** durante la floración pueden reducir drásticamente el cuajado de vainas. Este es uno de los indicadores más relevantes para el mejoramiento del frijol bajo cambio climático.

---

## Fuentes de Datos Climáticos Utilizadas

| Fuente | Variable | Resolución temporal | Resolución espacial |
|--------|----------|---------------------|---------------------|
| **WorldClim v2.1** | Tmax, Tmin, Precip, Rad, Viento, Humedad | Mensual (1970–2000) | ~1 km |
| **CHIRPS** | Precipitación diaria | Diaria / Mensual | ~5 km |
| **ERA5-Land** | Temperatura, ET₀, Humedad | Horaria / Diaria | ~9 km |
| **CHELSA** | Tmax, Tmin, Precip | Mensual | ~1 km |
| **SoilGrids (ISRIC)** | AWC, pH, arcilla, limo, arena | — | 250 m |

---

## Conexión con el Mejoramiento Genético

Los indicadores agroclimáticos calculados en este taller sirven como insumos para:

1. **Definir TPE** (*Target Population of Environments*): agrupar zonas productoras con patrones de estrés similares, identificando los tipos de ambientes a los que deben adaptarse las variedades.
2. **Estimar la frecuencia e intensidad del estrés**: informa sobre la probabilidad de que un genotipo enfrente calor o sequía en su contexto de producción.
3. **Priorizar rasgos**: por ejemplo, tolerancia al calor nocturno, eficiencia en el uso del agua (WUE), o precocidad para escapar del estrés terminal.
4. **Diseñar redes de ensayo**: seleccionar sitios experimentales representativos de los ambientes objetivo.
