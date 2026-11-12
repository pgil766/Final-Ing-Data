-- Verificacion de la nueva fecha 2026-10-03, cargada solo subiendo el archivo a S3
-- (sin crawlers, MSCK REPAIR TABLE, ALTER TABLE ADD PARTITION ni cambios en la tabla).
-- El archivo tiene varias consultas separadas por ';'. Cada una se ejecuta aparte
-- en Athena y su resultado se guarda en un CSV distinto de resultados/final/.

-- 1) Los seis registros del tercer dia -> resultados/final/verificacion_tercer_dia.csv
SELECT
    fecha,
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos
FROM mensajeria.entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio ASC;

-- 2) Conteo por estado del tercer dia -> resultados/final/verificacion_tercer_dia_conteo_estado.csv
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM mensajeria.entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC;

-- 3) Registros por fecha -> resultados/final/verificacion_registros_por_fecha.csv
SELECT
    fecha,
    COUNT(*) AS total_registros
FROM mensajeria.entregas
GROUP BY fecha
ORDER BY fecha ASC;

-- 4) Total de la tabla (debe ser 18) -> resultados/final/verificacion_total_tabla.csv
SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT fecha) AS total_fechas,
    COUNT(DISTINCT id_envio) AS total_envios_unicos
FROM mensajeria.entregas;
