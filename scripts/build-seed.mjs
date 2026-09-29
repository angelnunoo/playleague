import { writeFileSync } from 'node:fs'

const quiz = {
  futbol: [
    ['easy', '¿En qué año ganó España su primer Mundial?', ['2006', '2010', '2014', '2018'], 1],
    ['easy', '¿Cuántos jugadores tiene un equipo de fútbol en el campo?', ['9', '10', '11', '12'], 2],
    ['normal', '¿Qué selección ganó el Mundial de 2022?', ['Francia', 'Argentina', 'Brasil', 'Croacia'], 1],
    ['normal', '¿En qué club debutó Lionel Messi como profesional?', ['River Plate', 'Newell\'s', 'Barcelona', 'PSG'], 2],
    ['hard', '¿Quién marcó el gol de la final del Mundial 2010?', ['Villa', 'Iniesta', 'Xavi', 'Puyol'], 1],
    ['expert', '¿Cuántos Balones de Oro tiene Alfredo Di Stéfano?', ['1', '2', '3', '4'], 1],
  ],
  videojuegos: [
    ['easy', '¿De qué color es el fontanero más famoso de Nintendo?', ['Verde', 'Rojo', 'Azul', 'Amarillo'], 1],
    ['easy', '¿Cómo se llama el erizo azul de Sega?', ['Crash', 'Sonic', 'Spyro', 'Knuckles'], 1],
    ['normal', '¿Qué estudio creó The Legend of Zelda?', ['Rare', 'Nintendo', 'Capcom', 'Sega'], 1],
    ['normal', '¿En qué juego aparece el personaje Kratos?', ['God of War', 'Halo', 'Doom', 'Gears'], 0],
    ['hard', '¿Cuál fue la primera consola de Sony?', ['PlayStation 2', 'PlayStation', 'PSP', 'PS One'], 1],
    ['expert', '¿En qué año salió el primer Super Mario Bros.?', ['1983', '1985', '1987', '1990'], 1],
  ],
  cine: [
    ['easy', '¿Cómo se llama el mago de Harry Potter?', ['Harry', 'Ron', 'Dumbledore', 'Snape'], 0],
    ['easy', '¿Qué película tiene un barco llamado Titanic?', ['Titanic', 'Poseidón', 'Waterworld', 'Moana'], 0],
    ['normal', '¿Quién dirigió El padrino?', ['Scorsese', 'Coppola', 'Spielberg', 'Tarantino'], 1],
    ['normal', '¿Cómo se llama el león de El rey león?', ['Simba', 'Mufasa', 'Nala', 'Timón'], 0],
    ['hard', '¿Qué película ganó el Oscar a mejor película en 2020?', ['1917', 'Parásitos', 'Joker', 'Ford v Ferrari'], 1],
    ['expert', '¿Quién interpretó a Tony Montana en Scarface?', ['Pacino', 'De Niro', 'Pesci', 'Liotta'], 0],
  ],
  musica: [
    ['easy', '¿Cuántas cuerdas tiene una guitarra española clásica?', ['4', '5', '6', '7'], 2],
    ['easy', '¿Qué banda cantaba Bohemian Rhapsody?', ['The Beatles', 'Queen', 'U2', 'ABBA'], 1],
    ['normal', '¿De qué país es Rosalía?', ['México', 'Argentina', 'España', 'Colombia'], 2],
    ['normal', '¿Qué instrumento toca principalmente un DJ?', ['Batería', 'Mesa de mezclas', 'Violín', 'Arpa'], 1],
    ['hard', '¿Cuántas sinfonías compuso Beethoven?', ['5', '7', '9', '12'], 2],
    ['expert', '¿En qué año se publicó el álbum Thriller de Michael Jackson?', ['1979', '1982', '1987', '1991'], 1],
  ],
  geografia: [
    ['easy', '¿Cuál es la capital de Francia?', ['Lyon', 'París', 'Marsella', 'Niza'], 1],
    ['easy', '¿En qué continente está Egipto?', ['Asia', 'Europa', 'África', 'América'], 2],
    ['normal', '¿Cuál es el río más largo del mundo?', ['Nilo', 'Amazonas', 'Misisipi', 'Yangtsé'], 1],
    ['normal', '¿Qué país tiene forma de bota?', ['España', 'Grecia', 'Italia', 'Portugal'], 2],
    ['hard', '¿Cuál es la capital de Australia?', ['Sídney', 'Melbourne', 'Canberra', 'Perth'], 2],
    ['expert', '¿Qué país tiene más islas?', ['Indonesia', 'Filipinas', 'Suecia', 'Japón'], 2],
  ],
  historia: [
    ['easy', '¿Quién descubrió América en 1492?', ['Magallanes', 'Colón', 'Elcano', 'Pizarro'], 1],
    ['easy', '¿En qué país empezó la Revolución francesa?', ['Italia', 'Francia', 'Inglaterra', 'Alemania'], 1],
    ['normal', '¿En qué año cayó el muro de Berlín?', ['1985', '1989', '1991', '1995'], 1],
    ['normal', '¿Quién fue el primer presidente de Estados Unidos?', ['Lincoln', 'Washington', 'Jefferson', 'Adams'], 1],
    ['hard', '¿Qué civilización construyó Machu Picchu?', ['Azteca', 'Maya', 'Inca', 'Olmeca'], 2],
    ['expert', '¿En qué año terminó la Guerra Civil española?', ['1936', '1939', '1945', '1975'], 1],
  ],
  ciencia: [
    ['easy', '¿Qué planeta es el más cercano al Sol?', ['Venus', 'Mercurio', 'Marte', 'Tierra'], 1],
    ['easy', '¿El agua hierve a cuántos grados Celsius al nivel del mar?', ['90', '100', '110', '120'], 1],
    ['normal', '¿Qué gas respiramos principalmente del aire?', ['Oxígeno', 'Nitrógeno', 'CO2', 'Hidrógeno'], 1],
    ['normal', '¿Quién formuló la teoría de la relatividad?', ['Newton', 'Einstein', 'Galileo', 'Hawking'], 1],
    ['hard', '¿Cuál es el símbolo químico del oro?', ['Ag', 'Au', 'Fe', 'Pb'], 1],
    ['expert', '¿Cuántos huesos tiene un adulto humano, aproximadamente?', ['106', '206', '306', '156'], 1],
  ],
  cultura: [
    ['easy', '¿Cuántos días tiene un año normal?', ['364', '365', '366', '360'], 1],
    ['easy', '¿De qué color es una esmeralda?', ['Rojo', 'Azul', 'Verde', 'Amarillo'], 2],
    ['normal', '¿Quién pintó La Gioconda?', ['Velázquez', 'Da Vinci', 'Picasso', 'Goya'], 1],
    ['normal', '¿Cuántos lados tiene un hexágono?', ['5', '6', '7', '8'], 1],
    ['hard', '¿En qué ciudad está el Coliseo?', ['Atenas', 'Roma', 'Estambul', 'El Cairo'], 1],
    ['expert', '¿Qué escritor creó a Sherlock Holmes?', ['Poe', 'Christie', 'Doyle', 'Hammett'], 2],
  ],
  tecnologia: [
    ['easy', '¿Qué significa WWW?', ['World Wide Web', 'Wireless Web World', 'Web World Wide', 'Wide World Web'], 0],
    ['easy', '¿Qué empresa fabrica el iPhone?', ['Samsung', 'Apple', 'Google', 'Sony'], 1],
    ['normal', '¿Qué lenguaje usa principalmente una página web en el navegador?', ['Python', 'HTML', 'SQL', 'C'], 1],
    ['normal', '¿Cómo se llama el asistente de voz de Apple?', ['Alexa', 'Siri', 'Cortana', 'Gemini'], 1],
    ['hard', '¿Qué significa CPU?', ['Central Processing Unit', 'Computer Personal Unit', 'Core Power Unit', 'Control Program Utility'], 0],
    ['expert', '¿En qué año se fundó Google?', ['1996', '1998', '2001', '2004'], 1],
  ],
  marvel: [
    ['easy', '¿Cómo se llama el superhéroe de la araña?', ['Batman', 'Spider-Man', 'Ant-Man', 'Iron Man'], 1],
    ['easy', '¿De qué color es el traje clásico de Hulk?', ['Rojo', 'Verde', 'Azul', 'Negro'], 1],
    ['normal', '¿Cómo se llama el martillo de Thor?', ['Stormbreaker', 'Mjolnir', 'Gungnir', 'Hofund'], 1],
    ['normal', '¿Qué metal hay en el escudo del Capitán América?', ['Adamantium', 'Vibranium', 'Acero', 'Titanio'], 1],
    ['hard', '¿Quién interpreta a Iron Man en el UCM?', ['Chris Evans', 'Robert Downey Jr.', 'Chris Hemsworth', 'Mark Ruffalo'], 1],
    ['expert', '¿Cómo se llama la gema del tiempo en el infinito?', ['Alma', 'Tiempo', 'Espacio', 'Mente'], 1],
  ],
  f1: [
    ['easy', '¿Cuántas ruedas tiene un Fórmula 1?', ['3', '4', '6', '2'], 1],
    ['easy', '¿De qué color es tradicionalmente Ferrari?', ['Azul', 'Rojo', 'Verde', 'Amarillo'], 1],
    ['normal', '¿Qué piloto español ganó dos mundiales con Renault y Ferrari?', ['Alonso', 'Sainz', 'De la Rosa', 'Gené'], 0],
    ['normal', '¿En qué país se corre el Gran Premio de Mónaco?', ['Francia', 'Mónaco', 'Italia', 'España'], 1],
    ['hard', '¿Cuántos mundiales tiene Lewis Hamilton hasta 2024?', ['5', '6', '7', '8'], 2],
    ['expert', '¿Qué escudería debutó con el motor Mercedes de fábrica en 2010?', ['Red Bull', 'Mercedes', 'McLaren', 'Williams'], 1],
  ],
  deportes: [
    ['easy', '¿En qué deporte se usa una canasta?', ['Fútbol', 'Baloncesto', 'Tenis', 'Golf'], 1],
    ['easy', '¿Cuántos sets se necesitan para ganar un partido de tenis al mejor de 3?', ['1', '2', '3', '4'], 1],
    ['normal', '¿Cada cuántos años son los Juegos Olímpicos de verano?', ['2', '3', '4', '5'], 2],
    ['normal', '¿En qué deporte destaca Rafael Nadal?', ['Golf', 'Tenis', 'Pádel', 'Squash'], 1],
    ['hard', '¿Cuántos jugadores hay en una pista de baloncesto por equipo?', ['4', '5', '6', '7'], 1],
    ['expert', '¿En qué ciudad se celebraron los Juegos de 1992?', ['Madrid', 'Barcelona', 'Sevilla', 'Valencia'], 1],
  ],
  espana: [
    ['easy', '¿Cuál es la capital de España?', ['Barcelona', 'Madrid', 'Sevilla', 'Valencia'], 1],
    ['easy', '¿En qué comunidad está la Alhambra?', ['Andalucía', 'Galicia', 'Aragón', 'Murcia'], 0],
    ['normal', '¿Qué mar baña Valencia?', ['Cantábrico', 'Mediterráneo', 'Atlántico', 'Negro'], 1],
    ['normal', '¿Cuántas comunidades autónomas tiene España?', ['15', '17', '19', '21'], 1],
    ['hard', '¿Cuál es el pico más alto de la península?', ['Teide', 'Mulhacén', 'Aneto', 'Veleta'], 1],
    ['expert', '¿En qué año se aprobó la Constitución española actual?', ['1975', '1978', '1982', '1986'], 1],
  ],
  internet: [
    ['easy', '¿Qué red social usa fotos cuadradas y stories?', ['Instagram', 'LinkedIn', 'Reddit', 'Wikipedia'], 0],
    ['easy', '¿Cómo se llama el pájaro de Twitter, ahora X?', ['Piolín', 'El pájaro azul', 'Tweety', 'Duolingo'], 1],
    ['normal', '¿Qué significa LOL?', ['Lots of love', 'Laughing out loud', 'Lots of luck', 'Lost online'], 1],
    ['normal', '¿Qué plataforma es famosa por vídeos cortos verticales?', ['TikTok', 'Spotify', 'Twitch', 'Netflix'], 0],
    ['hard', '¿Qué significa meme, en origen?', ['Un virus', 'Una idea que se copia', 'Un filtro', 'Un emoji'], 1],
    ['expert', '¿En qué año se lanzó YouTube?', ['2003', '2005', '2007', '2010'], 1],
  ],
}

