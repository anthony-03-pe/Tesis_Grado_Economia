# Ejecutar en la terminal de VS Code: Rscript run.R
# También admite Rscript /ruta/al/proyecto/run.R desde otra carpeta.
argumentos <- commandArgs(trailingOnly = FALSE)
archivo <- grep('^--file=', argumentos, value = TRUE)
if (length(archivo)) setwd(dirname(normalizePath(sub('^--file=', '', archivo[1]))))
paquetes <- c('haven','dplyr','tidyr','fixest','rdrobust','openxlsx','ggplot2','tibble','rddensity','lpdensity')
faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly=TRUE)]
if (length(faltantes)) stop('Instala primero: ', paste(faltantes, collapse=', '))
suppressPackageStartupMessages(invisible(lapply(paquetes, library, character.only=TRUE)))
options(scipen=999)
dir_master <- dir_girardi <- file.path(getwd(),'data','raw')
dir_resultados <- file.path(getwd(),'output','R')
dir_temp <- dir_tables <- dir_figures <- dir_resultados
dir.create(dir_resultados, recursive=TRUE, showWarnings=FALSE)
stopifnot(file.exists(file.path(dir_master,'Estimations.dta')),file.exists(file.path(dir_girardi,'elections_dataset.dta')))
source('scripts/R/diagnostico.R', encoding='UTF-8')
for (modulo in c('01_funciones.R','02_panel_y_beta.R','03_estimaciones_rdd.R','04_densidad.R','05_covariables.R')) {
  cat('\nEjecutando ', modulo, '\n')
  source(file.path('scripts','R',modulo), encoding='UTF-8')
}
saveRDS(list(modelos=list(m1,m2,m3,m4),panel_gap=panel_gap,muestra_A=muestra_A,muestra_B=muestra_B,muestra_C=muestra_C,rd_A_gap=rd_A_gap,test_densidad=test_densidad,resultados_balance=resultados_balance),file.path(dir_resultados,'objetos.rds'))
capture.output(sessionInfo(), file=file.path(dir_resultados,'sessionInfo.txt'))
source('scripts/R/validar_pdf.R', encoding='UTF-8')
