# Diagnóstico y reproducción

Revisión del 29 de septiembre de 2026. Las bases originales y los dos scripts originales no se modificaron.

## Bases

| Base | Filas | Variables | Países | Años presentes |
|---|---:|---:|---:|---|
| Estimations.dta | 13 054 | 228 | 214 | 1960–2020 |
| elections_dataset.dta | 2 919 | 42 | 202 | 1945–2018 |

No hay filas completamente duplicadas. Martínez tiene una fila por país-año y Girardi tiene claves electorales `key` únicas. Los límites de años anteriores describen las bases completas, no la muestra de estimación.

## Selección que ya hace el código

- Martínez: 13 054 → 4 708 filas de 1992–2013 → 3 895 observaciones con PIB, NTL y FiW disponibles.
- Girardi: 2 919 → 2 880 al aplicar `exclude != 1` → 1 478 de 1992–2013 → 523 elecciones con tratamiento y margen disponibles.
- Esas 523 elecciones forman 491 grupos país-año. De ellos, 29 no tienen ningún año posterior disponible y quedan 462 registros finales, exactamente los 296 + 166 del PDF.

En el panel 1992–2013 faltan 528 valores de PIB, 279 de NTL y 569 de FiW. Esos faltantes se superponen y no se suman para obtener las exclusiones. `fiw2` coincide con `fiw^2` en el panel seleccionado. No se imputaron datos.

## Años posteriores disponibles

| Años con información dentro de t+1 a t+4 | Registros finales |
|---|---:|
| 4 | 371 |
| 3 | 34 |
| 2 | 33 |
| 1 | 24 |
| Total | 462 |

Por tanto, 91 registros (19.7%) tienen menos de cuatro años. Por ejemplo, Argentina 2011 tiene 2012 y 2013; Armenia 2012 tiene sólo 2013; Australia 2010 tiene 2011, 2012 y 2013. También hay faltantes internos en años anteriores. El CSV `output/diagnostico/cobertura_por_eleccion.csv` permite revisar cada elección, los años presentes y los ausentes.

La fórmula de la tesis describe cuatro años completos. El código que reproduce sus resultados usa los años disponibles. Se conserva esta regla para reproducir el documento; no se presenta como si todos tuvieran cuatro años.

## Elecciones coincidentes

Hay 32 grupos país-año con dos elecciones elegibles; 30 permanecen en la muestra final. Son elecciones diferentes, no claves duplicadas. La función original de R las combina al promediar por país-año, incluyendo margen y tratamiento. En seis registros finales el tratamiento queda entre 0 y 1. Esto se documenta y se conserva para reproducción, sin afirmar que sea la unidad de análisis más adecuada.

El Stata original generaba `k = _n` dentro de país-año después de expandir: con dos elecciones podía producir k=1,...,8. La versión ordenada genera k=1,...,4 por fila electoral, como R, y luego mantiene la misma agregación. Así se reproduce el PDF.

## Resultados comprobados

La ejecución completa del R original fue guardada como referencia local. El R modular conserva exactamente panel, muestras A/B/C y tabla de balance de esa ejecución.

- Tabla 2: coeficientes NTL 0.2964, 0.2919, 0.2154 y 0.2140; N=3895.
- Tabla 4: coeficiente convencional 6.7808; EE robusto 5.4615; p robusto 0.0928; IC robusto [-1.5260, 19.8828]; N=296/166; N efectivo=130/110; h=26.8863; b=46.4675.
- Densidad: estadístico 0.3433 y p=0.7314.
- Balance: coeficientes, errores estándar, valores p y N de las cinco covariables coinciden con el PDF.

El coeficiente convencional y la inferencia robusta se reportan como en el PDF; el coeficiente corregido por sesgo es distinto y no se confunde con el convencional. Esta comprobación reproduce cifras y no sustituye la revisión de los supuestos del diseño.

Los CSV de detalle se regeneran con `Rscript scripts/R/diagnostico.R`.

La versión organizada de Stata también se ejecutó completa. Pasó las comprobaciones contra el PDF de tablas 3 y 4 y densidad; además, `validar_lenguajes.R` confirmó equivalencia con R de las muestras A/B/C, tabla 4, balance y densidad con tolerancia de 0.000001. El panel de brechas coincide con R hasta diferencias del orden de 10^-12.
