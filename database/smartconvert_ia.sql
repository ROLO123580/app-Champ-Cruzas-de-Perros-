CREATE TABLE trabajos (
  id TEXT PRIMARY KEY NOT NULL,
  usuario_id TEXT NOT NULL REFERENCES usuarios(id),
  entrada_id TEXT NOT NULL REFERENCES archivos(id),
  salida_id TEXT REFERENCES archivos(id),
  tipo TEXT NOT NULL CHECK(tipo IN ('conversion','extraccion','importacion_factura')),
  formato_destino TEXT,
  estado TEXT NOT NULL CHECK(estado IN ('pendiente','procesando','completado','fallido')),
  error TEXT,
  creado_en TEXT NOT NULL
);
CREATE INDEX trabajos_por_usuario ON trabajos(usuario_id, creado_en);
CREATE TABLE extracciones (
  trabajo_id TEXT NOT NULL REFERENCES trabajos(id),
  campo TEXT NOT NULL,
  valor TEXT NOT NULL,
  confianza REAL CHECK(confianza BETWEEN 0 AND 1),
  PRIMARY KEY(trabajo_id, campo)
);
CREATE TABLE facturas_importadas (
  id TEXT PRIMARY KEY NOT NULL,
  trabajo_id TEXT NOT NULL REFERENCES trabajos(id),
  rut_emisor TEXT NOT NULL,
  tipo_documento TEXT NOT NULL,
  folio TEXT NOT NULL,
  fecha TEXT NOT NULL,
  moneda TEXT NOT NULL,
  total_minimo INTEGER NOT NULL CHECK(total_minimo>=0),
  UNIQUE(rut_emisor, tipo_documento, folio)
);
CREATE TABLE costos_procesamiento (
  id TEXT PRIMARY KEY NOT NULL,
  trabajo_id TEXT NOT NULL REFERENCES trabajos(id),
  concepto TEXT NOT NULL,
  importe_minimo INTEGER NOT NULL CHECK(importe_minimo>=0),
  moneda TEXT NOT NULL
);
