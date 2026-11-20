CREATE TABLE proyectos (
  id TEXT PRIMARY KEY NOT NULL,
  usuario_id TEXT NOT NULL REFERENCES usuarios(id),
  nombre TEXT NOT NULL,
  inicio TEXT NOT NULL,
  moneda TEXT NOT NULL
);
CREATE TABLE tareas (
  id TEXT PRIMARY KEY NOT NULL,
  proyecto_id TEXT NOT NULL REFERENCES proyectos(id),
  nombre TEXT NOT NULL,
  inicio_planificado TEXT,
  duracion_minutos INTEGER NOT NULL CHECK(duracion_minutos>=0),
  avance_porcentaje INTEGER NOT NULL DEFAULT 0 CHECK(avance_porcentaje BETWEEN 0 AND 100),
  costo_planificado_minimo INTEGER NOT NULL DEFAULT 0 CHECK(costo_planificado_minimo>=0),
  UNIQUE(proyecto_id, id)
);
CREATE TABLE dependencias (
  proyecto_id TEXT NOT NULL REFERENCES proyectos(id),
  predecesora_id TEXT NOT NULL,
  sucesora_id TEXT NOT NULL,
  tipo TEXT NOT NULL DEFAULT 'FS' CHECK(tipo IN ('FS','SS','FF','SF')),
  desfase_minutos INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY(proyecto_id, predecesora_id, sucesora_id),
  FOREIGN KEY(proyecto_id, predecesora_id) REFERENCES tareas(proyecto_id, id),
  FOREIGN KEY(proyecto_id, sucesora_id) REFERENCES tareas(proyecto_id, id),
  CHECK(predecesora_id<>sucesora_id)
);
CREATE TABLE recursos (
  id TEXT PRIMARY KEY NOT NULL,
  proyecto_id TEXT NOT NULL REFERENCES proyectos(id),
  nombre TEXT NOT NULL,
  capacidad_minutos_dia INTEGER NOT NULL CHECK(capacidad_minutos_dia>0),
  UNIQUE(proyecto_id, id)
);
CREATE TABLE asignaciones (
  proyecto_id TEXT NOT NULL REFERENCES proyectos(id),
  tarea_id TEXT NOT NULL,
  recurso_id TEXT NOT NULL,
  minutos INTEGER NOT NULL CHECK(minutos>0),
  PRIMARY KEY(proyecto_id, tarea_id, recurso_id),
  FOREIGN KEY(proyecto_id, tarea_id) REFERENCES tareas(proyecto_id, id),
  FOREIGN KEY(proyecto_id, recurso_id) REFERENCES recursos(proyecto_id, id)
);
CREATE TABLE avances (
  id TEXT PRIMARY KEY NOT NULL,
  tarea_id TEXT NOT NULL REFERENCES tareas(id),
  registrado_en TEXT NOT NULL,
  minutos_reales INTEGER NOT NULL CHECK(minutos_reales>=0),
  costo_real_minimo INTEGER NOT NULL CHECK(costo_real_minimo>=0),
  nota TEXT NOT NULL
);
CREATE INDEX avances_por_tarea ON avances(tarea_id, registrado_en);
