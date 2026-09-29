# Bases necesarias

Colocar ambos archivos en `data/raw/`. Son las entradas de los paquetes de replicación ya presentes en TESIS; no se reconstruyen desde todas las fuentes primarias.

| Archivo | Origen local | SHA-256 |
|---|---|---|
| Estimations.dta | `Replication Dictators GDP/Data/master/Estimations.dta` | `83dd6ee1d21f29ecadfa9f492fed36e414fbf50efd8a2f6c1294981a6a872b68` |
| elections_dataset.dta | `115008-V1/Replication_files/elections_dataset.dta` | `6d3ca412cddf044c6df26592153c25ff4bfa82d9639ef4fe7c57021e78ae6fd4` |

Los originales se conservaron intactos. Los hashes permiten verificar que se está usando la misma versión. Estas bases se mantienen fuera del control de versiones por defecto; un clon necesita copiarlas antes de ejecutar. Los resultados de R van a `output/R`, los de Stata a `output/stata` y el diagnóstico a `output/diagnostico`.
