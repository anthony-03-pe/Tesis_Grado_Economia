################################################################################
# TEST DE CONTINUIDAD DE COVARIABLES PREDETERMINADAS
#
# Covariables:
# 1. Brecha PIB--NTL en t-1
# 2. Brecha PIB--NTL en t-2
# 3. Brecha PIB--NTL en t-3
# 4. Logaritmo del PIB en t-1
# 5. Logaritmo de luces nocturnas en t-1
################################################################################

library(dplyr)
library(tidyr)
library(rdrobust)
library(openxlsx)


# ==============================================================================
# 1. COMPROBAR OBJETOS NECESARIOS
# ==============================================================================

stopifnot(
  exists("muestra_A"),
  exists("panel_gap"),
  exists("dir_resultados")
)

variables_muestra_necesarias <- c(
  "countrycode",
  "election_year",
  "margin_victory"
)

variables_panel_necesarias <- c(
  "countrycode",
  "year",
  "gap_pct_mart",
  "lngdp14_w",
  "lndn13_w"
)

faltan_muestra <- setdiff(
  variables_muestra_necesarias,
  names(muestra_A)
)

faltan_panel <- setdiff(
  variables_panel_necesarias,
  names(panel_gap)
)

if (length(faltan_muestra) > 0) {
  stop(
    paste(
      "Faltan variables en muestra_A:",
      paste(faltan_muestra, collapse = ", ")
    )
  )
}

if (length(faltan_panel) > 0) {
  stop(
    paste(
      "Faltan variables en panel_gap:",
      paste(faltan_panel, collapse = ", ")
    )
  )
}


# ==============================================================================
# 2. CREAR CARPETA DE RESULTADOS
# ==============================================================================

dir_covariables <- file.path(
  dir_resultados,
  "Validacion_RDD",
  "Test_Covariables"
)

dir.create(
  dir_covariables,
  recursive = TRUE,
  showWarnings = FALSE
)


# ==============================================================================
# 3. PREPARAR PANEL DE VARIABLES PREDETERMINADAS
# ==============================================================================

panel_covariables <- panel_gap |>
  select(
    countrycode,
    year,
    gap_pct_mart,
    lngdp14_w,
    lndn13_w
  ) |>
  distinct(
    countrycode,
    year,
    .keep_all = TRUE
  )


# ==============================================================================
# 4. PREPARAR BASE DE ELECCIONES
# ==============================================================================

base_elecciones <- muestra_A |>
  select(
    countrycode,
    election_year,
    margin_victory
  ) |>
  distinct(
    countrycode,
    election_year,
    .keep_all = TRUE
  )


# ==============================================================================
# 5. CONSTRUIR BRECHA t-1, t-2 Y t-3
# ==============================================================================

brechas_previas <- base_elecciones |>
  crossing(
    rezago = 1:3
  ) |>
  mutate(
    year = election_year - rezago
  ) |>
  left_join(
    panel_covariables |>
      select(
        countrycode,
        year,
        gap_pct_mart
      ),
    by = c(
      "countrycode",
      "year"
    )
  ) |>
  select(
    countrycode,
    election_year,
    rezago,
    gap_pct_mart
  ) |>
  pivot_wider(
    names_from = rezago,
    values_from = gap_pct_mart,
    names_glue = "gap_t_{rezago}"
  )


# ==============================================================================
# 6. CONSTRUIR PIB t-1 Y LUCES t-1
# ==============================================================================

pib_luces_t1 <- base_elecciones |>
  mutate(
    year = election_year - 1
  ) |>
  left_join(
    panel_covariables |>
      select(
        countrycode,
        year,
        lngdp14_w,
        lndn13_w
      ),
    by = c(
      "countrycode",
      "year"
    )
  ) |>
  transmute(
    countrycode,
    election_year,
    pib_t_1 = lngdp14_w,
    luces_t_1 = lndn13_w
  )


# ==============================================================================
# 7. UNIR TODAS LAS COVARIABLES
# ==============================================================================

muestra_balance <- base_elecciones |>
  left_join(
    brechas_previas,
    by = c(
      "countrycode",
      "election_year"
    )
  ) |>
  left_join(
    pib_luces_t1,
    by = c(
      "countrycode",
      "election_year"
    )
  )


cat("\nObservaciones no perdidas por covariable:\n")

print(
  sapply(
    muestra_balance[
      c(
        "gap_t_1",
        "gap_t_2",
        "gap_t_3",
        "pib_t_1",
        "luces_t_1"
      )
    ],
    function(x) sum(!is.na(x))
  )
)


