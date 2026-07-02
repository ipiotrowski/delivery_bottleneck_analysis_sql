# Key findings

Interpretive summary of what each analysis revealed and what it means operationally. 
Each section links back to the SQL file that generated the numbers.

Numbers change if data or filters change; interpretations here reflect the state 
of the warehouse as of Phase 3.

## 01. Seller lead-time percentiles

The range across sellers is enormous. Median lead time goes from 17 hours to 371 hours across 632 sellers with at least 30 shipments. That's a 22x gap. An average per seller would collapse this into one number and hide everything useful.

Market-wide median sits at 53 hours, roughly two days. The median seller actually beats that at 50 hours. The market number is being pulled up by big sellers with high volume, not by a slow typical seller. Among the top five by volume, the biggest one (1,848 shipments) has a median of 28 hours, the fastest of the group. Volume and speed can coexist.

Two different problems hide in the tail. About 39 sellers have P90 above 300 hours, five times the market. They're structurally slow. Then there's a second pattern: sellers with P50 under 40 hours and P99 above 800. Their shipments are fast 99% of the time, but the last 1% takes a month. Different problem, different fix. First group needs coaching or removal. Second needs incident diagnosis.

The vs-market file adds the benchmark directly, so sorting by `p90_vs_market` surfaces the sellers who need attention first.

This is the case for percentiles over averages. An average lead time would rank sellers roughly the same, but wouldn't show the split between "always slow" and "usually fast with rare disasters." Those two need different operational responses. Only the distribution shows the difference.

Files: [01_seller_lead_time_percentiles.sql](01_seller_lead_time_percentiles.sql), [01b_seller_lead_time_percentiles_vs_market.sql](01b_seller_lead_time_percentiles_vs_market.sql)

## 02. Customer cohort retention

Every cohort tells the same story. M+1 retention sits between 0.2% and 0.7% for all twenty months in the dataset. No cohort behaves differently. This isn't noise, it's structure — Olist is a one-time-buyer marketplace, not a returning-customer one.

The business scaled fast. January 2017 acquired 752 customers; November 2017 acquired 7,190. Ten times more customers in ten months, and retention stayed flat. Growth came entirely from acquisition, not repeat purchases.

The strategic read is heavy. Every acquisition dollar needs to pay back on the first order, because there won't be a second one. That's a very different model from marketplaces built on repeat behavior, and it forces a specific set of choices around margin, CAC, and category mix.

Cohort analysis itself is worth flagging. Even when the finding is "flat and low," the method reveals structure a topline metric would hide. An average retention number for Olist would say the same thing without showing that it's true for every month, every cohort size, and every season. That consistency is the actual insight.

One caveat: cohorts from May 2018 onwards have less than four months of observation, and August 2018 (M+1 = 0.02%) is a survivorship artifact — new customers didn't have time to return before the dataset ended.

Files: [02_customer_cohort_retention.sql](02_customer_cohort_retention.sql), [02b_customer_cohort_retention_wide.sql](02b_customer_cohort_retention_wide.sql)

## 03. Rolling delivery trends

Delivery time isn't stable. It moves in a clear arc. First half of 2017 sits around 12 days. Summer improves to 11 as volume grows. Then Q1 2018 breaks the pattern.

Three events matter. April 2017 has a brief two-week spike to 16 days, then clears. Black Friday 2017 pulls averages up for a few weeks — 24 November alone hits over a thousand orders, roughly 3x the trend. Q1 2018 is different. Rolling 30-day peaks near 17.5 days in mid-March. The typical order took almost three weeks.

The recovery is the story. From April through August 2018 the trend goes steadily down, ending near 8 days. That's a structural improvement, not a dip. Something changed — a carrier switch, warehouse capacity, seasonal effect, or a mix. The data flags the pattern. Explaining it needs Olist context we don't have.

One caveat: the last two weeks of August 2018 look artificially fast. Slow deliveries from those days haven't been recorded yet, so the filter only shows quick ones. Ignore anything past mid-August.

Files: [03_rolling_delivery_trends.sql](03_rolling_delivery_trends.sql)