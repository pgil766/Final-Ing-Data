# Respuestas conceptuales

## 1. ¿Por qué usar `_loaded_at` y no `fecha_venta` para este control?

Porque lo que nos interesa saber es si la carga llegó a tiempo, no cuándo pasaron las ventas. `_loaded_at` dice en qué momento entró cada fila a `raw`, entonces con el `max(_loaded_at)` sabemos cuánto tiempo lleva el sistema sin recibir datos nuevos. Eso es justo lo que se atrasa cuando la carga falla.

Con `fecha_venta` el control no tendría sentido. Una venta vieja se puede cargar hoy (por ejemplo una corrección), y también puede haber días sin ventas, como un festivo, sin que la carga tenga ningún problema. En este ejercicio se ve muy claro: las ventas son del 10 al 12 de enero de 2026 en los tres escenarios, así que si midiéramos con `fecha_venta` siempre daría error, aunque la carga fuera de hace 2 horas. Con `_loaded_at` el resultado sí cambia según la carga: a las 2 horas pasa, a las 18 advierte y a las 30 falla (se ve en `logs/*_resultado_freshness.txt` y en `logs/desactualizada_motivo_error_freshness.txt`).

Igual hay que tener en cuenta que este control solo mira la última carga. Que haya llegado algo hace poco no quiere decir que hayan llegado todas las ventas.

## 2. ¿Por qué las pruebas de integridad no garantizan actualidad?

Porque las pruebas de integridad revisan cómo están los datos, no cuándo llegaron. `unique`, `not_null` y `valores_ventas` verifican que no se repitan ids, que no falten campos y que las cantidades y precios tengan sentido. Unos datos de hace 30 horas, o de hace un mes, pueden pasar todas esas pruebas sin problema: están completos y bien, solo que están viejos.

Para saber si están al día hay que comparar la última carga con la hora actual, y eso es lo que hace `dbt source freshness`. Además, `dbt build` no corre freshness por su cuenta. En nuestras evidencias se nota: en el escenario de advertencia los datos tenían 18 horas y aun así el build pasó las 19 pruebas. Si no hubiéramos puesto la tarea de freshness antes, en el escenario de 30 horas el build también habría terminado bien y habría reconstruido el resumen con datos viejos sin que nadie se diera cuenta. Por eso en el DAG freshness va antes de construir el resumen.
