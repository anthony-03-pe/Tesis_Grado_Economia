################################################################################
# TEST DE MANIPULACIÓN / CONTINUIDAD DE LA DENSIDAD
#
# Running variable: margin_victory
# Punto de corte: 0
# Eje X: intervalos de 50 unidades
# Exportación: Excel con formato similar a Stata
################################################################################


# ==============================================================================
# 0. PAQUETES
# ==============================================================================

library(rddensity)
library(ggplot2)
library(openxlsx)


# ==============================================================================
# 1. COMPROBAR OBJETOS NECESARIOS
# ==============================================================================

if (!exists("muestra_A")) {
  stop(
    paste(
      "No existe el objeto 'muestra_A'.",
      "Ejecuta primero el código principal que construye la muestra."
    )
  )
}

if (!"margin_victory" %in% names(muestra_A)) {
  stop(
    "La variable 'margin_victory' no se encuentra dentro de muestra_A."
  )
}

# Si no existe dir_resultados, se usa el directorio de trabajo actual
if (!exists("dir_resultados")) {
  dir_resultados <- getwd()
}


# ==============================================================================
# 2. CREAR CARPETAS
# ==============================================================================

dir_manipulacion <- file.path(
  dir_resultados,
  "Validacion_RDD",
  "Test_Manipulacion"
)

dir_figuras_manipulacion <- file.path(
  dir_manipulacion,
  "Figuras"
)

dir_tablas_manipulacion <- file.path(
  dir_manipulacion,
  "Tablas"
)

dir.create(
  dir_figuras_manipulacion,
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  dir_tablas_manipulacion,
  recursive = TRUE,
  showWarnings = FALSE
)


# ==============================================================================
# 3. PREPARAR LA RUNNING VARIABLE
# ==============================================================================

running_variable <- suppressWarnings(
  as.numeric(muestra_A$margin_victory)
)

running_variable <- running_variable[
  is.finite(running_variable)
]

n_total <- length(running_variable)
n_izquierda <- sum(running_variable < 0)
n_derecha <- sum(running_variable >= 0)

if (n_total < 30) {
  stop(
    "Existen menos de 30 observaciones válidas para ejecutar el test."
  )
}

if (n_izquierda < 10 || n_derecha < 10) {
  stop(
    paste(
      "No existen suficientes observaciones a ambos lados",
      "del punto de corte."
    )
  )
}


# ==============================================================================
# 4. ESTIMAR EL TEST DE DENSIDAD
# ==============================================================================

test_densidad <- rddensity(
  X = running_variable,
  c = 0
)

cat("\n")
cat("============================================================\n")
cat("TEST DE MANIPULACIÓN DE LA VARIABLE DE ASIGNACIÓN\n")
cat("============================================================\n\n")

summary(test_densidad)


# Guardar también la salida completa de la consola
archivo_txt <- file.path(
  dir_manipulacion,
  "Resultado_Test_Densidad.txt"
)

capture.output(
  summary(test_densidad),
  file = archivo_txt
)


# ==============================================================================
# 5. FUNCIÓN PARA EXTRAER ELEMENTOS DEL OBJETO RDDENSITY
# ==============================================================================

convertir_componente_tabla <- function(componente, nombre_componente) {
  
  if (is.null(componente)) {
    return(NULL)
  }
  
  if (is.data.frame(componente)) {
    
    resultado <- componente
    
  } else if (is.matrix(componente)) {
    
    resultado <- as.data.frame(
      componente,
      stringsAsFactors = FALSE
    )
    
  } else if (is.atomic(componente) && length(componente) > 1) {
    
    resultado <- data.frame(
      Estadistico = if (
        is.null(names(componente))
      ) {
        paste0("Valor_", seq_along(componente))
      } else {
        names(componente)
      },
      
      Valor = as.vector(componente),
      
      stringsAsFactors = FALSE
    )
    
  } else if (is.atomic(componente) && length(componente) == 1) {
    
    resultado <- data.frame(
      Estadistico = nombre_componente,
      Valor = componente,
      stringsAsFactors = FALSE
    )
    
  } else {
    
    resultado <- data.frame(
      Resultado = paste(
        capture.output(
          print(componente)
        ),
        collapse = "\n"
      ),
      stringsAsFactors = FALSE
    )
  }
  
  if (
    !is.null(rownames(resultado)) &&
    !all(rownames(resultado) == as.character(seq_len(nrow(resultado))))
  ) {
    
    resultado <- cbind(
      Estadistico = rownames(resultado),
      resultado,
      row.names = NULL
    )
  }
  
  resultado
}


