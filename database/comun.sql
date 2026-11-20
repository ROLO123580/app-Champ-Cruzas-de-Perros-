CREATE TABLE usuarios (
  id TEXT PRIMARY KEY NOT NULL,
  proveedor TEXT,
  identidad_externa TEXT,
  nombre TEXT NOT NULL,
  creado_en TEXT NOT NULL,
  UNIQUE(proveedor, identidad_externa),
  CHECK ((proveedor IS NULL) = (identidad_externa IS NULL))
);
CREATE TABLE configuracion (
  usuario_id TEXT NOT NULL REFERENCES usuarios(id),
  clave TEXT NOT NULL,
  valor TEXT NOT NULL,
  PRIMARY KEY(usuario_id, clave)
);
CREATE TABLE archivos (
  id TEXT PRIMARY KEY NOT NULL,
  usuario_id TEXT NOT NULL REFERENCES usuarios(id),
  ruta_relativa TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  mime TEXT NOT NULL,
  sha256 TEXT NOT NULL CHECK(length(sha256)=64),
  bytes INTEGER NOT NULL CHECK(bytes>=0),
  creado_en TEXT NOT NULL
);
CREATE INDEX archivos_por_usuario ON archivos(usuario_id);
CREATE TABLE planes (
  id TEXT PRIMARY KEY NOT NULL,
  nombre TEXT NOT NULL,
  moneda TEXT NOT NULL,
  precio_minimo INTEGER NOT NULL CHECK(precio_minimo>=0),
  condiciones TEXT NOT NULL,
  publicado INTEGER NOT NULL DEFAULT 0 CHECK(publicado IN (0,1))
);
CREATE TABLE solicitudes_membership (
  id TEXT PRIMARY KEY NOT NULL,
  usuario_id TEXT NOT NULL REFERENCES usuarios(id),
  plan_id TEXT NOT NULL REFERENCES planes(id),
  condiciones_aceptadas TEXT NOT NULL,
  creado_en TEXT NOT NULL,
  estado TEXT NOT NULL DEFAULT 'pendiente' CHECK(estado IN ('pendiente','cancelada'))
);
CREATE INDEX membership_por_usuario ON solicitudes_membership(usuario_id, creado_en);
