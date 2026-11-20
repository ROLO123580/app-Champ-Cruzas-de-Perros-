CREATE TABLE personas (
  id TEXT PRIMARY KEY NOT NULL,
  usuario_id TEXT REFERENCES usuarios(id),
  nombre TEXT NOT NULL
);
CREATE TABLE entrenador_alumno (
  entrenador_id TEXT NOT NULL REFERENCES personas(id),
  alumno_id TEXT NOT NULL REFERENCES personas(id),
  PRIMARY KEY(entrenador_id, alumno_id),
  CHECK(entrenador_id<>alumno_id)
);
CREATE TABLE consumos (
  id TEXT PRIMARY KEY NOT NULL,
  persona_id TEXT NOT NULL REFERENCES personas(id),
  concepto TEXT NOT NULL,
  cantidad REAL NOT NULL CHECK(cantidad>0),
  unidad TEXT NOT NULL,
  ocurrido_en TEXT NOT NULL
);
CREATE INDEX consumos_por_persona ON consumos(persona_id, ocurrido_en);
CREATE TABLE gastos (
  id TEXT PRIMARY KEY NOT NULL,
  persona_id TEXT NOT NULL REFERENCES personas(id),
  concepto TEXT NOT NULL,
  importe_minimo INTEGER NOT NULL CHECK(importe_minimo>0),
  moneda TEXT NOT NULL,
  ocurrido_en TEXT NOT NULL
);
CREATE TABLE objetivos (
  id TEXT PRIMARY KEY NOT NULL,
  persona_id TEXT NOT NULL REFERENCES personas(id),
  descripcion TEXT NOT NULL,
  metrica TEXT NOT NULL,
  unidad TEXT NOT NULL,
  valor_meta REAL NOT NULL,
  fecha_meta TEXT
);
CREATE TABLE progreso (
  id TEXT PRIMARY KEY NOT NULL,
  objetivo_id TEXT NOT NULL REFERENCES objetivos(id),
  valor REAL NOT NULL,
  registrado_en TEXT NOT NULL
);
CREATE INDEX progreso_por_objetivo ON progreso(objetivo_id, registrado_en);
