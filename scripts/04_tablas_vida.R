# ============================================================
# 04_tablas_vida.R
# Construcción de tablas de vida para Baja California
# Años: 2010, 2019 y 2021
#
# Insumo:
# data/clean/lt_input_bc.csv
#
# Salidas:
# data/clean/tabla_vida_bc.csv
# data/clean/esperanza_vida_bc.csv
# ============================================================

# ------------------------------------------------------------
# 0. Paquetes
# ------------------------------------------------------------

library(data.table)
library(dplyr)
library(tidyr)

# ------------------------------------------------------------
# 1. Leer base con población, defunciones y mx
# ------------------------------------------------------------

lt_input_bc <- fread("data/clean/lt_input_bc.csv")

# ------------------------------------------------------------
# 2. Función para asignar ax
# ------------------------------------------------------------
# ax representa el número promedio de años vividos dentro del intervalo
# por quienes fallecen en ese intervalo.
#
# Para este proyecto:
# - En edad 0 usamos ax = 0.07, porque la mortalidad infantil en BC
#   no es extremadamente alta y este valor es una aproximación común.
# - En edades 1, 2, 3 y 4 usamos ax = 0.5.
# - En grupos quinquenales usamos ax = 2.5.
# - En el intervalo abierto 85+ ax no se usa directamente.
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

# ------------------------------------------------------------
# 3. Función para construir una tabla de vida
# ------------------------------------------------------------

construir_tabla_vida <- function(datos) {
  
  datos <- datos %>%
    arrange(age) %>%
    mutate(
      ax = asignar_ax(age, n),
      
      # Probabilidad de muerte qx.
      # Para el intervalo abierto 85+, qx = 1.
      qx = case_when(
        age == 85 ~ 1,
        TRUE ~ (n * mx) / (1 + (n - ax) * mx)
      ),
      
      # Por seguridad, qx debe estar entre 0 y 1.
      qx = pmin(pmax(qx, 0), 1)
    )
  
  # Número de edades o intervalos
  k <- nrow(datos)
  
  # Vectores vacíos para ir llenando la tabla
  lx <- numeric(k)
  dx <- numeric(k)
  Lx <- numeric(k)
  
  # Raíz de la tabla de vida
  lx[1] <- 100000
  
  # Cálculo iterativo de lx y dx
  for (i in 1:k) {
    
    dx[i] <- lx[i] * datos$qx[i]
    
    if (i < k) {
      lx[i + 1] <- lx[i] - dx[i]
    }
  }
  
  # Cálculo de Lx
  for (i in 1:k) {
    
    if (datos$age[i] == 85) {
      # Intervalo abierto:
      # L_omega = l_omega / m_omega
      Lx[i] <- lx[i] / datos$mx[i]
      
    } else {
      # Intervalos cerrados:
      # Lx = n*l_{x+n} + ax*dx
      Lx[i] <- datos$n[i] * lx[i + 1] + datos$ax[i] * dx[i]
    }
  }
  
  # Tx se calcula acumulando Lx desde la última edad hacia atrás
  Tx <- rev(cumsum(rev(Lx)))
  
  # Esperanza de vida
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
# 4. Construir tablas por año y sexo
# ------------------------------------------------------------

tabla_vida_bc <- lt_input_bc %>%
  group_by(year, sex) %>%
  group_modify(~ construir_tabla_vida(.x)) %>%
  ungroup() %>%
  arrange(year, sex, age)

# ------------------------------------------------------------
# 5. Redondear para presentación
# ------------------------------------------------------------

tabla_vida_bc <- tabla_vida_bc %>%
  mutate(
    pop = round(pop, 0),
    deaths = round(deaths, 3),
    mx = round(mx, 8),
    ax = round(ax, 2),
    qx = round(qx, 8),
    lx = round(lx, 0),
    dx = round(dx, 0),
    Lx = round(Lx, 0),
    Tx = round(Tx, 0),
    ex = round(ex, 2)
  )

# ------------------------------------------------------------
# 6. Obtener esperanza de vida al nacer
# ------------------------------------------------------------

esperanza_vida_bc <- tabla_vida_bc %>%
  filter(age == 0) %>%
  select(year, sex, ex) %>%
  mutate(
    sex = case_when(
      sex == "m" ~ "Hombres",
      sex == "f" ~ "Mujeres",
      TRUE ~ sex
    )
  ) %>%
  arrange(year, sex)

# También la dejamos en formato ancho para el informe
esperanza_vida_bc_ancha <- esperanza_vida_bc %>%
  pivot_wider(
    names_from = sex,
    values_from = ex
  ) %>%
  arrange(year)

# ------------------------------------------------------------
# 7. Validaciones de coherencia
# ------------------------------------------------------------

validacion <- tabla_vida_bc %>%
  group_by(year, sex) %>%
  summarise(
    qx_min = min(qx, na.rm = TRUE),
    qx_max = max(qx, na.rm = TRUE),
    lx_inicial = first(lx),
    lx_final = last(lx),
    lx_decreciente = all(diff(lx) <= 0),
    ex_nacer = first(ex),
    .groups = "drop"
  )

print(validacion)

if (any(validacion$qx_min < 0 | validacion$qx_max > 1)) {
  stop("Hay valores de qx fuera del intervalo [0,1].")
}

if (any(validacion$lx_inicial != 100000)) {
  stop("Alguna tabla no inicia con l0 = 100000.")
}

if (any(validacion$lx_decreciente == FALSE)) {
  stop("Alguna función lx no es decreciente.")
}

# ------------------------------------------------------------
# 8. Guardar resultados
# ------------------------------------------------------------

fwrite(tabla_vida_bc, "data/clean/tabla_vida_bc.csv")
fwrite(esperanza_vida_bc_ancha, "data/clean/esperanza_vida_bc.csv")

# ------------------------------------------------------------
# 9. Mostrar resultados importantes
# ------------------------------------------------------------

cat("\nTabla de vida creada correctamente:\n")
print(tabla_vida_bc)

cat("\nEsperanza de vida al nacer por sexo y año:\n")
print(esperanza_vida_bc_ancha)

cat("\nArchivos creados:\n")
cat("- data/clean/tabla_vida_bc.csv\n")
cat("- data/clean/esperanza_vida_bc.csv\n")