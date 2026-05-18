# ============================================================
# 01_limpieza_poblacion.R
# Limpieza de población para Baja California
# Años: 2010, 2019 y 2021
#
# Archivo usado:
# data/raw/00_Pob_Mitad_1950_2070.csv
#
# Objetivo:
# Construir la población expuesta al riesgo por año, sexo y edad.
# Se dejan abiertas las edades 0, 1, 2, 3 y 4.
# Después se agrupan edades quinquenales: 5-9, 10-14, ..., 80-84.
# La edad 85 representa 85 años y más.
# ============================================================

# ------------------------------------------------------------
# 0. Paquetes
# ------------------------------------------------------------

library(data.table)
library(dplyr)
library(tidyr)

# ------------------------------------------------------------
# 1. Crear carpeta de salida si no existe
# ------------------------------------------------------------

dir.create("data/clean", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# 2. Leer archivo original
# ------------------------------------------------------------

pob_raw <- fread("data/raw/00_Pob_Mitad_1950_2070.csv")

# ------------------------------------------------------------
# 3. Filtrar Baja California y años de interés
# ------------------------------------------------------------
# Baja California tiene clave CVE_GEO = 2.
# Los años del proyecto son 2010, 2019 y 2021.
# ------------------------------------------------------------

pob_bc_simple <- pob_raw %>%
  filter(
    CVE_GEO == 2,
    ANIO %in% c(2010, 2019, 2021)
  ) %>%
  transmute(
    year = ANIO,
    sex = case_when(
      SEXO == "Hombres" ~ "m",
      SEXO == "Mujeres" ~ "f",
      TRUE ~ NA_character_
    ),
    age_simple = EDAD,
    pop = POBLACION
  ) %>%
  filter(!is.na(sex))

# ------------------------------------------------------------
# 4. Crear grupos de edad compatibles con las defunciones
# ------------------------------------------------------------
# Edades abiertas:
# 0, 1, 2, 3 y 4.
#
# Grupos quinquenales:
# 5-9, 10-14, ..., 80-84.
#
# Grupo abierto:
# 85 años y más.
# ------------------------------------------------------------

poblacion_bc <- pob_bc_simple %>%
  mutate(
    age = case_when(
      age_simple == 0 ~ 0,
      age_simple == 1 ~ 1,
      age_simple == 2 ~ 2,
      age_simple == 3 ~ 3,
      age_simple == 4 ~ 4,
      age_simple >= 5  & age_simple <= 9  ~ 5,
      age_simple >= 10 & age_simple <= 14 ~ 10,
      age_simple >= 15 & age_simple <= 19 ~ 15,
      age_simple >= 20 & age_simple <= 24 ~ 20,
      age_simple >= 25 & age_simple <= 29 ~ 25,
      age_simple >= 30 & age_simple <= 34 ~ 30,
      age_simple >= 35 & age_simple <= 39 ~ 35,
      age_simple >= 40 & age_simple <= 44 ~ 40,
      age_simple >= 45 & age_simple <= 49 ~ 45,
      age_simple >= 50 & age_simple <= 54 ~ 50,
      age_simple >= 55 & age_simple <= 59 ~ 55,
      age_simple >= 60 & age_simple <= 64 ~ 60,
      age_simple >= 65 & age_simple <= 69 ~ 65,
      age_simple >= 70 & age_simple <= 74 ~ 70,
      age_simple >= 75 & age_simple <= 79 ~ 75,
      age_simple >= 80 & age_simple <= 84 ~ 80,
      age_simple >= 85 ~ 85,
      TRUE ~ NA_real_
    ),
    
    n = case_when(
      age %in% c(0, 1, 2, 3, 4) ~ 1,
      age %in% c(5, 10, 15, 20, 25, 30, 35, 40,
                 45, 50, 55, 60, 65, 70, 75, 80) ~ 5,
      age == 85 ~ NA_real_,
      TRUE ~ NA_real_
    )
  ) %>%
  filter(!is.na(age)) %>%
  group_by(year, sex, age, n) %>%
  summarise(
    pop = sum(pop, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(year, sex, age)

# ------------------------------------------------------------
# 5. Validar que no falten edades
# ------------------------------------------------------------

edades_esperadas <- expand_grid(
  year = c(2010, 2019, 2021),
  sex = c("f", "m"),
  age = c(0, 1, 2, 3, 4,
          5, 10, 15, 20, 25, 30, 35, 40,
          45, 50, 55, 60, 65, 70, 75, 80, 85)
)

faltantes <- edades_esperadas %>%
  anti_join(poblacion_bc, by = c("year", "sex", "age"))

if (nrow(faltantes) > 0) {
  cat("\nCuidado: faltan estas edades en población:\n")
  print(faltantes)
  stop("Hay edades faltantes en población. Revisa el archivo original.")
}

# ------------------------------------------------------------
# 6. Guardar base limpia
# ------------------------------------------------------------

fwrite(poblacion_bc, "data/clean/poblacion_bc.csv")

# ------------------------------------------------------------
# 7. Revisión rápida
# ------------------------------------------------------------

cat("\nBase limpia de población:\n")
print(poblacion_bc)

cat("\nResumen por año y sexo:\n")

resumen_pob <- poblacion_bc %>%
  group_by(year, sex) %>%
  summarise(
    edad_min = min(age),
    edad_max = max(age),
    numero_edades = n(),
    poblacion_total = sum(pop),
    .groups = "drop"
  )

print(resumen_pob)

cat("\nArchivo creado correctamente en: data/clean/poblacion_bc.csv\n")