const impostor = {
  comida: [['Pizza', '🍕'], ['Hamburguesa', '🍔'], ['Sushi', '🍣'], ['Paella', '🥘'], ['Tortilla', '🍳'], ['Helado', '🍦'], ['Croqueta', '🟤'], ['Gazpacho', '🍅'], ['Churro', '🍩'], ['Taco', '🌮']],
  animales: [['Perro', '🐶'], ['Gato', '🐱'], ['León', '🦁'], ['Delfín', '🐬'], ['Pingüino', '🐧'], ['Elefante', '🐘'], ['Águila', '🦅'], ['Tiburón', '🦈'], ['Jirafa', '🦒'], ['Koala', '🐨']],
  objetos: [['Paraguas', '☂️'], ['Reloj', '⌚'], ['Mochila', '🎒'], ['Lámpara', '💡'], ['Martillo', '🔨'], ['Espejo', '🪞'], ['Llave', '🔑'], ['Cepillo', '🪥'], ['Tijeras', '✂️'], ['Almohada', '🛏️']],
  lugares: [['Playa', '🏖️'], ['Hospital', '🏥'], ['Aeropuerto', '✈️'], ['Biblioteca', '📚'], ['Montaña', '⛰️'], ['Supermercado', '🛒'], ['Castillo', '🏰'], ['Estadio', '🏟️'], ['Museo', '🖼️'], ['Camping', '⛺']],
  profesiones: [['Médico', '🩺'], ['Bombero', '🚒'], ['Cocinero', '👨‍🍳'], ['Piloto', '🧑‍✈️'], ['Profesor', '👩‍🏫'], ['Policía', '👮'], ['Arquitecto', '📐'], ['Periodista', '📰'], ['Mecánico', '🔧'], ['Juez', '⚖️']],
  famosos: [['Shakira', '🎤'], ['Messi', '⚽'], ['Cervantes', '📖'], ['Picasso', '🎨'], ['Beyoncé', '👑'], ['Einstein', '🧠'], ['Mozart', '🎼'], ['Cleopatra', '🏺'], ['Chaplin', '🎩'], ['Frida Kahlo', '🌺']],
  deportes: [['Tenis', '🎾'], ['Baloncesto', '🏀'], ['Natación', '🏊'], ['Ciclismo', '🚴'], ['Boxeo', '🥊'], ['Golf', '⛳'], ['Esquí', '⛷️'], ['Voleibol', '🏐'], ['Surf', '🏄'], ['Ajedrez', '♟️']],
  marcas: [['Nike', '✔️'], ['Apple', '🍎'], ['Coca-Cola', '🥤'], ['IKEA', '🪑'], ['Netflix', '🎬'], ['Zara', '👗'], ['Lego', '🧱'], ['Nintendo', '🎮'], ['Adidas', '👟'], ['Toyota', '🚗']],
}

