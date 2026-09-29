////////////////////////////////////////////////////////////////////////////////
// DO-FILE 1: MARTINEZ (1992-2013) - Lógica de Ruzzier
// NTL: lndn13 (Martinez DMSP-OLS)
// GDP: lngdp14 (Banco Mundial vintage 2014)
// Período: 1992-2013
//
// Outcomes:
//   - gap_pct_mart  : Brecha GDP-NTL % (resultado principal)
//   - lngdp14_w     : GDP oficial within (¿sube el GDP oficial?)
//   - lndn13_w      : NTL satelital within (¿sube la actividad real?)
//
// Diseños RDD:
//   A. Fuzzy RDD  - Todas las elecciones
//   B. Sharp RDD  - Solo presidenciales
//   C. Sharp RDD  - Solo parlamentarias
//
// Gráficos:
//   - Primera etapa fuzzy (estilo Ruzzier Fig 3.1)
//   - rdplot por cada outcome y diseño
////////////////////////////////////////////////////////////////////////////////

// Ejecutar desde la carpeta reproducibilidad.
clear all
set more off
set type double
adopath ++ "ado/r"
adopath ++ "ado/l"
mata: mata mlib index
global master "data/raw"
global girardi "data/raw"
global temp "output/stata"
global tables "output/stata"
global figures "output/stata"
cap mkdir "output"
cap mkdir "output/stata"
log using "output/stata/ejecucion.log", text replace
foreach cmd in reghdfe outreg2 rdrobust rdplot {
    which `cmd'
}

////////////////////////////////////////////////////////////////////////////////
// PASO 1: Estimar β limpio con reghdfe + FiW
////////////////////////////////////////////////////////////////////////////////

use "${master}/Estimations.dta", clear
keep if year >= 1992 & year <= 2013
keep countrycode year lngdp14 lndn13 fiw fiw2
drop if lngdp14 == . | lndn13 == . | fiw == .

gen lndn13_fiw = lndn13 * fiw

// Tabla grande al estilo Martinez (4 columnas)
reghdfe lngdp14 lndn13, absorb(countrycode year) cluster(countrycode)
outreg2 using "${tables}/mart_paso1_beta.xls", ///
    bracket nocons nor2 keep(lndn13 fiw fiw2 lndn13_fiw) dec(3) ///
    addtext(Country FE, Yes, Year FE, Yes) ///
    addstat(Countries, e(N_clust), R-sq within, e(r2_within)) ///
    ctitle("(1) Baseline") replace

reghdfe lngdp14 lndn13 fiw, absorb(countrycode year) cluster(countrycode)
outreg2 using "${tables}/mart_paso1_beta.xls", ///
    bracket nocons nor2 keep(lndn13 fiw fiw2 lndn13_fiw) dec(3) ///
    addtext(Country FE, Yes, Year FE, Yes) ///
    addstat(Countries, e(N_clust), R-sq within, e(r2_within)) ///
    ctitle("(2) + FiW") append

reghdfe lngdp14 lndn13 fiw lndn13_fiw, absorb(countrycode year) cluster(countrycode)
outreg2 using "${tables}/mart_paso1_beta.xls", ///
    bracket nocons nor2 keep(lndn13 fiw fiw2 lndn13_fiw) dec(3) ///
    addtext(Country FE, Yes, Year FE, Yes) ///
    addstat(Countries, e(N_clust), R-sq within, e(r2_within)) ///
    ctitle("(3) + Interaccion") append

reghdfe lngdp14 lndn13 fiw fiw2 lndn13_fiw, ///
    absorb(countrycode year) cluster(countrycode)
outreg2 using "${tables}/mart_paso1_beta.xls", ///
    bracket nocons nor2 keep(lndn13 fiw fiw2 lndn13_fiw) dec(3) ///
    addtext(Country FE, Yes, Year FE, Yes) ///
    addstat(Countries, e(N_clust), R-sq within, e(r2_within)) ///
    ctitle("(4) Main - beta limpio") append

scalar beta_mart = _b[lndn13]
di "============================================"
di "β₀ limpio (Martinez) = " beta_mart
di "============================================"

file open f using "${tables}/mart_beta.txt", write replace
file write f "beta limpio (Martinez 1992-2013) = " (string(beta_mart)) _n
file close f

////////////////////////////////////////////////////////////////////////////////
// PASO 2: Within-transformation manual
////////////////////////////////////////////////////////////////////////////////

foreach var in lngdp14 lndn13 {
    bysort countrycode: egen mi_`var' = mean(`var')
    bysort year:        egen mt_`var' = mean(`var')
    egen                mg_`var' = mean(`var')
    gen `var'_w = `var' - mi_`var' - mt_`var' + mg_`var'
    drop mi_`var' mt_`var' mg_`var'
}

