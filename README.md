# Construcción de tablas de vida para Baja California, 2010, 2019 y 2021

Proyecto final de Demografía Actuarial para la construcción de tablas de vida por sexo para el estado de **Baja California** en los años **2010, 2019 y 2021**.

El objetivo principal es estimar indicadores de mortalidad como tasas específicas de mortalidad, probabilidades de muerte, sobrevivientes, defunciones de la tabla, años-persona vividos y esperanza de vida al nacer.

El análisis compara tres momentos:

- **2010**, como año base.
- **2019**, como año previo a la pandemia.
- **2021**, como año de análisis del impacto de la COVID-19.

## Integrantes

- Jaimes Porras Damariz
- Nava Badillo Yessica Isabel

## Descripción general del proyecto

El proyecto se plantea como un informe actuarial en el que se documenta paso a paso el procedimiento para construir tablas de vida para Baja California.

El trabajo incluye:

1. Contexto demográfico de Baja California.
2. Limpieza y organización de datos de población y defunciones.
3. Estimación de población expuesta al riesgo.
4. Cálculo de tasas específicas de mortalidad.
5. Conversión de tasas de mortalidad a probabilidades de muerte.
6. Construcción de tablas de vida.
7. Cálculo de esperanza de vida al nacer por sexo y año.
8. Elaboración de gráficas.
9. Análisis del impacto de la COVID-19 en 2021.

## Estructura del repositorio

```text
Demography_9219/
│
├── README.md
├── DEMOPROYECTO.qmd
├── DEMOPROYECTO.pdf
├── Demography_9219.Rproj
├── .gitignore
│
├── data/
│   └── Bases originales o bases de entrada
│
├── script/
│   └── Scripts de limpieza, cálculo y gráficas
│
├── output/
│   └── Bases limpias y resultados generados
│
└── Imagenes/
    └── Gráficas y diagrama de flujo
```

## Carpetas del proyecto

### `data/`

Contiene las bases originales o de entrada utilizadas para el análisis. En esta carpeta se guardan los datos de población y defunciones antes de ser procesados.

### `script/`

Contiene los códigos en R utilizados para limpiar datos, calcular población expuesta al riesgo, construir las tablas de vida y generar gráficas.

La organización esperada de los scripts es:

```text
script/
├── 00_librerias.R
├── 01_limpieza_poblacion.R
├── 02_limpieza_defunciones.R
├── 03_apv_crecimiento_exponencial.R
├── 04_tablas_vida.R
├── 05_graficas.R
└── funciones_tabla_vida.R
```

### `output/`

Contiene las bases limpias y resultados generados por los scripts. Aquí se guardarán archivos como:

```text
output/
├── poblacion_bc_limpia.csv
├── defunciones_bc_limpia.csv
├── apv_bc.csv
├── lt_input_bc.csv
├── tablas_vida_bc.csv
└── esperanza_vida_bc.csv
```

### `Imagenes/`

Contiene las gráficas utilizadas en el informe final, así como el diagrama de flujo del proceso.

Ejemplos de archivos esperados:

```text
Imagenes/
├── diagrama_flujo.png
├── piramide_2010.png
├── piramide_2019.png
├── piramide_2021.png
├── mx_bc.png
├── qx_bc.png
├── lx_bc.png
└── esperanza_vida_bc.png
```

## Metodología general

El procedimiento general para construir las tablas de vida es el siguiente:

1. Se organizan las bases de población y defunciones.
2. Se limpian las variables de edad, sexo, año y entidad.
3. Se estima la población expuesta al riesgo.
4. Se calculan las tasas específicas de mortalidad por edad y sexo.
5. Se convierten las tasas de mortalidad en probabilidades de muerte.
6. Se construyen las funciones de la tabla de vida.
7. Se obtiene la esperanza de vida al nacer.
8. Se comparan los resultados entre 2010, 2019 y 2021.
9. Se analiza el impacto de la COVID-19 sobre la mortalidad en 2021.

## Fórmulas principales

La tasa específica de mortalidad se calcula como:

```text
mx = Dx / Ex
```

donde:

- `Dx` representa las defunciones observadas.
- `Ex` representa la población expuesta al riesgo.

La tabla de vida parte de una raíz:

```text
l0 = 100000
```

A partir de esta raíz se calculan las funciones:

```text
dx = lx * qx
lx+n = lx - dx
Lx = n * lx+n + ax * dx
Tx = suma de Lx desde la edad x hasta la última edad
ex = Tx / lx
```

## Archivos principales

### `DEMOPROYECTO.qmd`

Archivo principal del informe en Quarto. Contiene el texto, las fórmulas, el código y la estructura del reporte.

### `DEMOPROYECTO.pdf`

Archivo final generado a partir del documento Quarto.

### `Demography_9219.Rproj`

Archivo del proyecto de RStudio. Se recomienda abrir este archivo antes de trabajar, para que las rutas relativas funcionen correctamente.

## Cómo replicar el proyecto

Para replicar el proyecto:

1. Abrir el archivo `Demography_9219.Rproj` en RStudio.
2. Verificar que las carpetas `data/`, `script/`, `output/` e `Imagenes/` estén disponibles.
3. Ejecutar los scripts de la carpeta `script/` en orden.
4. Abrir el archivo `DEMOPROYECTO.qmd`.
5. Renderizar el documento en formato PDF.

El orden esperado de ejecución será:

```r
source("script/00_librerias.R")
source("script/01_limpieza_poblacion.R")
source("script/02_limpieza_defunciones.R")
source("script/03_apv_crecimiento_exponencial.R")
source("script/04_tablas_vida.R")
source("script/05_graficas.R")
```

## Resultados esperados

El proyecto generará:

- Tablas de vida por sexo para 2010, 2019 y 2021.
- Cuadro de esperanza de vida al nacer por sexo y año.
- Gráficas de mortalidad por edad.
- Gráficas de probabilidades de muerte.
- Gráficas de sobrevivientes.
- Análisis del impacto de la COVID-19 en 2021.

## Notas de reproducibilidad

Para asegurar que el proyecto sea replicable:

- Se utilizan rutas relativas.
- Los datos originales se conservan en `data/`.
- Las bases procesadas se guardan en `output/`.
- Las gráficas se guardan en `Imagenes/`.
- El informe final se genera desde `DEMOPROYECTO.qmd`.

## Referencias

- CONAPO. Proyecciones de la población de México y de las entidades federativas.
- INEGI. Censo de Población y Vivienda.
- INEGI. Estadísticas de defunciones registradas.
- Notas de clase de Demografía.