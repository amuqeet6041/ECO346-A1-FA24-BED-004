# 00_prep.R: builds the analysis samples for variant 4 (KP rural)
# Run from the repository root. Other scripts load this with source("scripts/00_prep.R").

library(tidyverse)

stopifnot(file.exists("data/pslm_person_subset.csv"),
          file.exists("data/pslm_hh_subset.csv"))

person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)
hh     <- read_csv("data/pslm_hh_subset.csv",     show_col_types = FALSE)

# Variant 4 = Khyber Pakhtunkhwa (prov_code 1), rural (urban_rural 1)
VAR_PROV  <- 1
VAR_AREA  <- 1

# One row per household, only the columns we need
hh_keep <- hh |> select(hhid, hhweight, prov_code, urban_rural)
stopifnot(!anyDuplicated(hh_keep$hhid))   # hhid must be unique in the household file

# Attach weight, province and area to every person, then keep the variant
dat <- person |>
  left_join(hh_keep, by = "hhid") |>
  filter(prov_code == VAR_PROV, urban_rural == VAR_AREA)

stopifnot(!anyNA(dat$hhweight))           # every person must have a weight

# Literacy sample: age 10-64 and literate not missing
lit <- dat |>
  filter(age >= 10, age <= 64, !is.na(literate)) |>
  mutate(
    band     = floor((age - 10) / 5),             # 0..10
    band_lab = paste0(10 + 5 * band, "-", 14 + 5 * band),
    mid      = 10 + 5 * band + 2,                 # 12, 17, ..., 62
    sex_lab  = factor(sex, levels = c(1, 2), labels = c("Men", "Women"))
  )

# Students: annual education spending greater than zero
stu <- dat |> filter(ed_total > 0)

cat("Variant 4 (KP rural) | persons:", nrow(dat),
    "| literacy sample:", nrow(lit),
    "| students:", nrow(stu), "\n")