////////////////////////////////////////////////////////////////////////////////
// PASO 3: Construir brecha
////////////////////////////////////////////////////////////////////////////////

gen gap_mart     = lngdp14_w - beta_mart * lndn13_w
gen gap_pct_mart = (exp(gap_mart) - 1) * 100

keep countrycode year gap_mart gap_pct_mart lngdp14_w lndn13_w
save "${temp}/panel_gap_mart.dta", replace

////////////////////////////////////////////////////////////////////////////////
// ============================================================
// DISEÑO A: FUZZY RDD - Todas las elecciones
// ============================================================
////////////////////////////////////////////////////////////////////////////////

use "${girardi}/elections_dataset.dta", clear
rename iso3code countrycode

keep if exclude != 1 & !missing(exclude)
keep if year >= 1992 & year <= 2013
keep countrycode year left_gov left_win parliamentary pres_leftmargin parl_leftmargin

gen treatment = left_win          if parliamentary == 0
replace treatment = left_gov      if parliamentary == 1

gen margin_victory = pres_leftmargin     if parliamentary == 0
replace margin_victory = parl_leftmargin if parliamentary == 1

drop if missing(treatment) | missing(margin_victory)

rename year election_year

// Cada fila electoral recibe exactamente cuatro años posteriores.
gen long id_eleccion = _n
expand 4
bysort id_eleccion: gen k = _n
gen year = election_year + k

merge m:1 countrycode year using "${temp}/panel_gap_mart.dta", ///
    keepusing(gap_pct_mart gap_mart lngdp14_w lndn13_w) ///
    keep(match master) nogen

collapse (mean) gap_pct_mart gap_mart lngdp14_w lndn13_w ///
    treatment margin_victory parliamentary, ///
    by(countrycode election_year)

drop if gap_pct_mart == .
// Se conserva la agregación por país-año del R que reproduce el PDF.

di "N Fuzzy RDD (todas) = " _N
save "${temp}/muestra_A.dta", replace

// ---- PRIMERA ETAPA (estilo Ruzzier Fig 3.1) ----
// Muestra que ganar la elección lleva a gobernar
di ""
di "=== PRIMERA ETAPA: Ganar elección → Gobernar ==="
rdrobust treatment margin_victory, c(0) kernel(triangular) bwselect(mserd)

outreg2 using "${tables}/mart_A_firststage.xls", ///
    noobs nor2 dec(3) ctitle("First Stage") replace

rdplot treatment margin_victory, c(0) kernel(triangular) ///
    graph_options( ///
        title("Primera etapa: Victoria izquierda → Gobierno izquierda") ///
        xtitle("Margen de victoria izquierda (pp)") ///
        ytitle("Probabilidad de gobierno izquierda") ///
        note("Estilo Ruzzier Fig 3.1. Fuente: Girardi + Martinez (1992-2013)") ///
        scheme(s2mono))
graph export "${figures}/mart_A_firststage.pdf", replace

// ---- OUTCOME 1: Brecha GDP-NTL % (resultado principal) ----
di ""
di "=== FUZZY RDD - Todas: Brecha GDP-NTL % ==="
rdrobust gap_pct_mart margin_victory, c(0) fuzzy(treatment) ///
    kernel(triangular) bwselect(mserd)

matrix tabla4 = (e(tau_cl), e(se_tau_rb), e(pv_rb), e(ci_l_rb), e(ci_r_rb), e(N_l), e(N_r), e(N_h_l), e(N_h_r), e(h_l), e(b_l))
matrix colnames tabla4 = coef se_robusto p_robusto ci_inf ci_sup n_izq n_der nh_izq nh_der h b
preserve
clear
svmat double tabla4, names(col)
export delimited using "${tables}/tabla4_validacion.csv", replace
restore
outreg2 using "${tables}/mart_A_gap_pct.xls", ///
    noobs nor2 dec(3) ctitle("Fuzzy All - Brecha %") replace

