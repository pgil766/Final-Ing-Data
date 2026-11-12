# Entrega: ventas diarias con control de actualidad

**Autor:** Pablo Gil.

Esta carpeta contiene las evidencias del examen. El enunciado está en el [README del proyecto](../README.md). Solo se modificaron los tres archivos permitidos:

| Archivo | Cambio |
|---|---|
| [`dbt/models/ventas_diarias.sql`](../dbt/models/ventas_diarias.sql) | Resumen con una fila por `fecha_venta`: `count(*)`, `sum(cantidad)` y `sum(cantidad * precio_unitario)`. Se conserva `DECIMAL`, y el resultado es `DECIMAL(38,2)`. |
| [`dbt/models/sources.yml`](../dbt/models/sources.yml) | En la tabla `ventas`, al mismo nivel que `columns` y fuera de `config`: `loaded_at_field: _loaded_at`, `warn_after: {count: 12, period: hour}` y `error_after: {count: 24, period: hour}`. |
| [`airflow/dags/examen_ventas.py`](../airflow/dags/examen_ventas.py) | Tarea nueva `comprobar_freshness`, un `PythonOperator` que reutiliza `run_dbt` con `["source", "freshness"]`. Dependencia `comprobar_freshness >> construir_resumen`. Mantiene la regla `all_success`, `retries: 0` y no usa `--warn-error`. |

## Cómo se ejecutó

El entorno ya estaba preparado con el ZIP, así que se siguió esa sección del README:

1. Se conservó el `.env` que creó `preparar.sh`. No se versiona.
2. Se ejecutó `docker compose up -d --wait airflow` desde esta carpeta del proyecto.
3. Se ejecutó `bash scripts/examen.sh check`, con todo en OK.

No se hizo `pull`, no se reconstruyó la imagen y no se ejecutó `down -v`.

Comprobación del modelo: `bash scripts/examen.sh dbt build` dio `PASS=19 WARN=0 ERROR=0`. El resumen coincide con la tabla esperada.

Cada escenario se preparó justo antes de su ejecución, que se lanzó con **Trigger DAG** en la interfaz de Airflow. Cada vez fue una ejecución nueva, sin limpiar ni reutilizar tareas.

## Resultados

| # | Escenario | Run ID | Última carga | Freshness (dbt) | `comprobar_freshness` | `construir_resumen` |
|---|---|---|---|---|---|---|
| 1 | actualizada | `manual__2026-11-12T11:53:17.755263+00:00` | hace 2.00 h | `PASS` | success | success |
| 2 | advertencia (opcional) | `manual__2026-11-12T11:55:27.682370+00:00` | hace 18.00 h | `WARN` | success | success |
| 3 | desactualizada | `manual__2026-11-12T11:56:30.702456+00:00` | hace 30.00 h | `ERROR STALE` | **failed** | **upstream_failed** |

### 1. Fuente actualizada
- Capturas: [grafo con estados](capturas/1_actualizada_grafo_estados.jpg), [run ID y estado](capturas/1_actualizada_run_id_estado.jpg), [log de freshness](capturas/1_actualizada_log_freshness.jpg) y [log de build](capturas/1_actualizada_log_build.jpg). Freshness terminó a las 11:53:28 y build empezó a las 11:53:30, en ese orden. Ambos logs muestran `INICIO dbt` y `FIN dbt`.
- Estados: [estados_actualizada.txt](estados/estados_actualizada.txt). Logs completos: [freshness](logs/actualizada_comprobar_freshness.log) y [build](logs/actualizada_construir_resumen.log).
- Resumen consultado (**antes** del bloqueo): [resumen_antes_bloqueo.txt](resumenes/resumen_antes_bloqueo.txt).

### 2. Advertencia (opcional)
- Captura: [grafo con estados](capturas/2_advertencia_grafo_estados.jpg). dbt informó `WARN freshness of ventas_raw.ventas` con 18.00 h ([resultado](logs/advertencia_resultado_freshness.txt)). La salida fue exitosa, así que build se ejecutó.

### 3. Fuente desactualizada
- Capturas:
  - [Run ID y estados](capturas/3_desactualizada_run_id_y_estados.jpg), [grafo](capturas/3_desactualizada_grafo_estados.jpg) y [detalle de la ejecución, `failed`](capturas/3_desactualizada_run_id_estado_failed.jpg).
  - Log de freshness: [inicio](capturas/3_desactualizada_log_freshness_inicio.jpg), donde aparece `INICIO dbt ['source', 'freshness']`, y [error](capturas/3_desactualizada_log_freshness_error.jpg), donde aparece `CalledProcessError ... returned non-zero exit status 1` y `Marking task as FAILED`.
  - Build: [`upstream_failed`](capturas/3_desactualizada_build_upstream_failed.jpg), [regla `all_success` y duración 0](capturas/3_desactualizada_build_all_success_duracion_0.jpg) y [log vacío, sin `INICIO dbt`](capturas/3_desactualizada_build_sin_log.jpg).
- **Motivo del fallo:** [desactualizada_motivo_error_freshness.txt](logs/desactualizada_motivo_error_freshness.txt). dbt dio `ERROR STALE freshness of ventas_raw.ventas`, con `status: error`, una antigüedad de **30.00 horas** y el criterio `error_after 24 hour`.
  - `run_dbt` lanza dbt como subproceso, así que el log de Airflow solo muestra `INICIO dbt` y la excepción con el código de salida.
  - El detalle de dbt se toma de su propio log ([dbt_completo.log](logs/dbt_completo.log)) y del artefacto `sources.json` ([artefactos](logs/desactualizada_artefactos_dbt.json.txt)), obtenido con `bash scripts/examen.sh artifacts`.
- **Build no se ejecutó:**
  - [intentos_desactualizada.txt](estados/intentos_desactualizada.txt) muestra `construir_resumen | upstream_failed | try_number 0`, sin hostname ni pid.
  - No existe carpeta de logs para esa tarea en esa ejecución ([log](logs/desactualizada_construir_resumen.log)).
  - En `dbt_completo.log` no hay ningún `dbt build` posterior a las 11:56:36.
- Resumen consultado (**después** del bloqueo): [resumen_despues_bloqueo.txt](resumenes/resumen_despues_bloqueo.txt). Es idéntico al anterior (`diff` sin diferencias). El resumen se **conservó**; no se borró ni se reconstruyó.

Todas las ejecuciones del DAG: [ejecuciones_dag.txt](estados/ejecuciones_dag.txt).

## Respuestas conceptuales
Ver [respuestas.md](respuestas.md).

## Notas
- En `dbt_completo.log` aparecen también las ejecuciones manuales de comprobación por CLI (`dbt build` y `dbt source freshness` de las 11:52). Se hicieron antes de las ejecuciones del DAG, para verificar el modelo como indica la sección "Comprobación".
- Los tiempos están en UTC.
- No se incluyen imágenes Docker, volúmenes, `.env` ni credenciales.

## Uso de IA
Desarrollado con apoyo de Claude Code (Anthropic), lo cual el curso permite. El hilo de la conversación se envía al docente.
