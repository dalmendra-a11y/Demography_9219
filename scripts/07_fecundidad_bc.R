# ============================================================
# 07_fecundidad_bc.R
# Indicadores de fecundidad para Baja California
# Años: 2010 y 2019
#
# Calcula:
# - TEFE: Tasas Específicas de Fecundidad
# - TGF: Tasa Global de Fecundidad
# - TBR: Tasa Bruta de Reproducción
# - TNR: Tasa Neta de Reproducción
#
# Insumos:
# data/raw/fecundidad/nacimientos_bc_2010.xlsx
# data/raw/fecundidad/nacimientos_bc_2019.xlsx
# data/clean/poblacion_bc.csv
# data/clean/tabla_vida_bc.csv
#
# Salidas:
# data/clean/fecundidad/fecundidad_bc.csv
# data/clean/fecundidad/indicadores_fecundidad_bc.csv
# output/fecundidad_bc.xlsx
# images/tefe_bc_2010_2019.png
# images/tgf_tbr_tnr_bc.png
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
# 1. Crear carpetas de salida
# ------------------------------------------------------------

dir.create("data/clean/fecundidad", recursive = TRUE, showWarnings = FALSE)
dir.create("output", recursive = TRUE, showWarnings = FALSE)
dir.create("images", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# 2. Función auxiliar para limpiar números
# ------------------------------------------------------------

limpiar_numero <- function(x) {
  x <- as.character(x)
  x <- str_replace_all(x, ",", "")
  x <- str_replace_all(x, " ", "")
  x <- str_replace_all(x, "[^0-9.-]", "")
  x <- ifelse(is.na(x) | x == "", "0", x)
  as.numeric(x)
}

# ------------------------------------------------------------
# 3. Mapa de edades reproductivas
# ------------------------------------------------------------

mapa_edades_fec <- tibble(
  edad_txt_patron = c(
    "15\\s*a\\s*19",
    "20\\s*a\\s*24",
    "25\\s*a\\s*29",
    "30\\s*a\\s*34",
    "35\\s*a\\s*39",
    "40\\s*a\\s*44",
    "45\\s*a\\s*49"
  ),
  age = c(15, 20, 25, 30, 35, 40, 45),
  grupo_edad = c(
    "15-19",
    "20-24",
    "25-29",
    "30-34",
    "35-39",
    "40-44",
    "45-49"
  ),
  n = 5
)

# ------------------------------------------------------------
# 4. Función para leer nacimientos de INEGI
# ------------------------------------------------------------
# La consulta está filtrada por año de ocurrencia.
# Las columnas corresponden a año de registro.
# Por eso sumamos todas las columnas numéricas de registro.
# ------------------------------------------------------------

leer_nacimientos_inegi <- function(ruta, anio_ocurrencia) {
  
  bruto <- read_excel(
    path = ruta,
    sheet = 1,
    col_names = FALSE
  )
  
  # Primera columna: edad de la madre.
  # Columnas restantes: años de registro.
  tabla <- bruto %>%
    as.data.frame()
  
  names(tabla) <- paste0("V", seq_len(ncol(tabla)))
  
  tabla_limpia <- tabla %>%
    mutate(
      edad_txt = as.character(V1),
      edad_txt = str_squish(edad_txt),
      edad_txt = str_replace(edad_txt, "^\\+\\s*", ""),
      edad_txt = str_replace(edad_txt, "^\\-\\s*", ""),
      edad_norm = str_to_lower(edad_txt)
    )
  
  # Convertir todas las columnas excepto la primera a números
  columnas_valores <- setdiff(names(tabla_limpia), c("V1", "edad_txt", "edad_norm"))
  
  tabla_limpia <- tabla_limpia %>%
    mutate(
      across(
        all_of(columnas_valores),
        limpiar_numero
      )
    ) %>%
    rowwise() %>%
    mutate(
      births = sum(c_across(all_of(columnas_valores)), na.rm = TRUE)
    ) %>%
    ungroup()
  
  # Clasificar edades reproductivas
  nacimientos <- tabla_limpia %>%
    mutate(
      age = case_when(
        str_detect(edad_norm, "15\\s*a\\s*19") ~ 15,
        str_detect(edad_norm, "20\\s*a\\s*24") ~ 20,
        str_detect(edad_norm, "25\\s*a\\s*29") ~ 25,
        str_detect(edad_norm, "30\\s*a\\s*34") ~ 30,
        str_detect(edad_norm, "35\\s*a\\s*39") ~ 35,
        str_detect(edad_norm, "40\\s*a\\s*44") ~ 40,
        str_detect(edad_norm, "45\\s*a\\s*49") ~ 45,
        TRUE ~ NA_real_
      )
    ) %>%
    filter(!is.na(age)) %>%
    left_join(
      mapa_edades_fec %>% select(age, grupo_edad, n),
      by = "age"
    ) %>%
    transmute(
      year = anio_ocurrencia,
      age,
      grupo_edad,
      n,
      births
    ) %>%
    group_by(year, age, grupo_edad, n) %>%
    summarise(
      births = sum(births, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(year, age)
  
  return(nacimientos)
}

# ------------------------------------------------------------
# 5. Leer nacimientos 2010 y 2019
# ------------------------------------------------------------

nac_2010 <- leer_nacimientos_inegi(
  ruta = "data/raw/fecundidad/nacimientos_bc_2010.xlsx",
  anio_ocurrencia = 2010
)

nac_2019 <- leer_nacimientos_inegi(
  ruta = "data/raw/fecundidad/nacimientos_bc_2019.xlsx",
  anio_ocurrencia = 2019
)

nacimientos_bc <- bind_rows(nac_2010, nac_2019)

cat("\nNacimientos por edad de la madre:\n")
print(nacimientos_bc)

# ------------------------------------------------------------
# 6. Leer población femenina
# ------------------------------------------------------------

poblacion_bc <- fread("data/clean/poblacion_bc.csv")

pob_mujeres_fec <- poblacion_bc %>%
  filter(
    year %in% c(2010, 2019),
    sex == "f",
    age %in% c(15, 20, 25, 30, 35, 40, 45)
  ) %>%
  select(year, age, female_pop = pop)

# ------------------------------------------------------------
# 7. Calcular TEFE
# ------------------------------------------------------------

fecundidad_bc <- nacimientos_bc %>%
  left_join(
    pob_mujeres_fec,
    by = c("year", "age")
  ) %>%
  mutate(
    TEFE = births / female_pop,
    TEFE_1000 = TEFE * 1000
  ) %>%
  arrange(year, age)

if (any(is.na(fecundidad_bc$female_pop))) {
  stop("Hay población femenina faltante. Revisa poblacion_bc.csv.")
}

cat("\nTEFE Baja California:\n")
print(fecundidad_bc)

# ------------------------------------------------------------
# 8. Incorporar sobrevivencia femenina para TNR
# ------------------------------------------------------------
# En las notas de clase:
# TNR = 5 * K * sum(TEFE_x * sobrevivencia femenina)
#
# Para cada grupo quinquenal usamos:
# sobrevivencia aproximada = Lx / (5 * l0)
#
# donde Lx viene de la tabla de vida femenina del mismo año.
# ------------------------------------------------------------

tabla_vida_bc <- fread("data/clean/tabla_vida_bc.csv")

sobrevivencia_fem <- tabla_vida_bc %>%
  filter(
    year %in% c(2010, 2019),
    sex == "f",
    age %in% c(15, 20, 25, 30, 35, 40, 45)
  ) %>%
  mutate(
    l0 = 100000,
    sobrevivencia_fem = Lx / (5 * l0)
  ) %>%
  select(year, age, sobrevivencia_fem)

fecundidad_bc <- fecundidad_bc %>%
  left_join(
    sobrevivencia_fem,
    by = c("year", "age")
  )

if (any(is.na(fecundidad_bc$sobrevivencia_fem))) {
  stop("Hay sobrevivencia femenina faltante. Revisa tabla_vida_bc.csv.")
}

# ------------------------------------------------------------
# 9. Calcular TGF, TBR y TNR
# ------------------------------------------------------------

K <- 100 / 205

indicadores_fecundidad_bc <- fecundidad_bc %>%
  group_by(year) %>%
  summarise(
    TGF = 5 * sum(TEFE, na.rm = TRUE),
    TBR = TGF * K,
    TNR = 5 * K * sum(TEFE * sobrevivencia_fem, na.rm = TRUE),
    nacimientos_15_49 = sum(births, na.rm = TRUE),
    mujeres_15_49 = sum(female_pop, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    K = K,
    TGF = round(TGF, 3),
    TBR = round(TBR, 3),
    TNR = round(TNR, 3)
  )

cat("\nIndicadores sintéticos de fecundidad:\n")
print(indicadores_fecundidad_bc)

# ------------------------------------------------------------
# 10. Guardar bases limpias
# ------------------------------------------------------------

fwrite(
  fecundidad_bc,
  "data/clean/fecundidad/fecundidad_bc.csv"
)

fwrite(
  indicadores_fecundidad_bc,
  "data/clean/fecundidad/indicadores_fecundidad_bc.csv"
)

# ------------------------------------------------------------
# 11. Gráfica TEFE 2010 vs 2019
# ------------------------------------------------------------

fecundidad_bc <- fecundidad_bc %>%
  mutate(
    year_factor = as.factor(year)
  )

g_tefe_bc <- ggplot(
  fecundidad_bc,
  aes(x = age, y = TEFE_1000, color = year_factor, group = year_factor)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(
    breaks = c(15, 20, 25, 30, 35, 40, 45),
    labels = c("15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49")
  ) +
  labs(
    title = "Tasas específicas de fecundidad",
    subtitle = "Baja California, 2010 y 2019",
    x = "Grupo de edad de la madre",
    y = "Nacimientos por cada 1,000 mujeres",
    color = "Año",
    caption = "Fuente: elaboración propia con datos de INEGI."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  filename = "images/tefe_bc_2010_2019.png",
  plot = g_tefe_bc,
  width = 9,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 12. Gráfica TGF, TBR y TNR
# ------------------------------------------------------------

indicadores_largos <- indicadores_fecundidad_bc %>%
  select(year, TGF, TBR, TNR) %>%
  pivot_longer(
    cols = c(TGF, TBR, TNR),
    names_to = "indicador",
    values_to = "valor"
  ) %>%
  mutate(
    year_factor = as.factor(year)
  )

g_indicadores <- ggplot(
  indicadores_largos,
  aes(x = year_factor, y = valor, fill = indicador)
) +
  geom_col(
    position = position_dodge(width = 0.8),
    width = 0.7
  ) +
  geom_text(
    aes(label = round(valor, 2)),
    position = position_dodge(width = 0.8),
    vjust = -0.3,
    size = 3.5
  ) +
  labs(
    title = "Indicadores sintéticos de fecundidad",
    subtitle = "Baja California, 2010 y 2019",
    x = "Año",
    y = "Valor del indicador",
    fill = "Indicador",
    caption = "Fuente: elaboración propia con datos de INEGI."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  filename = "images/tgf_tbr_tnr_bc.png",
  plot = g_indicadores,
  width = 8,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 13. Exportar Excel
# ------------------------------------------------------------

wb <- createWorkbook()

addWorksheet(wb, "nacimientos")
writeData(wb, "nacimientos", nacimientos_bc)

addWorksheet(wb, "tefe")
writeData(wb, "tefe", fecundidad_bc)

addWorksheet(wb, "indicadores")
writeData(wb, "indicadores", indicadores_fecundidad_bc)

addWorksheet(wb, "formulas")
formulas <- data.frame(
  Indicador = c(
    "TEFE",
    "TGF",
    "TBR",
    "TNR",
    "K"
  ),
  Formula = c(
    "TEFE_x = Nacimientos_x / Mujeres_x",
    "TGF = 5 * sum(TEFE_x)",
    "TBR = TGF * K",
    "TNR = 5 * K * sum(TEFE_x * sobrevivencia_femenina_x)",
    "K = 100 / 205 = 0.4878"
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
  "output/fecundidad_bc.xlsx",
  overwrite = TRUE
)

# ------------------------------------------------------------
# 14. Revisión final
# ------------------------------------------------------------

cat("\nArchivos creados correctamente:\n")
cat("- data/clean/fecundidad/fecundidad_bc.csv\n")
cat("- data/clean/fecundidad/indicadores_fecundidad_bc.csv\n")
cat("- output/fecundidad_bc.xlsx\n")
cat("- images/tefe_bc_2010_2019.png\n")
cat("- images/tgf_tbr_tnr_bc.png\n")