# ==============================================================================
# 6. EXTRAER RESULTADOS PRINCIPALES
# ==============================================================================

# En distintas versiones de rddensity, los componentes pueden variar.
# Este código identifica automáticamente los componentes disponibles.

nombres_componentes <- names(test_densidad)

tabla_test <- if ("test" %in% nombres_componentes) {
  convertir_componente_tabla(
    test_densidad$test,
    "test"
  )
} else {
  NULL
}

tabla_estimaciones <- if ("hat" %in% nombres_componentes) {
  convertir_componente_tabla(
    test_densidad$hat,
    "hat"
  )
} else {
  NULL
}

tabla_bandwidths <- if ("h" %in% nombres_componentes) {
  convertir_componente_tabla(
    test_densidad$h,
    "h"
  )
} else {
  NULL
}

tabla_n_utilizado <- if ("N" %in% nombres_componentes) {
  convertir_componente_tabla(
    test_densidad$N,
    "N"
  )
} else {
  NULL
}


# ==============================================================================
# 7. CREAR TABLA PRINCIPAL TIPO STATA
# ==============================================================================

# Se intenta construir una tabla limpia con estadístico y p-valor.
# Si la versión instalada usa otros nombres, la información completa
# también quedará exportada en las hojas adicionales.

obtener_numero <- function(objeto, posibles_nombres) {
  
  if (is.null(objeto)) {
    return(NA_real_)
  }
  
  objeto_vector <- unlist(
    objeto,
    recursive = TRUE,
    use.names = TRUE
  )
  
  nombres_vector <- names(objeto_vector)
  
  for (nombre_buscado in posibles_nombres) {
    
    coincidencia <- which(
      tolower(nombres_vector) == tolower(nombre_buscado)
    )
    
    if (length(coincidencia) > 0) {
      return(
        suppressWarnings(
          as.numeric(objeto_vector[coincidencia[1]])
        )
      )
    }
  }
  
  NA_real_
}


estadistico_convencional <- obtener_numero(
  test_densidad$test,
  c(
    "T_asy",
    "T_p",
    "T",
    "z",
    "statistic"
  )
)

pvalor_convencional <- obtener_numero(
  test_densidad$test,
  c(
    "P_asy",
    "P_p",
    "pv",
    "p",
    "p.value"
  )
)

estadistico_robusto <- obtener_numero(
  test_densidad$test,
  c(
    "T_jk",
    "T_q",
    "T_robust",
    "z_robust"
  )
)

pvalor_robusto <- obtener_numero(
  test_densidad$test,
  c(
    "P_jk",
    "P_q",
    "P_robust",
    "pv_robust"
  )
)


# Si no se identificaron los nombres, intentar obtenerlos por posición
if (
  all(
    is.na(
      c(
        estadistico_convencional,
        pvalor_convencional,
        estadistico_robusto,
        pvalor_robusto
      )
    )
  ) &&
  !is.null(test_densidad$test)
) {
  
  valores_test <- suppressWarnings(
    as.numeric(
      unlist(test_densidad$test)
    )
  )
  
  valores_test <- valores_test[
    is.finite(valores_test)
  ]
  
  if (length(valores_test) >= 4) {
    
    estadistico_convencional <- valores_test[1]
    pvalor_convencional      <- valores_test[2]
    estadistico_robusto      <- valores_test[3]
    pvalor_robusto           <- valores_test[4]
    
  } else if (length(valores_test) >= 2) {
    
    estadistico_robusto <- valores_test[1]
    pvalor_robusto      <- valores_test[2]
  }
}