const taboo = {
  comida: [
    ['Manzana', '🍎', ['Fruta', 'Roja', 'Árbol', 'Comer', 'Verde']],
    ['Pizza', '🍕', ['Queso', 'Tomate', 'Italia', 'Horno', 'Redonda']],
    ['Helado', '🍦', ['Frío', 'Dulce', 'Cucurucho', 'Verano', 'Chocolate']],
    ['Paella', '🥘', ['Arroz', 'Valencia', 'Marisco', 'Azafrán', 'Sartén']],
  ],
  animales: [
    ['Elefante', '🐘', ['Grande', 'Trompa', 'África', 'Gris', 'Colmillos']],
    ['Pingüino', '🐧', ['Hielo', 'Ave', 'Frío', 'Blanco', 'Nadar']],
    ['León', '🦁', ['Rey', 'Melena', 'Rugir', 'Selva', 'Felino']],
    ['Delfín', '🐬', ['Mar', 'Inteligente', 'Saltar', 'Gris', 'Mamífero']],
  ],
  objetos: [
    ['Paraguas', '☂️', ['Lluvia', 'Abrir', 'Mojar', 'Mango', 'Gotas']],
    ['Reloj', '⌚', ['Hora', 'Tiempo', 'Muñeca', 'Agujas', 'Minutos']],
    ['Espejo', '🪞', ['Reflejo', 'Cara', 'Cristal', 'Baño', 'Verse']],
    ['Llave', '🔑', ['Puerta', 'Cerrar', 'Cerradura', 'Metal', 'Abrir']],
  ],
  lugares: [
    ['Playa', '🏖️', ['Mar', 'Arena', 'Verano', 'Toalla', 'Olas']],
    ['Hospital', '🏥', ['Médico', 'Enfermo', 'Cama', 'Urgencias', 'Bata']],
    ['Aeropuerto', '✈️', ['Avión', 'Maleta', 'Volar', 'Pasaporte', 'Pista']],
    ['Biblioteca', '📚', ['Libros', 'Silencio', 'Leer', 'Estudiar', 'Estantería']],
  ],
  deportes: [
    ['Tenis', '🎾', ['Raqueta', 'Pelota', 'Red', 'Set', 'Pista']],
    ['Baloncesto', '🏀', ['Canasta', 'Pelota', 'Aro', 'Equipo', 'Botar']],
    ['Natación', '🏊', ['Agua', 'Piscina', 'Nadar', 'Bañador', 'Brazada']],
    ['Ciclismo', '🚴', ['Bici', 'Rueda', 'Pedal', 'Casco', 'Carrera']],
  ],
  famosos: [
    ['Messi', '⚽', ['Fútbol', 'Argentina', 'Barcelona', 'Gol', 'Balón']],
    ['Shakira', '🎤', ['Cantar', 'Colombia', 'Cadera', 'Música', 'Loba']],
    ['Picasso', '🎨', ['Pintor', 'Cuadro', 'Cubismo', 'Málaga', 'Arte']],
    ['Einstein', '🧠', ['Física', 'Relatividad', 'Genio', 'Pelo', 'Ciencia']],
  ],
  casa: [
    ['Nevera', '🧊', ['Frío', 'Comida', 'Cocina', 'Hielo', 'Puerta']],
    ['Sofá', '🛋️', ['Sentarse', 'Salón', 'Cojín', 'Tele', 'Descansar']],
    ['Ducha', '🚿', ['Agua', 'Baño', 'Jabón', 'Mojar', 'Grifo']],
    ['Cama', '🛏️', ['Dormir', 'Almohada', 'Sábana', 'Noche', 'Colchón']],
  ],
  ciudad: [
    ['Semáforo', '🚦', ['Rojo', 'Verde', 'Tráfico', 'Coche', 'Parar']],
    ['Metro', '🚇', ['Tren', 'Subterráneo', 'Andén', 'Billete', 'Túnel']],
    ['Taxi', '🚕', ['Coche', 'Amarillo', 'Conductor', 'Pago', 'Calle']],
    ['Parque', '🌳', ['Árboles', 'Banco', 'Verde', 'Pasear', 'Niños']],
  ],
}

