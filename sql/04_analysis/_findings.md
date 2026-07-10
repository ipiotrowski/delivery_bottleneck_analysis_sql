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

Every cohort tells the same story. M+1 retention sits between 0.2% and 0.7% for all twenty months in the dataset. No cohort behaves differently. This isn't noise - Olist is a one-time-buyer marketplace, not a returning-customer one.

The business scaled fast. January 2017 acquired 752 customers; November 2017 acquired 7,190. Ten times more customers in ten months, and retention stayed flat. Growth came entirely from acquisition, not repeat purchases.

The strategic read is heavy. Every acquisition dollar needs to pay back on the first order, because there won't be a second one. That's a very different model from marketplaces built on repeat behavior, and it forces a specific set of choices around margin, CAC, and category mix.

Cohort analysis itself is worth flagging. Even when the finding is "flat and low," the method reveals structure a topline metric would hide. An average retention number for Olist would say the same thing without showing that it's true for every month, every cohort size, and every season. That consistency is the actual insight.

One caveat: cohorts from May 2018 onwards have less than four months of observation, and August 2018 (M+1 = 0.02%) is a survivorship artifact - new customers didn't have time to return before the dataset ended.

Files: [02_customer_cohort_retention.sql](02_customer_cohort_retention.sql), [02b_customer_cohort_retention_wide.sql](02b_customer_cohort_retention_wide.sql)

## 03. Rolling delivery trends

Delivery time isn't stable. It moves in a clear arc. First half of 2017 sits around 12 days. Summer improves to 11 as volume grows. Then Q1 2018 breaks the pattern.

Three events matter. April 2017 has a brief two-week spike to 16 days, then clears. Black Friday 2017 pulls averages up for a few weeks - 24 November alone hits over a thousand orders, roughly 3x the trend. Q1 2018 is different. Rolling 30-day peaks near 17.5 days in mid-March. The typical order took almost three weeks.

The recovery is the story. From April through August 2018 the trend goes steadily down, ending near 8 days. That's a structural improvement, not a dip. Something changed - a carrier switch, warehouse capacity, seasonal effect, or a mix. The data flags the pattern. Explaining it needs Olist context we don't have.

One caveat: the last two weeks of August 2018 look artificially fast. Slow deliveries from those days haven't been recorded yet, so the filter only shows quick ones. Ignore anything past mid-August.

Files: [03_rolling_delivery_trends.sql](03_rolling_delivery_trends.sql)

## 04. Sequence gap analysis

One stage dominates. Median time from carrier pickup to customer delivery is 171 hours, about 7 days. The other two stages combined take 45 hours. That's roughly 80% of delivery time sitting in transit, not in seller or payment processing.

The other numbers add texture. Purchase to approval is essentially instant, median 1 hour. That's the payment gateway working. The tail matters though - P99 hits 90 hours, meaning a small share of orders sits in payment limbo for four days.

Approved to carrier is the seller stage. Median 44 hours, average 66. This matches the marketplace-wide seller lead time from analysis 01 (median 53h). Most sellers ship within two days of getting the order. The P99 of 398 hours flags the same tail behavior we saw before: rare disaster shipments taking weeks.

Carrier to customer is the real bottleneck. Median 7 days, P90 nearly 3 weeks, P99 over 40 days. Brazil is huge and the courier network handles the geography, not the platform. If Olist wants to cut delivery time, this is where the leverage sits - it's carrier selection, regional warehouses, or last-mile partnerships.

Sequence gap analysis works because it splits a single "delivery time" number into components with different owners. Any effort to make delivery faster starts with knowing which stage to attack. This shows that seller pressure alone won't move the needle much - the transit stage runs the show.

Files: [04_sequence_gap_analysis.sql](04_sequence_gap_analysis.sql)

## 05. Geographic analysis

Geography drives delivery time more than anything else in the marketplace. Same-state orders arrive in 4 to 9 days depending on the state. Cross-state orders take 10 to 26 days. Every state without exception delivers faster to its own residents than to anyone else.

The penalty varies by state. SP customers pay 1.5x more time for cross-state orders. Goiás customers pay 3x. The further from the seller hub, the steeper the multiplier. This isn't about kilometers alone, it's about infrastructure between the seller region and the customer region.

SP's dominance is impossible to miss. 31,000 same-state shipments in SP alone - that's a third of every shipment in the analysis. Nine states have enough local sellers to even show up with a same_state row. The other eighteen states only receive cross-state orders because there aren't enough sellers living there.

The extreme cases sit in the North. Amazonas, Roraima, Amapá - median delivery hits 24 to 26 days. But volumes are tiny: 40 to 145 orders each. The map shows a real infrastructure problem, but it affects a small slice of the business. Any warehouse expansion decision needs to weigh delivery improvement against the volume that would actually benefit.

Geographic analysis is the answer to a question that topline metrics can't touch. A single "12 day average delivery" number hides that some customers wait 4 days and others wait a month, and that the difference comes from where they live and where their seller lives. Splitting by geography turns a flat number into a map of who wins and who loses in the current network.

Files: [05_geographic_analysis.sql](05_geographic_analysis.sql)

## 06. Top sellers by category

This one is mostly a technique demo. Three ranking functions applied to the same partition show three different behaviors on ties, and the results make it obvious when each function is the right choice.

Take the `air_conditioning` category. Two sellers tie with 26 items sold each. ROW_NUMBER gives them positions 2 and 3, arbitrarily. RANK gives them both 2, then skips to 4. DENSE_RANK gives them both 2, then continues at 3. Same data, three different top-5 lists. That's the whole point.

The rule of thumb:

- **ROW_NUMBER** when you need exactly N rows and ties don't matter. Pagination, or when "top 5" means "5 sellers, pick anyone if they tie."
- **RANK** when ranking positions with tie-aware gaps matter. Standard for sports leaderboards and legal rankings.
- **DENSE_RANK** when you want top N levels of the metric, taking everyone who reaches each level. Best when "top 5" means "all sellers in the top 5 tiers," not "exactly 5 rows."

The business layer is thinner but not empty. 73 categories produce 425 rows across the top-5 lists, spread across 330 unique sellers. That's fragmentation. No single seller dominates across categories. The biggest single-category leader is a garden tools seller with 1,881 items sold. Categories with real volume have clear leaders. Niche categories like music and arts_and_craftmanship have so many sellers tied at 1 or 2 items that the top-5 balloons to 10-19 rows regardless of function.

Which brings the technique back into focus. In categories with real volume differences, all three functions look similar. It's the tied, low-volume niches that expose why the choice of ranking function matters. Getting the wrong one silently changes what "top 5" means.

Files: [06_top_sellers_by_category.sql](06_top_sellers_by_category.sql)