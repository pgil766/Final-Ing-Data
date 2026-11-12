#!/usr/bin/env bash
# Ejecuta en Athena las consultas de un archivo .sql, descarga el CSV que Athena
# escribe en s3://<bucket>/resultados-athena/ y registra cada ejecucion en
# evidencias/ejecuciones_athena.csv.
#
# Uso (desde la raiz del repositorio):
#   bash scripts/ejecutar_consulta.sh <etapa> <archivo.sql> <resultado1.csv> [resultado2.csv ...]
#
# Si el .sql tiene varias consultas separadas por ';', se ejecutan en orden y la
# consulta N se guarda en el resultado N.
#
# Athena escribe los CSV con todos los valores entre comillas dobles. Como los
# datos no tienen comas ni comillas internas, se quitan las comillas para dejar
# el mismo formato de resultados_esperados/ (separador coma, LF, sin comillas).
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "Uso: $0 <inicial|final> <archivo.sql> <resultado1.csv> [resultado2.csv ...]" >&2
  exit 1
fi

ETAPA="$1"; SQL="$2"; shift 2
RESULTADOS=("$@")
REGISTRO="evidencias/ejecuciones_athena.csv"

WORKGROUP="$(terraform -chdir=infraestructura output -raw workgroup_athena)"
REGION="$(terraform -chdir=infraestructura output -raw region)"

# Quita comentarios de linea y separa las consultas por ';'
mapfile -d $'\x1e' CONSULTAS < <(sed -e 's/--.*$//' "$SQL" | tr ';' $'\x1e')
LIMPIAS=()
for q in "${CONSULTAS[@]}"; do
  q="${q%$'\x1e'}"
  if [ -n "$(echo "$q" | tr -d '[:space:]')" ]; then LIMPIAS+=("$q"); fi
done

if [ "${#LIMPIAS[@]}" -ne "${#RESULTADOS[@]}" ]; then
  echo "El archivo $SQL tiene ${#LIMPIAS[@]} consultas pero se indicaron ${#RESULTADOS[@]} resultados." >&2
  exit 1
fi

[ -f "$REGISTRO" ] || echo "etapa,archivo_sql,id_ejecucion,archivo_resultado" > "$REGISTRO"

for i in "${!LIMPIAS[@]}"; do
  CONSULTA="${LIMPIAS[$i]}"
  DESTINO="${RESULTADOS[$i]}"

  ID="$(aws athena start-query-execution \
        --region "$REGION" \
        --work-group "$WORKGROUP" \
        --query-string "$CONSULTA" \
        --query QueryExecutionId --output text)"

  while true; do
    ESTADO="$(aws athena get-query-execution --region "$REGION" \
              --query-execution-id "$ID" --query QueryExecution.Status.State --output text)"
    case "$ESTADO" in
      SUCCEEDED) break ;;
      FAILED|CANCELLED)
        aws athena get-query-execution --region "$REGION" --query-execution-id "$ID" \
          --query QueryExecution.Status.StateChangeReason --output text >&2
        exit 1 ;;
      *) sleep 1 ;;
    esac
  done

  SALIDA_S3="$(aws athena get-query-execution --region "$REGION" --query-execution-id "$ID" \
               --query QueryExecution.ResultConfiguration.OutputLocation --output text)"

  mkdir -p "$(dirname "$DESTINO")"
  aws s3 cp --region "$REGION" --only-show-errors "$SALIDA_S3" - | tr -d '"\r' > "$DESTINO"

  echo "$ETAPA,$SQL,$ID,$DESTINO" >> "$REGISTRO"
  echo "[$ETAPA] $SQL -> $DESTINO (id $ID, salida $SALIDA_S3)"
done
