# Construcción de tablas de vida para Baja California, 2010, 2019 y 2021

## Descripción del proyecto

Este repositorio contiene el proyecto final de Demografía, cuyo objetivo es construir tablas de vida para el estado de **Baja California** en los años **2010, 2019 y 2021**, separadas por sexo.

El trabajo se plantea como un informe para una firma actuarial. Por esta razón, no solo se presentan los resultados finales, sino también el procedimiento completo utilizado para obtenerlos: limpieza de datos, estimación de población expuesta al riesgo, cálculo de tasas de mortalidad, construcción de tablas de vida, elaboración de gráficas e interpretación de resultados.

El análisis compara tres momentos importantes:

- **2010:** año base de comparación.
- **2019:** año previo a la pandemia de COVID-19.
- **2021:** año que permite observar el impacto de la pandemia sobre la mortalidad y la esperanza de vida.

## Integrantes

- Jaimes Porras Damariz
- Nava Badillo Yessica Isabel

## Entidad analizada

La entidad federativa analizada es **Baja California**.

Se eligió esta entidad porque tiene características demográficas relevantes para el estudio de la mortalidad, entre ellas:

- Condición fronteriza con Estados Unidos.
- Alta movilidad poblacional.
- Concentración urbana en municipios como Tijuana, Mexicali y Ensenada.
- Presencia importante de población en edades laborales.
- Posible impacto diferenciado de causas externas y COVID-19 sobre la mortalidad por sexo y edad.

## Objetivo general

Construir y analizar tablas de vida para Baja California en 2010, 2019 y 2021 por sexo, con énfasis en la evolución de la esperanza de vida al nacer y el impacto de la COVID-19 en 2021.

## Objetivos específicos

- Organizar y limpiar la información de población y defunciones.
- Estimar la población expuesta al riesgo mediante crecimiento exponencial.
- Calcular tasas específicas de mortalidad por edad y sexo.
- Convertir las tasas de mortalidad en probabilidades de muerte.
- Construir tablas de vida para hombres y mujeres.
- Obtener la esperanza de vida al nacer para cada año y sexo.
- Elaborar gráficas de mortalidad, sobrevivencia y esperanza de vida.
- Analizar los cambios observados entre 2010, 2019 y 2021.

## Fuentes de información

Para el proyecto se utilizaron fuentes de información de **INEGI**.

### Población

La población se obtuvo de los tabulados del:

- **Censo de Población y Vivienda 2010**.
- **Censo de Población y Vivienda 2020**.

Como no existe un censo para 2019 ni para 2021, se estimó la población expuesta al riesgo mediante crecimiento exponencial por edad y sexo.

### Defunciones

Las defunciones se obtuvieron de las **Estadísticas de defunciones registradas** de INEGI.

Para la construcción de las tablas se trabajó con defunciones por:

- Año.
- Sexo.
- Edad.

Las edades se organizaron de la siguiente manera:

- Edades abiertas: 0, 1, 2, 3 y 4 años.
- Grupos quinquenales: 5-9, 10-14, ..., 80-84.
- Grupo abierto: 85 años y más.

## Metodología general

El proceso de construcción de las tablas de vida se resume en los siguientes pasos:

1. Descargar y organizar los datos originales de INEGI.
2. Limpiar la población de los censos 2010 y 2020.
3. Estimar la población expuesta al riesgo para 2010, 2019 y 2021 mediante crecimiento exponencial.
4. Limpiar las defunciones registradas por edad, sexo y año.
5. Agrupar edades de forma compatible entre población y defunciones.
6. Calcular tasas específicas de mortalidad.
7. Convertir tasas específicas de mortalidad en probabilidades de muerte.
8. Construir las funciones de la tabla de vida:
   - `mx`
   - `qx`
   - `ax`
   - `lx`
   - `dx`
   - `Lx`
   - `Tx`
   - `ex`
9. Obtener la esperanza de vida al nacer.
10. Elaborar gráficas e interpretar resultados.
11. Analizar el impacto de la COVID-19 en 2021.

## Estructura del repositorio

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
│   │   └── inegi_poblacion_2020.xlsx
│   │
│   └── clean/
│       ├── poblacion_bc.csv
│       ├── defunciones_bc.csv
│       ├── lt_input_bc.csv
│       ├── tabla_vida_bc.csv
│       └── esperanza_vida_bc.csv
│
├── scripts/
│   ├── 01_limpieza_poblacion.R
│   ├── 02_limpieza_defunciones.R
│   ├── 03_union_apv_mx.R
│   ├── 04_tablas_vida.R
│   └── 05_graficas.R
│
├── graficas/
│   ├── e0_bc.png
│   ├── mx_bc.png
│   ├── qx_bc.png
│   ├── lx_bc.png
│   └── impacto_covid_mx_bc.png
│
└── Imagenes/
    └── logo.png