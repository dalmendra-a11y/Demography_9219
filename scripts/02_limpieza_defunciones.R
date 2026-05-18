# ============================================================
# 02_limpieza_defunciones.R
# Limpieza de defunciones para Baja California
# Años: 2010, 2019 y 2021
#
# Usamos el archivo grande:
# data/raw/defunciones.xlsx
#
# Este archivo contiene defunciones registradas por:
# edad, año de registro y sexo.
#
# Importante:
# Dejamos abiertas las edades 1, 2, 3 y 4.
# Por eso NO usamos el renglón agregado "1-4 años".
# ============================================================

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(data.table)

dir.create("data/clean", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# 1. Función auxiliar para limpiar números
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
# 2. Mapa de edades
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
# 3. Leer archivo original
# ------------------------------------------------------------

def_raw_excel <- read_excel(
  path = "data/raw/defunciones.xlsx",
  sheet = 1,
  col_names = FALSE
)

# El archivo tiene esta estructura:
# columna 1: Edad
# columna 2: Año de registro
# columna 3: Año de ocurrencia o Total
# columna 4: Total
# columna 5: Hombre
# columna 6: Mujer
# columna 7: No especificado

def_raw <- def_raw_excel[, c(1, 2, 4, 5, 6, 7)]

names(def_raw) <- c(
  "edad_txt",
  "year",
  "total",
  "hombre",
  "mujer",
  "sexo_no_especificado"
)

# ------------------------------------------------------------
# 4. Limpieza general
# ------------------------------------------------------------

def_raw <- def_raw %>%
  mutate(
    edad_txt = as.character(edad_txt),
    edad_txt = str_squish(edad_txt),
    edad_txt = str_replace(edad_txt, "^\\+\\s*", ""),
    edad_txt = str_replace(edad_txt, "^\\-\\s*", ""),
    
    year = limpiar_numero(year, na_cero = FALSE),
    total = limpiar_numero(total, na_cero = TRUE),
    hombre = limpiar_numero(hombre, na_cero = TRUE),
    mujer = limpiar_numero(mujer, na_cero = TRUE),
    sexo_no_especificado = limpiar_numero(sexo_no_especificado, na_cero = TRUE)
  ) %>%
  filter(
    !is.na(year),
    year %in% c(2010, 2019, 2021)
  ) %>%
  mutate(
    year = as.integer(year)
  )

# ------------------------------------------------------------
# 5. Revisar renglones usados e ignorados
# ------------------------------------------------------------

edades_usadas <- def_raw %>%
  inner_join(mapa_edades, by = "edad_txt")

edades_ignoradas <- def_raw %>%
  anti_join(mapa_edades, by = "edad_txt")

cat("\nEdades que se usarán para la tabla de vida:\n")
print(sort(unique(edades_usadas$edad_txt)))

cat("\nRenglones ignorados del archivo original:\n")
print(sort(unique(edades_ignoradas$edad_txt)))

# ------------------------------------------------------------
# 6. Separar edades válidas y edad no especificada
# ------------------------------------------------------------

def_validas <- def_raw %>%
  inner_join(mapa_edades, by = "edad_txt")

def_no_esp <- def_raw %>%
  filter(edad_txt == "No especificado")

# ------------------------------------------------------------
# 7. Prorratear sexo no especificado
# ------------------------------------------------------------

def_validas <- def_validas %>%
  mutate(
    sexo_no_especificado = total - hombre - mujer,
    sexo_no_especificado = if_else(sexo_no_especificado < 0, 0, sexo_no_especificado),
    
    total_sexo_conocido = hombre + mujer,
    
    prop_hombre = if_else(
      total_sexo_conocido > 0,
      hombre / total_sexo_conocido,
      0
    ),
    
    prop_mujer = if_else(
      total_sexo_conocido > 0,
      mujer / total_sexo_conocido,
      0
    ),
    
    hombre = hombre + sexo_no_especificado * prop_hombre,
    mujer = mujer + sexo_no_especificado * prop_mujer
  )

def_no_esp <- def_no_esp %>%
  mutate(
    sexo_no_especificado = total - hombre - mujer,
    sexo_no_especificado = if_else(sexo_no_especificado < 0, 0, sexo_no_especificado),
    
    total_sexo_conocido = hombre + mujer,
    
    prop_hombre = if_else(
      total_sexo_conocido > 0,
      hombre / total_sexo_conocido,
      0
    ),
    
    prop_mujer = if_else(
      total_sexo_conocido > 0,
      mujer / total_sexo_conocido,
      0
    ),
    
    hombre = hombre + sexo_no_especificado * prop_hombre,
    mujer = mujer + sexo_no_especificado * prop_mujer
  )

# ------------------------------------------------------------
# 8. Pasar edades válidas a formato largo
# ------------------------------------------------------------

def_validas_long <- def_validas %>%
  select(year, age, n, hombre, mujer) %>%
  pivot_longer(
    cols = c(hombre, mujer),
    names_to = "sex",
    values_to = "deaths"
  ) %>%
  mutate(
    sex = case_when(
      sex == "hombre" ~ "m",
      sex == "mujer" ~ "f",
      TRUE ~ NA_character_
    )
  )

# ------------------------------------------------------------
# 9. Pasar edad no especificada a formato largo
# ------------------------------------------------------------

def_no_esp_long <- def_no_esp %>%
  select(year, hombre, mujer) %>%
  pivot_longer(
    cols = c(hombre, mujer),
    names_to = "sex",
    values_to = "deaths_no_esp"
  ) %>%
  mutate(
    sex = case_when(
      sex == "hombre" ~ "m",
      sex == "mujer" ~ "f",
      TRUE ~ NA_character_
    )
  )

# ------------------------------------------------------------
# 10. Prorratear edad no especificada
# ------------------------------------------------------------

defunciones_bc <- def_validas_long %>%
  left_join(def_no_esp_long, by = c("year", "sex")) %>%
  mutate(
    deaths_no_esp = if_else(is.na(deaths_no_esp), 0, deaths_no_esp)
  ) %>%
  group_by(year, sex) %>%
  mutate(
    prop_edad = deaths / sum(deaths, na.rm = TRUE),
    deaths = deaths + prop_edad * deaths_no_esp
  ) %>%
  ungroup() %>%
  select(year, sex, age, n, deaths) %>%
  arrange(year, sex, age)

# ------------------------------------------------------------
# 11. Validar edades
# ------------------------------------------------------------

edades_esperadas <- expand_grid(
  year = c(2010, 2019, 2021),
  sex = c("f", "m"),
  age = mapa_edades$age
)

faltantes <- edades_esperadas %>%
  anti_join(defunciones_bc, by = c("year", "sex", "age"))

if (nrow(faltantes) > 0) {
  cat("\nCuidado: faltan estas edades en la base final:\n")
  print(faltantes)
  stop("Hay edades faltantes. Revisa los nombres de edad del archivo de INEGI.")
}

# ------------------------------------------------------------
# 12. Guardar base limpia
# ------------------------------------------------------------

fwrite(defunciones_bc, "data/clean/defunciones_bc.csv")

# ------------------------------------------------------------
# 13. Revisión rápida
# ------------------------------------------------------------

cat("\nResumen por año y sexo:\n")

resumen_def <- defunciones_bc %>%
  group_by(year, sex) %>%
  summarise(
    edad_min = min(age),
    edad_max = max(age),
    numero_edades = n(),
    total_defunciones = sum(deaths),
    .groups = "drop"
  )

print(resumen_def)

cat("\nArchivo creado correctamente en: data/clean/defunciones_bc.csv\n")