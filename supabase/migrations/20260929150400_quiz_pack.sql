insert into public.quiz_categories (slug, name, emoji, sort)
values ('superheroes', 'Superhéroes', '🛡️', 105)
on conflict (slug) do nothing;

create or replace function private.add_quiz(
  p_slug text,
  p_difficulty text,
  p_prompt text,
  p_correct text,
  p_wrong text[]
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_cat uuid;
  i integer;
begin
  select id into v_cat from public.quiz_categories where slug = p_slug;
  if v_cat is null then
    raise exception 'No existe la categoría %', p_slug;
  end if;
  insert into public.quiz_questions (category_id, difficulty, prompt)
  values (v_cat, p_difficulty, p_prompt)
  on conflict (category_id, prompt) do nothing
  returning id into v_id;
  if v_id is null then
    return;
  end if;
  insert into public.quiz_answers (question_id, text, is_correct, sort_order)
  values (v_id, p_correct, true, 0);
  for i in 1 .. coalesce(array_length(p_wrong, 1), 0) loop
    insert into public.quiz_answers (question_id, text, is_correct, sort_order)
    values (v_id, p_wrong[i], false, i);
  end loop;
end;
$$;

select private.add_quiz('superheroes', 'easy', '¿Cómo se llama el martillo de Thor en el UCM?', 'Mjolnir', array['Stormbreaker', 'Gungnir', 'Hofund']);
select private.add_quiz('superheroes', 'easy', '¿Quién interpreta a Tony Stark en el UCM?', 'Robert Downey Jr.', array['Chris Evans', 'Chris Hemsworth', 'Mark Ruffalo']);
select private.add_quiz('superheroes', 'easy', '¿De qué metal está hecho el escudo del Capitán América?', 'Vibranium', array['Adamantium', 'Uru', 'Acero']);
select private.add_quiz('superheroes', 'easy', '¿Cómo se llama el país de Black Panther?', 'Wakanda', array['Latveria', 'Genosha', 'Sokovia']);
select private.add_quiz('superheroes', 'easy', '¿Quién es el padre de Thor?', 'Odín', array['Loki', 'Laufey', 'Heimdall']);
select private.add_quiz('superheroes', 'easy', '¿Cuántas Gemas del Infinito hay?', '6', array['5', '7', '8']);
select private.add_quiz('superheroes', 'easy', '¿Quién consigue las seis Gemas del Infinito en Infinity War?', 'Thanos', array['Loki', 'Ultrón', 'Kang']);
select private.add_quiz('superheroes', 'easy', '¿Qué frase repite Groot casi siempre?', 'Yo soy Groot', array['Yo soy Rocket', 'Somos Guardianes', 'Yo soy árbol']);
select private.add_quiz('superheroes', 'easy', '¿Cómo se llama el mapache de los Guardianes de la Galaxia?', 'Rocket', array['Groot', 'Drax', 'Mantis']);
select private.add_quiz('superheroes', 'easy', '¿Quién es Star-Lord?', 'Peter Quill', array['Peter Parker', 'Sam Wilson', 'Scott Lang']);
select private.add_quiz('superheroes', 'easy', '¿En qué año se estrenó Iron Man, la primera película del UCM?', '2008', array['2006', '2010', '2012']);
select private.add_quiz('superheroes', 'easy', '¿Quién interpreta al Capitán América?', 'Chris Evans', array['Chris Pratt', 'Chris Hemsworth', 'Sebastian Stan']);
select private.add_quiz('superheroes', 'easy', '¿Quién interpreta a Thor?', 'Chris Hemsworth', array['Chris Evans', 'Tom Hiddleston', 'Idris Elba']);
select private.add_quiz('superheroes', 'easy', '¿Quién interpreta a Loki?', 'Tom Hiddleston', array['Tom Holland', 'Benedict Cumberbatch', 'Paul Bettany']);
select private.add_quiz('superheroes', 'easy', '¿Cómo se llama la agente que interpreta Scarlett Johansson?', 'Natasha Romanoff', array['Wanda Maximoff', 'Peggy Carter', 'Carol Danvers']);
select private.add_quiz('superheroes', 'easy', '¿En qué ciudad invaden los Chitauri en la primera película de Los Vengadores?', 'Nueva York', array['Washington', 'Londres', 'Sokovia']);
select private.add_quiz('superheroes', 'normal', '¿Qué gema lleva Visión en la frente?', 'Mente', array['Tiempo', 'Espacio', 'Realidad']);
select private.add_quiz('superheroes', 'normal', '¿Quién chasquea los dedos en Endgame para traer de vuelta a los desaparecidos?', 'Bruce Banner', array['Tony Stark', 'Thor', 'Doctor Strange']);
select private.add_quiz('superheroes', 'normal', '¿Cómo se llama la hija de Thanos que se une a los Guardianes?', 'Gamora', array['Nebula', 'Proxima', 'Mantis']);
select private.add_quiz('superheroes', 'normal', '¿Quién interpreta a la Bruja Escarlata?', 'Elizabeth Olsen', array['Scarlett Johansson', 'Brie Larson', 'Zoe Saldaña']);
select private.add_quiz('superheroes', 'normal', '¿Cómo se llama el hermano de Wanda en La era de Ultrón?', 'Pietro', array['Visión', 'Clint', 'Sam']);
select private.add_quiz('superheroes', 'normal', '¿Qué grupo secuestra a Tony al principio de Iron Man?', 'Los Diez Anillos', array['Hydra', 'A.I.M.', 'La Mano']);
select private.add_quiz('superheroes', 'normal', '¿Cómo se llama el rey de Wakanda que interpreta Chadwick Boseman?', 'T''Challa', array['T''Chaka', 'M''Baku', 'N''Jadaka']);
select private.add_quiz('superheroes', 'normal', '¿Cómo se llama la hermana de T''Challa?', 'Shuri', array['Nakia', 'Okoye', 'Ramonda']);
select private.add_quiz('superheroes', 'normal', '¿Qué gema guarda el Ojo de Agamotto?', 'Tiempo', array['Mente', 'Alma', 'Poder']);
select private.add_quiz('superheroes', 'normal', '¿Quién es el padre celeste de Star-Lord?', 'Ego', array['Yondu', 'Thanos', 'El Coleccionista']);
select private.add_quiz('superheroes', 'normal', '¿Quién hereda el escudo al final de Endgame?', 'Sam Wilson', array['Bucky Barnes', 'Peter Parker', 'Scott Lang']);
select private.add_quiz('superheroes', 'normal', '¿Cómo se llama el ejército que invade Nueva York en Los Vengadores?', 'Chitauri', array['Skrulls', 'Kree', 'Outriders']);
select private.add_quiz('superheroes', 'normal', '¿Qué gema esconde el cetro de Loki en Los Vengadores?', 'Mente', array['Espacio', 'Realidad', 'Alma']);
select private.add_quiz('superheroes', 'normal', '¿Quién es el villano de Spider-Man: Lejos de casa?', 'Mysterio', array['Buitre', 'Duende Verde', 'Escorpión']);
select private.add_quiz('superheroes', 'normal', '¿Quién hace de mentor de Peter Parker en el UCM?', 'Tony Stark', array['Nick Fury', 'Happy Hogan', 'Doctor Strange']);
select private.add_quiz('superheroes', 'normal', '¿Cómo se llama el mejor amigo de Peter Parker?', 'Ned', array['Flash', 'MJ', 'Harry']);
select private.add_quiz('superheroes', 'normal', '¿Cómo se llama el Soldado de Invierno?', 'Bucky Barnes', array['Sam Wilson', 'John Walker', 'Isaiah Bradley']);
select private.add_quiz('superheroes', 'normal', '¿En qué guerra luchó Steve Rogers antes de quedar congelado?', 'Segunda Guerra Mundial', array['Guerra de Vietnam', 'Guerra de Corea', 'Primera Guerra Mundial']);
select private.add_quiz('superheroes', 'normal', '¿Qué organización se infiltra en S.H.I.E.L.D.?', 'Hydra', array['A.I.M.', 'Los Diez Anillos', 'La Mano']);
select private.add_quiz('superheroes', 'normal', '¿Quién interpreta a Capitana Marvel?', 'Brie Larson', array['Elizabeth Olsen', 'Hayley Atwell', 'Florence Pugh']);
select private.add_quiz('superheroes', 'normal', '¿Qué pueblo entrena a Carol Danvers tras el accidente?', 'Los Kree', array['Los Skrulls', 'Los Xandarianos', 'Los Soberanos']);
select private.add_quiz('superheroes', 'hard', '¿Quién se sacrifica en Vormir en Infinity War?', 'Gamora', array['Nebula', 'Natasha', 'Loki']);
select private.add_quiz('superheroes', 'hard', '¿Quién se sacrifica en Vormir en Endgame?', 'Natasha Romanoff', array['Clint Barton', 'Gamora', 'Tony Stark']);
select private.add_quiz('superheroes', 'hard', '¿En qué planeta está la Gema del Alma?', 'Vormir', array['Titan', 'Knowhere', 'Xandar']);
select private.add_quiz('superheroes', 'hard', '¿Quién pone el mango de Stormbreaker?', 'Groot', array['Rocket', 'Eitri', 'Thor']);
select private.add_quiz('superheroes', 'hard', '¿Cómo se llama la hermana de Thor en Ragnarok?', 'Hela', array['Sif', 'Valkiria', 'Frigga']);
select private.add_quiz('superheroes', 'hard', '¿En qué planeta acaba Thor al principio de Ragnarok, lleno de basura?', 'Sakaar', array['Jotunheim', 'Nidavellir', 'Contraxia']);
select private.add_quiz('superheroes', 'hard', '¿Quién provoca el Ragnarok al final de Thor: Ragnarok?', 'Surtur', array['Hela', 'Loki', 'Odín']);
select private.add_quiz('superheroes', 'hard', '¿Qué identidad usa Clint Barton como justiciero en Endgame?', 'Ronin', array['Ojo de Halcón', 'Hawkeye', 'Legolas']);
select private.add_quiz('superheroes', 'hard', '¿Cómo se llama la mujer de Ojo de Halcón?', 'Laura Barton', array['Natasha Romanoff', 'Peggy Carter', 'Maria Hill']);
select private.add_quiz('superheroes', 'hard', '¿Quién interpreta a Yelena Belova?', 'Florence Pugh', array['Scarlett Johansson', 'Rachel Weisz', 'Florence Welch']);
select private.add_quiz('superheroes', 'hard', '¿Cómo se llama el villano de Black Panther, primo de T''Challa?', 'Killmonger', array['Klaue', 'M''Baku', 'Zemo']);
select private.add_quiz('superheroes', 'hard', '¿Cómo se llama el hechicero rival de Doctor Strange en su primera película?', 'Kaecilius', array['Mordo', 'Dormammu', 'Wong']);
select private.add_quiz('superheroes', 'hard', '¿Cómo se llama la estrella donde se forjan las armas de uru?', 'Nidavellir', array['Xandar', 'Sakaar', 'Ego']);
select private.add_quiz('superheroes', 'easy', '¿Quién dice «Vengadores, reuníos» en Endgame?', 'Capitán América', array['Iron Man', 'Thor', 'Nick Fury']);
select private.add_quiz('superheroes', 'normal', '¿Cómo se llama el plan de viaje en el tiempo de Endgame?', 'Atraco al tiempo', array['Protocolo Infinity', 'Operación Ultrón', 'Iniciativa Vengadores']);
select private.add_quiz('superheroes', 'normal', '¿Qué arma nueva consigue Thor en Infinity War?', 'Stormbreaker', array['Mjolnir', 'Jarnbjorn', 'Gungnir']);
select private.add_quiz('superheroes', 'easy', '¿Cómo se llama la tía de Peter Parker?', 'May', array['Mary', 'Pepper', 'Peggy']);
select private.add_quiz('superheroes', 'normal', '¿Quién es el villano principal de Spider-Man: Homecoming?', 'El Buitre', array['Mysterio', 'El Duende', 'El Escorpión']);
select private.add_quiz('superheroes', 'hard', '¿Cómo se llama el científico que inyecta el suero a Steve Rogers?', 'Abraham Erskine', array['Howard Stark', 'Arnim Zola', 'Bruce Banner']);
select private.add_quiz('superheroes', 'normal', '¿Quién dirige S.H.I.E.L.D. y lo interpreta Samuel L. Jackson?', 'Nick Fury', array['Phil Coulson', 'Alexander Pierce', 'Maria Hill']);
select private.add_quiz('superheroes', 'easy', '¿Qué científico se convierte en Hulk?', 'Bruce Banner', array['Hank Pym', 'Stephen Strange', 'Reed Richards']);
select private.add_quiz('superheroes', 'normal', '¿Cómo se llama la nave original de los Guardianes?', 'Milano', array['Benatar', 'Quadrant', 'Sanctuary']);
select private.add_quiz('superheroes', 'hard', '¿Quién forja el Guantelete del Infinito en Nidavellir?', 'Eitri', array['Tony Stark', 'Odín', 'El Coleccionista']);
select private.add_quiz('futbol', 'easy', '¿Quién ganó el Mundial de 2022?', 'Argentina', array['Francia', 'Brasil', 'España']);
select private.add_quiz('futbol', 'easy', '¿En qué club debutó Lionel Messi como profesional?', 'Barcelona', array['PSG', 'Newell''s', 'Inter Miami']);
select private.add_quiz('futbol', 'normal', '¿Cuántos Mundiales ha ganado Brasil?', '5', array['4', '3', '6']);
select private.add_quiz('futbol', 'normal', '¿De qué país es Kylian Mbappé?', 'Francia', array['Bélgica', 'Portugal', 'España']);
select private.add_quiz('futbol', 'hard', '¿En qué estadio juega el Liverpool?', 'Anfield', array['Old Trafford', 'Stamford Bridge', 'Emirates']);
select private.add_quiz('futbol', 'easy', '¿Cuántas estrellas tiene el logo de la Champions?', '8', array['6', '5', '10']);
select private.add_quiz('futbol', 'normal', '¿Quién marcó el gol de la final del Mundial 2010?', 'Andrés Iniesta', array['David Villa', 'Fernando Torres', 'Xavi']);
select private.add_quiz('futbol', 'hard', '¿Qué selección ganó la Eurocopa de 2008 y 2012?', 'España', array['Alemania', 'Italia', 'Francia']);
select private.add_quiz('videojuegos', 'easy', '¿Cómo se llama el fontanero de Nintendo?', 'Mario', array['Luigi', 'Wario', 'Toad']);
select private.add_quiz('videojuegos', 'easy', '¿En qué juego aparece Master Chief?', 'Halo', array['Gears of War', 'Destiny', 'Call of Duty']);
select private.add_quiz('videojuegos', 'normal', '¿Cómo se llama el protagonista de The Legend of Zelda?', 'Link', array['Zelda', 'Ganondorf', 'Navi']);
select private.add_quiz('videojuegos', 'normal', '¿Qué compañía creó Minecraft?', 'Mojang', array['Epic', 'Valve', 'Ubisoft']);
select private.add_quiz('videojuegos', 'hard', '¿En qué año salió el primer Super Mario Bros.?', '1985', array['1983', '1990', '1979']);
select private.add_quiz('videojuegos', 'easy', '¿Cómo se llama el reino de Super Mario?', 'Reino Champiñón', array['Hyrule', 'Ciudad Esmeralda', 'Isla Kong']);
select private.add_quiz('videojuegos', 'normal', '¿Cómo se llama la ciudad de Grand Theft Auto V?', 'Los Santos', array['Vice City', 'Liberty City', 'San Fierro']);
select private.add_quiz('videojuegos', 'hard', '¿Qué estudio desarrolló The Witcher 3?', 'CD Projekt Red', array['BioWare', 'FromSoftware', 'Bethesda']);
select private.add_quiz('cine', 'easy', '¿Cómo se llama el mago protagonista de Harry Potter?', 'Harry Potter', array['Ron Weasley', 'Draco Malfoy', 'Neville Longbottom']);
select private.add_quiz('cine', 'easy', '¿Quién dirige Titanic y Avatar?', 'James Cameron', array['Steven Spielberg', 'Christopher Nolan', 'Ridley Scott']);
select private.add_quiz('cine', 'normal', '¿Cómo se llama el león de El rey león?', 'Simba', array['Mufasa', 'Scar', 'Nala']);
select private.add_quiz('cine', 'normal', '¿En qué película aparece la frase «Que la fuerza te acompañe»?', 'Star Wars', array['Star Trek', 'Dune', 'Avatar']);
select private.add_quiz('cine', 'hard', '¿Quién interpreta a Jack Sparrow?', 'Johnny Depp', array['Orlando Bloom', 'Brad Pitt', 'Leonardo DiCaprio']);
select private.add_quiz('cine', 'easy', '¿Cómo se llama el pez que busca a su hijo en Buscando a Nemo?', 'Marlin', array['Nemo', 'Dory', 'Gill']);
select private.add_quiz('cine', 'normal', '¿Qué juguete es el protagonista de Toy Story?', 'Woody', array['Buzz', 'Rex', 'Jessie']);
select private.add_quiz('cine', 'hard', '¿En qué año se estrenó El Padrino?', '1972', array['1969', '1975', '1980']);
select private.add_quiz('musica', 'easy', '¿De qué grupo es la canción «Bohemian Rhapsody»?', 'Queen', array['The Beatles', 'U2', 'Coldplay']);
select private.add_quiz('musica', 'easy', '¿Cómo se llama el cantante de los Rolling Stones?', 'Mick Jagger', array['Freddie Mercury', 'Bono', 'Axl Rose']);
select private.add_quiz('musica', 'normal', '¿De qué país es Bad Bunny?', 'Puerto Rico', array['Colombia', 'México', 'España']);
select private.add_quiz('musica', 'normal', '¿Cuántos miembros originales tenían The Beatles?', '4', array['3', '5', '6']);
select private.add_quiz('musica', 'hard', '¿Quién canta «Billie Jean»?', 'Michael Jackson', array['Prince', 'Stevie Wonder', 'Usher']);
select private.add_quiz('musica', 'easy', '¿Qué instrumento toca principalmente Shakira además de cantar?', 'La guitarra', array['El piano', 'La batería', 'El violín']);
select private.add_quiz('musica', 'normal', '¿Cómo se llama el álbum blanco de los Beatles, sin título en la portada?', 'The White Album', array['Abbey Road', 'Revolver', 'Let It Be']);
select private.add_quiz('musica', 'hard', '¿En qué ciudad nació Freddie Mercury?', 'Zanzíbar', array['Londres', 'Mumbai', 'Nueva York']);
select private.add_quiz('geografia', 'easy', '¿Cuál es la capital de Francia?', 'París', array['Lyon', 'Marsella', 'Niza']);
select private.add_quiz('geografia', 'easy', '¿Cuál es la capital de Portugal?', 'Lisboa', array['Oporto', 'Madrid', 'Faro']);
select private.add_quiz('geografia', 'normal', '¿En qué continente está Egipto?', 'África', array['Asia', 'Europa', 'Oceanía']);
select private.add_quiz('geografia', 'normal', '¿Cuál es la capital de Japón?', 'Tokio', array['Kioto', 'Osaka', 'Seúl']);
select private.add_quiz('geografia', 'hard', '¿Cuál es el país más pequeño del mundo?', 'Ciudad del Vaticano', array['Mónaco', 'San Marino', 'Liechtenstein']);
select private.add_quiz('geografia', 'easy', '¿Qué océano baña la costa oeste de España?', 'Atlántico', array['Mediterráneo', 'Índico', 'Pacífico']);
select private.add_quiz('geografia', 'normal', '¿Cuál es la montaña más alta del planeta?', 'Everest', array['K2', 'Kilimanjaro', 'Aconcagua']);
select private.add_quiz('geografia', 'hard', '¿Cuál es la capital de Australia?', 'Canberra', array['Sídney', 'Melbourne', 'Perth']);
select private.add_quiz('historia', 'easy', '¿En qué año llegó Colón a América?', '1492', array['1498', '1482', '1502']);
select private.add_quiz('historia', 'easy', '¿Quién fue el primer presidente de Estados Unidos?', 'George Washington', array['Abraham Lincoln', 'Thomas Jefferson', 'John Adams']);
select private.add_quiz('historia', 'normal', '¿En qué año cayó el muro de Berlín?', '1989', array['1991', '1985', '1979']);
select private.add_quiz('historia', 'normal', '¿Cómo se llamaba el barco de Cristóbal Colón más famoso, junto a la Pinta y la Niña?', 'Santa María', array['Santa Clara', 'Victoria', 'Trinidad']);
select private.add_quiz('historia', 'hard', '¿Quién pintó la Capilla Sixtina?', 'Miguel Ángel', array['Leonardo da Vinci', 'Rafael', 'Donatello']);
select private.add_quiz('historia', 'easy', '¿En qué país empezó la Revolución francesa?', 'Francia', array['Inglaterra', 'Italia', 'España']);
select private.add_quiz('historia', 'normal', '¿Quién fue la reina de España en 1492?', 'Isabel I de Castilla', array['Juana la Loca', 'Isabel II', 'María Antonieta']);
select private.add_quiz('historia', 'hard', '¿En qué año terminó la Segunda Guerra Mundial en Europa?', '1945', array['1944', '1946', '1939']);
select private.add_quiz('ciencia', 'easy', '¿Cuál es el planeta más cercano al Sol?', 'Mercurio', array['Venus', 'Marte', 'Tierra']);
select private.add_quiz('ciencia', 'easy', '¿Qué gas respiramos sobre todo para vivir?', 'Oxígeno', array['Nitrógeno', 'Dióxido de carbono', 'Hidrógeno']);
select private.add_quiz('ciencia', 'normal', '¿Cuántos huesos tiene un adulto, aproximadamente?', '206', array['180', '300', '150']);
select private.add_quiz('ciencia', 'normal', '¿Quién propuso la teoría de la relatividad?', 'Albert Einstein', array['Isaac Newton', 'Galileo', 'Stephen Hawking']);
select private.add_quiz('ciencia', 'hard', '¿Cuál es el símbolo químico del oro?', 'Au', array['Ag', 'Or', 'Fe']);
select private.add_quiz('ciencia', 'easy', '¿Qué planeta es conocido como el planeta rojo?', 'Marte', array['Venus', 'Júpiter', 'Saturno']);
select private.add_quiz('ciencia', 'normal', '¿A qué velocidad aproximada viaja la luz en el vacío?', '300.000 km/s', array['150.000 km/s', '3.000 km/s', '30.000 km/s']);
select private.add_quiz('ciencia', 'hard', '¿Qué partícula tiene carga negativa en el átomo?', 'Electrón', array['Protón', 'Neutrón', 'Fotón']);
select private.add_quiz('cultura', 'easy', '¿Cuántos colores tiene el arcoíris tradicional?', '7', array['5', '6', '8']);
select private.add_quiz('cultura', 'easy', '¿En qué juego de mesa se come al rey contrario?', 'Ajedrez', array['Damas', 'Parchís', 'Go']);
select private.add_quiz('cultura', 'normal', '¿Quién escribió Don Quijote?', 'Miguel de Cervantes', array['Lope de Vega', 'Quevedo', 'Calderón']);
select private.add_quiz('cultura', 'normal', '¿Cuántas cuerdas tiene una guitarra española clásica?', '6', array['4', '5', '12']);
select private.add_quiz('cultura', 'hard', '¿En qué país se inventó el ajedrez, según la versión más aceptada?', 'India', array['China', 'Persia', 'Egipto']);
select private.add_quiz('cultura', 'easy', '¿Qué animal es la mascota de los Juegos Olímpicos de Barcelona 1992?', 'Cobi, un perro', array['Un toro', 'Un león', 'Un águila']);
select private.add_quiz('cultura', 'normal', '¿Cómo se llama el detective de Baker Street?', 'Sherlock Holmes', array['Hércules Poirot', 'Philip Marlowe', 'Watson']);
select private.add_quiz('cultura', 'hard', '¿Quién pintó Las meninas?', 'Diego Velázquez', array['Goya', 'El Greco', 'Picasso']);
select private.add_quiz('tecnologia', 'easy', '¿Qué empresa creó el iPhone?', 'Apple', array['Samsung', 'Google', 'Microsoft']);
select private.add_quiz('tecnologia', 'easy', '¿Qué empresa fabrica la PlayStation?', 'Sony', array['Microsoft', 'Nintendo', 'Sega']);
select private.add_quiz('tecnologia', 'normal', '¿Quién fundó Microsoft junto a Paul Allen?', 'Bill Gates', array['Steve Jobs', 'Mark Zuckerberg', 'Elon Musk']);
select private.add_quiz('tecnologia', 'normal', '¿Qué lenguaje usa sobre todo una página web para su estructura?', 'HTML', array['Python', 'SQL', 'C++']);
select private.add_quiz('tecnologia', 'hard', '¿En qué año se fundó Google?', '1998', array['1995', '2001', '2004']);
select private.add_quiz('tecnologia', 'easy', '¿Cómo se llama el asistente de voz de Apple?', 'Siri', array['Alexa', 'Cortana', 'Gemini']);
select private.add_quiz('tecnologia', 'normal', '¿Qué empresa compró YouTube en 2006?', 'Google', array['Microsoft', 'Meta', 'Amazon']);
select private.add_quiz('tecnologia', 'hard', '¿Cómo se llama el chip principal de un ordenador?', 'CPU', array['GPU', 'RAM', 'SSD']);
select private.add_quiz('marvel', 'easy', '¿Cómo se llama el grupo de héroes de Iron Man, Cap, Thor y Hulk?', 'Los Vengadores', array['La Liga de la Justicia', 'Los X-Men', 'Los 4 Fantásticos']);
select private.add_quiz('marvel', 'normal', '¿De qué planeta es Thor?', 'Asgard', array['Titan', 'Xandar', 'Sakaar']);
select private.add_quiz('marvel', 'normal', '¿Quién es el archienemigo clásico de Spider-Man con un planeador?', 'El Duende Verde', array['Venom', 'Doctor Octopus', 'Kingpin']);
select private.add_quiz('marvel', 'hard', '¿Cómo se llama el metal del esqueleto de Lobezno en los cómics?', 'Adamantium', array['Vibranium', 'Uru', 'Carbonadio']);
select private.add_quiz('marvel', 'easy', '¿Qué superhéroe es ciego y usa radar?', 'Daredevil', array['Ojo de Halcón', 'Cíclope', 'Iron Fist']);
select private.add_quiz('marvel', 'normal', '¿Cómo se llama el edificio de los Cuatro Fantásticos?', 'Baxter Building', array['Torre Avengers', 'Edificio Daily Bugle', 'Mansión X']);
select private.add_quiz('f1', 'easy', '¿De qué color es históricamente Ferrari en la Fórmula 1?', 'Rojo', array['Azul', 'Verde', 'Amarillo']);
select private.add_quiz('f1', 'easy', '¿Cuántos pilotos salen en una parrilla actual de Fórmula 1, con 10 equipos?', '20', array['18', '22', '24']);
select private.add_quiz('f1', 'normal', '¿Qué bandera detiene por completo una carrera de Fórmula 1?', 'La bandera roja', array['La bandera amarilla', 'La bandera azul', 'La bandera a cuadros']);
select private.add_quiz('f1', 'normal', '¿En qué país se corre el Gran Premio de Mónaco?', 'Mónaco', array['Francia', 'Italia', 'España']);
select private.add_quiz('f1', 'hard', '¿Cómo se llama la curva más famosa de Spa-Francorchamps?', 'Eau Rouge', array['Parabolica', '130R', 'Maggots']);
select private.add_quiz('f1', 'easy', '¿Qué neumático es el más blando de los de seco, por color?', 'El rojo', array['El blanco', 'El amarillo', 'El verde']);
select private.add_quiz('deportes', 'easy', '¿Cuántos jugadores hay en una cancha de baloncesto por equipo?', '5', array['6', '7', '11']);
select private.add_quiz('deportes', 'easy', '¿En qué deporte se usa un hoyo de 18 recorridos?', 'Golf', array['Tenis', 'Polo', 'Críquet']);
select private.add_quiz('deportes', 'normal', '¿Cada cuántos años se celebran los Juegos Olímpicos de verano?', '4', array['2', '3', '5']);
select private.add_quiz('deportes', 'normal', '¿En qué deporte destaca Rafael Nadal?', 'Tenis', array['Pádel', 'Golf', 'Fútbol']);
select private.add_quiz('deportes', 'hard', '¿Cuántos sets hay que ganar para llevarse un partido de Grand Slam masculino al mejor de 5?', '3', array['2', '4', '5']);
select private.add_quiz('deportes', 'easy', '¿Qué país inventó el baloncesto?', 'Estados Unidos', array['Canadá', 'España', 'Francia']);
select private.add_quiz('espana', 'easy', '¿Cuál es la capital de España?', 'Madrid', array['Barcelona', 'Sevilla', 'Valencia']);
select private.add_quiz('espana', 'easy', '¿En qué ciudad está la Sagrada Familia?', 'Barcelona', array['Madrid', 'Bilbao', 'Valencia']);
select private.add_quiz('espana', 'normal', '¿Cuántas comunidades autónomas tiene España?', '17', array['15', '19', '16']);
select private.add_quiz('espana', 'normal', '¿Qué río pasa por Sevilla?', 'Guadalquivir', array['Tajo', 'Ebro', 'Duero']);
select private.add_quiz('espana', 'hard', '¿En qué año se aprobó la Constitución española actual?', '1978', array['1975', '1982', '1976']);
select private.add_quiz('espana', 'easy', '¿En qué comunidad se originó la paella?', 'Comunidad Valenciana', array['Andalucía', 'Cataluña', 'Galicia']);
select private.add_quiz('internet', 'easy', '¿Qué red social compró Facebook y usa fotos que desaparecen en historias?', 'Instagram', array['Twitter', 'TikTok', 'LinkedIn']);
select private.add_quiz('internet', 'easy', '¿Cómo se llama el buscador de Google?', 'Google', array['Bing', 'Yahoo', 'DuckDuckGo']);
select private.add_quiz('internet', 'normal', '¿Qué significa URL?', 'Localizador uniforme de recursos', array['Unidad de red local', 'Usuario registrado libre', 'Unión de redes largas']);
select private.add_quiz('internet', 'normal', '¿Quién fundó Facebook?', 'Mark Zuckerberg', array['Jack Dorsey', 'Elon Musk', 'Larry Page']);
select private.add_quiz('internet', 'hard', '¿En qué año se lanzó YouTube al público?', '2005', array['2003', '2008', '2010']);
select private.add_quiz('internet', 'easy', '¿Qué app de vídeos cortos se hizo famosa con bailes?', 'TikTok', array['WhatsApp', 'Telegram', 'Spotify']);
drop function private.add_quiz(text, text, text, text, text[]);