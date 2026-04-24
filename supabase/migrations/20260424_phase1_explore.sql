create extension if not exists pgcrypto;

create table if not exists users (
    id uuid primary key default gen_random_uuid(),
    apple_id text unique not null,
    display_name text not null,
    created_at timestamptz default now()
);

create table if not exists patterns (
    id uuid primary key default gen_random_uuid(),
    author_id uuid references users(id) on delete set null,
    author_name text not null default '',
    title text not null default '',
    pixels jsonb not null default '[]',
    width int not null,
    height int not null,
    palette text[] default '{}',
    difficulty text not null default 'easy',
    theme text not null default 'other',
    status text not null default 'pending',
    thumbnail_path text,
    save_count int not null default 0,
    created_at timestamptz default now(),
    published_at timestamptz,
    withdrawn_at timestamptz,
    deleted_at timestamptz,
    size_tier text generated always as (
        case
            when least(width, height) <= 16 then 'small'
            when least(width, height) <= 32 then 'medium'
            else 'large'
        end
    ) stored
);

create table if not exists saves (
    pattern_id uuid references patterns(id) on delete cascade,
    device_id text not null,
    saved_at timestamptz default now(),
    primary key (pattern_id, device_id)
);

create index if not exists idx_patterns_status_published_at
    on patterns(status, published_at desc)
    where status = 'published';

create index if not exists idx_saves_pattern_id
    on saves(pattern_id);

create index if not exists idx_saves_saved_at
    on saves(saved_at);

alter table patterns enable row level security;
alter table saves enable row level security;
alter table users enable row level security;

drop policy if exists "public read published" on patterns;
create policy "public read published"
    on patterns for select
    using (status = 'published');

drop policy if exists "author can insert" on patterns;
create policy "author can insert"
    on patterns for insert
    with check (author_id = auth.uid());

drop policy if exists "author can update own" on patterns;
create policy "author can update own"
    on patterns for update
    using (author_id = auth.uid());

drop policy if exists "anyone can save" on saves;
create policy "anyone can save"
    on saves for insert
    with check (true);

drop policy if exists "anyone can read saves" on saves;
create policy "anyone can read saves"
    on saves for select
    using (true);

drop policy if exists "anyone can delete own device save" on saves;
create policy "anyone can delete own device save"
    on saves for delete
    using (true);

drop policy if exists "user owns their row" on users;
create policy "user owns their row"
    on users for all
    using (apple_id = auth.jwt() ->> 'sub');