const quick = {
  paises: ['Nombra 3 países de Europa.', 'Nombra 3 países de América.', 'Nombra 3 países que empiecen por A.', 'Nombra 3 islas que sean países.', 'Nombra 3 países de África.', 'Nombra 3 países vecinos de España.'],
  futbolistas: ['Nombra 3 futbolistas españoles.', 'Nombra 3 porteros famosos.', 'Nombra 3 jugadores del Real Madrid.', 'Nombra 3 jugadoras de fútbol.', 'Nombra 3 balones de oro.', 'Nombra 3 equipos de la Premier.'],
  coches: ['Nombra 3 marcas de coches.', 'Nombra 3 marcas alemanas.', 'Nombra 3 coches deportivos.', 'Nombra 3 marcas japonesas.', 'Nombra 3 marcas francesas.', 'Nombra 3 SUV famosos.'],
  videojuegos: ['Nombra 3 videojuegos de Mario.', 'Nombra 3 sagas de disparos.', 'Nombra 3 juegos de fútbol.', 'Nombra 3 consolas.', 'Nombra 3 personajes de Pokémon.', 'Nombra 3 juegos de móvil.'],
  marvel: ['Nombra 3 vengadores.', 'Nombra 3 villanos de Marvel.', 'Nombra 3 películas de Marvel.', 'Nombra 3 superhéroes que vuelan.', 'Nombra 3 actores del UCM.', 'Nombra 3 gemas del infinito.'],
  animales: ['Nombra 3 animales marinos.', 'Nombra 3 animales de granja.', 'Nombra 3 aves.', 'Nombra 3 felinos.', 'Nombra 3 animales africanos.', 'Nombra 3 insectos.'],
  ciudades: ['Nombra 3 ciudades de Andalucía.', 'Nombra 3 capitales de provincia.', 'Nombra 3 ciudades costeras.', 'Nombra 3 ciudades del norte.', 'Nombra 3 ciudades con playa.', 'Nombra 3 ciudades que no sean Madrid ni Barcelona.'],
  comidas: ['Nombra 3 postres.', 'Nombra 3 platos con arroz.', 'Nombra 3 frutas.', 'Nombra 3 comidas italianas.', 'Nombra 3 tapas.', 'Nombra 3 desayunos.'],
  profesiones: ['Nombra 3 profesiones de hospital.', 'Nombra 3 oficios manuales.', 'Nombra 3 trabajos de un colegio.', 'Nombra 3 profesiones artísticas.', 'Nombra 3 trabajos al aire libre.', 'Nombra 3 profesiones con uniforme.'],
  musica: ['Nombra 3 instrumentos.', 'Nombra 3 cantantes españoles.', 'Nombra 3 bandas de rock.', 'Nombra 3 géneros musicales.', 'Nombra 3 canciones de los 2000.', 'Nombra 3 festivales.'],
}

