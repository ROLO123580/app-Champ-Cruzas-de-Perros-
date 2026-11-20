// Datos 100% ficticios para el entorno señuelo de Champ.
// Ninguna persona, correo ni perro corresponde a alguien real.
// Los correos usan el dominio reservado .test, que no puede recibir mensajes.
const usuario = (n, nombre, ciudad, perro) => ({
  n, nombre, ciudad, correo: `sim${String(n).padStart(2, '0')}@champ-sim.test`, perro,
});
const perro = (nombre, raza, sexo, edadMeses, descripcion) => ({ nombre, raza, sexo, edadMeses, descripcion });

export const DATOS = {
  usuarios: [
    usuario(1, 'Camila Rojas', 'Santiago', perro('Luna', 'Golden Retriever', 'Hembra', 30, 'Cariñosa, juguetona y muy sociable con otros perros.')),
    usuario(2, 'Matías González', 'Santiago', perro('Rocco', 'Golden Retriever', 'Macho', 36, 'Tranquilo, le encanta nadar y buscar la pelota.')),
    usuario(3, 'Valentina Muñoz', 'Viña del Mar', perro('Nala', 'Labrador', 'Hembra', 24, 'Energía alta, ideal para paseos largos por la costa.')),
    usuario(4, 'Benjamín Soto', 'Valparaíso', perro('Thor', 'Labrador', 'Macho', 42, 'Grande y noble, campeón de obediencia básica.')),
    usuario(5, 'Javiera Contreras', 'Concepción', perro('Mia', 'Beagle', 'Hembra', 18, 'Curiosa y comilona, sigue cualquier olor.')),
    usuario(6, 'Sebastián Silva', 'Santiago', perro('Bruno', 'Beagle', 'Macho', 28, 'Alegre, aúlla cuando escucha la sirena del camión de la basura.')),
    usuario(7, 'Fernanda Martínez', 'La Serena', perro('Kira', 'Border Collie', 'Hembra', 20, 'Inteligentísima, aprende trucos en minutos.')),
    usuario(8, 'Diego Sepúlveda', 'Temuco', perro('Max', 'Border Collie', 'Macho', 33, 'Necesita actividad diaria, excelente en agility.')),
    usuario(9, 'Antonia Morales', 'Santiago', perro('Lola', 'Bulldog Francés', 'Hembra', 22, 'Dormilona y regalona, ronca bajito.')),
    usuario(10, 'Joaquín Rodríguez', 'Rancagua', perro('Simón', 'Bulldog Francés', 'Macho', 26, 'Simpático y glotón, se lleva bien con niños.')),
    usuario(11, 'Catalina López', 'Puerto Montt', perro('Maya', 'Pastor Alemán', 'Hembra', 40, 'Protectora y leal, muy bien socializada.')),
    usuario(12, 'Tomás Fuentes', 'Antofagasta', perro('Zeus', 'Pastor Alemán', 'Macho', 48, 'Equilibrado, entrenado para convivir con gatos.')),
    usuario(13, 'Isidora Hernández', 'Santiago', perro('Canela', 'Mestizo', 'Hembra', 15, 'Rescatada, tímida al principio y luego un amor.')),
    usuario(14, 'Lucas Torres', 'Talca', perro('Pancho', 'Mestizo', 'Macho', 60, 'Quiltro sabio del barrio, conoce todas las plazas.')),
    usuario(15, 'Martina Araya', 'Viña del Mar', perro('Frida', 'Schnauzer', 'Hembra', 34, 'Elegante, no le gusta mojarse las patas.')),
  ],
  paseadores: [
    { usuario: 3, zona: 'Viña del Mar, sector Reñaca', duracion: 60, descripcion: 'Paseos por la costanera y plazas. Experiencia con perros de energía alta.', condiciones: 'Máximo 3 perros por paseo. Correa y collar obligatorios.', disponibilidad: 'Lunes a viernes de 8:00 a 12:00' },
    { usuario: 6, zona: 'Santiago, Providencia y Ñuñoa', duracion: 30, descripcion: 'Paseos cortos para perros de departamento. Envío fotos durante el paseo.', condiciones: 'Perros con vacunas al día. Pago al finalizar.', disponibilidad: 'Todos los días de 18:00 a 21:00' },
    { usuario: 8, zona: 'Temuco centro', duracion: 90, descripcion: 'Salidas largas al cerro Ñielol para perros activos.', condiciones: 'Solo perros sociables. Llevar agua.', disponibilidad: 'Sábados y domingos de 9:00 a 14:00' },
    { usuario: 11, zona: 'Puerto Montt, costanera', duracion: 60, descripcion: 'Paseadora con curso de primeros auxilios caninos.', condiciones: 'Cancelaciones con 12 horas de aviso.', disponibilidad: 'Martes a sábado de 10:00 a 17:00' },
    { usuario: 14, zona: 'Talca, Alameda', duracion: 120, descripcion: 'Paseos de grupo pequeño y juego en parque cerrado.', condiciones: 'Máximo 2 perros grandes por grupo.', disponibilidad: 'Lunes, miércoles y viernes de 15:00 a 19:00' },
  ],
  reservas: [
    { cliente: 15, paseador: 3, dias: 2, hora: 9, zona: 'Entrada del Jardín Botánico', nota: 'Frida tira un poco de la correa.', estado: 'aceptada' },
    { cliente: 1, paseador: 6, dias: 1, hora: 19, zona: 'Plaza Ñuñoa', nota: 'Luna es amistosa con todos.', estado: 'aceptada' },
    { cliente: 9, paseador: 6, dias: 3, hora: 18, zona: 'Parque Bustamante', nota: 'Lola se cansa rápido, paseo tranquilo por favor.', estado: 'solicitada' },
    { cliente: 13, paseador: 6, dias: 4, hora: 20, zona: 'Parque Inés de Suárez', nota: 'Canela es tímida con hombres.', estado: 'rechazada' },
    { cliente: 7, paseador: 8, dias: 6, hora: 10, zona: 'Acceso cerro Ñielol', nota: '', estado: 'solicitada' },
    { cliente: 12, paseador: 11, dias: 5, hora: 11, zona: 'Muelle Cal y Canto', nota: 'Zeus no se acerca al agua.', estado: 'aceptada' },
    { cliente: 10, paseador: 14, dias: 3, hora: 15, zona: 'Alameda con 4 Oriente', nota: 'Simón ama a otros perros.', estado: 'solicitada' },
  ],
  avisos: [
    { usuario: 5, tipo: 'perdido', nombre: 'Copito', raza: 'Poodle', zona: 'Concepción', lugar: 'Laguna Las Tres Pascualas', descripcion: 'Blanco, collar rojo con placa. Se asustó con fuegos artificiales.', horasAtras: 20, chip: 'si', chipUltimos: '4821' },
    { usuario: 2, tipo: 'perdido', nombre: 'Tobías', raza: 'Mestizo', zona: 'Santiago', lugar: 'Parque O\'Higgins, sector laguna', descripcion: 'Café con mancha blanca en el pecho, mediano. Responde a su nombre.', horasAtras: 48, chip: 'no' },
    { usuario: 13, tipo: 'encontrado', nombre: '', raza: 'Cocker Spaniel', zona: 'Santiago', lugar: 'Metro Irarrázaval', descripcion: 'Hembra dorada, muy dócil, sin collar. Está a salvo en mi casa.', horasAtras: 6, chip: 'desconocido' },
    { usuario: 4, tipo: 'perdido', nombre: 'Princesa', raza: 'Chihuahua', zona: 'Valparaíso', lugar: 'Cerro Alegre, Paseo Gervasoni', descripcion: 'Pequeña, color crema, chaleco rosado. Es muy asustadiza.', horasAtras: 72, chip: 'si', chipUltimos: '0937' },
    { usuario: 11, tipo: 'encontrado', nombre: '', raza: 'Husky Siberiano', zona: 'Puerto Montt', lugar: 'Costanera frente a Mall Paseo Costanera', descripcion: 'Macho de ojos azules, collar negro sin placa. Muy amistoso.', horasAtras: 3, chip: 'desconocido' },
  ],
  muro: [
    { usuario: 1, texto: '¿Alguien conoce una peluquería canina buena en Ñuñoa? Luna necesita un corte urgente 🐶' },
    { usuario: 7, texto: 'Kira aprendió a cerrar la puerta del refri. No sé si estar orgullosa o preocupada.' },
    { usuario: 14, texto: 'Recordatorio: este fin de semana hay operativo de vacunación gratuita en la Alameda de Talca.' },
    { usuario: 9, texto: 'Primera vez que Lola juega con otro bulldog en la plaza. ¡Fue amor a primera vista!' },
    { usuario: 3, texto: 'Tengo cupos para paseos matinales en Reñaca esta semana, escríbanme por chat.' },
    { usuario: 12, texto: '¿Qué alimento recomiendan para un pastor alemán de 4 años con piel sensible?' },
    { usuario: 5, texto: 'Por favor compartan el aviso de Copito, se perdió anoche cerca de la laguna 🙏' },
    { usuario: 15, texto: 'Frida se negó a salir porque estaba lloviendo. Diva total.' },
    { usuario: 6, texto: 'Tip de paseador: lleven siempre bolsas extra y agua, aunque el paseo sea corto.' },
    { usuario: 10, texto: 'Simón cumplió 2 años y le hicimos torta de zapallo. ¡Le encantó!' },
  ],
  eventos: [
    { autor: 1, titulo: 'Encuentro de Golden Retrievers', descripcion: 'Juegos, fotos y convivencia para goldens y sus familias.', lugar: 'Parque Bicentenario', zona: 'Vitacura', dias: 9, hora: 11, duracion: 120, cupos: 20, tipo: 'evento', inscritos: [2, 9, 13, 6], mensajes: [{ usuario: 1, texto: '¡Bienvenidos! Lleven agua y premios.' }, { usuario: 2, texto: 'Rocco ya está ansioso, ahí estaremos.' }] },
    { autor: 8, titulo: 'Paseo grupal al cerro Ñielol', descripcion: 'Caminata de dificultad media, perros con correa.', lugar: 'Cerro Ñielol', zona: 'Temuco', dias: 7, hora: 9, duracion: 180, cupos: 10, tipo: 'paseo', inscritos: [7, 12], mensajes: [{ usuario: 8, texto: 'Nos juntamos en el acceso principal 8:45.' }] },
    { autor: 15, titulo: 'Charla: primeros auxilios caninos', descripcion: 'Qué hacer ante golpes de calor, cortes e intoxicaciones.', lugar: 'Centro comunitario Recreo', zona: 'Viña del Mar', dias: 12, hora: 18, duracion: 90, cupos: 30, tipo: 'evento', inscritos: [3, 4, 11, 5, 10], mensajes: [] },
  ],
  chats: [
    { entre: [1, 2], mensajes: [{ de: 0, texto: 'Hola Matías, vi a Rocco en Cruces, ¿se juntan a jugar?' }, { de: 1, texto: '¡Hola Camila! Claro, ¿el sábado en el Parque Bicentenario?' }, { de: 0, texto: 'Perfecto, ahí nos vemos 🐾' }] },
    { entre: [9, 10], mensajes: [{ de: 0, texto: '¿Simón es tranquilo con otros frenchies?' }, { de: 1, texto: 'Muy tranquilo, le encanta jugar. ¿Coordinamos?' }] },
    { entre: [5, 13], mensajes: [{ de: 1, texto: 'Hola, vi tu aviso de Copito. Encontré un cocker, no es él, pero estaré atenta.' }, { de: 0, texto: 'Gracias Isidora, cualquier cosa me avisas 🙏' }] },
    { entre: [15, 3], mensajes: [{ de: 0, texto: 'Hola, ¿confirmamos el paseo del jueves?' }, { de: 1, texto: 'Sí, nos vemos en la entrada del Jardín Botánico.' }] },
    { entre: [7, 8], mensajes: [{ de: 0, texto: '¿Max hace agility? Kira está empezando.' }, { de: 1, texto: 'Sí, entrenamos los domingos, ¡súmense!' }] },
  ],
};
