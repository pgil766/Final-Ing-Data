terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Proyecto = "DE-Final-Entregas"
    }
  }
}

data "aws_caller_identity" "actual" {}

locals {
  nombre_bucket = "${var.prefijo_bucket}-${data.aws_caller_identity.actual.account_id}"
}

# ---------------------------------------------------------------------------
# 1. Bucket S3 privado (datos en entregas/ y resultados en resultados-athena/)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "datos" {
  bucket = local.nombre_bucket
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket = aws_s3_bucket.datos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "datos" {
  bucket = aws_s3_bucket.datos.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datos" {
  bucket = aws_s3_bucket.datos.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------------------------------------------------------------------
# 2. Base de datos de Glue Data Catalog
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_database" "mensajeria" {
  name        = var.nombre_base_datos
  description = "Catalogo de los intentos de entrega de la empresa de mensajeria."
}

# ---------------------------------------------------------------------------
# 3. Tabla externa con partition projection por fecha
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_table" "entregas" {
  name          = var.nombre_tabla
  database_name = aws_glue_catalog_database.mensajeria.name
  description   = "Intentos de entrega diarios en CSV, particionados por fecha con partition projection."
  table_type    = "EXTERNAL_TABLE"

  # La fecha viene de la carpeta fecha=yyyy-MM-dd, no del CSV.
  partition_keys {
    name    = "fecha"
    type    = "string"
    comment = "Fecha del archivo, tomada de la carpeta fecha=yyyy-MM-dd"
  }

  parameters = {
    EXTERNAL                 = "TRUE"
    classification           = "csv"
    "skip.header.line.count" = "1"

    # Partition projection: Athena calcula las particiones al consultar.
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = var.rango_fechas
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"
    "storage.location.template"      = "s3://${aws_s3_bucket.datos.bucket}/${var.prefijo_datos}fecha=$${fecha}/"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.datos.bucket}/${var.prefijo_datos}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv-lazy-simple"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    # Las cinco columnas del CSV, en el mismo orden del encabezado.
    columns {
      name = "id_envio"
      type = "string"
    }

    columns {
      name = "ciudad"
      type = "string"
    }

    columns {
      name = "transportadora"
      type = "string"
    }

    columns {
      name = "estado"
      type = "string"
    }

    columns {
      name = "duracion_minutos"
      type = "int"
    }
  }
}

# ---------------------------------------------------------------------------
# 4. Workgroup de Athena con resultados en resultados-athena/
# ---------------------------------------------------------------------------
resource "aws_athena_workgroup" "entregas" {
  name          = var.nombre_workgroup
  description   = "Workgroup del ejercicio de entregas con partition projection."
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = "s3://${aws_s3_bucket.datos.bucket}/${var.prefijo_resultados}"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
