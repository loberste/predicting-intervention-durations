-- based on the code provided in the MIMIC-III code repository
-- MIT-LCP/mimic-code

CREATE TABLE patientheights AS (
  with ce0 as
  (
      SELECT
        c.icustay_id
        , case
          -- convert inches to centimetres
            when itemid in (920, 1394, 4187, 3486)
                then valuenum * 2.54
              else valuenum
          end as Height
      FROM chartevents c
      inner join icustays ie
          on c.icustay_id = ie.icustay_id
          and c.charttime <= ie.intime + interval '1' day
          and c.charttime > ie.intime - interval '1' day -- some fuzziness for admit time
      WHERE c.valuenum IS NOT NULL
      AND c.itemid in (226730,920, 1394, 4187, 3486,3485,4188) -- height
      AND c.valuenum != 0
      -- exclude rows marked as error
      AND c.error <> 1
  ), ce as (
      SELECT
          icustay_id
          -- extract the median height from the chart to add robustness against outliers
          , AVG(height) as Height_chart
      from ce0
      where height > 100
      group by icustay_id
  )

  select
      ie.icustay_id
      , ce.Height_chart as Height

  from icustays ie

  left join ce
      on ie.icustay_id = ce.icustay_id
);
