# ============================================================================== 
# DISEÑO A: FUZZY RDD - TODAS LAS ELECCIONES
# ============================================================================== 

elecciones_A <- read_dta(file.path(dir_girardi, "elections_dataset.dta")) |>
  rename(countrycode = iso3code) |>
  filter(exclude != 1, year >= 1992, year <= 2013) |>
  select(countrycode, year, left_gov, left_win, parliamentary,
         pres_leftmargin, parl_leftmargin) |>
  mutate(
    treatment = if_else(parliamentary == 0, left_win, left_gov),
    margin_victory = if_else(parliamentary == 0, pres_leftmargin, parl_leftmargin),
    election_year = year
  ) |>
  filter(!is.na(treatment), !is.na(margin_victory)) |>
  select(countrycode, election_year, treatment, margin_victory, parliamentary)

muestra_A <- preparar_posteleccion(elecciones_A, panel_gap, incluir_parlamentaria = TRUE)
cat("N Fuzzy RDD (todas) =", nrow(muestra_A), "\n")

# Primera etapa
cat("\n=== PRIMERA ETAPA: Ganar elección -> Gobernar ===\n")
rd_A_first <- rdrobust(
  y = muestra_A$treatment,
  x = muestra_A$margin_victory,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)
print(rd_A_first)
exportar_rdrobust(rd_A_first, file.path(dir_tables, "Tabla_02_RDD_Fuzzy_Primera_Etapa_Todas_Elecciones.xlsx"), "First Stage")
guardar_rdplot(
  muestra_A$treatment, muestra_A$margin_victory,
  "Figura_01_RDD_Fuzzy_Primera_Etapa_Todas_Elecciones",
  "Primera etapa: Victoria izquierda -> Gobierno izquierda",
  "Margen de victoria izquierda (pp)",
  "Probabilidad de gobierno izquierda"
)

# Outcome 1
cat("\n=== FUZZY RDD - Todas: Brecha GDP-NTL % ===\n")
rd_A_gap <- rdrobust(
  y = muestra_A$gap_pct_mart,
  x = muestra_A$margin_victory,
  c = 0,
  fuzzy = muestra_A$treatment,
  kernel = "triangular",
  bwselect = "mserd"
)
print(rd_A_gap)
exportar_rdrobust(rd_A_gap, file.path(dir_tables, "Tabla_03_RDD_Fuzzy_Brecha_GDP_NTL_Todas_Elecciones.xlsx"), "Fuzzy All - Brecha %")
guardar_rdplot(
  muestra_A$gap_pct_mart, muestra_A$margin_victory,
  "Figura_02_RDD_Fuzzy_Brecha_GDP_NTL_Todas_Elecciones",
  "Fuzzy RDD: Brecha GDP-NTL (%) - Todas las elecciones",
  "Margen victoria izquierda (pp)",
  "Brecha GDP-NTL % (promedio t+1 a t+4)"
)

# Outcome 2
cat("\n=== FUZZY RDD - Todas: GDP oficial (within) ===\n")
rd_A_gdp <- rdrobust(
  y = muestra_A$lngdp14_w,
  x = muestra_A$margin_victory,
  c = 0,
  fuzzy = muestra_A$treatment,
  kernel = "triangular",
  bwselect = "mserd"
)
print(rd_A_gdp)
exportar_rdrobust(rd_A_gdp, file.path(dir_tables, "Tabla_04_RDD_Fuzzy_GDP_Oficial_Todas_Elecciones.xlsx"), "Fuzzy All - GDP within")
guardar_rdplot(
  muestra_A$lngdp14_w, muestra_A$margin_victory,
  "Figura_03_RDD_Fuzzy_GDP_Oficial_Todas_Elecciones",
  "Fuzzy RDD: GDP oficial (within) - Todas las elecciones",
  "Margen victoria izquierda (pp)",
  "ln(GDP) within promedio t+1 a t+4"
)

# Outcome 3
cat("\n=== FUZZY RDD - Todas: NTL satelital (within) ===\n")
rd_A_ntl <- rdrobust(
  y = muestra_A$lndn13_w,
  x = muestra_A$margin_victory,
  c = 0,
  fuzzy = muestra_A$treatment,
  kernel = "triangular",
  bwselect = "mserd"
)
print(rd_A_ntl)
exportar_rdrobust(rd_A_ntl, file.path(dir_tables, "Tabla_05_RDD_Fuzzy_NTL_Satelital_Todas_Elecciones.xlsx"), "Fuzzy All - NTL within")
guardar_rdplot(
  muestra_A$lndn13_w, muestra_A$margin_victory,
  "Figura_04_RDD_Fuzzy_NTL_Satelital_Todas_Elecciones",
  "Fuzzy RDD: NTL satelital (within) - Todas las elecciones",
  "Margen victoria izquierda (pp)",
  "ln(NTL) within promedio t+1 a t+4"
)

# ============================================================================== 
# DISEÑO B: SHARP RDD - SOLO PRESIDENCIALES
# ============================================================================== 

elecciones_B <- read_dta(file.path(dir_girardi, "elections_dataset.dta")) |>
  rename(countrycode = iso3code) |>
  filter(parliamentary == 0, exclude != 1, year >= 1992, year <= 2013) |>
  transmute(
    countrycode,
    election_year = year,
    treatment = left_win,
    margin_victory = pres_leftmargin
  ) |>
  filter(!is.na(treatment), !is.na(margin_victory))

