// Pruebas incluidas en el PDF, ausentes en el do-file antiguo.
use "${temp}/muestra_A.dta", clear
rddensity margin_victory, c(0)
ereturn list
local dens_t = e(T_q)
local dens_p = e(pv_q)
assert abs(`dens_t' - 0.3433) < 0.000051
assert abs(`dens_p' - 0.7314) < 0.000051
preserve
clear
set obs 1
gen double estadistico = `dens_t'
gen double p_valor = `dens_p'
export delimited using "${temp}/densidad_validacion.csv", replace
restore

keep countrycode election_year margin_victory
isid countrycode election_year
forvalues k = 1/3 {
    gen year = election_year - `k'
    merge m:1 countrycode year using "${temp}/panel_gap_mart.dta", keep(master match) nogen keepusing(gap_pct_mart lngdp14_w lndn13_w)
    rename gap_pct_mart gap_t_`k'
    if `k' == 1 {
        rename lngdp14_w pib_t_1
        rename lndn13_w luces_t_1
    }
    else {
        drop lngdp14_w lndn13_w
    }
    drop year
}
tempname handle
postfile `handle' str20 variable double coef double se_robusto double p_robusto double ci_inf double ci_sup double n using "${temp}/balance.dta", replace
foreach v in gap_t_1 gap_t_2 gap_t_3 pib_t_1 luces_t_1 {
    rdrobust `v' margin_victory, c(0) p(1) q(2) kernel(triangular) bwselect(cerrd)
    post `handle' ("`v'") (e(tau_cl)) (e(se_tau_rb)) (e(pv_rb)) (e(ci_l_rb)) (e(ci_r_rb)) (e(N_l)+e(N_r))
}
postclose `handle'
use "${temp}/balance.dta", clear
gen orden_original = _n
sort p_robusto
gen double q_BH = min(1,p_robusto*_N/_n)
gsort -p_robusto
replace q_BH = min(q_BH,q_BH[_n-1]) if _n > 1
sort orden_original
drop orden_original
export delimited using "${temp}/balance_validacion.csv", replace

// Comprobaciones directas contra las cifras publicadas (sin ajustar estimaciones).
local esperados "0.5250 -0.1681 -4.1608 0.0079 0.0161"
local errores "3.8423 2.4528 3.1818 0.0373 0.0507"
local pvalores "0.8451 0.9530 0.1565 0.7724 0.6953"
local tamanos "432 409 382 432 432"
forvalues j=1/5 {
    local objetivo : word `j' of `esperados'
    local ee : word `j' of `errores'
    local pv : word `j' of `pvalores'
    local nn : word `j' of `tamanos'
    assert abs(coef[`j'] - `objetivo') < 0.000051
    assert abs(se_robusto[`j'] - `ee') < 0.000051
    assert abs(p_robusto[`j'] - `pv') < 0.000051
    assert n[`j'] == `nn'
}
import delimited using "${temp}/tabla4_validacion.csv", clear
assert abs(coef-6.7808)<0.000051
assert abs(se_robusto-5.4615)<0.000051
assert abs(p_robusto-0.0928)<0.000051
assert abs(ci_inf+1.5260)<0.000051
assert abs(ci_sup-19.8828)<0.000051
assert abs(h-26.8863)<0.000051
assert abs(b-46.4675)<0.000051
assert n_izq==296 & n_der==166 & nh_izq==130 & nh_der==110
display "VERIFICADO: tablas 3 y 4 y test de densidad coinciden con el PDF."