rdplot gap_pct_mart margin_victory, c(0) kernel(triangular) ///
    graph_options( ///
        title("Fuzzy RDD: Brecha GDP-NTL (%) - Todas las elecciones") ///
        xtitle("Margen victoria izquierda (pp)") ///
        ytitle("Brecha GDP-NTL % (promedio t+1 a t+4)") ///
        scheme(s2mono))
graph export "${figures}/mart_A_gap_pct.pdf", replace

// ---- OUTCOME 2: GDP oficial within ----
di ""
di "=== FUZZY RDD - Todas: GDP oficial (within) ==="
rdrobust lngdp14_w margin_victory, c(0) fuzzy(treatment) ///
    kernel(triangular) bwselect(mserd)

outreg2 using "${tables}/mart_A_gdp_within.xls", ///
    noobs nor2 dec(3) ctitle("Fuzzy All - GDP within") replace

rdplot lngdp14_w margin_victory, c(0) kernel(triangular) ///
    graph_options( ///
        title("Fuzzy RDD: GDP oficial (within) - Todas las elecciones") ///
        xtitle("Margen victoria izquierda (pp)") ///
        ytitle("ln(GDP) within promedio t+1 a t+4") ///
        scheme(s2mono))
graph export "${figures}/mart_A_gdp_within.pdf", replace

// ---- OUTCOME 3: NTL satelital within ----
di ""
di "=== FUZZY RDD - Todas: NTL satelital (within) ==="
rdrobust lndn13_w margin_victory, c(0) fuzzy(treatment) ///
    kernel(triangular) bwselect(mserd)

outreg2 using "${tables}/mart_A_ntl_within.xls", ///
    noobs nor2 dec(3) ctitle("Fuzzy All - NTL within") replace

rdplot lndn13_w margin_victory, c(0) kernel(triangular) ///
    graph_options( ///
        title("Fuzzy RDD: NTL satelital (within) - Todas las elecciones") ///
        xtitle("Margen victoria izquierda (pp)") ///
        ytitle("ln(NTL) within promedio t+1 a t+4") ///
        scheme(s2mono))
graph export "${figures}/mart_A_ntl_within.pdf", replace

////////////////////////////////////////////////////////////////////////////////
// ============================================================
// DISEÑO B: SHARP RDD - Solo presidenciales
// ============================================================
////////////////////////////////////////////////////////////////////////////////

use "${girardi}/elections_dataset.dta", clear
rename iso3code countrycode

keep if parliamentary == 0
keep if exclude != 1 & !missing(exclude)
keep if year >= 1992 & year <= 2013
keep countrycode year left_win pres_leftmargin
drop if missing(left_win) | missing(pres_leftmargin)

rename year            election_year
rename left_win        treatment
rename pres_leftmargin margin_victory

// Cada fila electoral recibe exactamente cuatro años posteriores.
gen long id_eleccion = _n
expand 4
bysort id_eleccion: gen k = _n
gen year = election_year + k

merge m:1 countrycode year using "${temp}/panel_gap_mart.dta", ///
    keepusing(gap_pct_mart gap_mart lngdp14_w lndn13_w) ///
    keep(match master) nogen

collapse (mean) gap_pct_mart gap_mart lngdp14_w lndn13_w ///
    treatment margin_victory, ///
    by(countrycode election_year)

drop if gap_pct_mart == .
// Se conserva la agregación por país-año del R que reproduce el PDF.

di "N Sharp RDD (presidenciales) = " _N
save "${temp}/muestra_B.dta", replace

// ---- OUTCOME 1: Brecha GDP-NTL % ----
di ""
di "=== SHARP RDD - Presidenciales: Brecha GDP-NTL % ==="
rdrobust gap_pct_mart margin_victory, c(0) ///
    kernel(triangular) bwselect(mserd)

outreg2 using "${tables}/mart_B_gap_pct.xls", ///
    noobs nor2 dec(3) ctitle("Sharp Pres - Brecha %") replace

