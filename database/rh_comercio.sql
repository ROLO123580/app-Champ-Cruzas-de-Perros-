CREATE TABLE productos (
  id TEXT PRIMARY KEY NOT NULL,
  sku TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  precio_minimo INTEGER NOT NULL CHECK(precio_minimo>=0),
  moneda TEXT NOT NULL
);
CREATE TABLE inventario_movimientos (
  id TEXT PRIMARY KEY NOT NULL,
  producto_id TEXT NOT NULL REFERENCES productos(id),
  cantidad_milesimas INTEGER NOT NULL CHECK(cantidad_milesimas<>0),
  motivo TEXT NOT NULL,
  creado_en TEXT NOT NULL
);
CREATE INDEX inventario_por_producto ON inventario_movimientos(producto_id, creado_en);
CREATE TABLE cajas (
  id TEXT PRIMARY KEY NOT NULL,
  usuario_id TEXT NOT NULL REFERENCES usuarios(id),
  moneda TEXT NOT NULL,
  apertura_en TEXT NOT NULL,
  cierre_en TEXT,
  fondo_minimo INTEGER NOT NULL CHECK(fondo_minimo>=0)
);
CREATE TABLE ventas (
  id TEXT PRIMARY KEY NOT NULL,
  caja_id TEXT NOT NULL REFERENCES cajas(id),
  moneda TEXT NOT NULL,
  creado_en TEXT NOT NULL,
  estado TEXT NOT NULL CHECK(estado IN ('borrador','confirmada','anulada'))
);
CREATE TABLE venta_detalle (
  venta_id TEXT NOT NULL REFERENCES ventas(id),
  linea INTEGER NOT NULL CHECK(linea>0),
  producto_id TEXT NOT NULL REFERENCES productos(id),
  descripcion TEXT NOT NULL,
  cantidad_milesimas INTEGER NOT NULL CHECK(cantidad_milesimas>0),
  precio_unitario_minimo INTEGER NOT NULL CHECK(precio_unitario_minimo>=0),
  total_linea_minimo INTEGER NOT NULL CHECK(total_linea_minimo>=0),
  PRIMARY KEY(venta_id, linea)
);
CREATE TABLE cobros (
  id TEXT PRIMARY KEY NOT NULL,
  venta_id TEXT NOT NULL REFERENCES ventas(id),
  referencia_externa TEXT UNIQUE,
  medio TEXT NOT NULL,
  importe_minimo INTEGER NOT NULL CHECK(importe_minimo>0),
  estado TEXT NOT NULL CHECK(estado IN ('pendiente','confirmado','rechazado')),
  creado_en TEXT NOT NULL
);
CREATE INDEX cobros_por_venta ON cobros(venta_id);
