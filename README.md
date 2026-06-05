# 📊 Tablas de vida y fecundidad para Baja California

## Mortalidad, causa eliminada por homicidios e indicadores de fecundidad

Este repositorio contiene el proyecto final de Demografía para la construcción y análisis de **tablas de vida de Baja California** en los años **2010, 2019 y 2021**, separadas por sexo, además del cálculo de indicadores de fecundidad y una tabla de vida de causa eliminada por homicidios para 2019.

El proyecto está organizado para que todos los resultados sean **replicables**: se incluyen bases originales, bases limpias, scripts, gráficas, archivos Excel de salida, informe final en Quarto/PDF y este README.

---

## 👩‍💻 Integrantes

* Jaimes Porras Damariz
* Nava Badillo Yessica Isabel

---

## 📍 Entidad federativa analizada

La entidad analizada es **Baja California**, ubicada en el noroeste de México.

Su contexto demográfico es relevante porque presenta:

* Condición fronteriza con Estados Unidos.
* Alta movilidad poblacional.
* Concentración urbana en Tijuana, Mexicali y Ensenada.
* Presencia importante de población en edades laborales.
* Exposición diferenciada a causas externas, especialmente homicidios.
* Cambios recientes en fecundidad y mortalidad asociados a dinámicas sociales, económicas y sanitarias.

---

## 🎯 Objetivo general

Construir y analizar tablas de vida para Baja California en 2010, 2019 y 2021 por sexo, así como estimar indicadores de fecundidad y evaluar el impacto de eliminar hipotéticamente los homicidios en la mortalidad de 2019.

---

## ✅ Objetivos específicos

* Construir tablas de vida por sexo para 2010, 2019 y 2021.
* Calcular tasas específicas de mortalidad, probabilidades de muerte y esperanza de vida al nacer.
* Estimar población expuesta al riesgo mediante crecimiento exponencial con información censal de INEGI.
* Construir una tabla de vida de 2019 con causa eliminada por homicidios.
* Calcular TEFE, TGF, TBR y TNR para Baja California en 2010 y 2019.
* Comparar las curvas de TEFE de Baja California, México y Japón para 2019.
* Documentar el procedimiento completo en un informe reproducible hecho en Quarto.
* Generar archivos Excel finales para facilitar la revisión de cálculos.

---

## 📚 Fuentes de información

El proyecto utiliza fuentes oficiales nacionales e internacionales:

### 🇲🇽 INEGI

* Censo de Población y Vivienda 2010.
* Censo de Población y Vivienda 2020.
* Estadísticas de Defunciones Registradas.
* Defunciones por homicidios.
* Estadísticas de Natalidad: nacimientos registrados.

### 🌎 Naciones Unidas

* World Population Prospects 2024.
* Tasas específicas de fecundidad por grupos quinquenales de edad para México y Japón.

---

## 🧮 Metodología general

El proyecto se divide en tres bloques principales:

### 1. Mortalidad general

Se construyeron tablas de vida para Baja California en 2010, 2019 y 2021 por sexo.

El procedimiento fue:

1. Limpiar población de INEGI 2010 y 2020.
2. Estimar población expuesta al riesgo mediante crecimiento exponencial.
3. Limpiar defunciones registradas por edad, sexo y año.
4. Calcular tasas específicas de mortalidad.
5. Convertir tasas de mortalidad en probabilidades de muerte.
6. Construir las funciones de la tabla de vida:

   * `mx`
   * `qx`
   * `ax`
   * `lx`
   * `dx`
   * `Lx`
   * `Tx`
   * `ex`
7. Obtener la esperanza de vida al nacer.

### 2. Causa eliminada: homicidios

Para 2019 se construyó una tabla de vida bajo un escenario hipotético en el que se eliminan los homicidios.

El procedimiento fue:

1. Descargar homicidios ocurridos en 2019 en Baja California por edad y sexo.
2. Restar homicidios a las defunciones totales observadas.
3. Recalcular tasas específicas de mortalidad.
4. Reconstruir la tabla de vida.
5. Comparar esperanza de vida y probabilidades de muerte observadas vs. sin homicidios.

### 3. Fecundidad

Se calcularon indicadores de fecundidad para Baja California en 2010 y 2019:

* TEFE: Tasas Específicas de Fecundidad.
* TGF: Tasa Global de Fecundidad.
* TBR: Tasa Bruta de Reproducción.
* TNR: Tasa Neta de Reproducción.

Además, se compararon las curvas de TEFE 2019 de:

* Baja California.
* México.
* Japón.

---

