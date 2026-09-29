# ============================================================================== 
# PASO 1: REPLICAR LAS COLUMNAS (1)-(4) DE LA TABLA 1 DE MARTÍNEZ
# ============================================================================== 

estimations <- read_dta(file.path(dir_master, "Estimations.dta")) |>
  filter(year >= 1992, year <= 2013) |>
  select(countrycode, year, lngdp14, lndn13, fiw, fiw2) |>
  filter(!is.na(lngdp14), !is.na(lndn13), !is.na(fiw)) |>
  mutate(lndn13_fiw = lndn13 * fiw)

m1 <- feols(lngdp14 ~ lndn13 | countrycode + year,
            data = estimations, vcov = ~countrycode)

m2 <- feols(lngdp14 ~ lndn13 + fiw | countrycode + year,
            data = estimations, vcov = ~countrycode)

# Columna (3) de Martínez:
# ln(GDP) = ln(NTL) + FiW + [ln(NTL) × FiW] + FE país + FE año
m3 <- feols(lngdp14 ~ lndn13 + fiw + lndn13_fiw | countrycode + year,
            data = estimations, vcov = ~countrycode)

# Columna (4), especificación preferida de Martínez:
# se agrega FiW² a la especificación de la columna (3)
m4 <- feols(lngdp14 ~ lndn13 + fiw + fiw2 + lndn13_fiw | countrycode + year,
            data = estimations, vcov = ~countrycode)

# Comprobación de las cuatro especificaciones:
# (1) ln(NTL)
# (2) ln(NTL) + FiW
# (3) ln(NTL) + FiW + ln(NTL)×FiW
# (4) ln(NTL) + FiW + FiW² + ln(NTL)×FiW
cat("\n============================================================\n")
cat("TABLA 1 DE MARTÍNEZ: ESPECIFICACIONES (1)-(4)\n")
cat("============================================================\n")
etable(
  m1, m2, m3, m4,
  headers = c("(1)", "(2)", "(3)", "(4)"),
  fitstat = ~ n + r2 + wr2,
  digits = 4
)

exportar_tabla_beta(
  modelos = list(m1, m2, m3, m4),
  archivo = file.path(dir_tables, "Tabla_01_Modelos_FE_Beta_Martinez.xlsx")
)

# Para construir el GDP–Lights Gap se utiliza la especificación preferida,
# correspondiente a la columna (4) de Martínez.
beta_mart <- unname(coef(m4)["lndn13"])

cat("============================================\n")
cat("beta limpio (Martinez) =", beta_mart, "\n")
cat("============================================\n")

writeLines(
  paste0("beta limpio (Martinez 1992-2013) = ", beta_mart),
  con = file.path(dir_tables, "Resultado_01_Beta_Limpio_Martinez.txt")
)

# ============================================================================== 
# PASO 2: TRANSFORMACIÓN WITHIN MANUAL
# ============================================================================== 

panel_gap <- estimations |>
  group_by(countrycode) |>
  mutate(
    mi_lngdp14 = mean(lngdp14, na.rm = TRUE),
    mi_lndn13 = mean(lndn13, na.rm = TRUE)
  ) |>
  ungroup() |>
  group_by(year) |>
  mutate(
    mt_lngdp14 = mean(lngdp14, na.rm = TRUE),
    mt_lndn13 = mean(lndn13, na.rm = TRUE)
  ) |>
  ungroup() |>
  mutate(
    mg_lngdp14 = mean(lngdp14, na.rm = TRUE),
    mg_lndn13 = mean(lndn13, na.rm = TRUE),
    lngdp14_w = lngdp14 - mi_lngdp14 - mt_lngdp14 + mg_lngdp14,
    lndn13_w = lndn13 - mi_lndn13 - mt_lndn13 + mg_lndn13,
    gap_mart = lngdp14_w - beta_mart * lndn13_w,
    gap_pct_mart = (exp(gap_mart) - 1) * 100
  ) |>
  select(countrycode, year, gap_mart, gap_pct_mart, lngdp14_w, lndn13_w)

write_dta(panel_gap, file.path(dir_resultados, "Datos_01_Panel_Gap_Martinez.dta"))
saveRDS(panel_gap, file.path(dir_resultados, "Datos_01_Panel_Gap_Martinez.rds"))

