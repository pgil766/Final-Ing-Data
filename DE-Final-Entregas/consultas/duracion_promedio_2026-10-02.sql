-- Duracion promedio (minutos) de las entregas exitosas del 2026-10-02.
-- Un solo promedio para todas las ciudades y transportadoras.
-- Solo se incluyen intentos 'entregado', asi los fallidos (duracion 0) no bajan el promedio.
SELECT
    fecha,
    CAST(
        ROUND(AVG(CAST(duracion_minutos AS DOUBLE)), 2) AS DECIMAL(10, 2)
    ) AS duracion_promedio_minutos
FROM mensajeria.entregas
WHERE fecha = '2026-10-02'
  AND estado = 'entregado'
GROUP BY fecha;