## 📐 Fórmulas principales

### Tasa específica de mortalidad

```math
m_x = \frac{D_x}{E_x}
```

### Crecimiento exponencial

```math
r_x = \frac{\ln(P_x(t_2))-\ln(P_x(t_1))}{t_2-t_1}
```

```math
\widehat{P}_x(t)=P_x(t_1)e^{r_x(t-t_1)}
```

### Probabilidad de muerte

```math
{}_nq_x = \frac{n \cdot {}_nm_x}{1+(n-{}_na_x){}_nm_x}
```

### Funciones de tabla de vida

```math
l_0 = 100000
```

```math
d_x = l_xq_x
```

```math
l_{x+n}=l_x-d_x
```

```math
L_x = nl_{x+n}+a_xd_x
```

```math
T_x = \sum_{y \geq x}L_y
```

```math
e_x = \frac{T_x}{l_x}
```

### Fecundidad

```math
{}_5f_x = \frac{B_x}{M_x}
```

```math
TGF = 5\sum {}_5f_x
```

```math
K = \frac{100}{205}=0.4878
```

```math
TBR = TGF \cdot K
```

```math
TNR = 5K\sum {}_5f_x \cdot {}_{x+2.5}p_0^f
```

---

## 📈 Resultados principales

### Esperanza de vida al nacer

|  Año | Hombres | Mujeres |
| ---: | ------: | ------: |
| 2010 |   69.70 |   77.46 |
| 2019 |   70.71 |   79.04 |
| 2021 |   67.35 |   76.43 |

Entre 2010 y 2019 se observa una mejora en la esperanza de vida. En 2021 se identifica una caída asociada al aumento de mortalidad durante la pandemia de COVID-19.

---

## ⚰️ Causa eliminada: homicidios 2019

| Sexo    | Escenario      |    e0 |
| ------- | -------------- | ----: |
| Hombres | Observada      | 70.71 |
| Hombres | Sin homicidios | 73.06 |
| Mujeres | Observada      | 79.04 |
| Mujeres | Sin homicidios | 79.35 |

La eliminación hipotética de homicidios aumenta la esperanza de vida masculina en aproximadamente **2.35 años**, mientras que en mujeres el aumento es de aproximadamente **0.31 años**. Esto muestra que los homicidios tienen un impacto mucho más fuerte en la mortalidad masculina.

---

## 👶 Indicadores de fecundidad

|  Año |   TGF |   TBR |   TNR |
| ---: | ----: | ----: | ----: |
| 2010 | 2.140 | 1.044 | 1.016 |
| 2019 | 1.559 | 0.761 | 0.743 |

Baja California pasó de una fecundidad cercana al reemplazo en 2010 a una fecundidad claramente por debajo del reemplazo en 2019.

---

## 🌏 Comparación TEFE 2019

La comparación entre Baja California, México y Japón muestra diferencias importantes en el calendario reproductivo:

* México presenta tasas más altas que Baja California en casi todos los grupos de edad.
* Baja California conserva un patrón similar al nacional, pero con menor nivel de fecundidad.
* Japón presenta fecundidad muy baja en edades adolescentes y concentra su máximo en el grupo 30-34 años.

---

## 🗂️ Estructura del repositorio

```text
Demography_9219/
│
├── README.md
├── DEMOPROYECTO.qmd
├── DEMOPROYECTO.pdf
├── Demography_9219.Rproj
│
├── data/
│   ├── raw/
│   │   ├── defunciones.xlsx
│   │   ├── inegi_poblacion_2010.xlsx
│   │   ├── inegi_poblacion_2020.xlsx
│   │   ├── homicidios/
│   │   │   └── homicidios_2019_bc.xlsx
│   │   └── fecundidad/
│   │       ├── nacimientos_bc_2010.xlsx
│   │       ├── nacimientos_bc_2019.xlsx
│   │       ├── nacimientos_mexico_2019.xlsx
│   │       └── tefe_japon_2019.xlsx
│   │
│   └── clean/
│       ├── poblacion_bc.csv
│       ├── defunciones_bc.csv
│       ├── lt_input_bc.csv
│       ├── tabla_vida_bc.csv
│       ├── esperanza_vida_bc.csv
│       ├── homicidios/
│       └── fecundidad/
│
├── scripts/
│   ├── 01_limpieza_poblacion.R
│   ├── 02_limpieza_defunciones.R
│   ├── 03_union_apv_mx.R
│   ├── 04_tablas_vida.R
│   ├── 05_graficas.R
│   ├── 06_causa_eliminada_homicidios.R
│   ├── 07_fecundidad_bc.R
│   ├── 08_fecundidad_comparativa.R
│   └── 09_exportar_excel_final.R
│
├── images/
│   ├── diagrama_flujo_final.png
│   ├── e0_bc.png
│   ├── mx_bc.png
│   ├── qx_bc.png
│   ├── lx_bc.png
│   ├── impacto_covid_mx_bc.png
│   ├── e0_causa_eliminada.png
│   ├── qx_causa_eliminada.png
│   ├── tefe_bc_2010_2019.png
│   ├── tgf_tbr_tnr_bc.png
│   └── tefe_comparativa_2019.png
│
├── output/
│   ├── tasas_mortalidad_y_tablas_vida_bc.xlsx
│   ├── tabla_vida_2019_causa_eliminada_homicidios.xlsx
│   ├── fecundidad_bc.xlsx
│   └── fecundidad_comparativa_2019.xlsx
│
└── Imagenes/
    └── logo.png
```

