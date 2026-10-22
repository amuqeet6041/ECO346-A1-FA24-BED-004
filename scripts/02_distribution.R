# 02_distribution.R: weighted histogram of annual education spending (Q2)
source("scripts/00_prep.R")
library(svglite)
library(scales)

# Weighted quantile, exactly as the assignment defines it:
# sort by x, take cumulative share of weight, return smallest x where share >= p
wq <- function(x, w, p) {
  o  <- order(x)
  x  <- x[o]; w <- w[o]
  cs <- cumsum(w) / sum(w)
  x[which(cs >= p - 1e-12)[1]]      # tiny tolerance for floating-point error
}

# ---- Statistics on ALL students ----
n_students <- nrow(stu)
med_w   <- wq(stu$ed_total, stu$hhweight, 0.5)
p10_w   <- wq(stu$ed_total, stu$hhweight, 0.1)
p90_w   <- wq(stu$ed_total, stu$hhweight, 0.9)
med_unw <- median(stu$ed_total)           # unweighted median (weights ignored)
ratio   <- p90_w / p10_w

# ---- Histogram data: only students between Rs 100 and Rs 1,000,000 ----
stu <- stu |> mutate(lx = log10(ed_total))
inr <- stu |> filter(lx >= 2, lx <= 6)
n_excl <- n_students - nrow(inr)

# Bins 0.1 wide from 2.0 to 6.0 = 40 bins (0..39). round() protects values on bin edges.
inr <- inr |> mutate(bin = pmin(floor(round((lx - 2) / 0.1, 8)), 39))

hist_df <- inr |>
  group_by(bin) |>
  summarise(w = sum(hhweight), .groups = "drop") |>
  complete(bin = 0:39, fill = list(w = 0)) |>
  mutate(left = 2 + 0.1 * bin,
         mid  = left + 0.05,
         dens = (w / sum(w)) / 0.1)        # density per log10 unit

fmt <- function(x) format(round(x), big.mark = ",", trim = TRUE)

p <- ggplot(hist_df, aes(mid, dens)) +
  geom_col(width = 0.1, fill = "grey60", colour = "white") +
  geom_vline(xintercept = log10(c(med_w, p90_w)), linetype = "dashed") +
  annotate("text", x = log10(med_w), y = max(hist_df$dens),
           label = paste0("Median: Rs ", fmt(med_w)), hjust = 1.05, vjust = 1) +
  annotate("text", x = log10(p90_w), y = max(hist_df$dens),
           label = paste0("90th pct: Rs ", fmt(p90_w)), hjust = -0.05, vjust = 1) +
  scale_x_continuous(breaks = 2:6,
                     labels = paste0("Rs ", format(10^(2:6), big.mark = ",", trim = TRUE)),
                     limits = c(2, 6)) +
  labs(
    title = paste0("Half of rural KP students cost families Rs ", fmt(med_w),
                   " a year or less; the top tenth spend Rs ", fmt(p90_w), " or more"),
    x = "Annual education spending per student (log scale)",
    y = "Density per log10 unit",
    caption = paste0("Source: PSLM 2019-20 person file. Sample: students in rural KP with ",
                     "education spending above zero (n = ", fmt(n_students), "). Weighted by hhweight.\n",
                     fmt(n_excl), " students outside Rs 100 to Rs 1,000,000 are excluded from the histogram; ",
                     "median and percentiles use all students.")
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 12),
        plot.title.position = "plot", plot.caption = element_text(hjust = 0),
        plot.caption.position = "plot", panel.grid.minor = element_blank())

dir.create("figures", showWarnings = FALSE)
ggsave("figures/distribution.svg", p, width = 9, height = 5.5)

cat("\nStudents:", n_students,
    "\nWeighted median:", med_w, "| Unweighted median:", med_unw,
    "\nWeighted p10:", p10_w, "| p90:", p90_w, "| ratio:", round(ratio, 2),
    "\nExcluded from histogram:", n_excl, "\n")