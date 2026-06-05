# ============================================================
# 06_causa_eliminada_homicidios.R
# Tabla de vida 2019 con causa eliminada: homicidios
# Baja California, por sexo
#
# Insumos:
# data/raw/homicidios/homicidios_2019_bc.xlsx
# data/clean/lt_input_bc.csv
#
# Salidas:
# data/clean/homicidios/homicidios_2019_bc.csv
# data/clean/homicidios/tabla_vida_2019_observada_vs_sin_homicidios.csv
# output/tabla_vida_2019_causa_eliminada_homicidios.xlsx
# images/e0_causa_eliminada.png
# images/qx_causa_eliminada.png
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

dir.create("data/clean/homicidios", recursive = TRUE, showWarnings = FALSE)
dir.create("output", recursive = TRUE, showWarnings = FALSE)
dir.create("images", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# 2. Función auxiliar para limpiar números
# ------------------------------------------------------------

limpiar_numero <- function(x, na_cero = TRUE) {
  x <- as.character(x)
  x <- str_replace_all(x, ",", "")
  x <- str_replace_all(x, " ", "")
  x <- str_replace_all(x, "[^0-9.-]", "")
  
  if (na_cero) {
    x <- ifelse(is.na(x) | x == "", "0", x)
  } else {
    x <- ifelse(is.na(x) | x == "", NA, x)
  }
  
  as.numeric(x)
}

# ------------------------------------------------------------
# 3. Mapa de edades compatible con la tabla de vida
# ------------------------------------------------------------

mapa_edades <- tibble(
  edad_txt = c(
    "Menores de 1 año",
    "1 año",
    "2 años",
    "3 años",
    "4 años",
    "5-9 años",
    "10-14 años",
    "15-19 años",
    "20-24 años",
    "25-29 años",
    "30-34 años",
    "35-39 años",
    "40-44 años",
    "45-49 años",
    "50-54 años",
    "55-59 años",
    "60-64 años",
    "65-69 años",
    "70-74 años",
    "75-79 años",
    "80-84 años",
    "85 años y más"
  ),
  age = c(
    0, 1, 2, 3, 4,
    5, 10, 15, 20, 25, 30, 35, 40,
    45, 50, 55, 60, 65, 70, 75, 80, 85
  ),
  n = c(
    1, 1, 1, 1, 1,
    rep(5, 16),
    NA
  )
)

# ------------------------------------------------------------
# 4. Leer homicidios de INEGI
# ------------------------------------------------------------

homicidios_raw_excel <- read_excel(
  path = "data/raw/homicidios/homicidios_2019_bc.xlsx",
  sheet = 1,
  col_names = FALSE
)

# La consulta descargada tiene la estructura:
# Edad | Año de registro | Total | Hombre | Mujer | No especificado
homicidios_raw <- homicidios_raw_excel[, 1:6]

names(homicidios_raw) <- c(
  "edad_txt",
  "anio_registro",
  "total",
  "hombre",
  "mujer",
  "sexo_no_especificado"
)

# ------------------------------------------------------------
# 5. Limpieza de homicidios
# ------------------------------------------------------------

homicidios_raw <- homicidios_raw %>%
  mutate(
    edad_txt = as.character(edad_txt),
    edad_txt = str_squish(edad_txt),
    edad_txt = str_replace(edad_txt, "^\\+\\s*", ""),
    edad_txt = str_replace(edad_txt, "^\\-\\s*", ""),
    
    anio_registro = limpiar_numero(anio_registro, na_cero = FALSE),
    total = limpiar_numero(total, na_cero = TRUE),
    hombre = limpiar_numero(hombre, na_cero = TRUE),
    mujer = limpiar_numero(mujer, na_cero = TRUE),
    sexo_no_especificado = limpiar_numero(sexo_no_especificado, na_cero = TRUE)
  ) %>%
  filter(!is.na(anio_registro)) %>%
  mutate(year = 2019)

# Sumamos todos los años de registro, porque la consulta está filtrada
# por año de ocurrencia 2019.
homicidios_raw <- homicidios_raw %>%
  group_by(year, edad_txt) %>%
  summarise(
    total = sum(total, na.rm = TRUE),
    hombre = sum(hombre, na.rm = TRUE),
    mujer = sum(mujer, na.rm = TRUE),
    sexo_no_especificado = sum(sexo_no_especificado, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nEdades que aparecen en el archivo de homicidios:\n")
print(sort(unique(homicidios_raw$edad_txt)))

# ------------------------------------------------------------
# 6. Separar edades válidas y edad no especificada
# ------------------------------------------------------------

homicidios_validos <- homicidios_raw %>%
  inner_join(mapa_edades, by = "edad_txt")

homicidios_no_esp <- homicidios_raw %>%
  filter(edad_txt == "No especificado")

# ------------------------------------------------------------
# 7. Prorratear sexo no especificado
# ------------------------------------------------------------

homicidios_validos <- homicidios_validos %>%
  mutate(
    sexo_no_especificado = total - hombre - mujer,
    sexo_no_especificado = if_else(sexo_no_especificado < 0, 0, sexo_no_especificado),
    
    total_sexo_conocido = hombre + mujer,
    
    prop_hombre = if_else(total_sexo_conocido > 0, hombre / total_sexo_conocido, 0),
    prop_mujer = if_else(total_sexo_conocido > 0, mujer / total_sexo_conocido, 0),
    
    hombre = hombre + sexo_no_especificado * prop_hombre,
    mujer = mujer + sexo_no_especificado * prop_mujer
  )

homicidios_no_esp <- homicidios_no_esp %>%
  mutate(
    sexo_no_especificado = total - hombre - mujer,
    sexo_no_especificado = if_else(sexo_no_especificado < 0, 0, sexo_no_especificado),
    
    total_sexo_conocido = hombre + mujer,
    
    prop_hombre = if_else(total_sexo_conocido > 0, hombre / total_sexo_conocido, 0),
    prop_mujer = if_else(total_sexo_conocido > 0, mujer / total_sexo_conocido, 0),
    
    hombre = hombre + sexo_no_especificado * prop_hombre,
    mujer = mujer + sexo_no_especificado * prop_mujer
  )

# ------------------------------------------------------------
# 8. Pasar a formato largo
# ------------------------------------------------------------

homicidios_validos_long <- homicidios_validos %>%
  select(year, age, n, hombre, mujer) %>%
  pivot_longer(
    cols = c(hombre, mujer),
    names_to = "sex",
    values_to = "homicides"
  ) %>%
  mutate(
    sex = case_when(
      sex == "hombre" ~ "m",
      sex == "mujer" ~ "f",
      TRUE ~ NA_character_
    )
  )

homicidios_no_esp_long <- homicidios_no_esp %>%
  select(year, hombre, mujer) %>%
  pivot_longer(
    cols = c(hombre, mujer),
    names_to = "sex",
    values_to = "homicides_no_esp"
  ) %>%
  mutate(
    sex = case_when(
      sex == "hombre" ~ "m",
      sex == "mujer" ~ "f",
      TRUE ~ NA_character_
    )
  )

# ------------------------------------------------------------
# 9. Prorratear edad no especificada
# ------------------------------------------------------------
# Primero completamos todas las edades esperadas.
# Esto es importante porque en homicidios algunas edades pueden no aparecer
# en INEGI si tienen cero casos.
# ------------------------------------------------------------

estructura_completa <- expand_grid(
  year = 2019,
  sex = c("f", "m"),
  age = mapa_edades$age
) %>%
  left_join(
    mapa_edades %>% select(age, n),
    by = "age"
  )

homicidios_validos_long <- estructura_completa %>%
  left_join(
    homicidios_validos_long,
    by = c("year", "sex", "age", "n")
  ) %>%
  mutate(
    homicides = if_else(is.na(homicides), 0, homicides)
  )

homicidios_2019_bc <- homicidios_validos_long %>%
  left_join(homicidios_no_esp_long, by = c("year", "sex")) %>%
  mutate(
    homicides_no_esp = if_else(is.na(homicides_no_esp), 0, homicides_no_esp)
  ) %>%
  group_by(year, sex) %>%
  mutate(
    total_homicidios_validos = sum(homicides, na.rm = TRUE),
    prop_edad = if_else(
      total_homicidios_validos > 0,
      homicides / total_homicidios_validos,
      0
    ),
    homicides = homicides + prop_edad * homicides_no_esp
  ) %>%
  ungroup() %>%
  select(year, sex, age, n, homicides) %>%
  arrange(year, sex, age)


# ------------------------------------------------------------
# 10. Validar edades
# ------------------------------------------------------------

edades_esperadas <- expand_grid(
  year = 2019,
  sex = c("f", "m"),
  age = mapa_edades$age
)

faltantes <- edades_esperadas %>%
  anti_join(homicidios_2019_bc, by = c("year", "sex", "age"))

if (nrow(faltantes) > 0) {
  cat("\nCuidado: faltan estas edades en homicidios:\n")
  print(faltantes)
  stop("Hay edades faltantes en homicidios. Revisa la consulta de INEGI.")
}

# Guardar homicidios limpios
fwrite(
  homicidios_2019_bc,
  "data/clean/homicidios/homicidios_2019_bc.csv"
)

cat("\nResumen de homicidios 2019 por sexo:\n")
print(
  homicidios_2019_bc %>%
    group_by(year, sex) %>%
    summarise(
      total_homicidios = sum(homicides),
      .groups = "drop"
    )
)

# ------------------------------------------------------------
# 11. Funciones para construir tabla de vida
# ------------------------------------------------------------

asignar_ax <- function(age, n) {
  case_when(
    age == 0 ~ 0.07,
    age %in% c(1, 2, 3, 4) ~ 0.5,
    age >= 5 & age < 85 ~ 2.5,
    age == 85 ~ NA_real_,
    TRUE ~ NA_real_
  )
}

construir_tabla_vida <- function(datos) {
  
  datos <- datos %>%
    arrange(age) %>%
    mutate(
      ax = asignar_ax(age, n),
      qx = case_when(
        age == 85 ~ 1,
        TRUE ~ (n * mx) / (1 + (n - ax) * mx)
      ),
      qx = pmin(pmax(qx, 0), 1)
    )
  
  k <- nrow(datos)
  
  lx <- numeric(k)
  dx <- numeric(k)
  Lx <- numeric(k)
  
  lx[1] <- 100000
  
  for (i in 1:k) {
    dx[i] <- lx[i] * datos$qx[i]
    
    if (i < k) {
      lx[i + 1] <- lx[i] - dx[i]
    }
  }
  
  for (i in 1:k) {
    if (datos$age[i] == 85) {
      Lx[i] <- lx[i] / datos$mx[i]
    } else {
      Lx[i] <- datos$n[i] * lx[i + 1] + datos$ax[i] * dx[i]
    }
  }
  
  Tx <- rev(cumsum(rev(Lx)))
  ex <- Tx / lx
  
  tabla <- datos %>%
    mutate(
      lx = lx,
      dx = dx,
      Lx = Lx,
      Tx = Tx,
      ex = ex
    )
  
  return(tabla)
}

# ------------------------------------------------------------
# 12. Construir tabla observada y tabla sin homicidios
# ------------------------------------------------------------

lt_input_bc <- fread("data/clean/lt_input_bc.csv")

lt_2019 <- lt_input_bc %>%
  filter(year == 2019) %>%
  left_join(
    homicidios_2019_bc,
    by = c("year", "sex", "age", "n")
  ) %>%
  mutate(
    homicides = if_else(is.na(homicides), 0, homicides),
    deaths_observadas = deaths,
    deaths_sin_homicidios = deaths_observadas - homicides,
    deaths_sin_homicidios = if_else(deaths_sin_homicidios < 0, 0, deaths_sin_homicidios)
  )

tabla_observada_2019 <- lt_2019 %>%
  transmute(
    year,
    sex,
    age,
    n,
    pop,
    deaths = deaths_observadas,
    mx = deaths / pop,
    escenario = "Observada"
  ) %>%
  group_by(year, sex, escenario) %>%
  group_modify(~ construir_tabla_vida(.x)) %>%
  ungroup()

tabla_sin_homicidios_2019 <- lt_2019 %>%
  transmute(
    year,
    sex,
    age,
    n,
    pop,
    deaths = deaths_sin_homicidios,
    homicides,
    mx = deaths / pop,
    escenario = "Sin homicidios"
  ) %>%
  group_by(year, sex, escenario) %>%
  group_modify(~ construir_tabla_vida(.x)) %>%
  ungroup()

tabla_causa_eliminada <- bind_rows(
  tabla_observada_2019,
  tabla_sin_homicidios_2019
) %>%
  arrange(sex, escenario, age)

# ------------------------------------------------------------
# 13. Esperanza de vida al nacer observada vs sin homicidios
# ------------------------------------------------------------

e0_causa_eliminada <- tabla_causa_eliminada %>%
  filter(age == 0) %>%
  mutate(
    sexo = case_when(
      sex == "m" ~ "Hombres",
      sex == "f" ~ "Mujeres",
      TRUE ~ sex
    )
  ) %>%
  select(year, sexo, escenario, e0 = ex) %>%
  mutate(
    e0 = round(e0, 2)
  ) %>%
  arrange(sexo, escenario)

cat("\nEsperanza de vida observada vs sin homicidios:\n")
print(e0_causa_eliminada)

# ------------------------------------------------------------
# 14. Redondear tabla para exportar
# ------------------------------------------------------------

tabla_causa_eliminada_export <- tabla_causa_eliminada %>%
  mutate(
    pop = round(pop, 0),
    deaths = round(deaths, 3),
    homicides = if_else(is.na(homicides), 0, homicides),
    homicides = round(homicides, 3),
    mx = round(mx, 8),
    ax = round(ax, 2),
    qx = round(qx, 8),
    lx = round(lx, 0),
    dx = round(dx, 0),
    Lx = round(Lx, 0),
    Tx = round(Tx, 0),
    ex = round(ex, 2)
  )

fwrite(
  tabla_causa_eliminada_export,
  "data/clean/homicidios/tabla_vida_2019_observada_vs_sin_homicidios.csv"
)

fwrite(
  e0_causa_eliminada,
  "data/clean/homicidios/e0_causa_eliminada.csv"
)

# ------------------------------------------------------------
# 15. Gráfica e0 observada vs sin homicidios
# ------------------------------------------------------------

g_e0_causa <- ggplot(
  e0_causa_eliminada,
  aes(x = sexo, y = e0, fill = escenario)
) +
  geom_col(
    position = position_dodge(width = 0.8),
    width = 0.7
  ) +
  geom_text(
    aes(label = round(e0, 2)),
    position = position_dodge(width = 0.8),
    vjust = -0.3,
    size = 3.5
  ) +
  labs(
    title = "Esperanza de vida al nacer observada y sin homicidios",
    subtitle = "Baja California, 2019",
    x = "Sexo",
    y = expression(e[0]),
    fill = "Escenario",
    caption = "Fuente: elaboración propia con datos de INEGI."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  filename = "images/e0_causa_eliminada.png",
  plot = g_e0_causa,
  width = 8,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 16. Gráfica qx observada vs sin homicidios
# ------------------------------------------------------------

tabla_qx_causa <- tabla_causa_eliminada %>%
  mutate(
    sexo = case_when(
      sex == "m" ~ "Hombres",
      sex == "f" ~ "Mujeres",
      TRUE ~ sex
    ),
    qx_plot = if_else(qx <= 0, NA_real_, qx)
  )

g_qx_causa <- ggplot(
  tabla_qx_causa,
  aes(x = age, y = qx_plot, color = escenario, group = escenario)
) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.5) +
  facet_wrap(~ sexo, nrow = 1) +
  scale_y_log10(labels = label_number()) +
  labs(
    title = "Probabilidades de muerte observadas y sin homicidios",
    subtitle = "Baja California, 2019",
    x = "Edad",
    y = expression(q[x]),
    color = "Escenario",
    caption = "Fuente: elaboración propia con datos de INEGI."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  filename = "images/qx_causa_eliminada.png",
  plot = g_qx_causa,
  width = 9,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 17. Exportar archivo Excel
# ------------------------------------------------------------

wb <- createWorkbook()

addWorksheet(wb, "homicidios_limpios")
writeData(wb, "homicidios_limpios", homicidios_2019_bc)

addWorksheet(wb, "base_2019")
writeData(wb, "base_2019", lt_2019)

addWorksheet(wb, "tabla_observada_y_sin_hom")
writeData(wb, "tabla_observada_y_sin_hom", tabla_causa_eliminada_export)

addWorksheet(wb, "e0_comparacion")
writeData(wb, "e0_comparacion", e0_causa_eliminada)

# Estilo básico
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
  "output/tabla_vida_2019_causa_eliminada_homicidios.xlsx",
  overwrite = TRUE
)

# ------------------------------------------------------------
# 18. Revisión final
# ------------------------------------------------------------

cat("\nArchivos creados correctamente:\n")
cat("- data/clean/homicidios/homicidios_2019_bc.csv\n")
cat("- data/clean/homicidios/tabla_vida_2019_observada_vs_sin_homicidios.csv\n")
cat("- data/clean/homicidios/e0_causa_eliminada.csv\n")
cat("- output/tabla_vida_2019_causa_eliminada_homicidios.xlsx\n")
cat("- images/e0_causa_eliminada.png\n")
cat("- images/qx_causa_eliminada.png\n")