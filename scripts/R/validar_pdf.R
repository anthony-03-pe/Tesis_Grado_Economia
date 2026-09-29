# Compara cifras publicadas a cuatro decimales; no altera ningún estimador.
a <- readRDS('output/R/objetos.rds')
comprobaciones <- list()
comprobar <- function(nombre, actual, esperado, tolerancia=0.000051) {
  comprobaciones[[length(comprobaciones)+1]] <<- data.frame(indicador=nombre, calculado=as.numeric(actual), PDF=esperado, tolerancia=tolerancia, coincide=abs(as.numeric(actual)-esperado)<=tolerancia)
}
comprobar(paste0('Tabla2_beta_',1:4),sapply(a$modelos,function(m)coef(m)['lndn13']),c(.2964,.2919,.2154,.2140))
comprobar(paste0('Tabla2_N_',1:4),sapply(a$modelos,nobs),rep(3895,4),0)
rd <- a$rd_A_gap
comprobar(c('Tabla4_coef','Tabla4_se_robusto','Tabla4_p_robusto','Tabla4_IC_inf','Tabla4_IC_sup','Tabla4_h','Tabla4_b'), c(rd$coef[1],rd$se[3],rd$pv[3],rd$ci[3,1],rd$ci[3,2],rd$bws[1,1],rd$bws[2,1]),c(6.7808,5.4615,.0928,-1.5260,19.8828,26.8863,46.4675))
comprobar(c('Tabla4_N_izq','Tabla4_N_der','Tabla4_Nh_izq','Tabla4_Nh_der'),c(rd$N,rd$N_h),c(296,166,130,110),0)
comprobar(c('Densidad_estadistico','Densidad_p'),c(a$test_densidad$test$t_jk,a$test_densidad$test$p_jk),c(.3433,.7314))
b <- a$resultados_balance
comprobar(paste0('Tabla3_coef_',1:5),b$Coeficiente_convencional,c(.5250,-.1681,-4.1608,.0079,.0161))
comprobar(paste0('Tabla3_se_',1:5),b$Error_estandar_robusto,c(3.8423,2.4528,3.1818,.0373,.0507))
comprobar(paste0('Tabla3_p_',1:5),b$Valor_p_robusto,c(.8451,.9530,.1565,.7724,.6953))
comprobar(paste0('Tabla3_N_',1:5),b$Observaciones,c(432,409,382,432,432),0)
resultado <- do.call(rbind,comprobaciones)
write.csv(resultado,'output/R/comparacion_pdf.csv',row.names=FALSE)
stopifnot(all(resultado$coincide))
cat('\nVERIFICADO: ',nrow(resultado),' cifras coinciden con el PDF.\n')