muestra_B <- preparar_posteleccion(elecciones_B, panel_gap)
cat("N Sharp RDD (presidenciales) =", nrow(muestra_B), "\n")

resultados_B <- list(
  gap = list(y = muestra_B$gap_pct_mart, archivo = "Tabla_06_RDD_Sharp_Brecha_GDP_NTL_Presidenciales.xlsx",
             figura = "Figura_05_RDD_Sharp_Brecha_GDP_NTL_Presidenciales", titulo_tabla = "Sharp Pres - Brecha %",
             titulo = "Sharp RDD: Brecha GDP-NTL (%) - Presidenciales",
             ylabel = "Brecha GDP-NTL % (promedio t+1 a t+4)"),
  gdp = list(y = muestra_B$lngdp14_w, archivo = "Tabla_07_RDD_Sharp_GDP_Oficial_Presidenciales.xlsx",
             figura = "Figura_06_RDD_Sharp_GDP_Oficial_Presidenciales", titulo_tabla = "Sharp Pres - GDP within",
             titulo = "Sharp RDD: GDP oficial (within) - Presidenciales",
             ylabel = "ln(GDP) within promedio t+1 a t+4"),
  ntl = list(y = muestra_B$lndn13_w, archivo = "Tabla_08_RDD_Sharp_NTL_Satelital_Presidenciales.xlsx",
             figura = "Figura_07_RDD_Sharp_NTL_Satelital_Presidenciales", titulo_tabla = "Sharp Pres - NTL within",
             titulo = "Sharp RDD: NTL satelital (within) - Presidenciales",
             ylabel = "ln(NTL) within promedio t+1 a t+4")
)

for (r in resultados_B) {
  modelo <- rdrobust(
    y = r$y,
    x = muestra_B$margin_victory,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  print(modelo)
  exportar_rdrobust(modelo, file.path(dir_tables, r$archivo), r$titulo_tabla)
  guardar_rdplot(
    r$y, muestra_B$margin_victory,
    r$figura,
    r$titulo,
    "Margen victoria izquierda (pp)",
    r$ylabel
  )
}

# ============================================================================== 
# DISEÑO C: SHARP RDD - SOLO PARLAMENTARIAS
# ============================================================================== 

elecciones_C <- read_dta(file.path(dir_girardi, "elections_dataset.dta")) |>
  rename(countrycode = iso3code) |>
  filter(parliamentary == 1, exclude != 1, year >= 1992, year <= 2013) |>
  transmute(
    countrycode,
    election_year = year,
    treatment = as.numeric(parl_leftmargin >= 0),
    margin_victory = parl_leftmargin
  ) |>
  filter(!is.na(margin_victory))

muestra_C <- preparar_posteleccion(elecciones_C, panel_gap)
cat("N Sharp RDD (parlamentarias) =", nrow(muestra_C), "\n")

resultados_C <- list(
  gap = list(y = muestra_C$gap_pct_mart, archivo = "Tabla_09_RDD_Sharp_Brecha_GDP_NTL_Parlamentarias.xlsx",
             figura = "Figura_08_RDD_Sharp_Brecha_GDP_NTL_Parlamentarias", titulo_tabla = "Sharp Parl - Brecha %",
             titulo = "Sharp RDD: Brecha GDP-NTL (%) - Parlamentarias",
             ylabel = "Brecha GDP-NTL % (promedio t+1 a t+4)"),
  gdp = list(y = muestra_C$lngdp14_w, archivo = "Tabla_10_RDD_Sharp_GDP_Oficial_Parlamentarias.xlsx",
             figura = "Figura_09_RDD_Sharp_GDP_Oficial_Parlamentarias", titulo_tabla = "Sharp Parl - GDP within",
             titulo = "Sharp RDD: GDP oficial (within) - Parlamentarias",
             ylabel = "ln(GDP) within promedio t+1 a t+4"),
  ntl = list(y = muestra_C$lndn13_w, archivo = "Tabla_11_RDD_Sharp_NTL_Satelital_Parlamentarias.xlsx",
             figura = "Figura_10_RDD_Sharp_NTL_Satelital_Parlamentarias", titulo_tabla = "Sharp Parl - NTL within",
             titulo = "Sharp RDD: NTL satelital (within) - Parlamentarias",
             ylabel = "ln(NTL) within promedio t+1 a t+4")
)

for (r in resultados_C) {
  modelo <- rdrobust(
    y = r$y,
    x = muestra_C$margin_victory,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  print(modelo)
  exportar_rdrobust(modelo, file.path(dir_tables, r$archivo), r$titulo_tabla)
  guardar_rdplot(
    r$y, muestra_C$margin_victory,
    r$figura,
    r$titulo,
    "Margen victoria izquierda (pp)",
    r$ylabel
  )
}

# ============================================================================== 
# RESUMEN FINAL
# ============================================================================== 

cat("\n============================================\n")
cat("SCRIPT R 1 (MARTINEZ 1992-2013) COMPLETADO\n")
cat("Todos los resultados se guardaron en: ", dir_resultados, "\n", sep = "")
cat("============================================\n")
