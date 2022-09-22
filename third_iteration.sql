create temp table Xandrtest as (
with upper_funnel as (
select pp.date as view_date,
    pp.company_id as client_id,
    c.slug as client_slug,
    xli.line_item_name,
    pp.dsp_deal_id  as deal_name,
    xsm.xandr_seller_member_name as seller,
   xs.xandr_split_name  as split,
    xp.xandr_publisher_name  DSP_specific_publisher_name,
    pp.upper_metric_id,
     (case when pp.upper_metric_id=m.id and is_top_funnel_metric=TRUE then m.type end) as metric_type,
    pp.spend,
    --check impression (from xppf or pp)
    pp.impressions as impressions,
    pp.lift_ct as incremental_session_lift_clickthrough,
    pp.lift_nct as incremental_session_lift_non_clickthrough,
    pp.lift as incremental_session_lift,
    pp.vt_1d,
    pp.vt_7d,
    pp.vt_28d,
    pp.tatari_vt_1d,
    pp.tatari_vt_7d,
    pp.tatari_vt_28d
from programmatic_bi.programmatic_performance pp
join philo.companies c on pp.company_id = c.id
left join programmatic_bi.campaign cm on pp.campaign_id = cm.id
left join programmatic_bi.xandr_line_item xli on xli.line_item_id = pp.dsp_line_item_id
left join programmatic_bi.xandr_seller_member xsm on xsm.xandr_seller_member_id = pp.dsp_seller_member_id
left join programmatic_bi.xandr_split xs on xs.xandr_split_id = pp.dsp_split_id
left join programmatic_bi.xandr_publisher xp on xp.xandr_publisher_id = pp.dsp_publisher_id
left join programmatic_bi.xandr_deal xd on xd.xandr_deal_id = pp.dsp_deal_id
left join programmatic_bi.beeswax_publisher bp on bp.beeswax_publisher_id = pp.dsp_publisher_id
left join programmatic_bi.beeswax_line_item bli on pp.dsp_line_item_id=bli.beeswax_line_item_id
join philo.conversion_metrics m on pp.upper_metric_id=m.id
where pp.week>'2022-07-01' and c.slug='opendoor' and pp.dsp='Xandr'),

down_funnel as (
select pp.date as df_view_date,
    pp.company_id as df_client_id,
    c.slug as df_client_slug,
    json_extract_path_text(m.parameters, 'basis_metric_id') as basis_metric_id,
    case when m.id=pp.down_metric_id and m.is_top_funnel_metric=FALSE then m.type end as df_metric,
    pp.conversions,
    pp.conversions_ct,
    pp.conversions_nct,
    pp.vtc_1d,
    pp.vtc_7d,
    pp.vtc_28d,
    pp.tatari_vtc_1d,
    pp.tatari_vtc_7d,
    pp.tatari_vtc_28d
from programmatic_bi.programmatic_performance pp
join philo.companies c on pp.company_id = c.id
join philo.conversion_metrics m on pp.down_metric_id=m.id
where pp.week>'2022-07-01'and slug='opendoor' and pp.dsp='Xandr')

select *
from upper_funnel as uf
left join down_funnel as df on uf.client_id=df.df_client_id and uf.upper_metric_id=df.basis_metric_id)

select *
from Xandrtest
limit 100
