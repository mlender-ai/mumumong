-- Privileged aggregate-only report: no dreams, manuscript text, IDs or tokens.
select jsonb_build_object(
  'generated_at',now(),'jobs',(select coalesce(jsonb_object_agg(status,n),'{}'::jsonb)
    from(select status,count(*)n from public.jobs where created_at>now()-interval '24 hours' group by status)t),
  'stalled_running',(select count(*) from public.jobs where status='running' and updated_at<now()-interval '5 minutes'),
  'ready_queue',(select count(*) from public.jobs where status='queued' and available_at<=now()),
  'stages',(select coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb) from(select stage,count(*) as calls,
    round(percentile_cont(.5) within group(order by latency_ms)) as latency_p50_ms,
    round(percentile_cont(.95) within group(order by latency_ms)) as latency_p95_ms,
    coalesce(sum(cost_krw),0) as cost_krw from public.generation_runs
    where created_at>now()-interval '24 hours' group by stage)t),
  'completed_books',(select count(*) from public.completed_books),
  'recovery_cron',(select coalesce(jsonb_agg(jsonb_build_object('name',jobname,'active',active,'schedule',schedule)),'[]'::jsonb)
    from cron.job where jobname in ('wake-generation-worker','reap-zombies')),
  'cron_failures_24h',(select count(*) from cron.job_run_details r join cron.job j using(jobid)
    where j.jobname in ('wake-generation-worker','reap-zombies') and r.start_time>now()-interval '24 hours' and r.status='failed'),
  'client_funnel','not_centrally_collected','physical_device_performance','unmeasured'
) as report;
