# Reproducción de la tesis de Anthony Quispe

Proyecto de R y Stata para reproducir las cifras de `Tesis_Anthony_Quispe.pdf` (versión recibida el 29 de septiembre de 2026). Los archivos originales de TESIS se conservan fuera de esta carpeta.

## Desde Visual Studio Code

1. Abre esta carpeta (`Tesis_Grado_Economía`) mediante **File → Open Folder**.
2. Abre **Terminal → New Terminal**.
3. Ejecuta `Rscript run.R`. El proceso termina comprobando las cifras del PDF.
4. Para Stata en este Mac: `/Applications/Stata/StataSE.app/Contents/MacOS/stata-se -q -b do scripts/stata/tesis.do`.
5. Revisa `output/R/comparacion_pdf.csv` y `output/stata/ejecucion.log`. Stata puede devolver estado 0 al sistema aunque el do-file falle: confirma el mensaje `VERIFICADO` y que el log llegue a `log close`.

También puedes usar **Terminal → Run Task** y elegir una de las tres tareas incluidas. VS Code es el editor; R y Stata ejecutan el análisis. Stata requiere su propia instalación y licencia.

## Flujo de ejecución

`run.R` es el punto de entrada de R. Ejecuta el diagnóstico, carga funciones auxiliares, estima beta y construye el panel, ejecuta los RDD y las pruebas de densidad y covariables. Conserva la lógica numérica y las exportaciones del script original, separadas en módulos. No instala paquetes automáticamente.

`scripts/stata/tesis.do` es el punto de entrada de Stata; llama a `validaciones.do`. Se alineó la columna 3 con R y el PDF, se corrigió la expansión temporal por elección y se usan nuevas variables en doble precisión. Se añadieron las pruebas de densidad y balance que faltaban en el do-file original.

## Dependencias

R: `haven`, `dplyr`, `tidyr`, `fixest`, `rdrobust`, `openxlsx`, `ggplot2`, `tibble`, `rddensity`, `lpdensity`.

Entorno validado: R 4.5.1; haven 2.5.5, dplyr 1.2.1, tidyr 1.3.2, fixest 0.13.2, rdrobust 4.0.0, openxlsx 4.2.8.1, ggplot2 4.0.3, tibble 3.3.1, rddensity 3.0, lpdensity 3.0. Cada ejecución guarda `sessionInfo.txt`. Otra versión puede producir diferencias: las verificaciones las detectan.

Stata: `reghdfe`, `ftools`, `outreg2`, `rdrobust`, `rdplot`, `rddensity` y `lpdensity`. `scripts/stata/instalar_rdd.do` instala los paquetes RDD en `ado/` dentro del proyecto. En este Mac, reghdfe y outreg2 ya estaban instalados. Si faltan en otra computadora, instalarlos primero mediante SSC. La instalación local de los paquetes RDD evita la mezcla de un ado nuevo con funciones Mata antiguas detectada en el entorno previo.

## Datos y decisiones de reproducción

Consulta `data/README.md` y `DIAGNOSTICO.md`. Los datos fuente se copian sin cambios a `data/raw/`. Las bases locales y los resultados generados están excluidos de Git; el repositorio contiene código, instrucciones, diagnóstico y copias de tablas y figuras en `resultados/`. Al clonar es necesario aportar las dos bases documentadas.

Esta versión reproduce el PDF; conserva explícitamente el promedio de los años disponibles dentro de t+1 a t+4 y la agregación por país-año electoral. No exige cuatro años completos ni separa las elecciones coincidentes, porque eso cambiaría la muestra. Estas decisiones requieren una revisión metodológica aparte si se desea modificar el análisis.

Las covariables PIB y NTL del test de balance son sus versiones transformadas within, tal como en el código original; los nombres de la tabla del PDF no explicitan esa transformación.

## Control de resultados

El script verifica cifras del PDF con una tolerancia de 0.000051 para valores publicados a cuatro decimales; los tamaños de muestra deben coincidir exactamente. No redondea entradas ni altera coeficientes para cumplir la verificación. R genera tablas Excel y figuras; Stata genera tablas y figuras y CSV de validación. El formato de las tablas puede variar entre lenguajes.

Para volver a ejecutar sólo el diagnóstico: `Rscript scripts/R/diagnostico.R`.

Después de ejecutar ambos lenguajes, `Rscript scripts/R/validar_lenguajes.R` comprueba la equivalencia de las tres muestras, la tabla 4, la densidad y el balance. Validación completada localmente: las diferencias numéricas entre R y Stata son menores de 0.000001 en esas comprobaciones.

## Fuentes de los datos

Este proyecto utiliza las bases de replicación de:

- Martínez, Luis R. (2022). *How Much Should We Trust the Dictator’s GDP Growth Estimates?* Journal of Political Economy, 130(10), 2731–2769. [Artículo](https://doi.org/10.1086/720458).
- Girardi, Daniele (2020). *Partisan Shocks and Financial Markets: Evidence from Close National Elections.* American Economic Journal: Applied Economics, 12(4), 224–252. [Artículo](https://doi.org/10.1257/app.20190292) · [Datos, versión V1](https://doi.org/10.3886/E115008V1).

En [data/README.md](data/README.md) se incluyen las citas, los enlaces a los paquetes de replicación, los archivos exactos utilizados y las instrucciones para colocarlos en `data/raw/` y ejecutar el análisis. Las bases originales no se incluyen en este repositorio.

## Consultar los resultados

Las [tablas y figuras de R y Stata](resultados/README.md) están disponibles en `resultados/` para consultarlas sin ejecutar el análisis. Los resultados de cada nueva ejecución se escriben en `output/`, que permanece fuera de Git. La tesis escrita y las bases de datos no se incluyen.
