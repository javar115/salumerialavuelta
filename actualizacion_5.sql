-- Salumería La Vuelta: actualización 5 (estados de pedido y cobro)
-- Ejecutar completo, una sola vez, en Supabase > SQL Editor

-- 1) Nuevo estado "preparacion" (se elimina el control anterior del estado y se crea uno nuevo)
do $$
declare c text;
begin
  for c in
    select conname from pg_constraint
    where conrelid = 'public.pedidos'::regclass and contype = 'c'
      and pg_get_constraintdef(oid) like '%estado%'
  loop
    execute format('alter table pedidos drop constraint %I', c);
  end loop;
end $$;

alter table pedidos add constraint pedidos_estado_check
  check (estado in ('borrador','enviado','preparacion','entregado','cancelado'));

-- 2) Cobro, independiente del estado de entrega
alter table pedidos
  add column cobro text not null default 'por_cobrar' check (cobro in ('por_cobrar','cobrado')),
  add column cobrado_at timestamptz;

-- 3) Solo el administrador puede cambiar el cobro
create or replace function pedidos_before_update() returns trigger
language plpgsql security definer as $$
begin
  if not es_admin() then
    if old.estado <> 'borrador' or new.estado not in ('borrador','enviado','cancelado') then
      raise exception 'Cambio de estado no permitido';
    end if;
    new.persona_id := old.persona_id;
    new.cobro := old.cobro;
    new.cobrado_at := old.cobrado_at;
  end if;
  if new.estado = 'enviado' and old.estado = 'borrador' then
    new.numero := to_char(now() at time zone 'America/Argentina/Buenos_Aires','YYMMDD')
                  || '-' || lpad(nextval('pedido_seq')::text, 5, '0');
    new.enviado_at := now();
  end if;
  if new.cobro = 'cobrado' and old.cobro <> 'cobrado' then
    new.cobrado_at := now();
  elsif new.cobro = 'por_cobrar' then
    new.cobrado_at := null;
  end if;
  return new;
end $$;
