# Respuestas

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque la tabla usa partition projection. En vez de guardar en Glue una lista con cada partición, en Terraform le dejamos a la tabla unas reglas: las fechas van del 2026-10-01 al 2026-10-03, avanzan de a un día, tienen formato `yyyy-MM-dd` y viven en la ruta `entregas/fecha=${fecha}/`. Cuando uno consulta, Athena arma la lista de fechas con esas reglas, calcula en qué carpeta de S3 debería estar cada una y lee lo que encuentre ahí.

Como el día 3 estaba dentro del rango desde el primer `terraform apply`, Athena ya lo tenía en cuenta, solo que al principio esa carpeta estaba vacía. Eso se ve en `resultados/inicial/verificacion_tercer_dia_antes_de_carga.csv`: daba 0 registros y la tabla tenía 12. Apenas subimos el archivo del día 3, la misma consulta lo encontró sin hacer nada más. En `resultados/final/verificacion_tercer_dia.csv` salen los 6 registros nuevos, en `verificacion_total_tabla.csv` el total pasa a 18 y los resultados finales coinciden con los esperados del profe.

Tampoco tocamos la tabla ni registramos particiones: en `evidencias/cargas_s3.txt` se ve que Glue no tiene ninguna partición guardada y que `terraform plan` no detectó cambios después de la carga. No usamos crawlers, ni `MSCK REPAIR TABLE`, ni `ALTER TABLE ADD PARTITION`. Solo subimos el archivo y consultamos.

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

El archivo quedaría en S3, pero Athena no lo vería. El rango de la proyección termina el 2026-10-03, así que Athena nunca genera la fecha 4 ni va a buscar esa carpeta. Las consultas seguirían dando lo mismo de ahora (18 registros y sin filas del día 4), y si uno filtra `WHERE fecha = '2026-10-04'` sale vacío, pero sin ningún error. Por eso es fácil no darse cuenta de que faltan datos.

Para incluirlo hay que ampliar el rango de la proyección, y hacerlo desde Terraform para que siga siendo reproducible. Basta con cambiar la variable `rango_fechas` a `2026-10-01,2026-10-04` y correr `terraform apply`. Después de eso no hace falta registrar nada: solo consultar, siempre que el archivo respete la misma ruta y las mismas columnas. Otra opción sería dejar el rango como `2026-10-01,NOW`, así cada día nuevo entra solo sin tener que tocar Terraform.