rdplot gap_pct_mart margin_victory, c(0) kernel(triangular) ///
    graph_options( ///
        title("Sharp RDD: Brecha GDP-NTL (%) - Presidenciales") ///
        xtitle("Margen victoria izquierda (pp)") ///
        ytitle("Brecha GDP-NTL % (promedio t+1 a t+4)") ///
        scheme(s2mono))
graph export "${figures}/mart_B_gap_pct.pdf", replace

// ---- OUTCOME 2: GDP oficial within ----
di ""
di "=== SHARP RDD - Presidenciales: GDP oficial (within) ==="
rdrobust lngdp14_w margin_victory, c(0) ///
    kernel(triangular) bwselect(mserd)

outreg2 using "${tables}/mart_B_gdp_within.xls", ///
    noobs nor2 dec(3) ctitle("Sharp Pres - GDP within") replace

rdplot lngdp14_w margin_victory, c(0) kernel(triangular) ///
    graph_options( ///
        title("Sharp RDD: GDP oficial (within) - Presidenciales") ///
        xtitle("Margen victoria izquierda (pp)") ///
        ytitle("ln(GDP) within promedio t+1 a t+4") ///
        scheme(s2mono))
graph export "${figures}/mart_B_gdp_within.pdf", replace

// ---- OUTCOME 3: NTL satelital within ----
di ""
di "=== SHARP RDD - Presidenciales: NTL satelital (within) ==="
rdrobust lndn13_w margin_victory, c(0) ///
    kernel(triangular) bwselect(mserd)

outreg2 using "${tables}/mart_B_ntl_within.xls", ///
    noobs nor2 dec(3) ctitle("Sharp Pres - NTL within") replace

rdplot lndn13_w margin_victory, c(0) kernel(triangular) ///
    graph_options( ///
        title("Sharp RDD: NTL satelital (within) - Presidenciales") ///
        xtitle("Margen victoria izquierda (pp)") ///
        ytitle("ln(NTL) within promedio t+1 a t+4") ///
        scheme(s2mono))
graph export "${figures}/mart_B_ntl_within.pdf", replace

////////////////////////////////////////////////////////////////////////////////
// ============================================================
// DISEÑO C: SHARP RDD - Solo parlamentarias
// ============================================================
////////////////////////////////////////////////////////////////////////////////

use "${girardi}/elections_dataset.dta", clear
rename iso3code countrycode

keep if parliamentary == 1
keep if exclude != 1 & !missing(exclude)
keep if year >= 1992 & year <= 2013
keep countrycode year parl_leftmargin
drop if missing(parl_leftmargin)

rename year            election_year
gen treatment        = (parl_leftmargin >= 0)
rename parl_leftmargin margin_victory

// Cada fila electoral recibe exactamente cuatro años posteriores.
gen long id_eleccion = _n
expand 4
bysort id_eleccion: gen k = _n
gen year = election_year + k

merge m:1 countrycode year using "${temp}/panel_gap_mart.dta", ///
    keepusing(gap_pct_mart gap_mart lngdp14_w lndn13_w) ///
    keep(match master) nogen

collapse (mean) gap_pct_mart gap_mart lngdp14_w lndn13_w ///
    treatment margin_victory, ///
    by(countrycode election_year)

drop if gap_pct_mart == .
// Se conserva la agregación por país-año del R que reproduce el PDF.

di "N Sharp RDD (parlamentarias) = " _N
save "${temp}/muestra_C.dta", replace

// ---- OUTCOME 1: Brecha GDP-NTL % ----
di ""
di "=== SHARP RDD - Parlamentarias: Brecha GDP-NTL % ==="
rdrobust gap_pct_mart margin_victory, c(0) ///
    kernel(triangular) bwselect(mserd)

outreg2 using "${tables}/mart_C_gap_pct.xls", ///
    noobs nor2 dec(3) ctitle("Sharp Parl - Brecha %") replace

rdplot gap_pct_mart margin_victory, c(0) kernel(triangular) ///
    graph_options( ///
        title("Sharp RDD: Brecha GDP-NTL (%) - Parlamentarias") ///
        xtitle("Margen victoria izquierda (pp)") ///
        ytitle("Brecha GDP-NTL % (promedio t+1 a t+4)") ///
        scheme(s2mono))
