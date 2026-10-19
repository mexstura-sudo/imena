-- Лесные имена «Байкальского Скаута» — схема базы для Supabase.
-- Запускать целиком в Supabase → SQL Editor → New query → Run.
-- Скрипт можно запускать повторно: он ничего не дублирует и не стирает.
--
-- ПЕРЕД ЗАПУСКОМ: в самом конце файла замените ВАШ_EMAIL@example.com
-- на свою почту — она станет первым администратором.

create extension if not exists pgcrypto;

-- ---------- Администраторы ----------
create table if not exists public.admins (
  email      text primary key check (email = lower(email) and email like '%@%'),
  added_at   timestamptz not null default now()
);

-- true, если вошедший пользователь есть в списке админов
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.admins
    where email = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- ---------- База имён (видна всем) ----------
create table if not exists public.names (
  id          uuid primary key default gen_random_uuid(),
  fio         text not null default '' check (char_length(fio) <= 120),
  otryad      text not null default '' check (char_length(otryad) <= 120),
  forest_name text not null check (char_length(forest_name) between 1 and 60),
  year        int  check (year between 1900 and 2100),
  silhouette  text not null default 'w'
              check (silhouette in ('b','o','c','d','br','m','s','h','p','f','l','i','w')),
  photo_path  text check (char_length(photo_path) <= 200),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ---------- Заявки (пишут все, читают только админы) ----------
create table if not exists public.requests (
  id            uuid primary key default gen_random_uuid(),
  fio           text not null check (char_length(btrim(fio)) between 2 and 120),
  otryad        text not null default '' check (char_length(otryad) <= 120),
  forest_name   text not null check (char_length(btrim(forest_name)) between 1 and 60),
  year          int  check (year between 1900 and 2100),
  photo_path    text check (photo_path is null or photo_path ~ '^[0-9a-f-]{36}\.(jpg|png|webp)$'),
  photo_consent boolean not null default false,
  status        text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at    timestamptz not null default now(),
  constraint photo_needs_consent check (photo_path is null or photo_consent)
);
create index if not exists requests_status_idx on public.requests (status, created_at desc);

-- ---------- Права (RLS) ----------
alter table public.admins   enable row level security;
alter table public.names    enable row level security;
alter table public.requests enable row level security;

drop policy if exists "names: все читают"        on public.names;
drop policy if exists "names: админы добавляют"  on public.names;
drop policy if exists "names: админы меняют"     on public.names;
drop policy if exists "names: админы удаляют"    on public.names;
create policy "names: все читают"       on public.names for select to anon, authenticated using (true);
create policy "names: админы добавляют" on public.names for insert to authenticated with check (public.is_admin());
create policy "names: админы меняют"    on public.names for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "names: админы удаляют"   on public.names for delete to authenticated using (public.is_admin());

drop policy if exists "requests: все отправляют"  on public.requests;
drop policy if exists "requests: админы читают"   on public.requests;
drop policy if exists "requests: админы меняют"   on public.requests;
drop policy if exists "requests: админы удаляют"  on public.requests;
create policy "requests: все отправляют" on public.requests for insert to anon, authenticated with check (status = 'pending');
create policy "requests: админы читают"  on public.requests for select to authenticated using (public.is_admin());
create policy "requests: админы меняют"  on public.requests for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "requests: админы удаляют" on public.requests for delete to authenticated using (public.is_admin());

drop policy if exists "admins: админы видят"      on public.admins;
drop policy if exists "admins: админы приглашают" on public.admins;
drop policy if exists "admins: админы удаляют"    on public.admins;
create policy "admins: админы видят"      on public.admins for select to authenticated using (public.is_admin());
create policy "admins: админы приглашают" on public.admins for insert to authenticated with check (public.is_admin());
create policy "admins: админы удаляют"    on public.admins for delete to authenticated
  using (public.is_admin() and email <> lower(coalesce(auth.jwt() ->> 'email', '')));  -- себя удалить нельзя

-- ---------- Хранилище фото ----------
-- photos  — публичные фото одобренных имён
-- uploads — фото из заявок, закрытые, видят только админы
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('photos',  'photos',  true,  5242880, array['image/jpeg','image/png','image/webp']),
  ('uploads', 'uploads', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "uploads: все загружают"   on storage.objects;
drop policy if exists "uploads: админы читают"   on storage.objects;
drop policy if exists "uploads: админы удаляют"  on storage.objects;
drop policy if exists "photos: админы загружают" on storage.objects;
drop policy if exists "photos: админы меняют"    on storage.objects;
drop policy if exists "photos: админы удаляют"   on storage.objects;
create policy "uploads: все загружают" on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'uploads' and name ~ '^[0-9a-f-]{36}\.(jpg|png|webp)$');
create policy "uploads: админы читают"  on storage.objects for select to authenticated using (bucket_id = 'uploads' and public.is_admin());
create policy "uploads: админы удаляют" on storage.objects for delete to authenticated using (bucket_id = 'uploads' and public.is_admin());
create policy "photos: админы загружают" on storage.objects for insert to authenticated with check (bucket_id = 'photos' and public.is_admin());
create policy "photos: админы меняют"    on storage.objects for update to authenticated using (bucket_id = 'photos' and public.is_admin());
create policy "photos: админы удаляют"   on storage.objects for delete to authenticated using (bucket_id = 'photos' and public.is_admin());

-- ---------- Начальный список (вставляется, только если база пуста) ----------
-- silhouette: b птица, o сова, c кошачьи, d псовые, br медведь, m зверёк, s море,
--             h копытные, p приматы, f сказочные, l растение, i насекомое, w лапка
insert into public.names (fio, otryad, forest_name, year, silhouette)
select v.fio, v.otryad, v.forest_name, v.year, v.silhouette from (values
  ('Ноздрина Анна','Хаски, ОКИ-Р','Хаус',2022,'w'),
  ('Ширимова Ульяна','ОКИ-Р','Ласка',null,'m'),
  ('Степаненко Даниил','Дельфин, ОКИ-Р','Журавль',null,'b'),
  ('Цибин Артём','Амба, ОКИ-Р','Аист',null,'b'),
  ('Степаненко Дарья','Дельфин, ОКИ-Р','Фенек',null,'d'),
  ('Яцкевич Евгения','Хаски','Большая Медведица',null,'br'),
  ('Дягилева Анастасия','Витязь','Медведица',null,'br'),
  ('Ступишина Наталья','Витязь','Пума',null,'c'),
  ('Григорьев Иван','Дельфин','Барсук',null,'m'),
  ('Ильгнерова Анна','Витязь','Енот',null,'m'),
  ('Маняев Владислав','Бабр, ОКИ-Р','Лемур',null,'p'),
  ('Иванов Илья','Феникс, ОКИ-Р','Железный Дровосек',null,'f'),
  ('Чернов Вадим','Феникс','Кот Матроскин',null,'c'),
  ('Пристай Степан','Спарта','Манул',null,'c'),
  ('Негороженко Екатерина','Белый шиповник','Сова',null,'o'),
  ('Верхозин Михаил','Ирбис, ОКИ-Р','Горностай',null,'m'),
  ('Дмитриев Александр','Спарта','Сурикат',null,'m'),
  ('Боровченко Михаил','Горизонт','Филин',null,'o'),
  ('Войтович Ксения','Феникс','Ласточка',null,'b'),
  ('Парфёнов Илья','Дельфин, ОКИ-Р','Мангуст',null,'m'),
  ('Орлова Мария','Витязь, Фортуна','Муха',null,'i'),
  ('Орлов Олег','Витязь, Фортуна','Орёл',null,'b'),
  ('Новосёлова Дарья','Азиштау','Акация',null,'l'),
  ('Бегачева Ксения','Феникс','Колибри',null,'b'),
  ('Хромова Анастасия','Хаски','Фламинго',null,'b'),
  ('Алтынников Максим','ОКИ-Р','Балто',null,'d'),
  ('Хаяси Екатерина','ОКИ-Р','Спирит',null,'h'),
  ('Хабибулина Полина','Бабр','Красная Панда',null,'m'),
  ('Волынкин Артур','Амба','Балу',null,'br'),
  ('Попов Денис','Амба','Соболь',null,'m'),
  ('Парфёнов Олег','Дельфин','Акула',null,'s'),
  ('Поляков Павел','Амба','Корсак',null,'d'),
  ('Шободоева Анна','Сарма','Багира',null,'c'),
  ('Крючкова Ольга','Белый шиповник','Фея',null,'f'),
  ('Евдошенко Ольга','Амба','Эльфа',null,'f'),
  ('Красноштанов Владислав','Хаски','Папа Хаска',null,'d'),
  ('Константинова Надежда','Хаски, ОКИ-Р','Акита-Ину',2021,'d'),
  ('Яцкевич Андрей','Хаски, ОКИ-Р','Квокка',2021,'m'),
  ('Пахомова Мария','Бабр, ОКИ-Р','Фретка',2021,'m'),
  ('Герцун Глеб','Феникс, ОКИ-Р','Тасманский Дьявол',2021,'m'),
  ('Колесникова Ксения','Братск, ОКИ-Р','Лазоревка',2021,'b'),
  ('Тушкова Надежда','ДСИ','Тушканчик',2021,'m'),
  ('Квецко Михаил','Феникс, ОКИ-Р','Сапсан',2022,'b'),
  ('Махонькина Алина','Феникс, ОКИ-Р','Альпака',2022,'h'),
  ('Осипов Александр','ОКИ-Р','Заяц-русак',2022,'m'),
  ('Федорова Даша','Хаски, ОКИ-Р','Тануки',2022,'d'),
  ('Петрова Ирина','Ирбис','Индри',1993,'p'),
  ('Лень Соня','Братск, Сова','Сибирская Горихвостка',2023,'b'),
  ('Полещук Анна','Зодиак, Акула, Сова','Бледная Пересмешка',2023,'b'),
  ('Скворцова Злата','Лисята, Манулы, Сова','Пустельга',2023,'b'),
  ('Глазков Семён','Сова','Олинго',2023,'m'),
  ('Чеснокова Елизавета','СБ, Сова','Мушу',2023,'f'),
  ('Агеева Лилия','','Лань',2023,'h'),
  ('Гусева Софья','Хаски','Афалина',2023,'s'),
  ('Светлана','Снежный барс, Хакасия','Гепард',2024,'c'),
  ('Черных Влад','Феникс, Сова','Большой Куду',2024,'h'),
  ('Нежданова Лена','Мамонты, Сова','Саймири',2024,'p'),
  ('Роднин Вячеслав','Калипсо, Сова','Стриж',2024,'b'),
  ('Кудрявченко Маша','Акула, Сова','Зарянка',2024,'b'),
  ('Корнева Аня','Феникс, Сова','Фосса',2024,'c'),
  ('Горбаткова Настя','Пантера, Сова','Онцилла',2024,'c'),
  ('Коновалова Алина','Ястреб','Окапи',2024,'h'),
  ('Антонов Сергей','Ирбис','Барибал',2024,'br'),
  ('Савинов Артём','Ирбис','Легаси',2024,'w'),
  ('Синкевич Вячеслав','Симуран','Мастиф',2025,'d'),
  ('Редькин Алексей','Ирбис','Корсо',2025,'d')
) as v(fio, otryad, forest_name, year, silhouette)
where not exists (select 1 from public.names);

-- ---------- Первый администратор ----------
insert into public.admins (email) values (lower('ВАШ_EMAIL@example.com'))
on conflict do nothing;
