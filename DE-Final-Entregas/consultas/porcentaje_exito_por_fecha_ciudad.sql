-- Porcentaje de entregas exitosas por fecha y ciudad.
-- porcentaje = 100 * entregas con estado 'entregado' / total de intentos del grupo.
-- El denominador incluye todos los estados. Se usa DOUBLE para evitar la
-- division entera y DECIMAL(5,2) para mostrar siempre dos decimales.
SELECT
    fecha,
    ciudad,
    CAST(
        ROUND(
            100.0E0 * SUM(CASE WHEN estado = 'entregado' THEN 1 ELSE 0 END) / COUNT(*),
            2
        ) AS DECIMAL(5, 2)
    ) AS porcentaje_exito
FROM mensajeria.entregas
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC;
