create table if not exists public.research_journal_entries (
  entry_date date primary key,
  meeting boolean not null default false,
  gao text not null default '',
  wang text not null default '',
  updated_at timestamptz not null default now(),
  updated_by text
);

alter table public.research_journal_entries enable row level security;

drop policy if exists "Anyone can read journal entries" on public.research_journal_entries;
create policy "Anyone can read journal entries"
  on public.research_journal_entries
  for select
  using (true);

drop policy if exists "Anyone can insert journal entries" on public.research_journal_entries;
create policy "Anyone can insert journal entries"
  on public.research_journal_entries
  for insert
  with check (true);

drop policy if exists "Anyone can update journal entries" on public.research_journal_entries;
create policy "Anyone can update journal entries"
  on public.research_journal_entries
  for update
  using (true)
  with check (true);

drop policy if exists "Anyone can delete journal entries" on public.research_journal_entries;
create policy "Anyone can delete journal entries"
  on public.research_journal_entries
  for delete
  using (true);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'research_journal_entries'
  ) then
    alter publication supabase_realtime add table public.research_journal_entries;
  end if;
end $$;
