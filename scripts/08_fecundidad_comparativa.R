# ============================================================
# 08_fecundidad_comparativa.R
# Comparación de Tasas Específicas de Fecundidad, 2019
#
# Territorios:
# - Baja California
# - México
# - Japón
#
# Fuentes:
# Baja California: elaboración propia con nacimientos INEGI
# México y Japón: World Population Prospects 2024
#
# Salidas:
# data/clean/fecundidad/tefe_comparativa_2019.csv
# output/fecundidad_comparativa_2019.xlsx
# images/tefe_comparativa_2019.png
# ============================================================

# ------------------------------------------------------------
# 0. Paquetes
# ------------------------------------------------------------

paquetes_necesarios <- c(
  "readxl", "dplyr", "tidyr", "stringr",
  "data.table", "ggplot2", "scales", "openxlsx"
)

paquetes_faltantes <- paquetes_necesarios[
  !paquetes_necesarios %in% rownames(installed.packages())
]

if (length(paquetes_faltantes) > 0) {
  install.packages(paquetes_faltantes)
}

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(data.table)
library(ggplot2)
library(scales)
library(openxlsx)

# ------------------------------------------------------------
# 1. Crear carpetas
# ------------------------------------------------------------

dir.create("data/raw/fecundidad", recursive = TRUE, showWarnings = FALSE)
dir.create("data/clean/fecundidad", recursive = TRUE, showWarnings = FALSE)
dir.create("output", recursive = TRUE, showWarnings = FALSE)
dir.create("images", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# 2. Descargar archivo WPP si no existe
# ------------------------------------------------------------

url_wpp <- "https://population.un.org/wpp/assets/Excel%20Files/1_Indicator%20(Standard)/EXCEL_FILES/3_Fertility/WPP2024_FERT_F02_FERTILITY_RATES_BY_5-YEAR_AGE_GROUPS_OF_MOTHER.xlsx"

ruta_wpp <- "data/raw/fecundidad/tefe_japon_2019.xlsx"

if (!file.exists(ruta_wpp)) {
  download.file(
    url = url_wpp,
    destfile = ruta_wpp,
    mode = "wb"
  )
}

# ------------------------------------------------------------
# 3. Leer Baja California 2019
# ------------------------------------------------------------

fecundidad_bc <- fread("data/clean/fecundidad/fecundidad_bc.csv")

bc_2019 <- fecundidad_bc %>%
  filter(year == 2019) %>%
  transmute(
    grupo_edad,
    TEFE_1000 = TEFE_1000,
    territorio = "Baja California",
    year = 2019
  )

# ------------------------------------------------------------
# 4. Leer WPP 2024 para México y Japón
# ------------------------------------------------------------
# En el archivo WPP:
# - Encabezados reales en fila 17
# - Por eso usamos skip = 16
# ------------------------------------------------------------

wpp_raw <- read_excel(
  ruta_wpp,
  sheet = "Estimates",
  skip = 16
)

# ------------------------------------------------------------
# 5. Función para extraer TEFE de un país
# ------------------------------------------------------------

extraer_tefe_wpp <- function(base, pais, nombre_salida) {
  
  tefe <- base %>%
    filter(
      `Region, subregion, country or area *` == pais,
      Year == 2019
    ) %>%
    select(
      `15-19`,
      `20-24`,
      `25-29`,
      `30-34`,
      `35-39`,
      `40-44`,
      `45-49`
    ) %>%
    pivot_longer(
      cols = everything(),
      names_to = "grupo_edad",
      values_to = "TEFE"
    ) %>%
    mutate(
      TEFE = as.numeric(TEFE)
    )
  
  multiplicador <- if (max(tefe$TEFE, na.rm = TRUE) < 1) {
    1000
  } else {
    1
  }
  
  tefe <- tefe %>%
    mutate(
      TEFE_1000 = TEFE * multiplicador,
      territorio = nombre_salida,
      year = 2019
    ) %>%
    select(grupo_edad, TEFE_1000, territorio, year)
  
  return(tefe)
}

mexico_2019 <- extraer_tefe_wpp(
  base = wpp_raw,
  pais = "Mexico",
  nombre_salida = "México"
)

japon_2019 <- extraer_tefe_wpp(
  base = wpp_raw,
  pais = "Japan",
  nombre_salida = "Japón"
)

# ------------------------------------------------------------
# 6. Unir los tres territorios
# ------------------------------------------------------------

niveles_edad <- c(
  "15-19", "20-24", "25-29", "30-34",
  "35-39", "40-44", "45-49"
)

tefe_comparativa_2019 <- bind_rows(
  bc_2019,
  mexico_2019,
  japon_2019
) %>%
  mutate(
    grupo_edad = factor(grupo_edad, levels = niveles_edad),
    territorio = factor(
      territorio,
      levels = c("Baja California", "México", "Japón")
    ),
    TEFE_1000 = round(TEFE_1000, 3)
  ) %>%
  arrange(territorio, grupo_edad)

cat("\nTEFE comparativa 2019:\n")
print(tefe_comparativa_2019)

# ------------------------------------------------------------
# 7. Guardar base limpia
# ------------------------------------------------------------

fwrite(
  tefe_comparativa_2019,
  "data/clean/fecundidad/tefe_comparativa_2019.csv"
)

# ------------------------------------------------------------
# 8. Gráfica comparativa
# ------------------------------------------------------------

g_tefe_comp <- ggplot(
  tefe_comparativa_2019,
  aes(
    x = grupo_edad,
    y = TEFE_1000,
    color = territorio,
    group = territorio
  )
) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.4) +
  labs(
    title = "Tasas específicas de fecundidad por edad",
    subtitle = "Baja California, México y Japón, 2019",
    x = "Grupo de edad de la madre",
    y = "Nacimientos por cada 1,000 mujeres",
    color = "Territorio",
    caption = "Fuente: elaboración propia con datos de INEGI y World Population Prospects 2024."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 0)
  )

