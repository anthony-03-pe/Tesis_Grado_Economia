# Ejecutar después de run.R y scripts/stata/tesis.do desde la raíz del proyecto.
library(haven)
a <- readRDS('output/R/objetos.rds')
s <- read.csv('output/stata/tabla4_validacion.csv')
r <- a$rd_A_gap
objetivo <- c(r$coef[1],r$se[3],r$pv[3],r$ci[3,1],r$ci[3,2],r$N,r$N_h,r$bws[1,1],r$bws[2,1])
comparacion <- data.frame(indicador=names(s),R=objetivo,Stata=as.numeric(s[1,]))
comparacion$diferencia <- abs(comparacion$R-comparacion$Stata)
write.csv(comparacion,'output/comparacion_R_Stata.csv',row.names=FALSE)
stopifnot(all(comparacion$diferencia<1e-6))
for (tipo in c('A','B','C')) {
  stata <- read_dta(paste0('output/stata/muestra_',tipo,'.dta'))
  erre <- a[[paste0('muestra_',tipo)]]
  stata <- stata[order(stata$countrycode,stata$election_year),]
  erre <- erre[order(erre$countrycode,erre$election_year),]
  stopifnot(identical(stata$countrycode,erre$countrycode),all(stata$election_year==erre$election_year))
  for(v in c('gap_pct_mart','gap_mart','lngdp14_w','lndn13_w','treatment','margin_victory')) stopifnot(max(abs(stata[[v]]-erre[[v]]),na.rm=TRUE)<1e-6)
}
b <- read.csv('output/stata/balance_validacion.csv')
stopifnot(max(abs(b$coef-a$resultados_balance$Coeficiente_convencional))<1e-6)
stopifnot(max(abs(b$se_robusto-a$resultados_balance$Error_estandar_robusto))<1e-6)
stopifnot(max(abs(b$p_robusto-a$resultados_balance$Valor_p_robusto))<1e-6)
stopifnot(all(b$n==a$resultados_balance$Observaciones))
dens <- read.csv('output/stata/densidad_validacion.csv')
stopifnot(abs(dens$estadistico-a$test_densidad$test$t_jk)<1e-6,abs(dens$p_valor-a$test_densidad$test$p_jk)<1e-6)
cat('VERIFICADO: muestras A/B/C, tabla 4, balance y densidad equivalentes entre R y Stata.\n')
