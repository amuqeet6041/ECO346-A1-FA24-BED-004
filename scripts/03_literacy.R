# 03_literacy.R: weighted literacy rate by age band and sex (Q3)
# Run from the repository root.
source("scripts/00_prep.R")
library(svglite)

# ---- Band table: n and weighted literacy rate for each band and sex ----
tab <- lit |>
  group_by(band, band_lab, mid, sex_lab) |>
  summarise(n    = n(),
            rate = 100 * sum(hhweight * literate) / sum(hhweight),  # weighted mean of 0/1, in %
            .groups = "drop") |>
  mutate(thin = n < 30)                                              # thin cell = fewer than 30 people

# ---- Gap between men and women in each band ----
gap <- tab |>
  select(band_lab, mid, sex_lab, rate) |>
  pivot_wider(names_from = sex_lab, values_from = rate) |>
  mutate(gap = Men - Women)

top <- gap |> slice_max(abs(gap), n = 1)    # band with the largest gap

# ---- Plot ----
ends <- tab |> filter(band == 10)           # right-hand end of each line, for direct labels

p <- ggplot(tab, aes(mid, rate, colour = sex_lab, group = sex_lab)) +
  geom_line(linewidth = 0.8) +
  geom_point(aes(shape = thin), size = 3, stroke = 1) +
  scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 1)) +          # filled = normal, hollow = thin
  scale_colour_manual(values = c(Men = "#1b6ca8", Women = "#c0392b")) +
  geom_text(data = ends, aes(label = sex_lab), hjust = -0.3, fontface = "bold") +
  geom_segment(data = top, inherit.aes = FALSE,
               aes(x = mid, xend = mid, y = Women, yend = Men), colour = "grey30") +
  annotate("text", x = top$mid, y = (top$Men + top$Women) / 2, hjust = -0.1,
           label = paste0("Largest gap, ", top$band_lab, ":\n",
                          sprintf("%.1f", abs(top$gap)), " percentage points")) +
    scale_x_continuous(breaks = seq(12, 62, 5),
                   labels = paste0(seq(10, 60, 5), "-", seq(14, 64, 5)),
                   expand = expansion(add = c(1, 7))) +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0.02, 0.02))) +
  labs(
    title = paste0("In rural KP the literacy gap between men and women is widest at ages ",
                   top$band_lab, ": ", sprintf("%.1f", top$Men), "% of men vs ",
                   sprintf("%.1f", top$Women), "% of women"),
    x = "Age band (years)",
    y = "Literacy rate (%)",
    caption = paste0("Source: PSLM 2019-20 person file. Sample: persons aged 10-64 in rural KP with ",
                     "non-missing literacy (n = ", format(nrow(lit), big.mark = ","), "). ",
                     "Weighted by hhweight.\nHollow markers would show cells with fewer than 30 ",
                     "observations; no cell is that thin here.")
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", size = 12),
        plot.title.position = "plot",
        plot.caption = element_text(hjust = 0),
        plot.caption.position = "plot",
        panel.grid.minor = element_blank())

dir.create("figures", showWarnings = FALSE)
ggsave("figures/literacy.svg", p, width = 9, height = 5.5)

# ---- Band table for the README ----
band_table <- tab |>
  select(band_lab, sex_lab, n, rate) |>
  mutate(rate = round(rate, 1)) |>
  pivot_wider(names_from = sex_lab, values_from = c(n, rate)) |>
  select(band = band_lab, n_Women, rate_Women, n_Men, rate_Men)
write.csv(band_table, "figures/band_table.csv", row.names = FALSE)

# ---- Print the numbers for the form ----
print(as.data.frame(band_table))
get <- function(b, s) sprintf("%.1f", tab$rate[tab$band_lab == b & tab$sex_lab == s])
cat("\n===== Q3 RESULTS (KP rural) =====\n")
cat("15-19: women", get("15-19", "Women"), "| men", get("15-19", "Men"), "\n")
cat("55-59: women", get("55-59", "Women"), "| men", get("55-59", "Men"), "\n")
cat("Largest gap band:", top$band_lab, "| gap:", sprintf("%.1f", abs(top$gap)), "points\n")