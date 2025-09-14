library(dplyr)
library(ggplot2)
source("travart-scatter.R")

# 7 control graphs
# DOPLER-to-UVL, old vs. new size definition
# Native vs. transformed DOPLER-to-UVL
# Native vs. transformed Kconfig-to-UVL
# Linux dataset: UVL-to-Kconfig
# Linux dataset: UVL-to-FeatureIDE
# UVL-to-Kconfig, with or without complexity factor

data_dm2uvl <- read.csv(
  "~/envdev/repos/travart-core/benchmarks_new/merged-by-path/average_transformation_times(dm2uvl).csv",
  stringsAsFactors = FALSE
)

data_dm2uvl_old <- read.csv(
  "~/envdev/repos/travart-core/benchmarks/merged-by-path/average_transformation_times(dm2uvl).csv",
  stringsAsFactors = FALSE
)

data_dm2uvl_rt <- read.csv(
  "~/envdev/repos/travart-core/benchmarks_new/merged-by-path/average_transformation_times(roundtrip@dopler_backward).csv",
  stringsAsFactors = FALSE
)

data_dm2uvl_rt_old <- read.csv(
  "~/envdev/repos/travart-core/benchmarks/merged-by-path/average_transformation_times(roundtrip@dopler_backward).csv",
  stringsAsFactors = FALSE
)

data_dm2uvl_doctored <- data_dm2uvl
data_dm2uvl_rt_doctored <- data_dm2uvl_rt

data_dm2uvl_doctored$initialSize <- data_dm2uvl_old$initialSize[match(data_dm2uvl_doctored$fileName, data_dm2uvl_old$fileName)]
cat("Doctoring data, check #NA rows:", sum(!complete.cases(data_dm2uvl)), "=", sum(!complete.cases(data_dm2uvl_doctored)), "?\n")
data_dm2uvl_rt_doctored$initialSize <- data_dm2uvl_rt_old$initialSize[match(data_dm2uvl_rt_doctored$fileName, data_dm2uvl_rt_old$fileName)]
cat("Doctoring data, check #NA rows:", sum(!complete.cases(data_dm2uvl_rt)), "=", sum(!complete.cases(data_dm2uvl_rt_doctored)), "?\n")

analyze_and_plot(data_dm2uvl_doctored, "dm2uvl_old", "Model size (#decisions)")
analyze_and_plot(data_dm2uvl_rt_doctored, "dm2uvl-rt_old", "Model size (#decisions)")

  # If there is complexity data, try weighing model size
#  if (hasName(trimmed_data, "complexity") & mean(trimmed_data$complexity) > 0) {
#    cat("Weighing by complexity...\n")
#    trimmed_data$initialSize <- trimmed_data$initialSize * pmax(log10(trimmed_data$complexity) + 1, 1)
#    trimmed_data <- trimmed_data[trimmed_data$complexity > 0, ]
#    trimmed_data <- subset(trimmed_data, select = -c(complexity))
#    
#    model_complexity <- lm(avgTransformationTime/1000 ~ (initialSize*pmax(log10(complexity)+1, 1)), data = trimmed_data)
#   anova(model, model_complexity)
#  }
  
data_dopler_native <- read.csv(
  "~/envdev/repos/travart-core/dopler_native_avg_forward.csv",
  stringsAsFactors = FALSE
)

analyze_and_plot(data_dm2uvl, "dm2uvl-control", control_dataset =  data_dopler_native, xbound = 1000, draw_baseline = TRUE)
analyze_and_plot(data_dm2uvl, "dm2uvl-control-post50", control_dataset = data_dopler_native[data_dopler_native$initialSize > 50, ], xbound = 1000, draw_baseline = TRUE)

data_kconfig_native <- read.csv(
  "~/envdev/repos/travart-core/kconfig_native_avg_forward.csv",
  stringsAsFactors = FALSE
)

data_kc2uvl <- read.csv(
  "~/envdev/repos/travart-core/benchmarks_new/merged-by-path/average_transformation_times(kc2uvl).csv",
  stringsAsFactors = FALSE
)

data_uvl2kc <- read.csv(
  "~/envdev/repos/travart-core/benchmarks_new/merged-by-path/average_transformation_times(uvl2kc).csv",
  stringsAsFactors = FALSE
)

data_uvl2fide <- read.csv(
  "~/envdev/repos/travart-core/benchmarks_new/merged-by-path/average_transformation_times(uvl2fide).csv",
  stringsAsFactors = FALSE
)

data_uvl2kc_linux <- read.csv(
  "~/envdev/repos/travart-core/linux_uvl_avg_uvl2kc_rerun.csv",
  stringsAsFactors = FALSE
)

data_uvl2fide_linux <- read.csv(
  "~/envdev/repos/travart-core/linux_uvl_avg_uvl2fide_rerun.csv",
  stringsAsFactors = FALSE
)

analyze_and_plot(data_uvl2kc[data_uvl2kc$initialSize < 2000, ], "kc2uvl-is")

analyze_and_plot(data_kc2uvl, "kc2uvl-control", control_dataset =  data_kconfig_native, xbound = 1000, draw_baseline = TRUE)
analyze_and_plot(data_kc2uvl, "kc2uvl-control-post50", control_dataset =  data_kconfig_native[data_kconfig_native$initialSize > 50, ], xbound = 1000, draw_baseline = TRUE) # For comparsion, not included in thesis!

analyze_and_plot(data_uvl2kc, "uvl2kc-linux", control_dataset = data_uvl2kc_linux, xbound = 100000, ybound = 1500000, showDeserial = TRUE)
analyze_and_plot(data_uvl2fide, "uvl2fide-linux", control_dataset = data_uvl2fide_linux, xbound = 100000, ybound = 1500000, showDeserial = TRUE)

data_uvl2kc_complexity_scaled <- data_uvl2kc
data_uvl2kc_complexity_scaled$initialSize = data_uvl2kc_complexity_scaled$initialSize * pmax(log10(data_uvl2kc_complexity_scaled$complexity)+1, 1)
data_uvl2kc_complexity_scaled_trimmed = data_uvl2kc_complexity_scaled[data_uvl2kc_complexity_scaled$complexity > 0, ]

analyze_and_plot(data_uvl2kc_complexity_scaled, "uvl2kc_complexity", size_identifier = "Model size * max(log_10(C) + 1, 1)")
analyze_and_plot(data_uvl2kc_complexity_scaled_trimmed, "uvl2kc_complexity_trimmed", size_identifier =  "Model size * max(log_10(C) + 1, 1)")
analyze_and_plot(data_uvl2kc[data_uvl2kc$complexity > 0, ], "uvl2kc_complexity_onlyfit") # For comparsion, not included in thesis!