const sql = []
const q = (value) => `'${String(value).replaceAll("'", "''")}'`

for (const [slug, rows] of Object.entries(quiz)) {
  for (const [difficulty, prompt, answers, correct] of rows) {
    const id = `gen_random_uuid()`
    sql.push(`with c as (select id from public.quiz_categories where slug = ${q(slug)}),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, ${q(difficulty)}, ${q(prompt)} from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = ${correct}, answer.ord
from ins
cross join (values ${answers.map((text, index) => `(${q(text)}, ${index})`).join(', ')}) as answer(text, ord);`)
  }
}

for (const [slug, words] of Object.entries(impostor)) {
  for (const [word, emoji] of words) {
    const difficulty = ['easy', 'normal', 'hard'][word.length % 3]
    sql.push(`insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, ${q(word)}, ${q(emoji)}, ${q(difficulty)} from public.impostor_categories where slug = ${q(slug)}
on conflict (category_id, word) do nothing;`)
  }
}

for (const [slug, cards] of Object.entries(taboo)) {
  for (const [word, emoji, forbidden] of cards) {
    sql.push(`insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, ${q(word)}, ${q(emoji)}, array[${forbidden.map(q).join(', ')}], 'normal'
from public.taboo_categories where slug = ${q(slug)}
on conflict (category_id, word) do nothing;`)
  }
}

for (const [slug, prompts] of Object.entries(quick)) {
  prompts.forEach((prompt, index) => {
    const difficulty = ['easy', 'normal', 'hard'][index % 3]
    sql.push(`insert into public.quick_questions (category_id, prompt, difficulty)
select id, ${q(prompt)}, ${q(difficulty)} from public.quick_categories where slug = ${q(slug)}
on conflict (category_id, prompt) do nothing;`)
  })
}

writeFileSync(new URL('../supabase/seed.sql', import.meta.url), sql.join('\n'), 'utf8')
console.log(`wrote ${sql.length} statements`)
