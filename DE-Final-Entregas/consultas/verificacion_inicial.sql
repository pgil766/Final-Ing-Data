-- Verificacion adicional de la etapa inicial (solo dias 1 y 2 cargados en S3).

-- 1) Total de registros de la tabla (debe ser 12) -> resultados/inicial/verificacion_total_tabla.csv
SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT fecha) AS total_fechas
FROM mensajeria.entregas;

-- 2) El 2026-10-03 ya esta dentro del rango proyectado, pero su archivo aun no
--    existe en S3, asi que la consulta devuelve 0 registros
--    -> resultados/inicial/verificacion_tercer_dia_antes_de_carga.csv
SELECT
    '2026-10-03' AS fecha,
    COUNT(*) AS total_registros
FROM mensajeria.entregas
WHERE fecha = '2026-10-03';
