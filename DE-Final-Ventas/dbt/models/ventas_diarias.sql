-- Resumen diario de ventas: una fila por fecha de negocio.
-- ingreso_total multiplica cantidad (INTEGER) por precio_unitario (DECIMAL(12,2));
-- el resultado sigue siendo DECIMAL, por lo que no se pierde precision.
select
    fecha_venta,
    count(*) as numero_ventas,
    sum(cantidad) as unidades_vendidas,
    sum(cantidad * precio_unitario) as ingreso_total
from {{ ref('stg_ventas') }}
group by fecha_venta
