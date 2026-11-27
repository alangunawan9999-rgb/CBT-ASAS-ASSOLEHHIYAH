-- CBT ASAS SMK AS-SOLEHHIYAH | Jalankan sekali di Supabase SQL Editor
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null, nis text unique, class_name text, email text,
 role text not null default 'student' check(role in ('admin','student')),
 created_at timestamptz not null default now()
);
create table if not exists public.subjects (
 id uuid primary key default gen_random_uuid(), name text not null, code text,
 class_name text, kktp integer not null default 75 check(kktp between 0 and 100),
 created_at timestamptz not null default now()
);
create table if not exists public.questions (
 id uuid primary key default gen_random_uuid(), subject_id uuid not null references public.subjects(id) on delete cascade,
 question_text text not null, image_url text, choices jsonb not null default '[]'::jsonb,
 correct_answer text not null, weight numeric not null default 1,
 created_at timestamptz not null default now()
);
create table if not exists public.exams (
 id uuid primary key default gen_random_uuid(), title text not null,
 subject_id uuid not null references public.subjects(id) on delete cascade,
 start_at timestamptz not null, end_at timestamptz not null,
 duration_minutes integer not null default 90, academic_year text not null default '2026-2027',
 is_active boolean not null default true, created_by uuid references auth.users(id),
 created_at timestamptz not null default now(), check(end_at>start_at)
);
create table if not exists public.attempts (
 id uuid primary key default gen_random_uuid(), exam_id uuid not null references public.exams(id),
 student_id uuid not null references auth.users(id), started_at timestamptz not null default now(),
 submitted_at timestamptz, score numeric, violations integer not null default 0,
 status text not null default 'in_progress', unique(exam_id,student_id)
);
create table if not exists public.answers (
 id uuid primary key default gen_random_uuid(), attempt_id uuid not null references public.attempts(id) on delete cascade,
 question_id uuid not null references public.questions(id), answer text, is_correct boolean, points numeric default 0,
 unique(attempt_id,question_id)
);
create table if not exists public.violations (
 id uuid primary key default gen_random_uuid(), attempt_id uuid not null references public.attempts(id) on delete cascade,
 student_id uuid not null references auth.users(id), exam_id uuid not null references public.exams(id),
 violation_type text not null, occurred_at timestamptz not null default now()
);
create table if not exists public.results (
 id uuid primary key default gen_random_uuid(), exam_id uuid not null references public.exams(id),
 student_id uuid not null references auth.users(id), attempt_id uuid not null references public.attempts(id),
 score numeric not null, kktp integer not null default 75, violations integer not null default 0,
 created_at timestamptz not null default now(), unique(exam_id,student_id)
);
-- Admin role helper; profile role must be assigned securely by SQL / Edge Function.
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role='admin'); $$;
-- Create profile automatically for new auth user (default student). Admin-created account function updates profile.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id,full_name,email,role) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','Siswa'),new.email,'student') on conflict(id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
-- Enable RLS
alter table public.profiles enable row level security; alter table public.subjects enable row level security;
alter table public.questions enable row level security; alter table public.exams enable row level security;
alter table public.attempts enable row level security; alter table public.answers enable row level security;
alter table public.violations enable row level security; alter table public.results enable row level security;
-- Profiles
create policy "profiles self or admin read" on profiles for select using(id=auth.uid() or is_admin());
create policy "profiles admin insert" on profiles for insert with check(is_admin());
create policy "profiles admin update" on profiles for update using(is_admin()) with check(is_admin());
-- Public academic metadata; only admin modifies
create policy "subjects read authenticated" on subjects for select to authenticated using(true);
create policy "subjects admin all" on subjects for all to authenticated using(is_admin()) with check(is_admin());
create policy "questions read authenticated" on questions for select to authenticated using(true);
create policy "questions admin all" on questions for all to authenticated using(is_admin()) with check(is_admin());
create policy "exams read authenticated" on exams for select to authenticated using(true);
create policy "exams admin all" on exams for all to authenticated using(is_admin()) with check(is_admin());
-- Attempts / answers / violations: student can access own rows, admin can inspect all
create policy "attempts own or admin" on attempts for select using(student_id=auth.uid() or is_admin());
create policy "attempts student insert own" on attempts for insert with check(student_id=auth.uid());
create policy "attempts student update own" on attempts for update using(student_id=auth.uid() or is_admin()) with check(student_id=auth.uid() or is_admin());
create policy "answers own or admin read" on answers for select using(exists(select 1 from attempts a where a.id=attempt_id and (a.student_id=auth.uid() or is_admin())));
create policy "answers own write" on answers for insert with check(exists(select 1 from attempts a where a.id=attempt_id and a.student_id=auth.uid()));
create policy "answers own update" on answers for update using(exists(select 1 from attempts a where a.id=attempt_id and a.student_id=auth.uid())) with check(exists(select 1 from attempts a where a.id=attempt_id and a.student_id=auth.uid()));
create policy "violations own insert" on violations for insert with check(student_id=auth.uid());
create policy "violations own or admin read" on violations for select using(student_id=auth.uid() or is_admin());
create policy "results own or admin read" on results for select using(student_id=auth.uid() or is_admin());
create policy "results student insert own" on results for insert with check(student_id=auth.uid());
create policy "results student update own" on results for update using(student_id=auth.uid() or is_admin()) with check(student_id=auth.uid() or is_admin());
-- Bootstrap admin: create user in Authentication first, then replace UUID below and run.
-- update public.profiles set role='admin', full_name='Administrator CBT' where id='UUID_ADMIN_AUTH';