tabla_principal <- data.frame(
  Metodo = c(
    "Convencional",
    "Robusto con corrección de sesgo"
  ),
  
  Estadistico_z = c(
    estadistico_convencional,
    estadistico_robusto
  ),
  
  P_valor = c(
    pvalor_convencional,
    pvalor_robusto
  ),
  
  Decision_5_por_ciento = c(
    ifelse(
      is.na(pvalor_convencional),
      NA_character_,
      ifelse(
        pvalor_convencional < 0.05,
        "Se rechaza continuidad",
        "No se rechaza continuidad"
      )
    ),
    
    ifelse(
      is.na(pvalor_robusto),
      NA_character_,
      ifelse(
        pvalor_robusto < 0.05,
        "Se rechaza continuidad",
        "No se rechaza continuidad"
      )
    )
  ),
  
  stringsAsFactors = FALSE
)


# Eliminar una fila si no contiene resultados
tabla_principal <- tabla_principal[
  !(
    is.na(tabla_principal$Estadistico_z) &
      is.na(tabla_principal$P_valor)
  ),
  ,
  drop = FALSE
]


# Si la extracción automática no identificó resultados,
# se deja una observación explicativa.
if (nrow(tabla_principal) == 0) {
  
  tabla_principal <- data.frame(
    Resultado = paste(
      "Los resultados completos se encuentran en la hoja",
      "'Salida_completa' y en las hojas de componentes."
    ),
    stringsAsFactors = FALSE
  )
}


# ==============================================================================
# 8. INFORMACIÓN DE LA MUESTRA
# ==============================================================================

tabla_muestra <- data.frame(
  Indicador = c(
    "Punto de corte",
    "Número total de observaciones",
    "Observaciones a la izquierda",
    "Observaciones a la derecha",
    "Valor mínimo de la running variable",
    "Valor máximo de la running variable"
  ),
  
  Valor = c(
    0,
    n_total,
    n_izquierda,
    n_derecha,
    min(running_variable),
    max(running_variable)
  ),
  
  stringsAsFactors = FALSE
)


# ==============================================================================
# 9. CONSTRUIR GRÁFICO
# ==============================================================================

# Límites redondeados a múltiplos de 50
limite_inferior <- floor(
  min(running_variable, na.rm = TRUE) / 50
) * 50

limite_superior <- ceiling(
  max(running_variable, na.rm = TRUE) / 50
) * 50

# Evitar límites iguales
if (limite_inferior == limite_superior) {
  limite_inferior <- limite_inferior - 50
  limite_superior <- limite_superior + 50
}

marcas_eje_x <- seq(
  from = limite_inferior,
  to = limite_superior,
  by = 50
)


objeto_grafico_densidad <- rdplotdensity(
  rdd = test_densidad,
  X = running_variable,
  plotRange = c(
    limite_inferior,
    limite_superior
  ),
  plotN = 25,
  hist = TRUE,
  title = "Test de continuidad de la densidad",
  xlabel = "Margen de victoria de la izquierda",
  ylabel = "Densidad estimada",
  legendTitle = "Resultado electoral",
  legendGroups = c(
    "La izquierda pierde",
    "La izquierda gana"
  )
)


# ============================================================
# Gráfico del test de densidad
# ============================================================

grafico_densidad <- objeto_grafico_densidad$Estplot +
  scale_x_continuous(
    breaks = marcas_eje_x,
    limits = c(
      limite_inferior,
      limite_superior
    ),
    expand = expansion(mult = c(0.01, 0.01))
  ) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    linewidth = 0.6
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(
      face = "bold",
      hjust = 0.5,
      size = 14
    ),
    axis.title = element_text(
      face = "bold",
      size = 12
    ),
    axis.text = element_text(
      size = 10
    ),
    legend.position = "bottom",
    plot.caption = element_text(
      size = 9,
      hjust = 0,
      margin = margin(t = 12)
    )
  ) +
  labs(
    title = "Test de continuidad de la densidad del margen electoral",
    x = "Margen de victoria de la izquierda",
    y = "Densidad estimada",
  )

# Guardar PDF
ggsave(
  filename = file.path(
    dir_figuras_manipulacion,
    "Test_Manipulacion_Densidad.pdf"
  ),
  plot = grafico_densidad,
  width = 8,
  height = 6,
  dpi = 300
)

