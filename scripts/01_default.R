# 01_default.R: R's untouched default scatterplot of literate against age (Q4)
source("scripts/00_prep.R")
library(ggplot2)
library(svglite)

dir.create("figures", showWarnings = FALSE)

p <- ggplot(lit, aes(age, literate)) + geom_point()

ggsave("figures/default.svg", p)