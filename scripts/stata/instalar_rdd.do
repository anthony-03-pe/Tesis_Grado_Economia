clear all
set more off
cap mkdir "ado"
net set ado "ado"
net install rdrobust, from("https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata") replace
net install rddensity, from("https://raw.githubusercontent.com/rdpackages/rddensity/master/stata") replace
net install lpdensity, from("https://raw.githubusercontent.com/nppackages/lpdensity/master/stata") replace
