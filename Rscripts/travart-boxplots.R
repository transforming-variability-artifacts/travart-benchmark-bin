library(ggpubr)
library(dplyr)
library(readr)
library(purrr)
library(scales)
library(rstatix)
library(report)
library(crayon) # For better readability

files = list.files("../benchmarks", 
                   include.dirs = FALSE, recursive = FALSE, full.names = TRUE,
                   pattern="*.csv")

tuple_list <- lapply(files, function(fn){
  
  df <- read.csv(fn, stringsAsFactors = FALSE)

  nm <- tools::file_path_sans_ext(basename(fn))
  
  list(
    dataset      = df,
    dataset_name = nm
  )
})

make_boxplot <- function(dataset, dataset_name) {
  
  cat(red$bold("Now processing", dataset_name, "\n"))

  # Replace assigned dataset for different plots
  benchmark_data <- dataset

  # Can be used across all datasets, only affects reverse DOPLER datasets
  benchmark_data <- benchmark_data %>% mutate(targetType = recode(targetType, "uvl" = "DOPLER"))
  benchmark_data$targetType <- as.factor(benchmark_data$targetType)

  #benchmark_data$result <- factor(benchmark_data$result)
  #print(summary(benchmark_data$result))
  
  tab <- table(benchmark_data$targetType,
             benchmark_data$result)
  
  print(tab)
  
  #print(shapiro.test(benchmark_data$initialSize))
  
  benchmark_data <- na.omit(benchmark_data)
  cat("Missing measurements (#NA):", (nrow(dataset) - nrow(benchmark_data)), "\n")

  # General ANOVA: Any stat. signif. difference between groups?
  res_aov <- aov(log10(avgTransformationTime) ~ targetType,
    data = benchmark_data)
  
  #res_k <- kruskal.test(log10(avgTransformationTime) ~ targetType,
  #                      data = benchmark_data)
  
  print(report(res_aov))
  #print(report(res_k, data = benchmark_data))
  print(levene_test(log10(avgTransformationTime) ~ targetType,
              data = benchmark_data))
  
  # Mean comparison for ranking
  tukey <- TukeyHSD(res_aov)
  print(tukey)
  
  # Actual pairwise significance test with Wilcoxon rank sum/t-test
  #res <- pairwise.wilcox.test(log10(benchmark_data$avgTransformationTime), benchmark_data$targetType, p.adjust.method = "bonferroni")
  res_t <- pairwise.t.test(log10(benchmark_data$avgTransformationTime), benchmark_data$targetType, p.adjust.method = "bonferroni")

  #print(res)
  print(res_t)
  
  cat("Mean model size:",  mean(benchmark_data$initialSize), "- IQR:", IQR(benchmark_data$initialSize), "\n")
  cat(bold("Above values only relevant if dataset has no omissions!\n"))
  
  # Only used if geom_signif is not commented out!
  my_comparisons = combn(as.character(unique(benchmark_data$targetType)), 2, simplify=FALSE) 
  
  boxplot <- ggplot(benchmark_data, 
                    aes(x = benchmark_data$targetType, y = (benchmark_data$avgTransformationTime)/1000, fill = benchmark_data$targetType)) +
    stat_boxplot(geom = "errorbar", width = 0.5, linetype = 1) +
    geom_boxplot(outlier.shape = "cross") +
    scale_y_log10(labels = label_number(), breaks = c(0.1, 1, 10, 100, 1000, 10000, 100000)) +
    geom_hline(yintercept=5000, size = 1, color = "cyan") + # Five-second mark
    geom_hline(yintercept=1000, size = 1, color = "magenta") + # One-second mark
    #stat_summary(fun = mean, colour="darkred", geom="point", shape=18, size=3, show.legend=FALSE) + 
    annotation_logticks(sides = "l") +
    scale_x_discrete(limits = c("DOPLER", "FeatureIDE", "Kconfig")) +
    scale_fill_manual(values = c("DOPLER" = "green", "FeatureIDE" = "orange", "Kconfig" = "blue")) +
    labs(x = "Plugin", y = "Avg. transformation time (milliseconds)") +
    coord_cartesian(ylim = c(0.1,100000)) +
    theme_linedraw() +
#    geom_signif(comparisons = my_comparisons,
#                test.args = list(var.equal = FALSE),
#                step_increase = 0.01,
#                margin_top = .1,
#                test = t.test,
#                map_signif_level=TRUE) +
    theme(legend.position = "none")
  
  ggsave(filename = paste0(dataset_name, "_boxplot.png"), plot = boxplot, width = 1200, height = 1800, units = "px", bg = "white", dpi = "print")
  cat("---\n")

}

for (tuple in tuple_list) {
  make_boxplot(tuple[[1]], tuple[[2]])
}