ggsave(
  filename = "images/tefe_comparativa_2019.png",
  plot = g_tefe_comp,
  width = 9,
  height = 5.5,
  dpi = 300
)

# ------------------------------------------------------------
# 9. Exportar Excel comparativo
# ------------------------------------------------------------

wb <- createWorkbook()

addWorksheet(wb, "tefe_comparativa_2019")
writeData(wb, "tefe_comparativa_2019", tefe_comparativa_2019)

addWorksheet(wb, "fuentes")
fuentes <- data.frame(
  Territorio = c("Baja California", "México", "Japón"),
  Fuente = c(
    "Cálculo propio con nacimientos registrados de INEGI y población femenina estimada para Baja California.",
    "World Population Prospects 2024, archivo de ASFR por grupos quinquenales.",
    "World Population Prospects 2024, archivo de ASFR por grupos quinquenales."
  )
)
writeData(wb, "fuentes", fuentes)

addWorksheet(wb, "formulas")
formulas <- data.frame(
  Concepto = c(
    "TEFE",
    "TEFE por cada 1,000 mujeres",
    "Grupos de edad usados"
  ),
  Formula = c(
    "TEFE_x = nacimientos_x / mujeres_x",
    "TEFE_1000 = TEFE_x * 1000",
    "15-19, 20-24, 25-29, 30-34, 35-39, 40-44, 45-49"
  )
)
writeData(wb, "formulas", formulas)

estilo_encabezado <- createStyle(
  textDecoration = "bold",
  fgFill = "#D9EAF7",
  border = "Bottom"
)

for (hoja in names(wb)) {
  addStyle(
    wb,
    sheet = hoja,
    style = estilo_encabezado,
    rows = 1,
    cols = 1:50,
    gridExpand = TRUE
  )
  freezePane(wb, sheet = hoja, firstRow = TRUE)
  setColWidths(wb, sheet = hoja, cols = 1:50, widths = "auto")
}

saveWorkbook(
  wb,
  "output/fecundidad_comparativa_2019.xlsx",
  overwrite = TRUE
)

# ------------------------------------------------------------
# 10. Revisión final
# ------------------------------------------------------------

cat("\nArchivos creados correctamente:\n")
cat("- data/clean/fecundidad/tefe_comparativa_2019.csv\n")
cat("- output/fecundidad_comparativa_2019.xlsx\n")
cat("- images/tefe_comparativa_2019.png\n")