---

## 🧾 Archivos principales

* `DEMOPROYECTO.qmd`: informe principal en Quarto.
* `DEMOPROYECTO.pdf`: informe final.
* `README.md`: descripción general del proyecto.
* `scripts/`: código utilizado para limpiar datos, calcular indicadores y generar gráficas.
* `data/raw/`: bases originales.
* `data/clean/`: bases procesadas.
* `images/`: gráficas y diagrama de flujo.
* `output/`: archivos Excel finales.

---

## ⚙️ Scripts utilizados

| Script                            | Descripción                                                      |
| --------------------------------- | ---------------------------------------------------------------- |
| `01_limpieza_poblacion.R`         | Limpia población de INEGI y estima población expuesta al riesgo. |
| `02_limpieza_defunciones.R`       | Limpia defunciones generales por edad y sexo.                    |
| `03_union_apv_mx.R`               | Une población y defunciones para calcular tasas de mortalidad.   |
| `04_tablas_vida.R`                | Construye las tablas de vida generales.                          |
| `05_graficas.R`                   | Genera gráficas principales de mortalidad.                       |
| `06_causa_eliminada_homicidios.R` | Construye tabla de vida 2019 sin homicidios.                     |
| `07_fecundidad_bc.R`              | Calcula TEFE, TGF, TBR y TNR para Baja California.               |
| `08_fecundidad_comparativa.R`     | Compara TEFE 2019 de Baja California, México y Japón.            |
| `09_exportar_excel_final.R`       | Exporta Excel final de mortalidad y tablas de vida.              |

---

## ▶️ Cómo reproducir el proyecto

Abrir el archivo:

```text
Demography_9219.Rproj
```

en RStudio.

Después ejecutar:

```r
source("scripts/01_limpieza_poblacion.R")
source("scripts/02_limpieza_defunciones.R")
source("scripts/03_union_apv_mx.R")
source("scripts/04_tablas_vida.R")
source("scripts/05_graficas.R")
source("scripts/06_causa_eliminada_homicidios.R")
source("scripts/07_fecundidad_bc.R")
source("scripts/08_fecundidad_comparativa.R")
source("scripts/09_exportar_excel_final.R")
```

Finalmente, renderizar el informe:

```r
quarto::quarto_render("DEMOPROYECTO.qmd")
```

---

## 📦 Salidas generadas

El proyecto genera:

* Tablas de vida generales.
* Esperanzas de vida al nacer.
* Tasas específicas de mortalidad.
* Tabla de vida 2019 sin homicidios.
* Indicadores de fecundidad.
* Curvas TEFE comparativas.
* Gráficas finales.
* Archivos Excel en `output/`.
* Informe final en PDF.

---

## 📌 Referencias

* Instituto Nacional de Estadística y Geografía (INEGI). Censo de Población y Vivienda 2010.
* Instituto Nacional de Estadística y Geografía (INEGI). Censo de Población y Vivienda 2020.
* Instituto Nacional de Estadística y Geografía (INEGI). Estadísticas de Defunciones Registradas.
* Instituto Nacional de Estadística y Geografía (INEGI). Defunciones por homicidios.
* Instituto Nacional de Estadística y Geografía (INEGI). Estadísticas de Natalidad. Nacimientos registrados.
* United Nations, Department of Economic and Social Affairs, Population Division. World Population Prospects 2024.
* Ortega, A. (1987). Tablas de mortalidad. Centro Latinoamericano de Demografía.
* Preston, S. H., Heuveline, P., & Guillot, M. (2001). Demography: Measuring and Modeling Population Processes.
* Notas de clase de Demografía.