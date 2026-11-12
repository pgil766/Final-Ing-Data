-- Cantidad de intentos por fecha y estado.
-- No filtra por fecha: con partition projection Athena recorre todo el rango
-- proyectado (2026-10-01 a 2026-10-03) y solo devuelve las fechas con datos en S3.
-- Por eso la misma consulta sirve para la etapa inicial y la final.
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM mensajeria.entregas
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC;
