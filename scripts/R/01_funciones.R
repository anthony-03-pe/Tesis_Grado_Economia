# ============================================================================== 
# 2. FUNCIONES AUXILIARES
# ============================================================================== 

# Exporta cada resultado de rdrobust en UN SOLO archivo Excel y UNA SOLA hoja.
# La presentación imita la salida compacta de Stata.
exportar_rdrobust <- function(modelo, archivo, titulo) {
  extraer_vector <- function(x, n = 3) {
    if (is.null(x)) return(rep(NA_real_, n))
    z <- suppressWarnings(as.numeric(x))
    if (length(z) < n) z <- c(z, rep(NA_real_, n - length(z)))
    z[seq_len(n)]
  }
  
  estimacion <- extraer_vector(modelo$coef)
  error_std  <- extraer_vector(modelo$se)
  estad_z    <- extraer_vector(modelo$z)
  valor_p    <- extraer_vector(modelo$pv)
  
  ci <- tryCatch(as.matrix(modelo$ci), error = function(e) matrix(NA_real_, 3, 2))
  if (nrow(ci) < 3 || ncol(ci) < 2) ci <- matrix(NA_real_, 3, 2)
  
  tabla_principal <- data.frame(
    Método = c("Conventional", "Bias-corrected", "Robust"),
    Coeficiente = estimacion,
    `Error estándar` = error_std,
    `Estadístico z` = estad_z,
    `Valor p` = valor_p,
    `IC 95% inferior` = ci[1:3, 1],
    `IC 95% superior` = ci[1:3, 2],
    check.names = FALSE
  )
  
  # Información adicional de muestra y bandwidths.
  n_total <- suppressWarnings(as.numeric(modelo$N))
  n_h <- suppressWarnings(as.numeric(modelo$N_h))
  bws <- tryCatch(as.matrix(modelo$bws), error = function(e) NULL)
  
  info <- data.frame(
    Estadístico = character(),
    Izquierda = numeric(),
    Derecha = numeric(),
    check.names = FALSE
  )
  
  if (length(n_total) >= 2) {
    info <- rbind(info, data.frame(
      Estadístico = "Observaciones",
      Izquierda = n_total[1], Derecha = n_total[2]
    ))
  }
  if (length(n_h) >= 2) {
    info <- rbind(info, data.frame(
      Estadístico = "Observaciones efectivas",
      Izquierda = n_h[1], Derecha = n_h[2]
    ))
  }
  if (!is.null(bws) && ncol(bws) >= 2) {
    rn <- rownames(bws)
    if (is.null(rn)) rn <- paste0("Bandwidth ", seq_len(nrow(bws)))
    for (i in seq_len(nrow(bws))) {
      info <- rbind(info, data.frame(
        Estadístico = rn[i],
        Izquierda = suppressWarnings(as.numeric(bws[i, 1])),
        Derecha = suppressWarnings(as.numeric(bws[i, 2]))
      ))
    }
  }
  
  wb <- createWorkbook()
  addWorksheet(wb, "Resultados", gridLines = FALSE)
  
  estilo_titulo <- createStyle(
    fontSize = 14, textDecoration = "bold",
    halign = "center", valign = "center"
  )
  estilo_encabezado <- createStyle(
    textDecoration = "bold", halign = "center",
    border = c("Top", "Bottom"), borderStyle = "thin"
  )
  estilo_numero <- createStyle(numFmt = "0.0000", halign = "center")
  estilo_entero <- createStyle(numFmt = "0", halign = "center")
  estilo_nota <- createStyle(fontSize = 9, fontColour = "#444444", wrapText = TRUE)
  estilo_seccion <- createStyle(textDecoration = "bold", border = "Bottom")
  
  mergeCells(wb, "Resultados", cols = 1:7, rows = 1)
  writeData(wb, "Resultados", titulo, startRow = 1, startCol = 1)
  addStyle(wb, "Resultados", estilo_titulo, rows = 1, cols = 1:7, gridExpand = TRUE)
  
  writeData(wb, "Resultados", tabla_principal, startRow = 3, headerStyle = estilo_encabezado)
  addStyle(wb, "Resultados", estilo_numero,
           rows = 4:(3 + nrow(tabla_principal)), cols = 2:7,
           gridExpand = TRUE, stack = TRUE)
  
  fila_info <- 5 + nrow(tabla_principal)
  writeData(wb, "Resultados", "Información de la estimación", startRow = fila_info, startCol = 1)
  addStyle(wb, "Resultados", estilo_seccion, rows = fila_info, cols = 1:3, gridExpand = TRUE)
  
  if (nrow(info) > 0) {
    writeData(wb, "Resultados", info, startRow = fila_info + 1, headerStyle = estilo_encabezado)
    addStyle(wb, "Resultados", estilo_numero,
             rows = (fila_info + 2):(fila_info + 1 + nrow(info)), cols = 2:3,
             gridExpand = TRUE, stack = TRUE)
  }
  
  fila_notas <- fila_info + max(nrow(info), 1) + 3
  notas <- c(
    "Notas:",
    "Punto de corte: 0.",
    "Kernel triangular.",
    "Bandwidth seleccionado mediante mserd.",
    "La inferencia recomendada corresponde a la fila Robust."
  )
  writeData(wb, "Resultados", notas, startRow = fila_notas, startCol = 1, colNames = FALSE)
  addStyle(wb, "Resultados", estilo_nota,
           rows = fila_notas:(fila_notas + length(notas) - 1), cols = 1:7,
           gridExpand = TRUE)
  
  setColWidths(wb, "Resultados", cols = 1, widths = 24)
  setColWidths(wb, "Resultados", cols = 2:7, widths = 17)
  setRowHeights(wb, "Resultados", rows = 1, heights = 25)
  freezePane(wb, "Resultados", firstActiveRow = 4)
  
  saveWorkbook(wb, archivo, overwrite = TRUE)
}