graph export "${figures}/mart_C_gap_pct.pdf", replace

// ---- OUTCOME 2: GDP oficial within ----
di ""
di "=== SHARP RDD - Parlamentarias: GDP oficial (within) ==="
rdrobust lngdp14_w margin_victory, c(0) ///
    kernel(triangular) bwselect(mserd)

outreg2 using "${tables}/mart_C_gdp_within.xls", ///
    noobs nor2 dec(3) ctitle("Sharp Parl - GDP within") replace

rdplot lngdp14_w margin_victory, c(0) kernel(triangular) ///
    graph_options( ///
        title("Sharp RDD: GDP oficial (within) - Parlamentarias") ///
        xtitle("Margen victoria izquierda (pp)") ///
        ytitle("ln(GDP) within promedio t+1 a t+4") ///
        scheme(s2mono))
graph export "${figures}/mart_C_gdp_within.pdf", replace

// ---- OUTCOME 3: NTL satelital within ----
di ""
di "=== SHARP RDD - Parlamentarias: NTL satelital (within) ==="
rdrobust lndn13_w margin_victory, c(0) ///
    kernel(triangular) bwselect(mserd)

outreg2 using "${tables}/mart_C_ntl_within.xls", ///
    noobs nor2 dec(3) ctitle("Sharp Parl - NTL within") replace

rdplot lndn13_w margin_victory, c(0) kernel(triangular) ///
    graph_options( ///
        title("Sharp RDD: NTL satelital (within) - Parlamentarias") ///
        xtitle("Margen victoria izquierda (pp)") ///
        ytitle("ln(NTL) within promedio t+1 a t+4") ///
        scheme(s2mono))
graph export "${figures}/mart_C_ntl_within.pdf", replace

////////////////////////////////////////////////////////////////////////////////
// RESUMEN FINAL
////////////////////////////////////////////////////////////////////////////////

di ""
di "============================================"
di "DO-FILE 1 (MARTINEZ 1992-2013) COMPLETADO"
di "Tablas en:  ${tables}"
di "Figuras en: ${figures}"
di ""
di "Tablas:"
di "  mart_paso1_beta.xls    -> β limpio (4 columnas)"
di "  mart_beta.txt          -> β escalar"
di "  mart_A_firststage.xls  -> Primera etapa fuzzy"
di "  mart_A_gap_pct.xls     -> Fuzzy: Brecha GDP-NTL %"
di "  mart_A_gdp_within.xls  -> Fuzzy: GDP oficial within"
di "  mart_A_ntl_within.xls  -> Fuzzy: NTL satelital within"
di "  mart_B_gap_pct.xls     -> Sharp Pres: Brecha %"
di "  mart_B_gdp_within.xls  -> Sharp Pres: GDP within"
di "  mart_B_ntl_within.xls  -> Sharp Pres: NTL within"
di "  mart_C_gap_pct.xls     -> Sharp Parl: Brecha %"
di "  mart_C_gdp_within.xls  -> Sharp Parl: GDP within"
di "  mart_C_ntl_within.xls  -> Sharp Parl: NTL within"
di ""
di "Figuras:"
di "  mart_A_firststage.pdf  -> Primera etapa (Ruzzier Fig 3.1)"
di "  mart_A_gap_pct.pdf     -> Fuzzy: discontinuidad brecha"
di "  mart_A_gdp_within.pdf  -> Fuzzy: discontinuidad GDP"
di "  mart_A_ntl_within.pdf  -> Fuzzy: discontinuidad NTL"
di "  mart_B_gap_pct.pdf     -> Sharp Pres: discontinuidad brecha"
di "  mart_B_gdp_within.pdf  -> Sharp Pres: GDP within"
di "  mart_B_ntl_within.pdf  -> Sharp Pres: NTL within"
di "  mart_C_gap_pct.pdf     -> Sharp Parl: discontinuidad brecha"
di "  mart_C_gdp_within.pdf  -> Sharp Parl: GDP within"
di "  mart_C_ntl_within.pdf  -> Sharp Parl: NTL within"
di "============================================"

do "scripts/stata/validaciones.do"
log close
