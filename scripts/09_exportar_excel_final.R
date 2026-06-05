# ============================================================
# 09_exportar_excel_final.R
# Exporta archivo Excel final de mortalidad y tablas de vida
# ============================================================

library(data.table)
library(dplyr)
library(openxlsx)

dir.create("output", showWarnings = FALSE)

lt_input_bc <- fread("data/clean/lt_input_bc.csv")
tabla_vida_bc <- fread("data/clean/tabla_vida_bc.csv")
esperanza_vida_bc <- fread("data/clean/esperanza_vida_bc.csv")

resumen_mortalidad <- lt_input_bc %>%
  group_by(year, sex) %>%
  summarise(
    defunciones_totales = sum(deaths, na.rm = TRUE),
    poblacion_total = sum(pop, na.rm = TRUE),
    mx_general = defunciones_totales / poblacion_total,
    .groups = "drop"
  )

validacion_tabla <- tabla_vida_bc %>%
  group_by(year, sex) %>%
  summarise(
    qx_min = min(qx, na.rm = TRUE),
    qx_max = max(qx, na.rm = TRUE),
    lx_inicial = first(lx),
    lx_final = last(lx),
    dx_min = min(dx, na.rm = TRUE),
    Tx_min = min(Tx, na.rm = TRUE),
    Tx_max = max(Tx, na.rm = TRUE),
    e0 = first(ex),
    .groups = "drop"
  )

wb <- createWorkbook()

addWorksheet(wb, "tasas_mortalidad")
writeData(wb, "tasas_mortalidad", lt_input_bc)

addWorksheet(wb, "tabla_vida_completa")
writeData(wb, "tabla_vida_completa", tabla_vida_bc)

addWorksheet(wb, "esperanza_vida")
writeData(wb, "esperanza_vida", esperanza_vida_bc)

addWorksheet(wb, "resumen_mortalidad")
writeData(wb, "resumen_mortalidad", resumen_mortalidad)

addWorksheet(wb, "validacion")
writeData(wb, "validacion", validacion_tabla)

addWorksheet(wb, "formulas")
formulas <- data.frame(
  Concepto = c(
    "Tasa específica de mortalidad",
    "Probabilidad de muerte",
    "Raíz de la tabla",
    "Defunciones de la tabla",
    "Sobrevivientes",
    "Años-persona vividos",
    "Total de años-persona por vivir",
    "Esperanza de vida"
  ),
  Formula = c(
    "mx = Dx / Ex",
    "qx = (n * mx) / (1 + (n - ax) * mx)",
    "l0 = 100000",
    "dx = lx * qx",
    "l_{x+n} = lx - dx",
    "Lx = n * l_{x+n} + ax * dx",
    "Tx = suma de Ly desde y >= x",
    "ex = Tx / lx"
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
  "output/tasas_mortalidad_y_tablas_vida_bc.xlsx",
  overwrite = TRUE
)

cat("\nArchivo creado correctamente:\n")
cat("- output/tasas_mortalidad_y_tablas_vida_bc.xlsx\n")