# Guardar PNG
ggsave(
  filename = file.path(
    dir_figuras_manipulacion,
    "Test_Manipulacion_Densidad.png"
  ),
  plot = grafico_densidad,
  width = 8,
  height = 6,
  dpi = 300
)

print(grafico_densidad)


# ==============================================================================
# 10. GUARDAR GRÁFICO
# ==============================================================================

ggsave(
  filename = file.path(
    dir_figuras_manipulacion,
    "Test_Manipulacion_Densidad.pdf"
  ),
  plot = grafico_densidad,
  width = 9,
  height = 6,
  units = "in"
)

ggsave(
  filename = file.path(
    dir_figuras_manipulacion,
    "Test_Manipulacion_Densidad.png"
  ),
  plot = grafico_densidad,
  width = 9,
  height = 6,
  units = "in",
  dpi = 300
)


# ==============================================================================
# 11. PREPARAR SALIDA COMPLETA DE LA CONSOLA PARA EXCEL
# ==============================================================================

salida_completa <- capture.output(
  summary(test_densidad)
)

tabla_salida_completa <- data.frame(
  Linea = salida_completa,
  stringsAsFactors = FALSE
)


# ==============================================================================
# 12. EXPORTAR EXCEL CON FORMATO TIPO STATA
# ==============================================================================

archivo_excel <- file.path(
  dir_tablas_manipulacion,
  "Test_Densidad_RDD_Tipo_Stata.xlsx"
)

wb <- createWorkbook()


# ------------------------------------------------------------------------------
# Hoja 1: resultado principal
# ------------------------------------------------------------------------------

addWorksheet(
  wb,
  "Resultado_principal",
  gridLines = FALSE
)

writeData(
  wb,
  sheet = "Resultado_principal",
  x = "Manipulation testing using local polynomial density estimation",
  startRow = 1,
  startCol = 1
)

writeData(
  wb,
  sheet = "Resultado_principal",
  x = paste0(
    "Cutoff c = 0    Number of obs = ",
    n_total
  ),
  startRow = 3,
  startCol = 1
)

writeData(
  wb,
  sheet = "Resultado_principal",
  x = tabla_principal,
  startRow = 5,
  startCol = 1,
  rowNames = FALSE
)


# ------------------------------------------------------------------------------
# Hoja 2: información de la muestra
# ------------------------------------------------------------------------------

addWorksheet(
  wb,
  "Muestra",
  gridLines = FALSE
)

writeData(
  wb,
  sheet = "Muestra",
  x = tabla_muestra,
  startRow = 1,
  startCol = 1
)


# ------------------------------------------------------------------------------
# Hoja 3: test original
# ------------------------------------------------------------------------------

if (!is.null(tabla_test)) {
  
  addWorksheet(
    wb,
    "Test_original",
    gridLines = FALSE
  )
  
  writeData(
    wb,
    sheet = "Test_original",
    x = tabla_test,
    startRow = 1,
    startCol = 1
  )
}


# ------------------------------------------------------------------------------
# Hoja 4: estimaciones de densidad
# ------------------------------------------------------------------------------

if (!is.null(tabla_estimaciones)) {
  
  addWorksheet(
    wb,
    "Estimaciones",
    gridLines = FALSE
  )
  
  writeData(
    wb,
    sheet = "Estimaciones",
    x = tabla_estimaciones,
    startRow = 1,
    startCol = 1
  )
}


# ------------------------------------------------------------------------------
# Hoja 5: bandwidths
# ------------------------------------------------------------------------------

if (!is.null(tabla_bandwidths)) {
  
  addWorksheet(
    wb,
    "Bandwidths",
    gridLines = FALSE
  )
  
  writeData(
    wb,
    sheet = "Bandwidths",
    x = tabla_bandwidths,
    startRow = 1,
    startCol = 1
  )
}


# ------------------------------------------------------------------------------
# Hoja 6: observaciones utilizadas
# ------------------------------------------------------------------------------

if (!is.null(tabla_n_utilizado)) {
  
  addWorksheet(
    wb,
    "Observaciones_efectivas",
    gridLines = FALSE
  )
  
  writeData(
    wb,
    sheet = "Observaciones_efectivas",
    x = tabla_n_utilizado,
    startRow = 1,
    startCol = 1
  )
}


