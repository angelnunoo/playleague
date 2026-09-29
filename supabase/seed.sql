with c as (select id from public.quiz_categories where slug = 'futbol'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿En qué año ganó España su primer Mundial?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('2006', 0), ('2010', 1), ('2014', 2), ('2018', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'futbol'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Cuántos jugadores tiene un equipo de fútbol en el campo?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('9', 0), ('10', 1), ('11', 2), ('12', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'futbol'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Qué selección ganó el Mundial de 2022?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Francia', 0), ('Argentina', 1), ('Brasil', 2), ('Croacia', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'futbol'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿En qué club debutó Lionel Messi como profesional?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('River Plate', 0), ('Newell''s', 1), ('Barcelona', 2), ('PSG', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'futbol'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Quién marcó el gol de la final del Mundial 2010?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Villa', 0), ('Iniesta', 1), ('Xavi', 2), ('Puyol', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'futbol'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿Cuántos Balones de Oro tiene Alfredo Di Stéfano?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('1', 0), ('2', 1), ('3', 2), ('4', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'videojuegos'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿De qué color es el fontanero más famoso de Nintendo?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Verde', 0), ('Rojo', 1), ('Azul', 2), ('Amarillo', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'videojuegos'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Cómo se llama el erizo azul de Sega?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Crash', 0), ('Sonic', 1), ('Spyro', 2), ('Knuckles', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'videojuegos'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Qué estudio creó The Legend of Zelda?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Rare', 0), ('Nintendo', 1), ('Capcom', 2), ('Sega', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'videojuegos'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿En qué juego aparece el personaje Kratos?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 0, answer.ord
from ins
cross join (values ('God of War', 0), ('Halo', 1), ('Doom', 2), ('Gears', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'videojuegos'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Cuál fue la primera consola de Sony?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('PlayStation 2', 0), ('PlayStation', 1), ('PSP', 2), ('PS One', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'videojuegos'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿En qué año salió el primer Super Mario Bros.?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('1983', 0), ('1985', 1), ('1987', 2), ('1990', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cine'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Cómo se llama el mago de Harry Potter?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 0, answer.ord
from ins
cross join (values ('Harry', 0), ('Ron', 1), ('Dumbledore', 2), ('Snape', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cine'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Qué película tiene un barco llamado Titanic?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 0, answer.ord
from ins
cross join (values ('Titanic', 0), ('Poseidón', 1), ('Waterworld', 2), ('Moana', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cine'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Quién dirigió El padrino?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Scorsese', 0), ('Coppola', 1), ('Spielberg', 2), ('Tarantino', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cine'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Cómo se llama el león de El rey león?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 0, answer.ord
from ins
cross join (values ('Simba', 0), ('Mufasa', 1), ('Nala', 2), ('Timón', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cine'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Qué película ganó el Oscar a mejor película en 2020?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('1917', 0), ('Parásitos', 1), ('Joker', 2), ('Ford v Ferrari', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cine'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿Quién interpretó a Tony Montana en Scarface?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 0, answer.ord
from ins
cross join (values ('Pacino', 0), ('De Niro', 1), ('Pesci', 2), ('Liotta', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'musica'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Cuántas cuerdas tiene una guitarra española clásica?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('4', 0), ('5', 1), ('6', 2), ('7', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'musica'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Qué banda cantaba Bohemian Rhapsody?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('The Beatles', 0), ('Queen', 1), ('U2', 2), ('ABBA', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'musica'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿De qué país es Rosalía?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('México', 0), ('Argentina', 1), ('España', 2), ('Colombia', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'musica'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Qué instrumento toca principalmente un DJ?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Batería', 0), ('Mesa de mezclas', 1), ('Violín', 2), ('Arpa', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'musica'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Cuántas sinfonías compuso Beethoven?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('5', 0), ('7', 1), ('9', 2), ('12', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'musica'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿En qué año se publicó el álbum Thriller de Michael Jackson?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('1979', 0), ('1982', 1), ('1987', 2), ('1991', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'geografia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Cuál es la capital de Francia?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Lyon', 0), ('París', 1), ('Marsella', 2), ('Niza', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'geografia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿En qué continente está Egipto?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('Asia', 0), ('Europa', 1), ('África', 2), ('América', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'geografia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Cuál es el río más largo del mundo?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Nilo', 0), ('Amazonas', 1), ('Misisipi', 2), ('Yangtsé', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'geografia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Qué país tiene forma de bota?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('España', 0), ('Grecia', 1), ('Italia', 2), ('Portugal', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'geografia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Cuál es la capital de Australia?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('Sídney', 0), ('Melbourne', 1), ('Canberra', 2), ('Perth', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'geografia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿Qué país tiene más islas?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('Indonesia', 0), ('Filipinas', 1), ('Suecia', 2), ('Japón', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'historia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Quién descubrió América en 1492?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Magallanes', 0), ('Colón', 1), ('Elcano', 2), ('Pizarro', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'historia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿En qué país empezó la Revolución francesa?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Italia', 0), ('Francia', 1), ('Inglaterra', 2), ('Alemania', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'historia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿En qué año cayó el muro de Berlín?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('1985', 0), ('1989', 1), ('1991', 2), ('1995', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'historia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Quién fue el primer presidente de Estados Unidos?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Lincoln', 0), ('Washington', 1), ('Jefferson', 2), ('Adams', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'historia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Qué civilización construyó Machu Picchu?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('Azteca', 0), ('Maya', 1), ('Inca', 2), ('Olmeca', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'historia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿En qué año terminó la Guerra Civil española?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('1936', 0), ('1939', 1), ('1945', 2), ('1975', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'ciencia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Qué planeta es el más cercano al Sol?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Venus', 0), ('Mercurio', 1), ('Marte', 2), ('Tierra', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'ciencia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿El agua hierve a cuántos grados Celsius al nivel del mar?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('90', 0), ('100', 1), ('110', 2), ('120', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'ciencia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Qué gas respiramos principalmente del aire?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Oxígeno', 0), ('Nitrógeno', 1), ('CO2', 2), ('Hidrógeno', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'ciencia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Quién formuló la teoría de la relatividad?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Newton', 0), ('Einstein', 1), ('Galileo', 2), ('Hawking', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'ciencia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Cuál es el símbolo químico del oro?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Ag', 0), ('Au', 1), ('Fe', 2), ('Pb', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'ciencia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿Cuántos huesos tiene un adulto humano, aproximadamente?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('106', 0), ('206', 1), ('306', 2), ('156', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cultura'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Cuántos días tiene un año normal?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('364', 0), ('365', 1), ('366', 2), ('360', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cultura'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿De qué color es una esmeralda?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('Rojo', 0), ('Azul', 1), ('Verde', 2), ('Amarillo', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cultura'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Quién pintó La Gioconda?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Velázquez', 0), ('Da Vinci', 1), ('Picasso', 2), ('Goya', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cultura'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Cuántos lados tiene un hexágono?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('5', 0), ('6', 1), ('7', 2), ('8', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cultura'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿En qué ciudad está el Coliseo?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Atenas', 0), ('Roma', 1), ('Estambul', 2), ('El Cairo', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'cultura'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿Qué escritor creó a Sherlock Holmes?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('Poe', 0), ('Christie', 1), ('Doyle', 2), ('Hammett', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'tecnologia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Qué significa WWW?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 0, answer.ord
from ins
cross join (values ('World Wide Web', 0), ('Wireless Web World', 1), ('Web World Wide', 2), ('Wide World Web', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'tecnologia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Qué empresa fabrica el iPhone?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Samsung', 0), ('Apple', 1), ('Google', 2), ('Sony', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'tecnologia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Qué lenguaje usa principalmente una página web en el navegador?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Python', 0), ('HTML', 1), ('SQL', 2), ('C', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'tecnologia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Cómo se llama el asistente de voz de Apple?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Alexa', 0), ('Siri', 1), ('Cortana', 2), ('Gemini', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'tecnologia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Qué significa CPU?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 0, answer.ord
from ins
cross join (values ('Central Processing Unit', 0), ('Computer Personal Unit', 1), ('Core Power Unit', 2), ('Control Program Utility', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'tecnologia'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿En qué año se fundó Google?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('1996', 0), ('1998', 1), ('2001', 2), ('2004', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'marvel'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Cómo se llama el superhéroe de la araña?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Batman', 0), ('Spider-Man', 1), ('Ant-Man', 2), ('Iron Man', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'marvel'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿De qué color es el traje clásico de Hulk?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Rojo', 0), ('Verde', 1), ('Azul', 2), ('Negro', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'marvel'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Cómo se llama el martillo de Thor?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Stormbreaker', 0), ('Mjolnir', 1), ('Gungnir', 2), ('Hofund', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'marvel'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Qué metal hay en el escudo del Capitán América?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Adamantium', 0), ('Vibranium', 1), ('Acero', 2), ('Titanio', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'marvel'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Quién interpreta a Iron Man en el UCM?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Chris Evans', 0), ('Robert Downey Jr.', 1), ('Chris Hemsworth', 2), ('Mark Ruffalo', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'marvel'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿Cómo se llama la gema del tiempo en el infinito?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Alma', 0), ('Tiempo', 1), ('Espacio', 2), ('Mente', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'f1'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Cuántas ruedas tiene un Fórmula 1?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('3', 0), ('4', 1), ('6', 2), ('2', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'f1'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿De qué color es tradicionalmente Ferrari?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Azul', 0), ('Rojo', 1), ('Verde', 2), ('Amarillo', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'f1'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Qué piloto español ganó dos mundiales con Renault y Ferrari?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 0, answer.ord
from ins
cross join (values ('Alonso', 0), ('Sainz', 1), ('De la Rosa', 2), ('Gené', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'f1'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿En qué país se corre el Gran Premio de Mónaco?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Francia', 0), ('Mónaco', 1), ('Italia', 2), ('España', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'f1'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Cuántos mundiales tiene Lewis Hamilton hasta 2024?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('5', 0), ('6', 1), ('7', 2), ('8', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'f1'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿Qué escudería debutó con el motor Mercedes de fábrica en 2010?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Red Bull', 0), ('Mercedes', 1), ('McLaren', 2), ('Williams', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'deportes'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿En qué deporte se usa una canasta?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Fútbol', 0), ('Baloncesto', 1), ('Tenis', 2), ('Golf', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'deportes'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Cuántos sets se necesitan para ganar un partido de tenis al mejor de 3?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('1', 0), ('2', 1), ('3', 2), ('4', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'deportes'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Cada cuántos años son los Juegos Olímpicos de verano?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 2, answer.ord
from ins
cross join (values ('2', 0), ('3', 1), ('4', 2), ('5', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'deportes'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿En qué deporte destaca Rafael Nadal?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Golf', 0), ('Tenis', 1), ('Pádel', 2), ('Squash', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'deportes'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Cuántos jugadores hay en una pista de baloncesto por equipo?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('4', 0), ('5', 1), ('6', 2), ('7', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'deportes'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿En qué ciudad se celebraron los Juegos de 1992?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Madrid', 0), ('Barcelona', 1), ('Sevilla', 2), ('Valencia', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'espana'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Cuál es la capital de España?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Barcelona', 0), ('Madrid', 1), ('Sevilla', 2), ('Valencia', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'espana'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿En qué comunidad está la Alhambra?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 0, answer.ord
from ins
cross join (values ('Andalucía', 0), ('Galicia', 1), ('Aragón', 2), ('Murcia', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'espana'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Qué mar baña Valencia?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Cantábrico', 0), ('Mediterráneo', 1), ('Atlántico', 2), ('Negro', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'espana'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Cuántas comunidades autónomas tiene España?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('15', 0), ('17', 1), ('19', 2), ('21', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'espana'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Cuál es el pico más alto de la península?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Teide', 0), ('Mulhacén', 1), ('Aneto', 2), ('Veleta', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'espana'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿En qué año se aprobó la Constitución española actual?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('1975', 0), ('1978', 1), ('1982', 2), ('1986', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'internet'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Qué red social usa fotos cuadradas y stories?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 0, answer.ord
from ins
cross join (values ('Instagram', 0), ('LinkedIn', 1), ('Reddit', 2), ('Wikipedia', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'internet'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'easy', '¿Cómo se llama el pájaro de Twitter, ahora X?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Piolín', 0), ('El pájaro azul', 1), ('Tweety', 2), ('Duolingo', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'internet'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Qué significa LOL?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Lots of love', 0), ('Laughing out loud', 1), ('Lots of luck', 2), ('Lost online', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'internet'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'normal', '¿Qué plataforma es famosa por vídeos cortos verticales?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 0, answer.ord
from ins
cross join (values ('TikTok', 0), ('Spotify', 1), ('Twitch', 2), ('Netflix', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'internet'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'hard', '¿Qué significa meme, en origen?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('Un virus', 0), ('Una idea que se copia', 1), ('Un filtro', 2), ('Un emoji', 3)) as answer(text, ord);
with c as (select id from public.quiz_categories where slug = 'internet'),
ins as (
  insert into public.quiz_questions (category_id, difficulty, prompt)
  select c.id, 'expert', '¿En qué año se lanzó YouTube?' from c
  on conflict (category_id, prompt) do nothing
  returning id
)
insert into public.quiz_answers (question_id, text, is_correct, sort_order)
select ins.id, answer.text, answer.ord = 1, answer.ord
from ins
cross join (values ('2003', 0), ('2005', 1), ('2007', 2), ('2010', 3)) as answer(text, ord);
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Pizza', '🍕', 'hard' from public.impostor_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Hamburguesa', '🍔', 'hard' from public.impostor_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Sushi', '🍣', 'hard' from public.impostor_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Paella', '🥘', 'easy' from public.impostor_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Tortilla', '🍳', 'hard' from public.impostor_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Helado', '🍦', 'easy' from public.impostor_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Croqueta', '🟤', 'hard' from public.impostor_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Gazpacho', '🍅', 'hard' from public.impostor_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Churro', '🍩', 'easy' from public.impostor_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Taco', '🌮', 'normal' from public.impostor_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Perro', '🐶', 'hard' from public.impostor_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Gato', '🐱', 'normal' from public.impostor_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'León', '🦁', 'normal' from public.impostor_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Delfín', '🐬', 'easy' from public.impostor_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Pingüino', '🐧', 'hard' from public.impostor_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Elefante', '🐘', 'hard' from public.impostor_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Águila', '🦅', 'easy' from public.impostor_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Tiburón', '🦈', 'normal' from public.impostor_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Jirafa', '🦒', 'easy' from public.impostor_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Koala', '🐨', 'hard' from public.impostor_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Paraguas', '☂️', 'hard' from public.impostor_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Reloj', '⌚', 'hard' from public.impostor_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Mochila', '🎒', 'normal' from public.impostor_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Lámpara', '💡', 'normal' from public.impostor_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Martillo', '🔨', 'hard' from public.impostor_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Espejo', '🪞', 'easy' from public.impostor_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Llave', '🔑', 'hard' from public.impostor_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Cepillo', '🪥', 'normal' from public.impostor_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Tijeras', '✂️', 'normal' from public.impostor_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Almohada', '🛏️', 'hard' from public.impostor_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Playa', '🏖️', 'hard' from public.impostor_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Hospital', '🏥', 'hard' from public.impostor_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Aeropuerto', '✈️', 'normal' from public.impostor_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Biblioteca', '📚', 'normal' from public.impostor_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Montaña', '⛰️', 'normal' from public.impostor_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Supermercado', '🛒', 'easy' from public.impostor_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Castillo', '🏰', 'hard' from public.impostor_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Estadio', '🏟️', 'normal' from public.impostor_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Museo', '🖼️', 'hard' from public.impostor_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Camping', '⛺', 'normal' from public.impostor_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Médico', '🩺', 'easy' from public.impostor_categories where slug = 'profesiones'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Bombero', '🚒', 'normal' from public.impostor_categories where slug = 'profesiones'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Cocinero', '👨‍🍳', 'hard' from public.impostor_categories where slug = 'profesiones'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Piloto', '🧑‍✈️', 'easy' from public.impostor_categories where slug = 'profesiones'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Profesor', '👩‍🏫', 'hard' from public.impostor_categories where slug = 'profesiones'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Policía', '👮', 'normal' from public.impostor_categories where slug = 'profesiones'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Arquitecto', '📐', 'normal' from public.impostor_categories where slug = 'profesiones'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Periodista', '📰', 'normal' from public.impostor_categories where slug = 'profesiones'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Mecánico', '🔧', 'hard' from public.impostor_categories where slug = 'profesiones'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Juez', '⚖️', 'normal' from public.impostor_categories where slug = 'profesiones'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Shakira', '🎤', 'normal' from public.impostor_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Messi', '⚽', 'hard' from public.impostor_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Cervantes', '📖', 'easy' from public.impostor_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Picasso', '🎨', 'normal' from public.impostor_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Beyoncé', '👑', 'normal' from public.impostor_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Einstein', '🧠', 'hard' from public.impostor_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Mozart', '🎼', 'easy' from public.impostor_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Cleopatra', '🏺', 'easy' from public.impostor_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Chaplin', '🎩', 'normal' from public.impostor_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Frida Kahlo', '🌺', 'hard' from public.impostor_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Tenis', '🎾', 'hard' from public.impostor_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Baloncesto', '🏀', 'normal' from public.impostor_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Natación', '🏊', 'hard' from public.impostor_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Ciclismo', '🚴', 'hard' from public.impostor_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Boxeo', '🥊', 'hard' from public.impostor_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Golf', '⛳', 'normal' from public.impostor_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Esquí', '⛷️', 'hard' from public.impostor_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Voleibol', '🏐', 'hard' from public.impostor_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Surf', '🏄', 'normal' from public.impostor_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Ajedrez', '♟️', 'normal' from public.impostor_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Nike', '✔️', 'normal' from public.impostor_categories where slug = 'marcas'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Apple', '🍎', 'hard' from public.impostor_categories where slug = 'marcas'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Coca-Cola', '🥤', 'easy' from public.impostor_categories where slug = 'marcas'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'IKEA', '🪑', 'normal' from public.impostor_categories where slug = 'marcas'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Netflix', '🎬', 'normal' from public.impostor_categories where slug = 'marcas'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Zara', '👗', 'normal' from public.impostor_categories where slug = 'marcas'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Lego', '🧱', 'normal' from public.impostor_categories where slug = 'marcas'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Nintendo', '🎮', 'hard' from public.impostor_categories where slug = 'marcas'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Adidas', '👟', 'easy' from public.impostor_categories where slug = 'marcas'
on conflict (category_id, word) do nothing;
insert into public.impostor_words (category_id, word, emoji, difficulty)
select id, 'Toyota', '🚗', 'easy' from public.impostor_categories where slug = 'marcas'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Manzana', '🍎', array['Fruta', 'Roja', 'Árbol', 'Comer', 'Verde'], 'normal'
from public.taboo_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Pizza', '🍕', array['Queso', 'Tomate', 'Italia', 'Horno', 'Redonda'], 'normal'
from public.taboo_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Helado', '🍦', array['Frío', 'Dulce', 'Cucurucho', 'Verano', 'Chocolate'], 'normal'
from public.taboo_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Paella', '🥘', array['Arroz', 'Valencia', 'Marisco', 'Azafrán', 'Sartén'], 'normal'
from public.taboo_categories where slug = 'comida'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Elefante', '🐘', array['Grande', 'Trompa', 'África', 'Gris', 'Colmillos'], 'normal'
from public.taboo_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Pingüino', '🐧', array['Hielo', 'Ave', 'Frío', 'Blanco', 'Nadar'], 'normal'
from public.taboo_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'León', '🦁', array['Rey', 'Melena', 'Rugir', 'Selva', 'Felino'], 'normal'
from public.taboo_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Delfín', '🐬', array['Mar', 'Inteligente', 'Saltar', 'Gris', 'Mamífero'], 'normal'
from public.taboo_categories where slug = 'animales'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Paraguas', '☂️', array['Lluvia', 'Abrir', 'Mojar', 'Mango', 'Gotas'], 'normal'
from public.taboo_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Reloj', '⌚', array['Hora', 'Tiempo', 'Muñeca', 'Agujas', 'Minutos'], 'normal'
from public.taboo_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Espejo', '🪞', array['Reflejo', 'Cara', 'Cristal', 'Baño', 'Verse'], 'normal'
from public.taboo_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Llave', '🔑', array['Puerta', 'Cerrar', 'Cerradura', 'Metal', 'Abrir'], 'normal'
from public.taboo_categories where slug = 'objetos'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Playa', '🏖️', array['Mar', 'Arena', 'Verano', 'Toalla', 'Olas'], 'normal'
from public.taboo_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Hospital', '🏥', array['Médico', 'Enfermo', 'Cama', 'Urgencias', 'Bata'], 'normal'
from public.taboo_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Aeropuerto', '✈️', array['Avión', 'Maleta', 'Volar', 'Pasaporte', 'Pista'], 'normal'
from public.taboo_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Biblioteca', '📚', array['Libros', 'Silencio', 'Leer', 'Estudiar', 'Estantería'], 'normal'
from public.taboo_categories where slug = 'lugares'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Tenis', '🎾', array['Raqueta', 'Pelota', 'Red', 'Set', 'Pista'], 'normal'
from public.taboo_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Baloncesto', '🏀', array['Canasta', 'Pelota', 'Aro', 'Equipo', 'Botar'], 'normal'
from public.taboo_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Natación', '🏊', array['Agua', 'Piscina', 'Nadar', 'Bañador', 'Brazada'], 'normal'
from public.taboo_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Ciclismo', '🚴', array['Bici', 'Rueda', 'Pedal', 'Casco', 'Carrera'], 'normal'
from public.taboo_categories where slug = 'deportes'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Messi', '⚽', array['Fútbol', 'Argentina', 'Barcelona', 'Gol', 'Balón'], 'normal'
from public.taboo_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Shakira', '🎤', array['Cantar', 'Colombia', 'Cadera', 'Música', 'Loba'], 'normal'
from public.taboo_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Picasso', '🎨', array['Pintor', 'Cuadro', 'Cubismo', 'Málaga', 'Arte'], 'normal'
from public.taboo_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Einstein', '🧠', array['Física', 'Relatividad', 'Genio', 'Pelo', 'Ciencia'], 'normal'
from public.taboo_categories where slug = 'famosos'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Nevera', '🧊', array['Frío', 'Comida', 'Cocina', 'Hielo', 'Puerta'], 'normal'
from public.taboo_categories where slug = 'casa'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Sofá', '🛋️', array['Sentarse', 'Salón', 'Cojín', 'Tele', 'Descansar'], 'normal'
from public.taboo_categories where slug = 'casa'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Ducha', '🚿', array['Agua', 'Baño', 'Jabón', 'Mojar', 'Grifo'], 'normal'
from public.taboo_categories where slug = 'casa'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Cama', '🛏️', array['Dormir', 'Almohada', 'Sábana', 'Noche', 'Colchón'], 'normal'
from public.taboo_categories where slug = 'casa'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Semáforo', '🚦', array['Rojo', 'Verde', 'Tráfico', 'Coche', 'Parar'], 'normal'
from public.taboo_categories where slug = 'ciudad'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Metro', '🚇', array['Tren', 'Subterráneo', 'Andén', 'Billete', 'Túnel'], 'normal'
from public.taboo_categories where slug = 'ciudad'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Taxi', '🚕', array['Coche', 'Amarillo', 'Conductor', 'Pago', 'Calle'], 'normal'
from public.taboo_categories where slug = 'ciudad'
on conflict (category_id, word) do nothing;
insert into public.taboo_cards (category_id, word, emoji, forbidden, difficulty)
select id, 'Parque', '🌳', array['Árboles', 'Banco', 'Verde', 'Pasear', 'Niños'], 'normal'
from public.taboo_categories where slug = 'ciudad'
on conflict (category_id, word) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 países de Europa.', 'easy' from public.quick_categories where slug = 'paises'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 países de América.', 'normal' from public.quick_categories where slug = 'paises'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 países que empiecen por A.', 'hard' from public.quick_categories where slug = 'paises'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 islas que sean países.', 'easy' from public.quick_categories where slug = 'paises'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 países de África.', 'normal' from public.quick_categories where slug = 'paises'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 países vecinos de España.', 'hard' from public.quick_categories where slug = 'paises'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 futbolistas españoles.', 'easy' from public.quick_categories where slug = 'futbolistas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 porteros famosos.', 'normal' from public.quick_categories where slug = 'futbolistas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 jugadores del Real Madrid.', 'hard' from public.quick_categories where slug = 'futbolistas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 jugadoras de fútbol.', 'easy' from public.quick_categories where slug = 'futbolistas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 balones de oro.', 'normal' from public.quick_categories where slug = 'futbolistas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 equipos de la Premier.', 'hard' from public.quick_categories where slug = 'futbolistas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 marcas de coches.', 'easy' from public.quick_categories where slug = 'coches'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 marcas alemanas.', 'normal' from public.quick_categories where slug = 'coches'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 coches deportivos.', 'hard' from public.quick_categories where slug = 'coches'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 marcas japonesas.', 'easy' from public.quick_categories where slug = 'coches'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 marcas francesas.', 'normal' from public.quick_categories where slug = 'coches'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 SUV famosos.', 'hard' from public.quick_categories where slug = 'coches'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 videojuegos de Mario.', 'easy' from public.quick_categories where slug = 'videojuegos'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 sagas de disparos.', 'normal' from public.quick_categories where slug = 'videojuegos'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 juegos de fútbol.', 'hard' from public.quick_categories where slug = 'videojuegos'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 consolas.', 'easy' from public.quick_categories where slug = 'videojuegos'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 personajes de Pokémon.', 'normal' from public.quick_categories where slug = 'videojuegos'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 juegos de móvil.', 'hard' from public.quick_categories where slug = 'videojuegos'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 vengadores.', 'easy' from public.quick_categories where slug = 'marvel'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 villanos de Marvel.', 'normal' from public.quick_categories where slug = 'marvel'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 películas de Marvel.', 'hard' from public.quick_categories where slug = 'marvel'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 superhéroes que vuelan.', 'easy' from public.quick_categories where slug = 'marvel'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 actores del UCM.', 'normal' from public.quick_categories where slug = 'marvel'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 gemas del infinito.', 'hard' from public.quick_categories where slug = 'marvel'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 animales marinos.', 'easy' from public.quick_categories where slug = 'animales'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 animales de granja.', 'normal' from public.quick_categories where slug = 'animales'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 aves.', 'hard' from public.quick_categories where slug = 'animales'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 felinos.', 'easy' from public.quick_categories where slug = 'animales'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 animales africanos.', 'normal' from public.quick_categories where slug = 'animales'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 insectos.', 'hard' from public.quick_categories where slug = 'animales'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 ciudades de Andalucía.', 'easy' from public.quick_categories where slug = 'ciudades'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 capitales de provincia.', 'normal' from public.quick_categories where slug = 'ciudades'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 ciudades costeras.', 'hard' from public.quick_categories where slug = 'ciudades'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 ciudades del norte.', 'easy' from public.quick_categories where slug = 'ciudades'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 ciudades con playa.', 'normal' from public.quick_categories where slug = 'ciudades'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 ciudades que no sean Madrid ni Barcelona.', 'hard' from public.quick_categories where slug = 'ciudades'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 postres.', 'easy' from public.quick_categories where slug = 'comidas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 platos con arroz.', 'normal' from public.quick_categories where slug = 'comidas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 frutas.', 'hard' from public.quick_categories where slug = 'comidas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 comidas italianas.', 'easy' from public.quick_categories where slug = 'comidas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 tapas.', 'normal' from public.quick_categories where slug = 'comidas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 desayunos.', 'hard' from public.quick_categories where slug = 'comidas'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 profesiones de hospital.', 'easy' from public.quick_categories where slug = 'profesiones'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 oficios manuales.', 'normal' from public.quick_categories where slug = 'profesiones'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 trabajos de un colegio.', 'hard' from public.quick_categories where slug = 'profesiones'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 profesiones artísticas.', 'easy' from public.quick_categories where slug = 'profesiones'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 trabajos al aire libre.', 'normal' from public.quick_categories where slug = 'profesiones'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 profesiones con uniforme.', 'hard' from public.quick_categories where slug = 'profesiones'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 instrumentos.', 'easy' from public.quick_categories where slug = 'musica'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 cantantes españoles.', 'normal' from public.quick_categories where slug = 'musica'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 bandas de rock.', 'hard' from public.quick_categories where slug = 'musica'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 géneros musicales.', 'easy' from public.quick_categories where slug = 'musica'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 canciones de los 2000.', 'normal' from public.quick_categories where slug = 'musica'
on conflict (category_id, prompt) do nothing;
insert into public.quick_questions (category_id, prompt, difficulty)
select id, 'Nombra 3 festivales.', 'hard' from public.quick_categories where slug = 'musica'
on conflict (category_id, prompt) do nothing;