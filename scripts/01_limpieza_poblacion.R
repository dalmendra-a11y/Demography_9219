# ============================================================
# 01_limpieza_poblacion.R
# Limpieza y estimación de población para Baja California
# Fuente: INEGI, Censo de Población y Vivienda 2010 y 2020
#
# Objetivo:
# Construir población expuesta al riesgo para 2010, 2019 y 2021,
# usando población censal de INEGI y crecimiento exponencial.
#
# Edades:
# 0, 1, 2, 3, 4 abiertas
# 5-9, 10-14, ..., 80-84 quinquenales
# 85 y más como grupo abierto
# ============================================================

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(data.table)

dir.create("data/clean", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# 1. Función para limpiar números con comas
# ------------------------------------------------------------

limpiar_numero <- function(x) {
  x <- as.character(x)
  x <- str_replace_all(x, ",", "")
  x <- str_replace_all(x, " ", "")
  x <- str_replace_all(x, "[^0-9.-]", "")
  x <- ifelse(is.na(x) | x == "", NA, x)
  as.numeric(x)
}

# ------------------------------------------------------------
# 2. Función para convertir fecha a año decimal
# ------------------------------------------------------------

decimal_year <- function(fecha) {
  fecha <- as.Date(fecha)
  anio <- as.numeric(format(fecha, "%Y"))
  inicio <- as.Date(paste0(anio, "-01-01"))
  fin <- as.Date(paste0(anio + 1, "-01-01"))
  anio + as.numeric(fecha - inicio) / as.numeric(fin - inicio)
}

# Fechas de referencia aproximadas de los censos
t_2010 <- decimal_year("2010-06-12")
t_2020 <- decimal_year("2020-03-15")

# Años objetivo a mitad de año
objetivos <- tibble(
  year = c(2010, 2019, 2021),
  t = c(2010.5, 2019.5, 2021.5)
)

# ------------------------------------------------------------
# 3. Función para leer población de INEGI
# ------------------------------------------------------------

leer_poblacion_inegi <- function(ruta, anio_censo) {
  
  bruto <- read_excel(
    path = ruta,
    sheet = 1,
    col_names = FALSE
  )
  
  # En los archivos descargados de INEGI, las primeras columnas son:
  # Edad | Total | Hombres | Mujeres
  tabla <- bruto[, 1:4]
  
  names(tabla) <- c(
    "edad_txt",
    "total",
    "hombres",
    "mujeres"
  )
  
  tabla_limpia <- tabla %>%
    mutate(
      edad_txt = as.character(edad_txt),
      edad_txt = str_squish(edad_txt),
      edad_txt = str_replace(edad_txt, "^\\+\\s*", ""),
      edad_txt = str_replace(edad_txt, "^\\-\\s*", ""),
      edad_norm = str_to_lower(edad_txt),
      
      total = limpiar_numero(total),
      hombres = limpiar_numero(hombres),
      mujeres = limpiar_numero(mujeres)
    ) %>%
    filter(!is.na(edad_txt))
  
  # ----------------------------------------------------------
  # Clasificación de edades
  # ----------------------------------------------------------
  # OJO:
  # No usamos el renglón "De 0 a 4 años", porque usamos 0,1,2,3,4
  # por separado.
  # ----------------------------------------------------------
  
  tabla_limpia <- tabla_limpia %>%
    mutate(
      age = case_when(
        str_detect(edad_norm, "^0\\s*años?$") ~ 0,
        str_detect(edad_norm, "^1\\s*años?$") ~ 1,
        str_detect(edad_norm, "^2\\s*años?$") ~ 2,
        str_detect(edad_norm, "^3\\s*años?$") ~ 3,
        str_detect(edad_norm, "^4\\s*años?$") ~ 4,
        
        str_detect(edad_norm, "5\\s*a\\s*9") ~ 5,
        str_detect(edad_norm, "10\\s*a\\s*14") ~ 10,
        str_detect(edad_norm, "15\\s*a\\s*19") ~ 15,
        str_detect(edad_norm, "20\\s*a\\s*24") ~ 20,
        str_detect(edad_norm, "25\\s*a\\s*29") ~ 25,
        str_detect(edad_norm, "30\\s*a\\s*34") ~ 30,
        str_detect(edad_norm, "35\\s*a\\s*39") ~ 35,
        str_detect(edad_norm, "40\\s*a\\s*44") ~ 40,
        str_detect(edad_norm, "45\\s*a\\s*49") ~ 45,
        str_detect(edad_norm, "50\\s*a\\s*54") ~ 50,
        str_detect(edad_norm, "55\\s*a\\s*59") ~ 55,
        str_detect(edad_norm, "60\\s*a\\s*64") ~ 60,
        str_detect(edad_norm, "65\\s*a\\s*69") ~ 65,
        str_detect(edad_norm, "70\\s*a\\s*74") ~ 70,
        str_detect(edad_norm, "75\\s*a\\s*79") ~ 75,
        str_detect(edad_norm, "80\\s*a\\s*84") ~ 80,
        str_detect(edad_norm, "85") & str_detect(edad_norm, "más") ~ 85,
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
    filter(!is.na(age))
  
  # Pasar a formato largo
  poblacion_larga <- tabla_limpia %>%
    select(age, n, hombres, mujeres) %>%
    pivot_longer(
      cols = c(hombres, mujeres),
      names_to = "sex",
      values_to = "pop"
    ) %>%
    mutate(
      sex = case_when(
        sex == "hombres" ~ "m",
        sex == "mujeres" ~ "f",
        TRUE ~ NA_character_
      ),
      year_censo = anio_censo
    ) %>%
    filter(!is.na(sex), !is.na(pop)) %>%
    group_by(year_censo, sex, age, n) %>%
    summarise(
      pop = sum(pop, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(year_censo, sex, age)
  
  return(poblacion_larga)
}

# ------------------------------------------------------------
# 4. Leer censos 2010 y 2020
# ------------------------------------------------------------

pob_2010 <- leer_poblacion_inegi(
  ruta = "data/raw/inegi_poblacion_2010.xlsx",
  anio_censo = 2010
)

pob_2020 <- leer_poblacion_inegi(
  ruta = "data/raw/inegi_poblacion_2020.xlsx",
  anio_censo = 2020
)

# ------------------------------------------------------------
# 5. Unir censos para calcular crecimiento exponencial
# ------------------------------------------------------------

pob_base <- pob_2010 %>%
  select(sex, age, n, pop_2010 = pop) %>%
  inner_join(
    pob_2020 %>% select(sex, age, n, pop_2020 = pop),
    by = c("sex", "age", "n")
  ) %>%
  mutate(
    r = log(pop_2020 / pop_2010) / (t_2020 - t_2010)
  )

# ------------------------------------------------------------
# 6. Estimar población para 2010, 2019 y 2021
# ------------------------------------------------------------

poblacion_bc <- merge(pob_base, objetivos, by = NULL) %>%
  mutate(
    pop = pop_2010 * exp(r * (t - t_2010)),
    pop = round(pop, 0)
  ) %>%
  select(year, sex, age, n, pop) %>%
  arrange(year, sex, age)

# ------------------------------------------------------------
# 7. Validar edades esperadas
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
  stop("Hay edades faltantes en población. Revisa los archivos de INEGI.")
}

# ------------------------------------------------------------
# 8. Guardar base limpia
# ------------------------------------------------------------

fwrite(poblacion_bc, "data/clean/poblacion_bc.csv")

# ------------------------------------------------------------
# 9. Revisión rápida
# ------------------------------------------------------------

cat("\nBase limpia de población usando INEGI:\n")
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