# 02_distribution.R: weighted histogram of annual education spending (Q2)
source("scripts/00_prep.R")
library(svglite)
library(scales)

# Weighted quantile (assignment definition): sort, cumulative weight share,
# smallest x where the share reaches p
wq <- function(x, w, p) {
  o  <- order(x)
  cs <- cumsum(w[o]) / sum(w)
  x[o][which(cs >= p - 1e-12)[1]]
}

# Statistics on ALL students
n_students <- nrow(stu)
med_w   <- wq(stu$ed_total, stu$hhweight, 0.5)
p10_w   <- wq(stu$ed_total, stu$hhweight, 0.1)
p90_w   <- wq(stu$ed_total, stu$hhweight, 0.9)
med_unw <- median(stu$ed_total)
ratio   <- p90_w / p10_w

# Histogram sample: Rs 100 to Rs 1,000,000
inr    <- stu |> mutate(lx = log10(ed_total)) |> filter(lx >= 2, lx <= 6)
n_excl <- n_students - nrow(inr)

fmt <- function(x) format(round(x), big.mark = ",", trim = TRUE, scientific = FALSE)

p <- ggplot(inr, aes(lx, weight = hhweight)) +
  geom_histogram(aes(y = after_stat(density)),
                 binwidth = 0.1, boundary = 2, closed = "left",
                 fill = "grey60", colour = "white") +
  geom_vline(xintercept = log10(c(med_w, p90_w)), linetype = "dashed") +
  annotate("text", x = log10(med_w), y = Inf, vjust = 1.5, hjust = 1.05,
           label = paste0("Median: Rs ", fmt(med_w))) +
  annotate("text", x = log10(p90_w), y = Inf, vjust = 1.5, hjust = -0.05,
           label = paste0("90th pct: Rs ", fmt(p90_w))) +
  scale_x_continuous(breaks = 2:6,
                     labels = label_number(prefix = "Rs ", big.mark = ",")(10^(2:6))) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  coord_cartesian(xlim = c(2, 6)) +
  labs(
    title = paste0("Half of rural KP students cost families Rs ", fmt(med_w),
                   " a year or less; the top tenth spend Rs ", fmt(p90_w), " or more"),
    x = "Annual education spending per student (log scale)",
    y = "Density per log10 unit",
    caption = paste0(
      "Source: PSLM 2019-20 person file. Sample: students in rural KP with ",
      "education spending above zero (n = ", fmt(n_students), "). Weighted by hhweight.\n",
      fmt(n_excl), " students outside Rs 100 to Rs 1,000,000 are excluded from the histogram; ",
      "median and percentiles use all students.")
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 12),
        plot.title.position = "plot",
        plot.caption = element_text(hjust = 0),
        plot.caption.position = "plot",
        panel.grid.minor = element_blank())

dir.create("figures", showWarnings = FALSE)
ggsave("figures/distribution.svg", p, width = 9, height = 5.5)



    # ---- Numbers for the README and the Google Form ----
cat("\n===== Q2 RESULTS (KP rural) =====\n")
cat("Number of students:        ", n_students, "\n")
cat("Weighted median (Rs):      ", med_w, "\n")
cat("Unweighted median (Rs):    ", med_unw, "\n")
cat("Weighted 10th pct (Rs):    ", p10_w, "\n")
cat("Weighted 90th pct (Rs):    ", p90_w, "\n")
cat("Ratio p90 / p10:           ", sprintf("%.2f", ratio), "\n")
cat("Excluded from histogram:   ", n_excl, "\n")