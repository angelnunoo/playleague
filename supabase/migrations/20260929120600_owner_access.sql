-- Security definer functions run as the table owner. Force RLS would block
-- those writes because clients have no insert/update policies on match data.
-- Clients still cannot write: grants are revoked and remaining policies hide rows.

alter table public.user_stats no force row level security;
alter table public.games no force row level security;
alter table public.quiz_questions no force row level security;
alter table public.quiz_answers no force row level security;
alter table public.impostor_secrets no force row level security;

revoke insert, update, delete on public.match_cards from anon, authenticated;
revoke insert, update, delete on public.impostor_secrets from anon, authenticated;
revoke insert, update, delete on public.impostor_votes from anon, authenticated;
revoke insert, update, delete on public.taboo_turns from anon, authenticated;
revoke insert, update, delete on public.taboo_events from anon, authenticated;
revoke insert, update, delete on public.quick_events from anon, authenticated;
revoke insert, update, delete on public.quiz_questions from anon, authenticated;
revoke insert, update, delete on public.quiz_answers from anon, authenticated;
revoke insert, update, delete on public.impostor_words from anon, authenticated;
revoke insert, update, delete on public.taboo_cards from anon, authenticated;
revoke insert, update, delete on public.quick_questions from anon, authenticated;
revoke select on public.quiz_questions from anon, authenticated;
revoke select on public.quiz_answers from anon, authenticated;
revoke select on public.impostor_secrets from anon, authenticated;
revoke select on public.impostor_words from anon, authenticated;
revoke select on public.match_cards from anon, authenticated;
