# ============================================================
# 05_graficas.R
# Gráficas para el informe de tablas de vida
# Baja California, 2010, 2019 y 2021
# ============================================================

# ------------------------------------------------------------
# 0. Paquetes
# ------------------------------------------------------------

library(data.table)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)

# ------------------------------------------------------------
# 1. Crear carpeta de salida
# ------------------------------------------------------------

dir.create("graficas", showWarnings = FALSE)

# ------------------------------------------------------------
# 2. Leer bases
# ------------------------------------------------------------

tabla_vida_bc <- fread("data/clean/tabla_vida_bc.csv")
esperanza_vida_bc <- fread("data/clean/esperanza_vida_bc.csv")

# ------------------------------------------------------------
# 3. Preparar etiquetas
# ------------------------------------------------------------

tabla_vida_bc <- tabla_vida_bc %>%
  mutate(
    sexo = case_when(
      sex == "m" ~ "Hombres",
      sex == "f" ~ "Mujeres",
      TRUE ~ sex
    ),
    anio = as.factor(year),
    mx_plot = if_else(mx <= 0, NA_real_, mx),
    qx_plot = if_else(qx <= 0, NA_real_, qx)
  )

# Colores sencillos
col_hombres <- "#2C7FB8"
col_mujeres <- "#D95F82"

# ------------------------------------------------------------
# 4. Gráfica de mx
# ------------------------------------------------------------

g_mx <- ggplot(
  tabla_vida_bc,
  aes(x = age, y = mx_plot, color = sexo, group = sexo)
) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.8) +
  facet_wrap(~ anio, nrow = 1) +
  scale_y_log10(labels = label_number()) +
  scale_color_manual(values = c("Hombres" = col_hombres,
                                "Mujeres" = col_mujeres)) +
  labs(
    title = "Tasas específicas de mortalidad por edad",
    subtitle = "Baja California, 2010, 2019 y 2021",
    x = "Edad",
    y = expression(m[x]),
    color = "Sexo",
    caption = "Fuente: elaboración propia con datos de INEGI y CONAPO."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  filename = "graficas/mx_bc.png",
  plot = g_mx,
  width = 9,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 5. Gráfica de qx
# ------------------------------------------------------------

g_qx <- ggplot(
  tabla_vida_bc,
  aes(x = age, y = qx_plot, color = anio, group = anio)
) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.6) +
  facet_wrap(~ sexo, nrow = 1) +
  scale_y_log10(labels = label_number()) +
  labs(
    title = "Probabilidades de muerte por edad",
    subtitle = "Baja California, comparación por sexo y año",
    x = "Edad",
    y = expression(q[x]),
    color = "Año",
    caption = "Fuente: elaboración propia con datos de INEGI y CONAPO."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  filename = "graficas/qx_bc.png",
  plot = g_qx,
  width = 9,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 6. Gráfica de lx
# ------------------------------------------------------------

g_lx <- ggplot(
  tabla_vida_bc,
  aes(x = age, y = lx, color = anio, group = anio)
) +
  geom_line(linewidth = 1) +
  facet_wrap(~ sexo, nrow = 1) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Función de sobrevivientes",
    subtitle = "Número de sobrevivientes de una cohorte inicial de 100,000 personas",
    x = "Edad",
    y = expression(l[x]),
    color = "Año",
    caption = "Fuente: elaboración propia con datos de INEGI y CONAPO."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  filename = "graficas/lx_bc.png",
  plot = g_lx,
  width = 9,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 7. Gráfica de esperanza de vida al nacer
# ------------------------------------------------------------

e0_larga <- esperanza_vida_bc %>%
  pivot_longer(
    cols = c(Hombres, Mujeres),
    names_to = "sexo",
    values_to = "e0"
  ) %>%
  mutate(anio = as.factor(year))

g_e0 <- ggplot(
  e0_larga,
  aes(x = anio, y = e0, fill = sexo)
) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(
    aes(label = round(e0, 2)),
    position = position_dodge(width = 0.8),
    vjust = -0.3,
    size = 3.5
  ) +
  scale_fill_manual(values = c("Hombres" = col_hombres,
                               "Mujeres" = col_mujeres)) +
  labs(
    title = "Esperanza de vida al nacer",
    subtitle = "Baja California, 2010, 2019 y 2021",
    x = "Año",
    y = expression(e[0]),
    fill = "Sexo",
    caption = "Fuente: elaboración propia con datos de INEGI y CONAPO."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  filename = "graficas/e0_bc.png",
  plot = g_e0,
  width = 8,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 8. Gráfica del impacto COVID: razón mx 2021 / mx 2019
# ------------------------------------------------------------
# Esta gráfica muestra cuánto aumentó la mortalidad en 2021
# respecto al año previo a la pandemia.
#
# Si la razón es mayor que 1, la mortalidad fue mayor en 2021.
# ------------------------------------------------------------

impacto_covid <- tabla_vida_bc %>%
  filter(year %in% c(2019, 2021)) %>%
  select(year, sex, sexo, age, mx) %>%
  pivot_wider(
    names_from = year,
    values_from = mx,
    names_prefix = "mx_"
  ) %>%
  mutate(
    razon_mx = mx_2021 / mx_2019
  )

g_covid <- ggplot(
  impacto_covid,
  aes(x = age, y = razon_mx, color = sexo, group = sexo)
) +
  geom_hline(yintercept = 1, linetype = "dashed") +
  geom_line(linewidth = 1) +
  geom_point(size = 1.8) +
  scale_color_manual(values = c("Hombres" = col_hombres,
                                "Mujeres" = col_mujeres)) +
  labs(
    title = "Cambio relativo de la mortalidad en 2021 respecto a 2019",
    subtitle = expression("Razón " ~ m[x] ~ " 2021 / " ~ m[x] ~ " 2019"),
    x = "Edad",
    y = expression(m[x]~"2021 /"~m[x]~"2019"),
    color = "Sexo",
    caption = "Fuente: elaboración propia con datos de INEGI y CONAPO."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  filename = "graficas/impacto_covid_mx_bc.png",
  plot = g_covid,
  width = 9,
  height = 5,
  dpi = 300
)

# ------------------------------------------------------------
# 9. Revisión final
# ------------------------------------------------------------

cat("\nGráficas creadas correctamente en la carpeta graficas:\n")
print(list.files("graficas"))