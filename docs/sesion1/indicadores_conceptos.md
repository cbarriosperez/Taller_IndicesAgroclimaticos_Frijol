# Indicadores Agroclimáticos — Conceptos Clave

## Definición

Un **indicador agroclimático** es una métrica derivada de variables climáticas (y eventualmente edáficas) que resume, de forma cuantitativa, un aspecto relevante del ambiente para el crecimiento, desarrollo y rendimiento del cultivo durante un período fenológico determinado.

Los indicadores deben ser:

- **Relevantes**: vinculados a procesos fisiológicos del cultivo.
- **Calculables**: a partir de datos disponibles.
- **Interpretables**: por técnicos, mejoradores y tomadores de decisiones.
- **Espacializables**: pueden expresarse como mapas.

---

## Clasificación de Indicadores

### Indicadores Térmicos

Resumen el régimen de temperatura y su relación con los requerimientos del cultivo.

| Indicador | Siglas | Descripción | Unidades |
|-----------|--------|-------------|----------|
| Grados-día de crecimiento | **GDD** | Acumulación de temperatura efectiva por encima de la temperatura base (Tb = 10 °C para frijol) | °C·día |
| Días con calor extremo en floración | **DTTF** | Número de días con Tmax > 35 °C durante la floración (R1–R2) | días |
| Temperatura nocturna en llenado | **TNnight** | Temperatura mínima media durante la fase de llenado de grano (R6–R7) | °C |
| Días con frío nocturno | **CFD** | Días con Tmin < 12 °C (riesgo de daño por frío) | días |
| Amplitud térmica | **DTR** | Diferencia diaria entre Tmax y Tmin | °C |

#### Fórmula de GDD

$$GDD = \sum_{i=1}^{n} \max\left(\frac{T_{max,i} + T_{min,i}}{2} - T_b,\; 0\right)$$

Donde:
- $T_{max,i}$ = temperatura máxima del día $i$
- $T_{min,i}$ = temperatura mínima del día $i$
- $T_b$ = temperatura base del cultivo (10 °C para frijol)
- $n$ = número de días en la ventana fenológica

---

### Indicadores Hídricos

Cuantifican la disponibilidad y déficit de agua en relación con las necesidades del cultivo.

| Indicador | Siglas | Descripción | Unidades |
|-----------|--------|-------------|----------|
| Evapotranspiración de referencia | **ET₀** | Demanda evaporativa de la atmósfera (método Penman-Monteith FAO 56) | mm/día |
| Evapotranspiración del cultivo | **ETc** | ET₀ × Kc (coeficiente de cultivo según fase fenológica) | mm/día |
| Déficit hídrico acumulado | **WHD** | Diferencia entre ETc y precipitación, acumulada en ventana fenológica | mm |
| Índice de Precipitación Estandarizado | **SPI** | Desviaciones estandarizadas de precipitación respecto a la media histórica | adimensional |
| Índice de Sequía Estandarizado | **SPEI** | Como SPI pero incorporando temperatura (demanda evaporativa) | adimensional |
| Días secos consecutivos | **CDD** | Número máximo de días consecutivos con precipitación < 1 mm | días |
| Fracción de agua disponible | **FAO** | Proporción del agua disponible en el suelo que no genera estrés (θ / θ_FC) | 0–1 |

#### Fórmula de ET₀ (Penman-Monteith simplificada)

$$ET_0 = \frac{0.408\,\Delta(R_n - G) + \gamma\,\frac{900}{T+273}\,u_2\,(e_s - e_a)}{\Delta + \gamma(1 + 0.34\,u_2)}$$

Donde:
- $R_n$ = radiación neta (MJ m⁻² día⁻¹)
- $G$ = flujo de calor del suelo (≈ 0 en escala diaria)
- $T$ = temperatura media del aire (°C)
- $u_2$ = velocidad del viento a 2 m (m s⁻¹)
- $e_s - e_a$ = déficit de presión de vapor (kPa)
- $\Delta$ = pendiente de la curva de presión de vapor de saturación
- $\gamma$ = constante psicrométrica

---

### Indicadores de Suelo–Agua

Combinan información edáfica con climática para estimar la disponibilidad real de agua para el cultivo.

| Indicador | Descripción |
|-----------|------------|
| **AWC** (Agua disponible en el suelo) | Diferencia entre capacidad de campo (θ_FC) y punto de marchitez permanente (θ_PWP), multiplied por la profundidad efectiva de raíces |
| **PAWC** | AWC ponderada por la profundidad de enraizamiento del frijol (típicamente 40–60 cm) |
| **Fracción de agotamiento (p)** | Para frijol, FAO-56 recomienda p = 0.45 (agotamiento crítico del agua disponible) |

---

## Coeficientes de Cultivo (Kc) del Frijol

Los valores de Kc (FAO-56, Allen et al. 1998) del frijol para el cálculo de ETc son:

| Fase | Duración (días) | Kc |
|------|-----------------|----|
| Establecimiento (ini) | 10–15 | 0.35 |
| Desarrollo (dev) | 25–30 | 0.35 → 1.15 |
| Mediados de ciclo (mid) | 25–35 | 1.15 |
| Madurez (late) | 10–20 | 0.25 – 0.35 |

---

## Umbrales de Estrés Relevantes para Frijol

| Tipo de estrés | Umbral crítico | Fase más sensible |
|----------------|---------------|-------------------|
| Calor diurno | Tmax > 35 °C | Floración (R1–R2) |
| Calor nocturno | Tmin > 20 °C | Floración y llenado |
| Frío | Tmin < 12 °C | Cualquier fase |
| Sequía moderada | FAD < 0.45 | Floración y llenado |
| Sequía severa | FAD < 0.25 | Cualquier fase |
| CDD | > 14 días consecutivos secos | Floración y llenado |

!!! tip "Interpretación del SPEI"
    Un SPEI < −1.0 indica sequía moderada; < −1.5, sequía severa; < −2.0, sequía extrema. Valores positivos indican condiciones húmedas por encima del promedio histórico.
