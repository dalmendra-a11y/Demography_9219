# ============================================================
# 03_union_apv_mx.R
# Unión de población expuesta al riesgo y defunciones
# Cálculo de tasas específicas de mortalidad mx
# Baja California, 2010, 2019 y 2021
# ============================================================

# ------------------------------------------------------------
# 0. Paquetes
# ------------------------------------------------------------

library(data.table)
library(dplyr)
library(tidyr)

# ------------------------------------------------------------
# 1. Leer bases limpias
# ------------------------------------------------------------

poblacion_bc <- fread("data/clean/poblacion_bc.csv")
defunciones_bc <- fread("data/clean/defunciones_bc.csv")

# ------------------------------------------------------------
# 2. Revisar estructura
# ------------------------------------------------------------

cat("\nRevisión de población:\n")
print(
  poblacion_bc %>%
    group_by(year, sex) %>%
    summarise(
      edad_min = min(age),
      edad_max = max(age),
      numero_edades = n(),
      poblacion_total = sum(pop),
      .groups = "drop"
    )
)

cat("\nRevisión de defunciones:\n")
print(
  defunciones_bc %>%
    group_by(year, sex) %>%
    summarise(
      edad_min = min(age),
      edad_max = max(age),
      numero_edades = n(),
      total_defunciones = sum(deaths),
      .groups = "drop"
    )
)

# ------------------------------------------------------------
# 3. Unir población y defunciones
# ------------------------------------------------------------
# La unión se hace por:
# year = año
# sex  = sexo
# age  = edad o grupo de edad
# n    = amplitud del intervalo
# ------------------------------------------------------------

lt_input_bc <- poblacion_bc %>%
  left_join(
    defunciones_bc,
    by = c("year", "sex", "age", "n")
  )

# ------------------------------------------------------------
# 4. Revisar si quedaron valores faltantes
# ------------------------------------------------------------

faltantes <- lt_input_bc %>%
  filter(is.na(pop) | is.na(deaths))

if (nrow(faltantes) > 0) {
  cat("\nCuidado: hay filas con población o defunciones faltantes:\n")
  print(faltantes)
  stop("La unión no quedó completa. Revisa población y defunciones.")
}

# ------------------------------------------------------------
# 5. Calcular tasa específica de mortalidad mx
# ------------------------------------------------------------
# Fórmula:
# mx = deaths / pop
# ------------------------------------------------------------

lt_input_bc <- lt_input_bc %>%
  mutate(
    mx = deaths / pop
  ) %>%
  arrange(year, sex, age)

# ------------------------------------------------------------
# 6. Validaciones básicas
# ------------------------------------------------------------

if (any(lt_input_bc$mx < 0, na.rm = TRUE)) {
  stop("Hay tasas mx negativas. Revisar datos.")
}

if (any(is.na(lt_input_bc$mx))) {
  stop("Hay tasas mx faltantes. Revisar datos.")
}

# ------------------------------------------------------------
# 7. Guardar base lista para tabla de vida
# ------------------------------------------------------------

fwrite(lt_input_bc, "data/clean/lt_input_bc.csv")

# ------------------------------------------------------------
# 8. Revisión final
# ------------------------------------------------------------

cat("\nBase lista para construir tablas de vida:\n")
print(lt_input_bc)

cat("\nResumen de mx por año y sexo:\n")

resumen_mx <- lt_input_bc %>%
  group_by(year, sex) %>%
  summarise(
    edad_min = min(age),
    edad_max = max(age),
    numero_edades = n(),
    defunciones = sum(deaths),
    poblacion = sum(pop),
    mx_min = min(mx),
    mx_max = max(mx),
    .groups = "drop"
  )

print(resumen_mx)

cat("\nArchivo creado correctamente en: data/clean/lt_input_bc.csv\n")