# ==============================================================================
# 8. DEFINIR COVARIABLES Y ETIQUETAS
# ==============================================================================

covariables <- c(
  "gap_t_1",
  "gap_t_2",
  "gap_t_3",
  "pib_t_1",
  "luces_t_1"
)

etiquetas <- c(
  gap_t_1 = "Brecha PIB--NTL, t-1",
  gap_t_2 = "Brecha PIB--NTL, t-2",
  gap_t_3 = "Brecha PIB--NTL, t-3",
  pib_t_1 = "Logaritmo del PIB, t-1",
  luces_t_1 = "Logaritmo de luces nocturnas, t-1"
)


# ==============================================================================
# 9. FUNCIÓN PARA ESTIMAR CADA TEST
# ==============================================================================

estimar_balance <- function(variable, datos) {
  
  y <- datos[[variable]]
  x <- datos$margin_victory
  
  muestra_valida <- (
    !is.na(y) &
      !is.na(x) &
      is.finite(as.numeric(y)) &
      is.finite(as.numeric(x))
  )
  
  y <- as.numeric(
    y[muestra_valida]
  )
  
  x <- as.numeric(
    x[muestra_valida]
  )
  
  n_total <- length(y)
  n_izquierda <- sum(x < 0)
  n_derecha <- sum(x >= 0)
  
  if (
    n_total < 30 ||
    n_izquierda < 10 ||
    n_derecha < 10 ||
    length(unique(y)) < 2
  ) {
    
    return(
      data.frame(
        Covariable = unname(etiquetas[variable]),
        Coeficiente_convencional = NA_real_,
        Coeficiente_corregido = NA_real_,
        Error_estandar_robusto = NA_real_,
        Estadistico_z_robusto = NA_real_,
        Valor_p_robusto = NA_real_,
        IC_95_inferior = NA_real_,
        IC_95_superior = NA_real_,
        h_izquierda = NA_real_,
        h_derecha = NA_real_,
        Observaciones = n_total,
        Observaciones_izquierda = n_izquierda,
        Observaciones_derecha = n_derecha,
        Estado = "Muestra insuficiente"
      )
    )
  }
  
  modelo <- tryCatch(
    rdrobust(
      y = y,
      x = x,
      c = 0,
      p = 1,
      q = 2,
      kernel = "triangular",
      
      # Para pruebas de falsificación interesa la inferencia
      bwselect = "cerrd"
    ),
    error = function(e) NULL
  )
  
  if (is.null(modelo)) {
    
    return(
      data.frame(
        Covariable = unname(etiquetas[variable]),
        Coeficiente_convencional = NA_real_,
        Coeficiente_corregido = NA_real_,
        Error_estandar_robusto = NA_real_,
        Estadistico_z_robusto = NA_real_,
        Valor_p_robusto = NA_real_,
        IC_95_inferior = NA_real_,
        IC_95_superior = NA_real_,
        h_izquierda = NA_real_,
        h_derecha = NA_real_,
        Observaciones = n_total,
        Observaciones_izquierda = n_izquierda,
        Observaciones_derecha = n_derecha,
        Estado = "Error en rdrobust"
      )
    )
  }
  
  data.frame(
    Covariable = unname(etiquetas[variable]),
    
    Coeficiente_convencional =
      as.numeric(modelo$coef[1, 1]),
    
    Coeficiente_corregido =
      as.numeric(modelo$coef[3, 1]),
    
    Error_estandar_robusto =
      as.numeric(modelo$se[3, 1]),
    
    Estadistico_z_robusto =
      as.numeric(modelo$z[3, 1]),
    
    Valor_p_robusto =
      as.numeric(modelo$pv[3, 1]),
    
    IC_95_inferior =
      as.numeric(modelo$ci[3, 1]),
    
    IC_95_superior =
      as.numeric(modelo$ci[3, 2]),
    
    h_izquierda =
      as.numeric(modelo$bws[1, 1]),
    
    h_derecha =
      as.numeric(modelo$bws[1, 2]),
    
    Observaciones = n_total,
    
    Observaciones_izquierda = n_izquierda,
    
    Observaciones_derecha = n_derecha,
    
    Estado = "Estimado correctamente"
  )
}


# ==============================================================================
# 10. EJECUTAR LOS CINCO TESTS
# ==============================================================================

resultados_balance <- do.call(
  rbind,
  lapply(
    covariables,
    estimar_balance,
    datos = muestra_balance
  )
)


# ==============================================================================
# 11. CORRECCIÓN POR PRUEBAS MÚLTIPLES
# ==============================================================================

