# Bases necesarias

Colocar ambos archivos en `data/raw/`. Son las entradas de los paquetes de replicación ya presentes en TESIS; no se reconstruyen desde todas las fuentes primarias.

| Archivo | Origen local | SHA-256 |
|---|---|---|
| Estimations.dta | `Replication Dictators GDP/Data/master/Estimations.dta` | `83dd6ee1d21f29ecadfa9f492fed36e414fbf50efd8a2f6c1294981a6a872b68` |
| elections_dataset.dta | `115008-V1/Replication_files/elections_dataset.dta` | `6d3ca412cddf044c6df26592153c25ff4bfa82d9639ef4fe7c57021e78ae6fd4` |

Los originales se conservaron intactos. Los hashes permiten verificar que se está usando la misma versión. Estas bases se mantienen fuera del control de versiones por defecto; un clon necesita copiarlas antes de ejecutar. Los resultados de R van a `output/R`, los de Stata a `output/stata` y el diagnóstico a `output/diagnostico`.

## Fuentes y citas

### Panel de PIB, luces nocturnas e indicadores políticos

Martínez, Luis R. (2022). “How Much Should We Trust the Dictator’s GDP Growth Estimates?” *Journal of Political Economy*, 130(10), 2731–2769. [Artículo y DOI](https://doi.org/10.1086/720458).

- [Página del autor con el enlace de replicación](https://sites.google.com/site/lrmartineza).
- [Paquete de replicación enlazado por el autor: Replication Dictators GDP.zip](https://drive.google.com/file/d/1A8ihVMB3rud84p73w9IkoO5Xk_LJ54OX/view).
- Archivo utilizado dentro del paquete: `Replication Dictators GDP/Data/master/Estimations.dta`.
- Uso en esta tesis: `countrycode`, `year`, `lngdp14`, `lndn13`, `fiw` y `fiw2`. Los scripts seleccionan 1992–2013 y construyen la brecha PIB–NTL.

### Elecciones y orientación política

Girardi, Daniele (2020). “Partisan Shocks and Financial Markets: Evidence from Close National Elections.” *American Economic Journal: Applied Economics*, 12(4), 224–252. [Artículo y DOI](https://doi.org/10.1257/app.20190292).

Girardi, Daniele (2020). *Replication Data for: Partisan shocks and financial markets: evidence from close national elections*. American Economic Association; distribuido por ICPSR, versión V1, 23 de septiembre de 2020. [DOI del conjunto de datos](https://doi.org/10.3886/E115008V1).

- [Repositorio de replicación, versión V1](https://www.openicpsr.org/openicpsr/project/115008/version/V1/view).
- Archivo utilizado dentro del paquete: `Replication_files/elections_dataset.dta`.
- Uso en esta tesis: país y año electoral, tipo de elección, indicadores de victoria y gobierno de izquierda, márgenes electorales y código de exclusión.

## Cómo obtener los datos y ejecutar

1. Descargar los paquetes de replicación desde los enlaces anteriores.
2. Extraer `Estimations.dta` y `elections_dataset.dta` de las rutas indicadas.
3. Copiar ambos a `data/raw/`, manteniendo exactamente esos nombres.
4. Comparar los SHA-256 con los de la tabla anterior para identificar diferencias de versión. Los enlaces se verificaron el 29 de septiembre de 2026; los archivos remotos no se descargaron para compararlos byte por byte con las copias locales.
5. Ejecutar `Rscript run.R` desde la raíz del proyecto.

Los datos de entrada proceden de los trabajos citados. La selección de muestra, combinación de bases y análisis de la tesis se documentan en los scripts de este proyecto. Para las fuentes primarias y la construcción de las bases de los autores, consultar los README de sus respectivos paquetes.
