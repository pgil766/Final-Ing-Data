output "region" {
  description = "Region donde se crearon los recursos."
  value       = var.region
}

output "bucket" {
  description = "Nombre del bucket S3 privado del ejercicio."
  value       = aws_s3_bucket.datos.bucket
}

output "bucket_arn" {
  description = "ARN del bucket S3."
  value       = aws_s3_bucket.datos.arn
}

output "ruta_datos" {
  description = "Prefijo S3 donde se cargan los CSV de entregas."
  value       = "s3://${aws_s3_bucket.datos.bucket}/${var.prefijo_datos}"
}

output "ruta_resultados_athena" {
  description = "Prefijo S3 donde Athena escribe los resultados."
  value       = "s3://${aws_s3_bucket.datos.bucket}/${var.prefijo_resultados}"
}

output "base_datos_glue" {
  description = "Nombre de la base de datos de Glue Data Catalog."
  value       = aws_glue_catalog_database.mensajeria.name
}

output "tabla_glue" {
  description = "Nombre de la tabla externa con partition projection."
  value       = aws_glue_catalog_table.entregas.name
}

output "tabla_completa" {
  description = "Tabla en formato base_datos.tabla para usar en Athena."
  value       = "${aws_glue_catalog_database.mensajeria.name}.${aws_glue_catalog_table.entregas.name}"
}

output "workgroup_athena" {
  description = "Nombre del workgroup de Athena."
  value       = aws_athena_workgroup.entregas.name
}
