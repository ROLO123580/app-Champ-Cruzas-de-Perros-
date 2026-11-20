CREATE TABLE deportistas (
  id TEXT PRIMARY KEY NOT NULL,
  usuario_id TEXT REFERENCES usuarios(id),
  nombre TEXT NOT NULL
);
CREATE TABLE clubes (id TEXT PRIMARY KEY NOT NULL, nombre TEXT NOT NULL);
CREATE TABLE equipos (
  id TEXT PRIMARY KEY NOT NULL,
  club_id TEXT NOT NULL REFERENCES clubes(id),
  nombre TEXT NOT NULL,
  disciplina TEXT NOT NULL
);
CREATE TABLE integrantes (
  equipo_id TEXT NOT NULL REFERENCES equipos(id),
  deportista_id TEXT NOT NULL REFERENCES deportistas(id),
  PRIMARY KEY(equipo_id, deportista_id)
);
CREATE TABLE entrenamientos (
  id TEXT PRIMARY KEY NOT NULL,
  equipo_id TEXT NOT NULL REFERENCES equipos(id),
  descripcion TEXT NOT NULL,
  inicio TEXT NOT NULL,
  duracion_minutos INTEGER NOT NULL CHECK(duracion_minutos>0)
);
CREATE TABLE asistencia (
  entrenamiento_id TEXT NOT NULL REFERENCES entrenamientos(id),
  deportista_id TEXT NOT NULL REFERENCES deportistas(id),
  presente INTEGER NOT NULL CHECK(presente IN (0,1)),
  PRIMARY KEY(entrenamiento_id, deportista_id)
);
CREATE TABLE evaluaciones (
  id TEXT PRIMARY KEY NOT NULL,
  deportista_id TEXT NOT NULL REFERENCES deportistas(id),
  metrica TEXT NOT NULL,
  valor REAL NOT NULL,
  unidad TEXT NOT NULL,
  registrado_en TEXT NOT NULL
);
CREATE INDEX evaluaciones_por_deportista ON evaluaciones(deportista_id, registrado_en);
CREATE TABLE competiciones (
  id TEXT PRIMARY KEY NOT NULL,
  nombre TEXT NOT NULL,
  inicio TEXT NOT NULL
);
CREATE TABLE resultados (
  competicion_id TEXT NOT NULL REFERENCES competiciones(id),
  deportista_id TEXT NOT NULL REFERENCES deportistas(id),
  metrica TEXT NOT NULL,
  valor REAL NOT NULL,
  unidad TEXT NOT NULL,
  PRIMARY KEY(competicion_id, deportista_id, metrica)
);