# Exporta la tabla de cuatro modelos de efectos fijos con formato Stata/esttab.
exportar_tabla_beta <- function(modelos, archivo) {
  nombres_modelos <- c("(1)", "(2)", "(3)", "(4)")
  etiquetas <- c(
    lndn13 = "Ln(luces nocturnas)",
    fiw = "Freedom in the World",
    fiw2 = "Freedom in the World²",
    lndn13_fiw = "Ln(luces) × FiW"
  )
  
  estrellas <- function(p) {
    ifelse(is.na(p), "",
           ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", ""))))
  }
  
  filas <- list()
  fila_id <- 1
  
  for (v in names(etiquetas)) {
    coef_fila <- c(etiquetas[[v]])
    se_fila <- c("")
    
    for (m in modelos) {
      ct <- as.data.frame(coeftable(m))
      if (v %in% rownames(ct)) {
        b <- ct[v, "Estimate"]
        se <- ct[v, "Std. Error"]
        pval <- ct[v, "Pr(>|t|)"]
        coef_fila <- c(coef_fila, sprintf("%.4f%s", b, estrellas(pval)))
        se_fila <- c(se_fila, sprintf("(%.4f)", se))
      } else {
        coef_fila <- c(coef_fila, "")
        se_fila <- c(se_fila, "")
      }
    }
    
    filas[[fila_id]] <- coef_fila; fila_id <- fila_id + 1
    filas[[fila_id]] <- se_fila; fila_id <- fila_id + 1
  }
  
  # Estadísticos al pie de la tabla.
  obs <- c("Observaciones", sapply(modelos, nobs))
  r2w <- c("R² within", sapply(modelos, function(m) sprintf("%.4f", fitstat(m, "wr2")$wr2)))
  fe_pais <- c("Efectos fijos país", rep("Sí", length(modelos)))
  fe_anio <- c("Efectos fijos año", rep("Sí", length(modelos)))
  cluster <- c("Errores agrupados por país", rep("Sí", length(modelos)))
  
  matriz <- do.call(rbind, c(filas, list(obs, r2w, fe_pais, fe_anio, cluster)))
  tabla <- as.data.frame(matriz, stringsAsFactors = FALSE)
  names(tabla) <- c("Variable", nombres_modelos)
  
  wb <- createWorkbook()
  addWorksheet(wb, "Resultados", gridLines = FALSE)
  
  estilo_titulo <- createStyle(fontSize = 14, textDecoration = "bold", halign = "center")
  estilo_encabezado <- createStyle(
    textDecoration = "bold", halign = "center",
    border = c("Top", "Bottom"), borderStyle = "thin"
  )
  estilo_variable <- createStyle(halign = "left")
  estilo_celda <- createStyle(halign = "center")
  estilo_se <- createStyle(halign = "center", fontColour = "#444444")
  estilo_nota <- createStyle(fontSize = 9, fontColour = "#444444", wrapText = TRUE)
  estilo_pie <- createStyle(border = "Top", borderStyle = "thin")
  
  mergeCells(wb, "Resultados", cols = 1:5, rows = 1)
  writeData(wb, "Resultados", "Estimación de la relación PIB–luminosidad", startRow = 1, startCol = 1)
  addStyle(wb, "Resultados", estilo_titulo, rows = 1, cols = 1:5, gridExpand = TRUE)
  
  writeData(wb, "Resultados", tabla, startRow = 3, headerStyle = estilo_encabezado)
  addStyle(wb, "Resultados", estilo_variable, rows = 4:(3 + nrow(tabla)), cols = 1, gridExpand = TRUE)
  addStyle(wb, "Resultados", estilo_celda, rows = 4:(3 + nrow(tabla)), cols = 2:5, gridExpand = TRUE)
  
  # Las filas pares dentro del bloque de coeficientes son errores estándar.
  filas_se <- 5 + 2 * (seq_along(etiquetas) - 1)
  addStyle(wb, "Resultados", estilo_se, rows = filas_se, cols = 2:5, gridExpand = TRUE, stack = TRUE)
  
  fila_pie <- 4 + 2 * length(etiquetas)
  addStyle(wb, "Resultados", estilo_pie, rows = fila_pie, cols = 1:5, gridExpand = TRUE, stack = TRUE)
  
  fila_notas <- 5 + nrow(tabla)
  notas <- c(
    "Notas: errores estándar agrupados por país entre paréntesis.",
    "*** p<0.01, ** p<0.05, * p<0.10.",
    "Todos los modelos incluyen efectos fijos de país y año."
  )
  writeData(wb, "Resultados", notas, startRow = fila_notas, startCol = 1, colNames = FALSE)
  addStyle(wb, "Resultados", estilo_nota,
           rows = fila_notas:(fila_notas + length(notas) - 1), cols = 1:5,
           gridExpand = TRUE)
  
  setColWidths(wb, "Resultados", cols = 1, widths = 32)
  setColWidths(wb, "Resultados", cols = 2:5, widths = 16)
  setRowHeights(wb, "Resultados", rows = 1, heights = 25)
  freezePane(wb, "Resultados", firstActiveRow = 4)
  
  saveWorkbook(wb, archivo, overwrite = TRUE)
}

# Muestra el gráfico en RStudio y lo guarda en PDF y PNG.
# El estilo replica una presentación académica limpia, cercana a Stata.
guardar_rdplot <- function(y, x, nombre_base, titulo, etiqueta_x, etiqueta_y) {
  grafico <- rdplot(
    y = y,
    x = x,
    c = 0,
    kernel = "triangular",
    hide = TRUE,
    title = titulo,
    x.label = etiqueta_x,
    y.label = etiqueta_y
  )
  
  p <- grafico$rdplot +
    geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.65) +
    labs(
      title = titulo,
      subtitle = "Estimación de discontinuidad en el punto de corte cero",
      x = etiqueta_x,
      y = etiqueta_y,
      caption = "Notas: kernel triangular; bandwidth seleccionado mediante MSE."
    ) +
    theme_bw(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0),
      plot.subtitle = element_text(size = 10.5, margin = margin(b = 10)),
      axis.title = element_text(face = "bold"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(linewidth = 0.25),
      legend.position = "bottom",
      plot.caption = element_text(hjust = 0, size = 9),
      plot.margin = margin(12, 16, 12, 12)
    )
  
  # Mostrar el gráfico en el panel Plots de RStudio.
  print(p)
  
  archivo_pdf <- file.path(dir_resultados, paste0(nombre_base, ".pdf"))
  archivo_png <- file.path(dir_resultados, paste0(nombre_base, ".png"))
  
  ggsave(
    filename = archivo_pdf,
    plot = p,
    width = 8.5,
    height = 6.2,
    units = "in",
    device = cairo_pdf
  )
  
  ggsave(
    filename = archivo_png,
    plot = p,
    width = 8.5,
    height = 6.2,
    units = "in",
    dpi = 320
  )
  
  invisible(p)
}

# Expande cada elección a t+1, t+2, t+3 y t+4, une el panel y promedia.
preparar_posteleccion <- function(elecciones, panel_gap, incluir_parlamentaria = FALSE) {
  elecciones |>
    tidyr::uncount(weights = 4, .id = "k") |>
    mutate(year = election_year + k) |>
    left_join(panel_gap, by = c("countrycode", "year")) |>
    group_by(countrycode, election_year) |>
    summarise(
      gap_pct_mart = mean(gap_pct_mart, na.rm = TRUE),
      gap_mart = mean(gap_mart, na.rm = TRUE),
      lngdp14_w = mean(lngdp14_w, na.rm = TRUE),
      lndn13_w = mean(lndn13_w, na.rm = TRUE),
      treatment = mean(treatment, na.rm = TRUE),
      margin_victory = mean(margin_victory, na.rm = TRUE),
      parliamentary = if (incluir_parlamentaria) mean(parliamentary, na.rm = TRUE) else NA_real_,
      .groups = "drop"
    ) |>
    mutate(across(c(gap_pct_mart, gap_mart, lngdp14_w, lndn13_w),
                  ~ ifelse(is.nan(.x), NA_real_, .x))) |>
    filter(!is.na(gap_pct_mart))
}

