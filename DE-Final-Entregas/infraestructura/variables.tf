variable "region" {
  description = "Region de AWS donde se despliegan todos los recursos."
  type        = string
  default     = "us-east-2"
}

variable "prefijo_bucket" {
  description = "Prefijo del nombre del bucket. Se le agrega el ID de la cuenta para que el nombre sea unico."
  type        = string
  default     = "de-final-entregas"
}

variable "nombre_base_datos" {
  description = "Nombre de la base de datos de Glue Data Catalog."
  type        = string
  default     = "mensajeria"
}

variable "nombre_tabla" {
  description = "Nombre de la tabla externa de entregas."
  type        = string
  default     = "entregas"
}

variable "nombre_workgroup" {
  description = "Nombre del workgroup de Athena."
  type        = string
  default     = "entregas-wg"
}

variable "prefijo_datos" {
  description = "Prefijo de S3 donde se guardan los CSV de entregas (termina en /)."
  type        = string
  default     = "entregas/"
}

variable "prefijo_resultados" {
  description = "Prefijo de S3 donde Athena escribe los resultados (termina en /)."
  type        = string
  default     = "resultados-athena/"
}

variable "rango_fechas" {
  description = "Rango de fechas proyectadas: inicio y fin incluidos, formato yyyy-MM-dd."
  type        = string
  default     = "2026-10-01,2026-10-03"
}