# ------------------------------------------------------------------------------
# Hoja final: salida completa como aparece en la consola
# ------------------------------------------------------------------------------

addWorksheet(
  wb,
  "Salida_completa",
  gridLines = FALSE
)

writeData(
  wb,
  sheet = "Salida_completa",
  x = tabla_salida_completa,
  startRow = 1,
  startCol = 1,
  colNames = FALSE
)


# ==============================================================================
# 13. FORMATO DEL EXCEL
# ==============================================================================

estilo_titulo <- createStyle(
  fontName = "Courier New",
  fontSize = 12,
  textDecoration = "bold",
  halign = "left"
)

estilo_encabezado <- createStyle(
  fontName = "Courier New",
  fontSize = 10,
  textDecoration = "bold",
  border = c(
    "top",
    "bottom"
  ),
  halign = "center"
)

estilo_cuerpo <- createStyle(
  fontName = "Courier New",
  fontSize = 10,
  halign = "center"
)

estilo_texto <- createStyle(
  fontName = "Courier New",
  fontSize = 10,
  halign = "left"
)

estilo_numerico <- createStyle(
  fontName = "Courier New",
  fontSize = 10,
  numFmt = "0.0000",
  halign = "center"
)


# Título
addStyle(
  wb,
  sheet = "Resultado_principal",
  style = estilo_titulo,
  rows = 1,
  cols = 1,
  gridExpand = TRUE
)


# Encabezado de tabla principal
if (ncol(tabla_principal) > 0) {
  
  addStyle(
    wb,
    sheet = "Resultado_principal",
    style = estilo_encabezado,
    rows = 5,
    cols = 1:ncol(tabla_principal),
    gridExpand = TRUE
  )
  
  if (nrow(tabla_principal) > 0) {
    
    addStyle(
      wb,
      sheet = "Resultado_principal",
      style = estilo_cuerpo,
      rows = 6:(5 + nrow(tabla_principal)),
      cols = 1:ncol(tabla_principal),
      gridExpand = TRUE
    )
  }
}


# Aplicar fuente tipo Stata a todas las hojas
for (nombre_hoja in names(wb)) {
  
  dimensiones <- tryCatch(
    {
      getSheetDims(
        wb,
        nombre_hoja
      )
    },
    error = function(e) {
      NULL
    }
  )
  
  setColWidths(
    wb,
    sheet = nombre_hoja,
    cols = 1:10,
    widths = "auto"
  )
}


# Ajustes concretos
setColWidths(
  wb,
  sheet = "Resultado_principal",
  cols = 1,
  widths = 35
)

setColWidths(
  wb,
  sheet = "Resultado_principal",
  cols = 2:4,
  widths = 23
)

setColWidths(
  wb,
  sheet = "Muestra",
  cols = 1,
  widths = 42
)

setColWidths(
  wb,
  sheet = "Muestra",
  cols = 2,
  widths = 20
)

setColWidths(
  wb,
  sheet = "Salida_completa",
  cols = 1,
  widths = 100
)

freezePane(
  wb,
  sheet = "Resultado_principal",
  firstActiveRow = 5
)


# ==============================================================================
# 14. GUARDAR EXCEL
# ==============================================================================

saveWorkbook(
  wb,
  file = archivo_excel,
  overwrite = TRUE
)


# ==============================================================================
# 15. MENSAJE FINAL
# ==============================================================================

cat("\n")
cat("============================================================\n")
cat("TEST DE MANIPULACIÓN COMPLETADO\n")
cat("============================================================\n\n")

cat(
  "Excel tipo Stata guardado en:\n",
  archivo_excel,
  "\n\n"
)

cat(
  "Gráfico PDF guardado en:\n",
  file.path(
    dir_figuras_manipulacion,
    "Test_Manipulacion_Densidad.pdf"
  ),
  "\n\n"
)

cat(
  "Gráfico PNG guardado en:\n",
  file.path(
    dir_figuras_manipulacion,
    "Test_Manipulacion_Densidad.png"
  ),
  "\n\n"
)

cat(
  "Resultado de consola guardado en:\n",
  archivo_txt,
  "\n"
)
