library(ggplot2)
library(ggpubr)
library(ggpmisc)
library(ggpp)
library(scales)
library(crayon)

analyze_and_plot <- 
  function(data,
           dataset_name,
           size_identifier = "Model size",
           control_dataset = NULL,
           draw_baseline = FALSE,
           xbound = 7500,
           ybound = 100000,
           showDeserial = FALSE) {
    
    cat(red$bold("Now processing", dataset_name, "\n"))
    # Cut lower 1% xy outliers
    lower_percentile <- 0.01
    
    # Calculate the quantile thresholds
    lower_threshold <- quantile(data$avgTransformationTime/data$initialSize, lower_percentile, na.rm = TRUE)
    
    cat("Lower threshold for tps:", lower_threshold, "\n")
    
    # Trim the dataset
    trimmed_data <- data[(data$avgTransformationTime/data$initialSize) > lower_threshold, ]
    cat("Values trimmed:", (nrow(data) - nrow(trimmed_data)), "\n")
    trimmed_data <- na.omit(trimmed_data)
    cat("Number of missing observations was", sum(!complete.cases(data)), "\n")
    cat("Number of rows in initial data frame:", nrow(data), "\n")
    cat("Number of effective observations for correlation analysis:", nrow(trimmed_data), "\n")
    
    # lm is determistic, should match model used in plot
    # Check different fits
    model_lin <- lm(avgTransformationTime ~ initialSize, data = trimmed_data)
    model_exp <- lm(log10(avgTransformationTime) ~ initialSize, data = trimmed_data)
    model_power <- lm(log10(avgTransformationTime) ~ log10(initialSize), data = trimmed_data)
    
    cat("Adj. R-squared for different fits (L/E/P):", summary(model_lin)$adj.r.squared, summary(model_exp)$adj.r.squared, summary(model_power)$adj.r.squared, "\n")
    
    pl_a <- unname(coef(model_power)[1])
    pl_exponent <- unname(coef(model_power)[2])
    pl_K <- 10^pl_a # Milliseconds!
    
    eq_str <- sprintf("y = %.3g · x^%.3f", pl_K, pl_exponent)
    cat("Power law indicates (y in milliseconds):", eq_str, "\n")
    
    cat(bold("Defaulting to power law model, no best fit if there is another model with larger R-squared!\n"))
    model <- model_power
    fs <- summary(model)$fstatistic
    model_p <- pf(fs["value"], fs["numdf"], fs["dendf"], lower.tail = FALSE)
    model_signif <- symnum(model_p, corr = FALSE, na = FALSE,
                           cutpoints = c(0, .001, .01, .05, .1, 1),
                           symbols = c("***","**","*","."," "))
    cat("Model significance:", model_signif, "\n")
    model_label <- sprintf("Exponent %.2f with adj. R² = %.2f, signif. (%s)", pl_exponent, summary(model)$adj.r.squared, model_signif)
    
    # Optional: Mark observations with largest Cook's distance
    trimmed_data$cooks <- cooks.distance(model)
    cooks_cutoff <- quantile(trimmed_data$cooks, 0.95)
    
    trimmed_data$cooks_outlier <- trimmed_data$cooks > cooks_cutoff
    trimmed_data <- trimmed_data[order(trimmed_data$cooks_outlier), ]
    cat("Number of Cook's outliers (99th quantile):", nrow(subset(trimmed_data, cooks_outlier)), "\n")
    cat("Size spread of outliers:", sd(subset(trimmed_data, cooks_outlier)$initialSize), "\n")
    
    #trimmed_data <- trimmed_data[trimmed_data$initialSize < 1500, ]
    
    print(summary(trimmed_data))
    cat("Pearson's for log-log:", cor(log10(trimmed_data$initialSize), log10(trimmed_data$avgTransformationTime), method = "pearson"), "\n")
    cat("Spearman's for log-log:", cor(log10(trimmed_data$initialSize), log10(trimmed_data$avgTransformationTime), method = "spearman"), "\n")
    
    if (!missing(control_dataset)) {
      # Ignore Cook's outliers
      trimmed_data$cooks_outlier = FALSE
    }
    
    # Display the trimmed dataset
    scatter_log <- ggplot(trimmed_data, aes(y=avgTransformationTime/1000, x=initialSize)) +
      geom_point(aes(colour = cooks_outlier)) +
      geom_hline(yintercept=5000, size = 1, color = "cyan") + # Five-second mark
      geom_hline(yintercept=1200000, size = 1, color = "orange") + # 20-minute mark
      (if (!missing(control_dataset)) 
        geom_point(data = control_dataset, aes(x = initialSize, y = avgTransformationTime/1000), colour = "violet") else NULL) +
      (if (showDeserial & !missing(control_dataset))
        geom_point(data = control_dataset, aes(y = avgDeserializationTime/1000, x = initialSize), color="blue", shape="cross") else NULL) +
      scale_y_log10(labels = label_number(),
                    breaks = c(0.1, 1, 10, 100, 1000, 10000, 100000)) +
      (if (!missing(control_dataset) & draw_baseline)
        stat_function(fun = function(x) mean(control_dataset$avgTransformationTime)/1000, 
                      color = "purple", size=1, xlim = c(0, max(control_dataset$initialSize, na.rm = TRUE))) else NULL) +
      stat_function(fun = function(x) (pl_K*(x^pl_exponent))/1000, mapping = aes(color = "fit"), xlim = c(0,xbound), size=1, n = 2000) +
      stat_function(fun = function(x) mean((trimmed_data$avgTransformationTime/trimmed_data$initialSize)/1000)*x, 
                    xlim = c(0,xbound), mapping = aes(color = "mean"), linetype = "dashed", size=1, n = 2000) +
      scale_colour_manual(values = c("TRUE" = "red", "FALSE" = "black", "fit" = "tomato", mean = "green")) +
      labs(x = size_identifier, y = "Avg. transformation time (milliseconds)") +
      (if (missing(control_dataset))
        annotate("label_npc", npcx = 0.8, npcy = 0.1, label = model_label, label.size = .5, fill = "tomato", alpha = 0.5)
       else NULL) +
      annotation_logticks(sides = "l") +
      coord_cartesian(xlim = c(0, xbound), ylim = c(0.1, ybound)) +
      theme_linedraw() +
      theme(legend.position = "none")
    
    if (!missing(control_dataset)) {
      
      cat("Control dataset given, will do OOS fit analysis...\n")
      control_dataset <- na.omit(control_dataset)
      cat("Control dataset contains", nrow(control_dataset), "valid observations!\n")
      cat("Mean model size is", mean(control_dataset$initialSize),"IQR:",IQR(control_dataset$initialSize),"\n")
      cat("Train-control split is", nrow(control_dataset)/nrow(trimmed_data)*100, "to 100\n")
      
      preds <- predict(model, newdata = control_dataset)
      actual <- log10(control_dataset$avgTransformationTime)
    
      rss <- sum((preds - actual) ^ 2)
      tss <- sum((actual - mean(actual)) ^ 2)
      rsq <- 1 - rss/tss
      
      cat("OOS R² (prediction for log10(y)):", rsq, "\n")
      
    } else {
      
      # Histogram with density plot, generate only when no control group is given
      hist <- ggplot(trimmed_data, aes(x=avgTransformationTime/initialSize)) + 
        geom_histogram(aes(y=..density..), colour="black", fill="white", bins = 50) +
        geom_density(alpha=.25, fill="red") +
        geom_vline(aes(xintercept=mean(trimmed_data$avgTransformationTime/trimmed_data$initialSize, na.rm = TRUE)),
                   color="green", linetype="dashed", size=1) +
        labs(x = "Time per size (microseconds)", y = "P(x)") +
        xlim(c(0,1000)) +
        coord_cartesian(ylim = c(0, 0.03)) +
        theme_linedraw()
      
      ggsave(filename = paste0(dataset_name, "_hist.png"), plot = hist, width = 3000, height = 1500, units = "px", bg = "white", dpi = "print")
      
    }
    
    ggsave(filename = paste0(dataset_name, "_scatter_log.png"), plot = scatter_log, width = 3000, height = 1500, units = "px", bg = "white", dpi = "print")  
    
    cat("----\n")
  }

make_scatter_default <- function() {
  
  files = list.files(
    "~/envdev/repos/travart-core/benchmarks_new/merged-by-path",
    include.dirs = FALSE,
    recursive = FALSE,
    full.names = TRUE,
    pattern = glob2rx("average_*.csv")
  )
  
  tuple_list <- lapply(files, function(fn) {
    df <- read.csv(fn, stringsAsFactors = FALSE)
    
    nm <- tools::file_path_sans_ext(basename(fn))
    
    list(dataset      = df, dataset_name = nm)
  })
  
  for (tuple in tuple_list) {
    analyze_and_plot(tuple[[1]], tuple[[2]])
  }
  
}