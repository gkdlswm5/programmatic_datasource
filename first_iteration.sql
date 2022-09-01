create temp table programmatic_bi as (
select
    pp.date as view_date,
    pp.dt_hour as view_hour,
    pp.company_id as client_id,
    cl.client_name as client_name,
    cl.client_slug as client_slug,
    pp.campaign_id as campaign_id,
    cm.campaign_name as campaign_name,
    cm.campaign_start_date::timestamp::date as campaign_start_date_inclusive,
    cm.campaign_end_date::timestamp::date as campaign_end_date_exclusive,
    cm.budget as budget,
    --case when logic as Xandr and Beeswax pulls different data from different sources
    (case
        when pp.dsp = 'Xandr' then xli.line_item_name
        --beeswax no dealID. Datasource: programmatic_bi.beeswax_deal
        when pp.dsp = 'Beeswax' then null::varchar
        end
        ) as line_item_name,
    (case
        when pp.dsp = 'Xandr' then pp.dsp_deal_id
        --beeswax no dealID. Datasource: programmatic_bi.beeswax_deal
        when pp.dsp = 'Beeswax' then pp.dsp_deal_id
        end
        ) as deal_name,
    (case
        when pp.dsp = 'Xandr' then xsm.xandr_seller_member_name
        when pp.dsp = 'Beeswax' then null::varchar
        end
        ) as seller,
    (case
        when pp.dsp = 'Xandr' then xs.xandr_split_name
        when pp.dsp = 'Beeswax' then null::varchar
        end
        ) as split,
    (case
        when pp.dsp = 'Xandr' then xp.xandr_publisher_name
        when pp.dsp = 'Beeswax' then bp.beeswax_publisher_name
        end
        ) as DSP_specific_publisher_name,
    pp.dsp_publisher_id as publisher_id,
    (case
        when pp.dsp = 'Xandr' then xp.xandr_publisher_name
        when pp.dsp = 'Beeswax' then bp.beeswax_publisher_name
        end
        ) as publisher_name,
    (case
        --xandr no code
        when pp.dsp = 'Xandr' then xp.xandr_publisher_code
        --beeswax no code
        when pp.dsp = 'Beeswax' then null::varchar
        end
        ) as publisher_code,
    pp.upper_metric_id,
    (case
        when pp.upper_metric_id = m.id then m.type
        end
        ) as upper_metric_type,
    pp.down_metric_id,
    (case
        when pp.down_metric_id = m.id then m.type
        end
        ) as lower_metric_type,
    p.publisher_family as publisher_family,
    pp.creative_isci as isci,
    c2.creative_name as creative_name,
    pp.spend,
    pp.impressions as impressions,
    pp.lift_ct as incremental_session_lift_clickthrough,
    pp.lift_nct as incremental_session_lift_non_clickthrough,
    pp.lift as incremental_session_lift,
    pp.vt_1d,
    pp.vt_7d,
    pp.vt_28d,
    --incremental_sale_lift
    pp.conversions,
    --1d sale
    pp.tatari_vt_1d,
    --7d sale
    pp.tatari_vt_7d,
    --28d sale
    pp.tatari_vt_28d
from programmatic_bi.programmatic_performance pp

    --primary conversion
    left join philo.companies com on com.id = pp.company_id

    --joins
    left join programmatic_bi.client cl on cl.id = pp.company_id
    left join programmatic_bi.campaign cm on cm.campaign_extreme_reach_id = pp.campaign_id
    left join programmatic_bi.publisher p on p.id = pp.dsp_publisher_id
    left join programmatic_bi.creative c2 on c2.creative_isci = pp.creative_isci
    left join philo.conversion_metrics m on m.company_id = pp.company_id

    --Xandr tables
    left join programmatic_bi.xandr_line_item xli on xli.line_item_id = pp.dsp_line_item_id
    left join programmatic_bi.xandr_seller_member xsm on xsm.xandr_seller_member_id = pp.dsp_seller_member_id
    left join programmatic_bi.xandr_split xs on xs.xandr_split_id = pp.dsp_split_id
    left join programmatic_bi.xandr_publisher xp on xp.xandr_publisher_id = pp.dsp_publisher_id
    left join programmatic_bi.xandr_deal xd on xd.xandr_deal_id = pp.dsp_deal_id

    --Beeswax tables
    left join programmatic_bi.beeswax_line_item bli on bli.beeswax_line_item_id = pp.dsp_line_item_id
    left join programmatic_bi.beeswax_publisher bp on bp.beeswax_publisher_id = pp.dsp_publisher_id
    left join philo.companies c on pp.company_id = c.id

--audit
where client_slug='opendoor' and view_date between '2022-05-09' and '2022-05-15' and c.primary_conversion_metric_id=pp.upper_metric_id and c.secondary_conversion_metric_id=pp.down_metric_id)

select
    upper_metric_id,
    client_name,
    view_date,
    sum(spend)
from programmatic_bi
group by 1,2,3
