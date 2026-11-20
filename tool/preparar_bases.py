"""Crea y verifica prototipos nuevos; nunca migra bases existentes."""
import argparse
from pathlib import Path
import sqlite3


SCHEMAS = Path(__file__).resolve().parents[1] / 'database'
APPS = ('fenix_fitness', 'legal_smart', 'myfitmentor', 'rh_comercio',
        'rh_pay', 'smartconvert_ia', 'taskflow_pro')


def inicializar(db, app):
    db.execute('PRAGMA foreign_keys=ON')
    sql = (SCHEMAS / 'comun.sql').read_text(encoding='utf-8')
    sql += '\n' + (SCHEMAS / f'{app}.sql').read_text(encoding='utf-8')
    db.executescript('BEGIN;\n' + sql + '\nPRAGMA user_version=1;\nCOMMIT;')
    assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    assert not db.execute('PRAGMA foreign_key_check').fetchall()


def rechazar(db, sql, parametros=()):
    try:
        db.execute(sql, parametros)
    except sqlite3.IntegrityError:
        return
    raise AssertionError(f'Se aceptó una operación inválida: {sql}')


def verificar():
    for app in APPS:
        with sqlite3.connect(':memory:') as db:
            inicializar(db, app)
            db.execute("INSERT INTO usuarios(id,nombre,creado_en) VALUES('u','Prueba','2026-10-29T00:00:00Z')")
            rechazar(db, "INSERT INTO configuracion VALUES('inexistente','tema','oscuro')")
            db.execute("INSERT INTO configuracion VALUES('u','tema','oscuro')")
            rechazar(db, "INSERT INTO configuracion VALUES('u','tema','claro')")
            db.execute("INSERT INTO planes VALUES('p','Prueba','CLP',0,'Prueba',0)")
            rechazar(db, "INSERT INTO solicitudes_membership VALUES('s','u','p','Prueba','2026-10-29','activa')")
            if app == 'taskflow_pro':
                db.execute("INSERT INTO proyectos VALUES('p1','u','Uno','2026-10-29','CLP')")
                db.execute("INSERT INTO proyectos VALUES('p2','u','Dos','2026-10-29','CLP')")
                for tarea, proyecto in [('t1', 'p1'), ('t2', 'p1'), ('t3', 'p2')]:
                    db.execute('INSERT INTO tareas(id,proyecto_id,nombre,duracion_minutos) VALUES(?,?,?,60)', (tarea, proyecto, tarea))
                db.execute("INSERT INTO dependencias VALUES('p1','t1','t2','FS',0)")
                rechazar(db, "INSERT INTO dependencias VALUES('p1','t1','t3','FS',0)")
                rechazar(db, "INSERT INTO dependencias VALUES('p1','t1','t1','FS',0)")
            if app == 'rh_pay':
                db.execute("INSERT INTO cuentas VALUES('c','u','Cuenta','CLP',0)")
                sql = 'INSERT INTO solicitudes_operacion VALUES(?,?,?,?,?,?,?,?,?,?,?)'
                fila = ('o', 'u', 'clave', 'c', 'CLP', 'transferencia', 100, 'destino', 'Prueba', '2026-10-29', 'solicitada')
                db.execute(sql, fila)
                rechazar(db, sql, ('o2',) + fila[1:])
                rechazar(db, sql, ('o3', 'u', 'otra', 'c', 'BTC') + fila[5:])
                rechazar(db, sql, ('o4', 'u', 'negativa', 'c', 'CLP', 'transferencia', -1) + fila[7:])
            tablas = db.execute("SELECT count(*) FROM sqlite_master WHERE type='table'").fetchone()[0]
            print(f'{app}: OK ({tablas} tablas)')


def crear(destino):
    destino.mkdir(parents=True, exist_ok=True)
    existentes = [destino / f'{app}.db' for app in APPS if (destino / f'{app}.db').exists()]
    if existentes:
        raise ValueError(f'El destino ya contiene bases: {existentes}')
    for app in APPS:
        ruta = destino / f'{app}.db'
        # Reserva exclusiva: tampoco sobrescribe si otro proceso crea el archivo.
        with ruta.open('xb'):
            pass
        db = sqlite3.connect(ruta)
        try:
            inicializar(db, app)
        except Exception:
            db.close()
            ruta.unlink()
            raise
        finally:
            db.close()
        print(ruta)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('accion', choices=('verificar', 'crear'))
    parser.add_argument('--destino', type=Path)
    args = parser.parse_args()
    if args.accion == 'verificar':
        verificar()
    elif args.destino is None:
        parser.error('crear requiere --destino')
    else:
        crear(args.destino.resolve())


if __name__ == '__main__':
    main()
