from datetime import datetime, timezone

from airflow import DAG
from airflow.operators.python import PythonOperator
from runtime import run_dbt

with DAG(
    dag_id="examen_ventas",
    start_date=datetime(2026, 1, 1, tzinfo=timezone.utc),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    max_active_tasks=1,
    default_args={"retries": 0},
    tags=["examen"],
) as dag:
    # Control de actualidad: consulta max(_loaded_at) de raw.ventas.
    # Advertencia (>12 h) -> dbt sale con codigo 0 y la tarea queda en success.
    # Error (>24 h) -> dbt sale con codigo distinto de 0, run_dbt lanza la
    # excepcion y la tarea queda en failed.
    comprobar_freshness = PythonOperator(
        task_id="comprobar_freshness",
        python_callable=run_dbt,
        op_args=[["source", "freshness"]],
    )

    construir_resumen = PythonOperator(
        task_id="construir_resumen",
        python_callable=run_dbt,
        op_args=[["build"]],
    )

    # Regla predeterminada all_success: si freshness falla, build queda upstream_failed.
    comprobar_freshness >> construir_resumen
