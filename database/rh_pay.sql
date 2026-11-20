-- Prototipo de solicitudes. No representa custodia de dinero ni saldos.
CREATE TABLE cuentas (
  id TEXT PRIMARY KEY NOT NULL,
  usuario_id TEXT NOT NULL REFERENCES usuarios(id),
  nombre TEXT NOT NULL,
  activo TEXT NOT NULL,
  decimales INTEGER NOT NULL CHECK(decimales BETWEEN 0 AND 18),
  UNIQUE(id, activo)
);
CREATE TABLE solicitudes_operacion (
  id TEXT PRIMARY KEY NOT NULL,
  usuario_id TEXT NOT NULL REFERENCES usuarios(id),
  clave_idempotencia TEXT NOT NULL,
  cuenta_id TEXT NOT NULL,
  activo TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK(tipo IN ('transferencia','pago_cuenta','compra','compra_dividida','cambio_divisa','bitcoin')),
  importe_minimo INTEGER NOT NULL CHECK(importe_minimo>0),
  destinatario_referencia TEXT NOT NULL,
  concepto TEXT NOT NULL,
  creado_en TEXT NOT NULL,
  estado TEXT NOT NULL DEFAULT 'borrador' CHECK(estado IN ('borrador','solicitada','cancelada')),
  UNIQUE(usuario_id, clave_idempotencia),
  FOREIGN KEY(cuenta_id, activo) REFERENCES cuentas(id, activo)
);
CREATE INDEX operaciones_por_usuario ON solicitudes_operacion(usuario_id, creado_en);