resultados_balance$Valor_q_BH <- p.adjust(
  resultados_balance$Valor_p_robusto,
  method = "BH"
)

resultados_balance$Conclusion_5_por_ciento <- ifelse(
  is.na(resultados_balance$Valor_p_robusto),
  NA_character_,
  ifelse(
    resultados_balance$Valor_p_robusto < 0.05,
    "Discontinuidad significativa",
    "No se rechaza continuidad"
  )
)

resultados_balance$Conclusion_BH_5_por_ciento <- ifelse(
  is.na(resultados_balance$Valor_q_BH),
  NA_character_,
  ifelse(
    resultados_balance$Valor_q_BH < 0.05,
    "Discontinuidad significativa",
    "No se rechaza continuidad"
  )
)


# Mostrar resultados en la consola
print(
  resultados_balance,
  row.names = FALSE
)


# ==============================================================================
# 12. PREPARAR TABLA PARA EXCEL
# ==============================================================================

resultado_excel <- resultados_balance |>
  mutate(
    across(
      where(is.numeric),
      ~ round(.x, 4)
    )
  )


# ==============================================================================
# 13. EXPORTAR EXCEL TIPO STATA, UNA SOLA HOJA
# ==============================================================================

archivo_excel <- file.path(
  dir_covariables,
  "Tabla_Test_Balance_Covariables_RDD.xlsx"
)

wb <- createWorkbook()

addWorksheet(
  wb,
  "Resultados",
  gridLines = FALSE
)

writeData(
  wb,
  sheet = "Resultados",
  x = "Test de continuidad de covariables predeterminadas",
  startRow = 1,
  startCol = 1
)

writeData(
  wb,
  sheet = "Resultados",
  x = paste0(
    "Running variable: margen de victoria | Cutoff: 0 | ",
    "Kernel triangular | Bandwidth CER-optimo"
  ),
  startRow = 2,
  startCol = 1
)

writeData(
  wb,
  sheet = "Resultados",
  x = resultado_excel,
  startRow = 4,
  startCol = 1
)

estilo_titulo <- createStyle(
  fontName = "Courier New",
  fontSize = 13,
  textDecoration = "bold",
  halign = "left"
)

estilo_subtitulo <- createStyle(
  fontName = "Courier New",
  fontSize = 10,
  fontColour = "#555555",
  halign = "left"
)

estilo_encabezado <- createStyle(
  fontName = "Courier New",
  fontSize = 10,
  textDecoration = "bold",
  halign = "center",
  valign = "center",
  border = c("top", "bottom")
)

estilo_cuerpo <- createStyle(
  fontName = "Courier New",
  fontSize = 10,
  halign = "center"
)

estilo_numerico <- createStyle(
  fontName = "Courier New",
  fontSize = 10,
  numFmt = "0.0000",
  halign = "center"
)

addStyle(
  wb,
  "Resultados",
  estilo_titulo,
  rows = 1,
  cols = 1,
  gridExpand = TRUE
)

addStyle(
  wb,
  "Resultados",
  estilo_subtitulo,
  rows = 2,
  cols = 1,
  gridExpand = TRUE
)

addStyle(
  wb,
  "Resultados",
  estilo_encabezado,
  rows = 4,
  cols = 1:ncol(resultado_excel),
  gridExpand = TRUE
)

addStyle(
  wb,
  "Resultados",
  estilo_cuerpo,
  rows = 5:(4 + nrow(resultado_excel)),
  cols = 1:ncol(resultado_excel),
  gridExpand = TRUE
)

columnas_numericas <- which(
  vapply(
    resultado_excel,
    is.numeric,
    logical(1)
  )
)

if (length(columnas_numericas) > 0) {
  
  addStyle(
    wb,
    "Resultados",
    estilo_numerico,
    rows = 5:(4 + nrow(resultado_excel)),
    cols = columnas_numericas,
    gridExpand = TRUE,
    stack = TRUE
  )
}

setColWidths(
  wb,
  "Resultados",
  cols = 1,
  widths = 38
)

setColWidths(
  wb,
  "Resultados",
  cols = 2:ncol(resultado_excel),
  widths = 18
)

freezePane(
  wb,
  "Resultados",
  firstActiveRow = 5
)

saveWorkbook(
  wb,
  file = archivo_excel,
  overwrite = TRUE
)


# ==============================================================================
# 14. MENSAJE FINAL
# ==============================================================================

cat("\n")
cat("============================================================\n")
cat("TEST DE COVARIABLES COMPLETADO\n")
cat("============================================================\n\n")

cat(
  "Tabla guardada en:\n",
  archivo_excel,
  "\n"
)