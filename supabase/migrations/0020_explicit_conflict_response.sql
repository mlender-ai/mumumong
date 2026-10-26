-- Business conflicts are not transaction serialization failures. PostgREST14
-- retries SQLSTATE40001 indefinitely; PT409 returns immediately as HTTP409.
-- https://supabase.com/docs/guides/troubleshooting/high-cpu-and-infinite-transaction-retries-when-using-custom-error-codes-in-rpc-functions-77326b
do $$
declare signature regprocedure; definition text;
begin
  foreach signature in array array[
    'public.user_update_generation_settings(uuid,integer,uuid,public.adaptation_level,public.writing_style,public.narrative_voice)'::regprocedure,
    'public.complete_volume_book(uuid,uuid,text,text,text)'::regprocedure
  ] loop
    definition:=pg_get_functiondef(signature);
    execute replace(definition,'''40001''','''PT409''');
  end loop;
end $$;
