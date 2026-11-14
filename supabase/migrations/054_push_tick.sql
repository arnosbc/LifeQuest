-- Migración 054 · El reloj de push llama a una función (requiere 050).
-- Ejecutar una vez en Supabase → SQL Editor. Se puede volver a ejecutar.
--
-- En 050 el cron guardaba un comando largo con subconsultas y comillas dentro de
-- $job$…$job$; al copiarlo a mano quedó con un error de sintaxis («syntax error
-- at or near where», 2026-11-14) y nunca llamó a push-dispatch. Ahora la lógica
-- vive en _push_tick() y el cron solo ejecuta «select public._push_tick()».
--
-- Necesita pg_cron, pg_net y los secretos del Vault de 050:
--   lifequest_project_url = https://<proyecto>.supabase.co
--   lifequest_push_secret = el mismo valor del secret PUSH_CRON_SECRET

begin;

create or replace function public._push_tick()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url
  from vault.decrypted_secrets where name = 'lifequest_project_url';
  select decrypted_secret into v_secret
  from vault.decrypted_secrets where name = 'lifequest_push_secret';
  if v_url is null or v_secret is null then
    raise exception 'push_secrets_missing'
      using hint = 'Crea lifequest_project_url y lifequest_push_secret en el Vault (050).';
  end if;
  -- Devuelve el id de la petición de pg_net (la respuesta llega a net._http_response).
  return net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/push-dispatch',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', v_secret),
    body := '{}'::jsonb);
end $$;

-- Solo el cron (postgres) la ejecuta.
revoke all on function public._push_tick() from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'lifequest_push';
    perform cron.schedule('lifequest_push', '*/5 * * * *', 'select public._push_tick()');
  else
    raise notice 'Activa pg_cron y pg_net (Database → Extensions) y vuelve a ejecutar esta migración.';
  end if;
end $$;

commit;
