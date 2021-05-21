-- based on the code provided in the MIMIC-III code repository
-- MIT-LCP/mimic-code

CREATE TABLE patientweights AS (

  with ce as
  (
      SELECT
        c.icustay_id
        -- we take the median value from roughly first day
        -- TODO: eliminate obvious outliers if there is a reasonable weight
        -- (e.g. weight of 180kg and 90kg would remove 180kg instead of taking the median)
        , AVG(valuenum) as Weight_Admit
      FROM chartevents c
      inner join icustays ie
          on c.icustay_id = ie.icustay_id
          and c.charttime <= ie.intime + interval '1' day
          and c.charttime > ie.intime - interval '1' day -- some fuzziness for admit time
      WHERE c.valuenum IS NOT NULL
      AND c.itemid in (762,226512) -- Admit Wt
      AND c.valuenum != 0
      AND c.error <> 1
      group by c.icustay_id
  )
  , dwt as
  (
      SELECT
        c.icustay_id
        , AVG(valuenum) as Weight_Daily
      FROM chartevents c
      INNER JOIN icustays ie
          on c.icustay_id = ie.icustay_id
          and c.charttime <= ie.intime + interval '1' day
          and c.charttime > ie.intime - interval '1' day -- some fuzziness for admit time
      WHERE c.valuenum IS NOT NULL
      AND c.itemid in (763,224639) -- Daily Weight
      AND c.valuenum != 0
      -- exclude rows marked as error
      AND c.error <> 1
      group by c.icustay_id
  )

  select
      ie.icustay_id
      , round(cast(
      case
          when ce.icustay_id is not null
              then ce.Weight_Admit
          when dwt.icustay_id is not null
              then dwt.Weight_Daily
          else null end
          as DECIMAL), 2)
      as Weight

      -- components
      , ce.Weight_Admit
      , dwt.Weight_Daily

  from icustays ie

  -- admission weight
  left join ce
      on ie.icustay_id = ce.icustay_id

  -- daily weights
  left join dwt
      on ie.icustay_id = dwt.icustay_id

  order by ie.icustay_id
);
