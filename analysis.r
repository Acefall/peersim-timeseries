library(tidyverse)
library(ggplot2)
library(viridis)
library(zoo)
library(latex2exp)
options(pillar.sigfig = 7)

theme_set(theme_bw())
# Set Directories
#setwd(Your Directory here)

# Directory for created plots
figures = ""

# Directory for created plots for the presentation
figuresPresentation = ""

mse <- function(approximations, groundTruth) {
    return (mean((approximations - groundTruth)^2))
}

mae <- function(approximations, groundTruth) {
    return (mean(abs(approximations - groundTruth)))
}

roundsLonger <- function(nodeData, colname){
    longData <-as_tibble(nodeData) %>%
    tibble::rownames_to_column() %>%
    pivot_longer(-rowname) %>%
    mutate(round = as.numeric(rowname)-1) %>%
    mutate("{colname}" := value) %>%
    select(name, sym(colname), round) %>%
    drop_na(sym(colname))
    return (longData)
}

groundTruthByRound <- function(inputData){
    groundTruths <- inputData %>%
    group_by(round) %>%
    summarize(groundTruth = mean(input))
    return (groundTruths)
}

errorsByRound <- function(approximations, groundTruths){
    errors <- approximations %>%
    left_join(groundTruths, by="round") %>%
    group_by(round) %>%
    summarize(mae = mean(abs(approximation - groundTruth)),
    mse = mean((approximation- groundTruth)^2))
    return (errors)
}



atomicPull <- function(rowwiseData){
    return (rowwiseData[seq(2, nrow(rowwiseData), 2),])
}

ingest <- function(path, isPull) {
    approximationsData <- read.csv(paste0(path, "approximations.csv"), header=F)
    inputsData <- read.csv(paste0(path, "inputs.csv"), header=F)
    if(isPull){
        approximationsData <- atomicPull(approximationsData)
        inputsData <- atomicPull(inputsData)
    }
    approximations <- roundsLonger(approximationsData, "approximation")
    inputs <- roundsLonger(inputsData, "input")
    groundTruths <- groundTruthByRound(inputs)
    errors <- errorsByRound(approximations, groundTruths)
    data = list(
        "approximationsData" = approximationsData,
        "inputsData" = inputsData,
        "approximations" = approximations,
        "inputs" = inputs,
        "groundTruths" = groundTruths,
        "errors" = errors
    )

    return (data)
}

plotGroundTruth <- function(groundTruths){
    plot <- ggplot()+
    geom_line(data=groundTruths, mapping=aes(x=round, y=groundTruth),
    color=viridis(1, begin=0.5, end=0.5), size=1)+
    labs(x=unname(TeX("$t$")), y=unname(TeX("$avg(X_t)$")), color = NULL, title=NULL)

    return (plot)
}

doNothingFirst <- function(inputs) {
    approximations <- inputs %>%
    group_by(name) %>%
    mutate(approximation = first(input)) %>%
    ungroup()%>%
    select(-input)
    groundTruths <- groundTruthByRound(inputs)
    errors <- errorsByRound(approximations, groundTruths)
    data = list(
        "approximations" = approximations,
        "inputs" = inputs,
        "groundTruths" = groundTruths,
        "errors" = errors
    )

    return (data)
}

doNothingCurrent <- function(inputs) {
    approximations <- inputs %>%
    mutate(approximation = input) %>%
    select(-input)
    groundTruths <- groundTruthByRound(inputs)
    errors <- errorsByRound(approximations, groundTruths)
    data = list(
        "approximations" = approximations,
        "inputs" = inputs,
        "groundTruths" = groundTruths,
        "errors" = errors
    )

    return (data)
}

firstGt <- function(inputs) {
    groundTruths <- groundTruthByRound(inputs)
    approximations <- inputs %>%
    mutate(approximation = groundTruths$groundTruth[1]) %>%
    select(-input)
    errors <- errorsByRound(approximations, groundTruths)
    data = list(
        "approximations" = approximations,
        "inputs" = inputs,
        "groundTruths" = groundTruths,
        "errors" = errors
    )

    return (data)
}



summaryByRound <- function(path, isPull){
    print(paste0(path, "mse.csv"))
    summaryMSE <- read.csv(paste0(path, "mse.csv"), header=F)
    summaryGT <- read.csv(paste0(path, "groundTruths.csv"), header=F)

    data <- as_tibble(data.frame(round=0:(length(summaryMSE$V1)-1), groundTruth = summaryGT$V1, mse = summaryMSE$V1))
    
    if(isPull) {
        data <- data %>%
        filter(round %% 2 == 0) %>%
        mutate(round = row_number()-1)
    }


    return (data)
}




firstGtMSEFromSummary <- function(groundTruths){
    errors <- groundTruths %>%
    mutate(mse = (groundTruth[1]-groundTruth)^2) %>%
    select(round, mse)

    return (errors)
}





# =========================
# Ingest Simulation Results
# =========================
breaks_y <- c(10^(-50:50))
minor_breaks_y <- rep(0:9, 61)*(10^rep(-50:10, each=10))


# ==================
# Plot error vs time
# ==================

# Experiment 1
# ==================

# Data
ex1PushSum <- ingest("Experiment1/pushSum/", FALSE)
ex1RandomCallPull <- ingest("Experiment1/randomCallPull/", TRUE)
ex1PermutationPull <- ingest("Experiment1/permutationPull/", TRUE)
ex1PullSum <- ingest("Experiment1/pullSum/", TRUE)
ex1HistMean <- ingest("Experiment1/histMean/", TRUE)

# Plot MSE vs Time
ex1errorVsTime <- ggplot() +
geom_line(data=ex1PushSum$errors, mapping=aes(x=round, y=mse, color="Push-Sum"), size=1)+
geom_line(data=ex1RandomCallPull$errors, mapping=aes(x=round, y=mse, color="Random-Call-Pull"), size=1)+
geom_line(data=ex1PermutationPull$errors, mapping=aes(x=round, y=mse, color="Permutation-Pull"), size=1)+
geom_line(data=ex1PullSum$errors, mapping=aes(x=round, y=mse, color="Pull-Sum"), size=1)+
geom_line(data=ex1HistMean$errors, mapping=aes(x=round, y=mse, color="Hist-Mean"), size=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.9)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
scale_y_log10(breaks=breaks_y[seq(1, length(breaks_y), 2)])+
scale_x_continuous(limits=c(0, 175))#+
#theme(legend.text.align = 0)+
#theme(legend.position = c(0.1, 0.15))+
#theme(legend.background = element_rect(size=0.5, linetype="solid", colour ="black"))
ex1errorVsTime
ggsave(paste0(figures, "ex1errorVsTime.pdf"), ex1errorVsTime, width=10, height =6)
ggsave(paste0(figures, "ex1errorVsTime.svg"), ex1errorVsTime, width=10, height =6)

ex1errorVsTimePresentation <- ggplot() +
geom_line(data=ex1PushSum$errors, mapping=aes(x=round, y=mse, color="Push-Sum"), size=1)+
geom_line(data=ex1PullSum$errors, mapping=aes(x=round, y=mse, color="Pull-Sum"), size=1)+
#scale_color_manual(values=c(viridis(1, begin=0.2, end=0.2)))+
scale_color_manual(values=c(viridis(1, begin=0.7, end=0.7), viridis(1, begin=0.2, end=0.2)))+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
scale_y_log10(breaks=breaks_y[seq(1, length(breaks_y), 4)])+
theme(legend.position="top")+
scale_x_continuous(limits=c(0, 175))#+
#theme(legend.text.align = 0)+
#theme(legend.position = c(0.1, 0.15))+
#theme(legend.background = element_rect(size=0.5, linetype="solid", colour ="black"))
ex1errorVsTimePresentation
ggsave(paste0(figuresPresentation, "ex1errorVsTimePresentationBoth.svg"), ex1errorVsTimePresentation, width=5, height =3)


ex1errorVsTimeZoom <- ex1errorVsTime +
geom_point(data=ex1PushSum$errors, mapping=aes(x=round, y=mse, color="Push-Sum"), size=2)+
geom_point(data=ex1RandomCallPull$errors, mapping=aes(x=round, y=mse, color="Random-Call-Pull"), size=2)+
geom_point(data=ex1PermutationPull$errors, mapping=aes(x=round, y=mse, color="Permutation-Pull"), size=2)+
geom_point(data=ex1PullSum$errors, mapping=aes(x=round, y=mse, color="Pull-Sum"), size=2)+
geom_point(data=ex1HistMean$errors, mapping=aes(x=round, y=mse, color="Hist-Mean"), size=2)+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y, limits=c(0.000001, 1000))+
scale_x_continuous(limits=c(0, 29))
ex1errorVsTimeZoom
ggsave(paste0(figures, "ex1errorVsTimeZoom.pdf"), ex1errorVsTimeZoom, width=10, height =6)
ggsave(paste0(figures, "ex1errorVsTimeZoom.svg"), ex1errorVsTimeZoom, width=10, height =6)


# Plot Ground Truth
ex1GtPlot <- plotGroundTruth(ex1PushSum$groundTruths)
ex1GtPlot
ggsave(paste0(figures, "ex1GtPlot.pdf"), ex1GtPlot, width=10, height =6)
ggsave(paste0(figures, "ex1GtPlot.svg"), ex1GtPlot, width=10, height =6)

# Experiment 2
# ==================

# Data
ex2TsPushSum <- summaryByRound("Experiment2/tsPushSum/", FALSE)
ex2TsPullSum <- summaryByRound("Experiment2/tsPullSum/", TRUE)
ex2TsHistMean <- summaryByRound("Experiment2/tsHistMean/", TRUE)
ex2FirstGt <- firstGtMSEFromSummary(ex2TsPushSum)


# Plot MSE vs Time
ex2errorVsTime <- ggplot() +
geom_line(data=ex2TsPushSum, mapping=aes(x=round, y=mse, color="TS-Push-Sum"), size=1)+
geom_line(data=ex2TsPullSum, mapping=aes(x=round, y=mse, color="TS-Pull-Sum"), size=1)+
geom_line(data=ex2TsHistMean, mapping=aes(x=round, y=mse, color="TS-Hist-Mean"), size=1)+
geom_line(data=ex2FirstGt, mapping=aes(x=round, y=mse, color="First Ground Truth"), size=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.8)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
theme(legend.position="top")+
scale_y_log10(breaks=breaks_y[seq(1, length(breaks_y), 2)])
ex2errorVsTime
ggsave(paste0(figures, "ex2errorVsTime.pdf"), ex2errorVsTime, width=10, height =6)
ggsave(paste0(figures, "ex2errorVsTime.svg"), ex2errorVsTime, width=10, height =6)

# Plot Ground Truth
ex2GtPlot <- plotGroundTruth(ex2TsPushSum)
ex2GtPlot
ggsave(paste0(figures, "ex2GtPlot.pdf"), ex2GtPlot, width=10, height =6)
ggsave(paste0(figures, "ex2GtPlot.svg"), ex2GtPlot, width=10, height =6)


# Experiment 3
# ==================

# Data
ex3TsPushSum <- summaryByRound("Experiment3/tsPushSum/", FALSE)
ex3TsPullSum <- summaryByRound("Experiment3/tsPullSum/", TRUE)
ex3FirstGt <- firstGtMSEFromSummary(ex3TsPushSum)

# Plot MSE vs Time
ex3errorVsTime <- ggplot() +
geom_line(data=ex3TsPushSum, mapping=aes(x=round, y=mse, color="TS-Push-Sum"), size=1)+
geom_line(data=ex3TsPullSum, mapping=aes(x=round, y=mse, color="TS-Pull-Sum"), size=1)+
geom_line(data=ex3FirstGt, mapping=aes(x=round, y=mse, color="First Ground Truth"), size=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.9)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
theme(legend.position="top")+
scale_y_log10(breaks=breaks_y[seq(1, length(breaks_y), 2)])
ex3errorVsTime
ggsave(paste0(figures, "ex3errorVsTime.pdf"), ex3errorVsTime, width=10, height =6)
ggsave(paste0(figures, "ex3errorVsTime.svg"), ex3errorVsTime, width=10, height =6)

# Plot Ground Truth
ex3GtPlot <- plotGroundTruth(ex3TsPushSum)+
scale_y_log10(breaks=breaks_y)
ex3GtPlot
ggsave(paste0(figures, "ex3GtPlot.pdf"), ex3GtPlot, width=10, height =6)
ggsave(paste0(figures, "ex3GtPlot.svg"), ex3GtPlot, width=10, height =6)


# Experiment 4
# ==================

# Data
ex4TsPushSum <- ingest("Experiment4/tsPushSum/", FALSE)
ex4TsPullSum <- ingest("Experiment4/tsPullSum/", TRUE)
ex4DoNothingFirst <- doNothingFirst(ex4TsPushSum$inputs)
ex4DoNothingCurrent <- doNothingCurrent(ex4TsPushSum$inputs)
ex4FirstGt <- firstGt(ex4TsPushSum$inputs)

paste("MMSE Plain PushSum:", mean(ex4TsPushSum$errors$mse))
paste("MMSE Plain PullSum:", mean(ex4TsPullSum$errors$mse))
paste("MMSE First GT:", mean(ex4FirstGt$errors$mse))


# Plot MSE vs Time
ex4errorVsTime <- ggplot() +
geom_line(data=ex4TsPushSum$errors, mapping=aes(x=round, y=mse, color="TS-Push-Sum"), size=1)+
geom_line(data=ex4TsPullSum$errors, mapping=aes(x=round, y=mse, color="TS-Pull-Sum"), size=1)+
#geom_line(data=ex4DoNothingFirst$errors, mapping=aes(x=round, y=mse, color="First Input"), size=1)+
#geom_line(data=ex4DoNothingCurrent$errors, mapping=aes(x=round, y=mse, color="Current Input"), size=1, linetype="dashed")+
geom_line(data=ex4FirstGt$errors, mapping=aes(x=round, y=mse, color="First Ground Truth"), size=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.9)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
theme(legend.position="top")+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)
ex4errorVsTime
ggsave(paste0(figures, "ex4errorVsTime.pdf"), ex4errorVsTime, width=10, height =6)
ggsave(paste0(figures, "ex4errorVsTime.svg"), ex4errorVsTime, width=10, height =6)

# Plot Ground Truth
ex4GtPlot <- plotGroundTruth(ex4TsPushSum$groundTruths)
ex4GtPlot
ggsave(paste0(figures, "ex4GtPlot.pdf"), ex4GtPlot, width=10, height =6)
ggsave(paste0(figures, "ex4GtPlot.svg"), ex4GtPlot, width=10, height =6)


# MMSE
# ==========
slidingWindow <- function(inputs, approximations, k){
    groundTruths <- groundTruthByRound(inputs)
    approximations <- approximations %>%
    group_by(name) %>%
    mutate(approximation = rollapply(approximation, k+1, mean, na.rm=T, fill=NA, align="right", partial=T))
    errors <- errorsByRound(approximations, groundTruths)
    
    data = list(
        "approximations" = approximations,
        "inputs" = inputs,
        "groundTruths" = groundTruths,
        "errors" = errors
    )
    return (data)
}

decay <- function(approximations, alpha){
    for(i in 2:length(approximations))
    {
        approximations[i] <- alpha*approximations[i] + (1-alpha) * approximations[i-1] 
    }
    return(approximations)
}


decayApproximations <- function(inputs, approximations, alpha){
    groundTruths <- groundTruthByRound(inputs)
  
    approximations <- approximations %>%
    group_by(name) %>%
    mutate(approximation = decay(approximation, alpha))

    errors <- errorsByRound(approximations, groundTruths)

    data = list(
        "approximations" = approximations,
        "inputs" = inputs,
        "groundTruths" = groundTruths,
        "errors" = errors
    )
    return (data)
}

meanErrors <- function(dataList, parameters, parameterName){
    mmse <- NULL
    mmae <- NULL
    for (i in 1:length(dataList)){
        mmse <- c(mmse, mean(dataList[[i]]$errors$mse))
        mmae <- c(mmae, mean(dataList[[i]]$errors$mae))
    }
    data <- as_tibble(data.frame(mmse = mmse, mmae=mmae)) %>%
    mutate("{parameterName}" := parameters) 

    return (data)
}

k <- c(seq(0, 10, 1), seq(20, 100, 10))
alpha <- seq(0.05, 1.2, 0.05)

ex4TsPushSumWindows <- lapply(k, slidingWindow, inputs=ex4TsPushSum$inputs, approximations=ex4TsPushSum$approximations)
mePushSumWindow <- meanErrors(ex4TsPushSumWindows, k, "k")
ex4TsPushSumDecays <- lapply(alpha, decayApproximations, inputs=ex4TsPushSum$inputs, approximations=ex4TsPushSum$approximations)
mePushSumDecay <- meanErrors(ex4TsPushSumDecays, alpha, "alpha")
ex4TsPullSumWindows <- lapply(k, slidingWindow, inputs=ex4TsPullSum$inputs, approximations=ex4TsPullSum$approximations)
mePullSumWindow <- meanErrors(ex4TsPullSumWindows, k, "k")
ex4TsPullSumDecays <- lapply(alpha, decayApproximations, inputs=ex4TsPullSum$inputs, approximations=ex4TsPullSum$approximations)
mePullSumDecay <- meanErrors(ex4TsPullSumDecays, alpha, "alpha")


# Plot MMSE vs Time for PushSum with different window size
ex4errorVsTimeWindows <- ggplot()
for (i in 1:length(k)) {
    ex4errorVsTimeWindows <- ex4errorVsTimeWindows +
    geom_line(data=ex4TsPushSumWindows[[i]]$errors, mapping=aes(x=round, y=mse, color=paste0("TS-Push-Sum Windows k=", !!k[i])), size=1)   
}
ex4errorVsTimeWindows <- ex4errorVsTimeWindows +
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.8)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)
ex4errorVsTimeWindows

# Plot MSE vs Time for PushSum with different decay rates
ex4errorVsTimeDecays <- ggplot()
for (i in 1:length(alpha)) {
    ex4errorVsTimeDecays <- ex4errorVsTimeDecays +
    geom_line(data=ex4TsPushSumDecays[[i]]$errors, mapping=aes(x=round, y=mse, color=paste0("TS-Push-Sum Windows alpha=", !!alpha[i])), size=1)   
}
ex4errorVsTimeDecays <- ex4errorVsTimeDecays +
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.8)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)
ex4errorVsTimeDecays

# Plot Mean MSE for PushSum and Pull Sum for different window sizes
print(paste0("Baseline: First Ground Truth MMSE", mean(ex4FirstGt$errors$mse)))
mmseWindowPlot <- ggplot() +
geom_point(data=mePushSumWindow, mapping=aes(x=k, y=mmse, color="TS-Push-Sum"), size=2) +
geom_line(data=mePushSumWindow, mapping=aes(x=k, y=mmse, color="TS-Push-Sum"), size=1) +
geom_point(data=mePullSumWindow, mapping=aes(x=k, y=mmse, color="TS-Pull-Sum"), size=2) + 
geom_line(data=mePullSumWindow, mapping=aes(x=k, y=mmse, color="TS-Pull-Sum"), size=1)+
geom_hline(yintercept=, color=viridis(1, begin=0.5, end=0.5), size=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.9)+
theme(legend.position="top")+
labs(x=unname(TeX("$k$")), y=unname(TeX("$MMSE$")), color = NULL, title=NULL)
mmseWindowPlot
ggsave(paste0(figures, "mmseWindowPlot.pdf"), mmseWindowPlot, width=10, height =6)
ggsave(paste0(figures, "mmseWindowPlot.svg"), mmseWindowPlot, width=10, height =6)
ggsave(paste0(figures, "mmseWindowPlotKlein.svg"), mmseWindowPlot, width=6, height =5)

max(mePullSumWindow$mmse)/min(mePullSumWindow$mmse)
mean(ex4FirstGt$errors$mse)

# Plot Mean MSE for PushSum and Pull Sum for different decay rates
mmseDecayPlot <- ggplot() +
geom_point(data=mePushSumDecay, mapping=aes(x=alpha, y=mmse, color="TS-Push-Sum"), size=2) +
geom_line(data=mePushSumDecay, mapping=aes(x=alpha, y=mmse, color="TS-Push-Sum"), size=1) +
geom_point(data=mePullSumDecay, mapping=aes(x=alpha, y=mmse, color="TS-Pull-Sum"), size=2) +
geom_line(data=mePullSumDecay, mapping=aes(x=alpha, y=mmse, color="TS-Pull-Sum"), size=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.9)+
theme(legend.position="top")+
labs(x=unname(TeX("$\\alpha$")), y=unname(TeX("$MMSE$")), color = NULL, title=NULL)
mmseDecayPlot
ggsave(paste0(figures, "mmseDecayPlot.pdf"), mmseDecayPlot, width=10, height =6)
ggsave(paste0(figures, "mmseDecayPlot.svg"), mmseDecayPlot, width=10, height =6)
ggsave(paste0(figures, "mmseDecayPlotKlein.svg"), mmseDecayPlot, width=6, height =5)

1-min(mePushSumDecay$mmse)/max(mePushSumDecay$mmse)
1-min(mePullSumDecay$mmse)/max(mePullSumDecay$mmse)
head(mePushSumDecay, n=20)


# Experiment 5
# ==================

# Data
ex5TsPushSum <- summaryByRound("Experiment5/tsPushSum/", FALSE)
ex5TsPullSum <- summaryByRound("Experiment5/tsPullSum/", TRUE)
ex5FirstGt <- firstGtMSEFromSummary(ex5TsPushSum)


# Plot MSE vs Time
ex5errorVsTime <- ggplot() +
geom_line(data=ex5TsPushSum, mapping=aes(x=round, y=mse, color="TS-Push-Sum"))+
geom_line(data=ex5TsPullSum, mapping=aes(x=round, y=mse, color="TS-Pull-Sum"))+
#geom_line(data=ex5DoNothingFirst$errors, mapping=aes(x=round, y=mse, color="First Input"), size=1)+
#geom_line(data=ex5DoNothingCurrent$errors, mapping=aes(x=round, y=mse, color="Current Input"), size=1, linetype="dashed")+
geom_line(data=ex5FirstGt, mapping=aes(x=round, y=mse, color="First Ground Truth"), size=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.9)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
theme(legend.position="top")+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)
ex5errorVsTime
ggsave(paste0(figures, "ex5errorVsTime.pdf"), ex5errorVsTime, width=10, height = 6)
ggsave(paste0(figures, "ex5errorVsTime.svg"), ex5errorVsTime, width=10, height = 6)

# Plot Ground Truth
ex5GtPlot <- plotGroundTruth(ex5TsPushSum)
ex5GtPlot
ggsave(paste0(figures, "ex5GtPlot.pdf"), ex5GtPlot, width=10, height =6)
ggsave(paste0(figures, "ex5GtPlot.svg"), ex5GtPlot, width=10, height =6)

# Comparing MMSE
paste("MMSE Plain PushSum:", mean(ex5TsPushSum$mse))
mean(ex5TsPushSum$mse)/mean(ex4TsPushSum$errors$mse)
paste("MMSE Plain PullSum:", mean(ex5TsPullSum$mse))
1-mean(ex5TsPullSum$mse)/mean(ex4TsPullSum$errors$mse)
paste("MMSE First GT:", mean(ex5FirstGt$mse))

# Experiment 6
# ==================

# Data
ex6TsPushSum <- summaryByRound("Experiment6/tsPushSum/", FALSE)
ex6TsPullSum <- summaryByRound("Experiment6/tsPullSum/", TRUE)
ex6FirstGt <- firstGtMSEFromSummary(ex6TsPushSum)

# Plot MSE vs Time
ex6errorVsTime <- ggplot() +
geom_line(data=ex6TsPushSum, mapping=aes(x=round, y=mse, color="TS-Push-Sum"))+
geom_line(data=ex6TsPullSum, mapping=aes(x=round, y=mse, color="TS-Pull-Sum"))+
#geom_line(data=ex6DoNothingFirst$errors, mapping=aes(x=round, y=mse, color="First Input"), size=1)+
#geom_line(data=ex6DoNothingCurrent$errors, mapping=aes(x=round, y=mse, color="Current Input"), size=1, linetype="dashed")+
geom_line(data=ex6FirstGt, mapping=aes(x=round, y=mse, color="First Ground Truth"), size=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.9)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
theme(legend.position="top")+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)
ex6errorVsTime
ggsave(paste0(figures, "ex6errorVsTime.pdf"), ex6errorVsTime, width=10, height =6)
ggsave(paste0(figures, "ex6errorVsTime.svg"), ex6errorVsTime, width=10, height =6)

# Plot Ground Truth
ex6GtPlot <- plotGroundTruth(ex6TsPushSum)
ex6GtPlot
ggsave(paste0(figures, "ex6GtPlot.pdf"), ex6GtPlot, width=10, height =6)
ggsave(paste0(figures, "ex6GtPlot.svg"), ex6GtPlot, width=10, height =6)

paste("MMSE Plain PushSum:", mean(ex6TsPushSum$mse))
mean(ex6TsPushSum$mse)/mean(ex5TsPushSum$mse)
paste("MMSE Plain PullSum:", mean(ex6TsPullSum$mse))
paste("MMSE First GT:", mean(ex6FirstGt$mse))

# Experiment 7
# ==================

# Data
ex7TsPushSum <- summaryByRound("Experiment7/tsPushSum/", FALSE)
ex7TsPullSum <- summaryByRound("Experiment7/tsPullSum/", TRUE)
ex7FirstGt <- firstGtMSEFromSummary(ex7TsPushSum)


# Plot MSE vs Time
ex7errorVsTime <- ggplot() +
geom_line(data=ex7TsPushSum, mapping=aes(x=round, y=mse, color="TS-Push-Sum"))+
geom_line(data=ex7TsPullSum, mapping=aes(x=round, y=mse, color="TS-Pull-Sum"))+
geom_line(data=ex7FirstGt, mapping=aes(x=round, y=mse, color="First Ground Truth"), size=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.9)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
theme(legend.position="top")+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)
ex7errorVsTime
ggsave(paste0(figures, "ex7errorVsTime.pdf"), ex7errorVsTime, width=10, height =6)
ggsave(paste0(figures, "ex7errorVsTime.svg"), ex7errorVsTime, width=10, height =6)

# Plot Ground Truth
ex7GtPlot <- plotGroundTruth(ex7TsPushSum)
ex7GtPlot
ggsave(paste0(figures, "ex7GtPlot.pdf"), ex7GtPlot, width=10, height =6)
ggsave(paste0(figures, "ex7GtPlot.svg"), ex7GtPlot, width=10, height =6)

paste("MMSE Plain PushSum:", mean(ex7TsPushSum$mse))
paste("MMSE Plain PullSum:", mean(ex7TsPullSum$mse))
paste("MMSE First GT:", mean(ex7FirstGt$mse))

# Compare MMSE for Ex5, Ex6, Ex7
mmseData = as_tibble(data.frame(l=c(500, 2000, 100),
    tsPushSum=c(mean(ex5TsPushSum$mse), mean(ex6TsPushSum$mse), mean(ex7TsPushSum$mse)),
    tsPullSum=c(mean(ex5TsPullSum$mse), mean(ex6TsPullSum$mse), mean(ex7TsPullSum$mse)),
    firstGt=c(mean(ex5FirstGt$mse), mean(ex6FirstGt$mse), mean(ex7FirstGt$mse))
))
names(mmseData)<-c('l','TS-Push-Sum', 'TS-PullSum', 'First Ground Truth')
mmseData <- mmseData %>%
pivot_longer(-l) %>%
mutate(mmse = value) %>%
select(l, name, mmse)
mmseData


mmseComparisonPlot <- ggplot(mmseData, aes(x=l, y=mmse, color=name))+
geom_point(size=2)+
geom_line(size=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.9)+
labs(x=unname(TeX("$l$")), y=unname(TeX("$MMSE$")), color = NULL, title=NULL)+
theme(legend.position="top")+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)
mmseComparisonPlot
ggsave(paste0(figures, "mmseComparisonPlot.pdf"), mmseComparisonPlot, width=10, height =6)
ggsave(paste0(figures, "mmseComparisonPlot.svg"), mmseComparisonPlot, width=10, height =6)


# Experiment 8
# ==================

# Data
ex8TsPushSum <- summaryByRound("Experiment8/tsPushSum/", FALSE) %>%
mutate(mseSmoothed = rollapply(mse, 300, mean, na.rm=T, fill=NA, align="right", partial=T)) %>%
mutate(groundTruthSmoothed = rollapply(groundTruth, 300, mean, na.rm=T, fill=NA, align="right", partial=T))
ex8TsPullSum <- summaryByRound("Experiment8/tsPullSum/", TRUE) %>%
mutate(mseSmoothed = rollapply(mse, 300, mean, na.rm=T, fill=NA, align="right", partial=T))
ex8FirstGt <- firstGtMSEFromSummary(ex8TsPushSum) %>%
mutate(mseSmoothed = rollapply(mse, 300, mean, na.rm=T, fill=NA, align="right", partial=T))

startTime = lubridate::ymd_hms("2021-05-01T18:00:00")
endTime = startTime + lubridate::dmilliseconds(1000*nrow(ex8TsPushSum))
times = startTime + lubridate::dmilliseconds(1000*(1:nrow(ex8TsPushSum)))
breaks_x = seq(startTime, endTime, by="6 hour")

# Plot MSE vs Time
ex8errorVsTime <- ggplot() +
geom_line(data=ex8TsPushSum, mapping=aes(x=times, y=mse, color="TS-Push-Sum"), alpha=0.2, size=1)+
geom_line(data=ex8TsPullSum, mapping=aes(x=times, y=mse, color="TS-Pull-Sum"), alpha=0.1)+
geom_line(data=ex8FirstGt, mapping=aes(x=times, y=mse, color="First Ground Truth"), alpha=0.1)+
geom_line(data=ex8TsPushSum, mapping=aes(x=times, y=mseSmoothed, color="TS-Push-Sum"))+
geom_line(data=ex8TsPullSum, mapping=aes(x=times, y=mseSmoothed, color="TS-Pull-Sum"))+
geom_line(data=ex8FirstGt, mapping=aes(x=times, y=mseSmoothed, color="First Ground Truth"))+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.8)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)+
theme(legend.position="top")+
scale_x_continuous(breaks=breaks_x)
ex8errorVsTime
ggsave(paste0(figures, "ex8errorVsTime.pdf"), ex8errorVsTime, width=10, height =6)
ggsave(paste0(figures, "ex8errorVsTime.svg"), ex8errorVsTime, width=10, height =6)

# Plot Ground Truth
ex8GtPlot <- ggplot(ex8TsPushSum, aes(x=times, y=groundTruth))+
geom_line(color=viridis(1, begin=0.5, end=0.5))+
labs(x=unname(TeX("$t$")), y=unname(TeX("$avg(X_t)$")), color = NULL, title=NULL)+
scale_x_continuous(breaks=breaks_x)
ex8GtPlot
ggsave(paste0(figures, "ex8GtPlot.pdf"), ex8GtPlot, width=10, height =6)
ggsave(paste0(figures, "ex8GtPlot.svg"), ex8GtPlot, width=10, height =6)

# For the Presentation
ex8GtPlotPresentation <- ex8GtPlot +
labs(x=unname(TeX("$t$")), y=unname(TeX("$avg$")), color = NULL, title=NULL)
ggsave(paste0(figuresPresentation, "ex8GtPlotPresentation.svg"), ex8GtPlotPresentation, width=10, height =3)
ex8GtPlotPresentation

ex8errorVsTimePresentation <- ggplot() +
geom_line(data=ex8TsPushSum, mapping=aes(x=times, y=mse, color="TS-Push-Sum"), alpha=1)+
geom_line(data=ex8TsPullSum, mapping=aes(x=times, y=mse, color="TS-Pull-Sum"), alpha=1)+
geom_line(data=ex8FirstGt, mapping=aes(x=times, y=mse, color="First Ground Truth"), alpha=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.8)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
scale_y_log10(breaks=breaks_y[seq(1, length(breaks_y), 2)])+
theme(legend.position="top")+
scale_x_continuous(breaks=breaks_x)
ex8errorVsTimePresentation
ggsave(paste0(figuresPresentation, "ex8errorVsTimePresentation.svg"), ex8errorVsTimePresentation, width=10, height =3)

ex8errorVsTimePresentationSmoothed <- ggplot() +
geom_line(data=ex8TsPushSum, mapping=aes(x=times, y=mse, color="TS-Push-Sum"), alpha=0.2, size=1)+
geom_line(data=ex8TsPullSum, mapping=aes(x=times, y=mse, color="TS-Pull-Sum"), alpha=0.1)+
geom_line(data=ex8FirstGt, mapping=aes(x=times, y=mse, color="First Ground Truth"), alpha=0.1)+
geom_line(data=ex8TsPushSum, mapping=aes(x=times, y=mseSmoothed, color="TS-Push-Sum"))+
geom_line(data=ex8TsPullSum, mapping=aes(x=times, y=mseSmoothed, color="TS-Pull-Sum"))+
geom_line(data=ex8FirstGt, mapping=aes(x=times, y=mseSmoothed, color="First Ground Truth"))+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.8)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
scale_y_log10(breaks=breaks_y[seq(1, length(breaks_y), 2)])+
theme(legend.position="top")+
scale_x_continuous(breaks=breaks_x)
ex8errorVsTimePresentationSmoothed
ggsave(paste0(figuresPresentation, "ex8errorVsTimePresentationSmoothed.svg"), ex8errorVsTimePresentationSmoothed, width=10, height =3)


# Comparing MMSE
min(ex8TsPushSum$groundTruth)
mean(ex8TsPushSum$mse)
mean(ex8TsPullSum$mse)
mean(ex8FirstGt$mse)

# Experiment 9
# ==================

# Data
ex9TsPushSum <- summaryByRound("Experiment9/tsPushSum/", FALSE) %>%
mutate(mseSmoothed = rollapply(mse, 300, mean, na.rm=T, fill=NA, align="right", partial=T)) %>%
mutate(groundTruthSmoothed = rollapply(groundTruth, 300, mean, na.rm=T, fill=NA, align="right", partial=T))
ex9TsPullSum <- summaryByRound("Experiment9/tsPullSum/", TRUE) %>%
mutate(mseSmoothed = rollapply(mse, 300, mean, na.rm=T, fill=NA, align="right", partial=T))
ex9FirstGt <- firstGtMSEFromSummary(ex9TsPushSum) %>%
mutate(mseSmoothed = rollapply(mse, 300, mean, na.rm=T, fill=NA, align="right", partial=T))

startTime = lubridate::ymd_hms("2021-05-01T18:00:00")
endTime = startTime + lubridate::dmilliseconds(1000*nrow(ex9TsPushSum))
times = startTime + lubridate::dmilliseconds(1000*(1:nrow(ex9TsPushSum)))
breaks_x = seq(startTime, endTime, by="6 hour")

# Plot MSE vs Time
ex9errorVsTime <- ggplot() +
geom_line(data=ex9TsPushSum, mapping=aes(x=times, y=mse, color="TS-Push-Sum"), alpha=0.2, size=1)+
geom_line(data=ex9TsPullSum, mapping=aes(x=times, y=mse, color="TS-Pull-Sum"), alpha=0.2)+
geom_line(data=ex9FirstGt, mapping=aes(x=times, y=mse, color="First Ground Truth"), alpha=0.2)+
geom_line(data=ex9TsPushSum, mapping=aes(x=times, y=mseSmoothed, color="TS-Push-Sum"), size=1)+
geom_line(data=ex9TsPullSum, mapping=aes(x=times, y=mseSmoothed, color="TS-Pull-Sum"), size=1)+
geom_line(data=ex9FirstGt, mapping=aes(x=times, y=mseSmoothed, color="First Ground Truth"), size=1)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.8)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$MSE_t$")), color = NULL, title=NULL)+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)+
theme(legend.position="top")+
scale_x_continuous(breaks=breaks_x)
ex9errorVsTime
ggsave(paste0(figures, "ex9errorVsTime.pdf"), ex9errorVsTime, width=10, height =6)
ggsave(paste0(figures, "ex9errorVsTime.svg"), ex9errorVsTime, width=10, height =6)

# Plot Ground Truth
ex9GtPlot <- ggplot(ex9TsPushSum, aes(x=times, y=groundTruth))+
geom_line(color=viridis(1, begin=0.5, end=0.5))+
labs(x=unname(TeX("$t$")), y=unname(TeX("$avg(X_t)$")), color = NULL, title=NULL)+
scale_x_continuous(breaks=breaks_x)
ex9GtPlot
ggsave(paste0(figures, "ex9GtPlot.pdf"), ex9GtPlot, width=10, height =6)
ggsave(paste0(figures, "ex9GtPlot.svg"), ex9GtPlot, width=10, height =6)

# Comparing MMSE
min(ex9TsPushSum$groundTruth)
mean(ex9TsPushSum$mse)
mean(ex9TsPullSum$mse)
mean(ex9FirstGt$mse)


# =================
# Tail Weights
# =================
tailWeightsByRound <- function(rowwiseApproximations, groundTruths, errorBars){
    tailWeights <- data.frame()
    for(i in 1:nrow(rowwiseApproximations)){
        row <- as.numeric(rowwiseApproximations[i,])
        ecdfFn <- ecdf(row)
        for(errorBar in errorBars){
            tailWeight <- 1-ecdfFn(groundTruths[i,]$groundTruth+errorBar) + ecdfFn(groundTruths[i,]$groundTruth-errorBar)
            tailWeights <- rbind(tailWeights, data.frame(round = i-1, errorBar=errorBar, tailWeight=tailWeight))
        }
    }
    tailWeights$errorBar = as.factor(tailWeights$errorBar)
    return (as_tibble(tailWeights))
}

meanApproxByRound <- function(rowwiseApproximations){
    means <- as_tibble(rowMeans(rowwiseApproximations, na.rm=T)) %>%
    mutate(round = row_number()) %>%
    mutate(groundTruth = value) %>%
    select(round, groundTruth)
    return (means)
}

tailWeightPlot <- function(tailWeights, ylab) {
    allErrorBars <- ggplot(tailWeights, aes(x=round, y=tailWeight, color=errorBar))+
    geom_line(size=1)+
    geom_point(size=2)+
    scale_colour_viridis_d(unname(TeX("$\\epsilon$")), option="viridis", begin = 0, end = 0.9)+
    labs(y=ylab, x=unname(TeX("$t$")), title=NULL) +
    scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)
    return (allErrorBars)
}

# Push Sum
# =================

# Distance to Ground Truth
errorBars = c(10^(1:-10))
tailWeightsGtPushSum <- tailWeightsByRound(ex1PushSum$approximationsData, ex1PushSum$groundTruths, errorBars)
tailWeightsToPlotPushSumGt <- tailWeightsGtPushSum %>%
filter(round <= 90)

allErrorBarsGtPushSum <- tailWeightPlot(tailWeightsToPlotPushSumGt, unname(TeX("$T_{gt}(t)$")))
allErrorBarsGtPushSum
ggsave(paste0(figures, "allErrorBarsGtPushSum.pdf"), allErrorBarsGtPushSum, width=10, height =6)
ggsave(paste0(figures, "allErrorBarsGtPushSum.svg"), allErrorBarsGtPushSum, width=10, height =6)

# Distance to Mean Approximation
tailWeightsApproxPushSum <- tailWeightsByRound(ex1PushSum$approximationsData, meanApproxByRound(ex1PushSum$approximationsData), errorBars)
tailWeightsToPlotPushSumApprox <- tailWeightsApproxPushSum %>%
filter(round <= 90)

allErrorBarsApproxPushSum <- tailWeightPlot(tailWeightsToPlotPushSumApprox, unname(TeX("$T_{\\bar{Y}}(t)$")))
allErrorBarsApproxPushSum
ggsave(paste0(figures, "allErrorBarsApproxPushSum.pdf"), allErrorBarsApproxPushSum, width=10, height =6)
ggsave(paste0(figures, "allErrorBarsApproxPushSum.svg"), allErrorBarsApproxPushSum, width=10, height =6)


# PullSum
# =================

# Distance to Ground Truth
errorBars = c(10^(1:-10))
tailWeightsGtPullSum <- tailWeightsByRound(ex1PullSum$approximationsData, ex1PullSum$groundTruths, errorBars)
tailWeightsToPlotPullSumGt <- tailWeightsGtPullSum %>%
filter(round <= 125)

allErrorBarsGtPullSum <- tailWeightPlot(tailWeightsToPlotPullSumGt, unname(TeX("$T_{gt}(t)$")))
allErrorBarsGtPullSum
ggsave(paste0(figures, "allErrorBarsGtPullSum.pdf"), allErrorBarsGtPullSum, width=10, height =6)
ggsave(paste0(figures, "allErrorBarsGtPullSum.svg"), allErrorBarsGtPullSum, width=10, height =6)

# Distance to Mean Approximation
tailWeightsApproxPullSum <- tailWeightsByRound(ex1PullSum$approximationsData, meanApproxByRound(ex1PullSum$approximationsData), errorBars)
tailWeightsToPlotPullSumApprox <- tailWeightsApproxPullSum %>%
filter(round <= 125)
allErrorBarsApproxPullSum <- tailWeightPlot(tailWeightsToPlotPullSumApprox, unname(TeX("$T_{\\bar{Y}}(t)$")))
allErrorBarsApproxPullSum
ggsave(paste0(figures, "allErrorBarsApproxPullSum.pdf"), allErrorBarsApproxPullSum, width=10, height =6)
ggsave(paste0(figures, "allErrorBarsApproxPullSum.svg"), allErrorBarsApproxPullSum, width=10, height =6)



# RandomCallPull
# =================

# Distance to Ground Truth
errorBars = c(10^(1:-2), seq(0.2, 0.9, 0.1))
#errorBars = c(10^(1:-2), seq(0.2, 0.9, 0.1), seq(0.21, 0.29, 0.01))
tailWeightsGtRandomCallPull <- tailWeightsByRound(ex1RandomCallPull$approximationsData, ex1RandomCallPull$groundTruths, errorBars)
tailWeightsToPlotRandomCallPullGt <- tailWeightsGtRandomCallPull %>%
filter(round <= 30)

allErrorBarsGtRandomCallPull <- tailWeightPlot(tailWeightsToPlotRandomCallPullGt, unname(TeX("$T_{gt}(t)$")))
allErrorBarsGtRandomCallPull
ggsave(paste0(figures, "allErrorBarsGtRandomCallPull.pdf"), allErrorBarsGtRandomCallPull, width=10, height =6)
ggsave(paste0(figures, "allErrorBarsGtRandomCallPull.svg"), allErrorBarsGtRandomCallPull, width=10, height =6)

# Distance to Mean Approximation
errorBars = c(10^(1:-10))
tailWeightsApproxRandomCallPull <- tailWeightsByRound(ex1RandomCallPull$approximationsData, meanApproxByRound(ex1RandomCallPull$approximationsData), errorBars)
tailWeightsToPlotRandomCallPullApprox <- tailWeightsApproxRandomCallPull %>%
filter(round <= 85)
allErrorBarsApproxRandomCallPull <- tailWeightPlot(tailWeightsToPlotRandomCallPullApprox, unname(TeX("$T_{\\bar{Y}}(t)$")))
allErrorBarsApproxRandomCallPull
ggsave(paste0(figures, "allErrorBarsApproxRandomCallPull.pdf"), allErrorBarsApproxRandomCallPull, width=10, height =6)
ggsave(paste0(figures, "allErrorBarsApproxRandomCallPull.svg"), allErrorBarsApproxRandomCallPull, width=10, height =6)



# PermutationPull
# =================

# Distance to Ground Truth
errorBars = c(10^(1:-10))
tailWeightsGtPermutationPull <- tailWeightsByRound(ex1PermutationPull$approximationsData, ex1PermutationPull$groundTruths, errorBars)
tailWeightsToPlotPermutationPullGt <- tailWeightsGtPermutationPull %>%
filter(round <= 85)

allErrorBarsGtPermutationPull <- tailWeightPlot(tailWeightsToPlotPermutationPullGt, unname(TeX("$T_{gt}(t)$")))
allErrorBarsGtPermutationPull
ggsave(paste0(figures, "allErrorBarsGtPermutationPull.pdf"), allErrorBarsGtPermutationPull, width=10, height =6)
ggsave(paste0(figures, "allErrorBarsGtPermutationPull.svg"), allErrorBarsGtPermutationPull, width=10, height =6)

# Distance to Mean Approximation
tailWeightsApproxPermutationPull <- tailWeightsByRound(ex1PermutationPull$approximationsData, meanApproxByRound(ex1PermutationPull$approximationsData), errorBars)
tailWeightsToPlotPermutationPullApprox <- tailWeightsApproxPermutationPull %>%
filter(round <= 85)
allErrorBarsApproxPermutationPull <- tailWeightPlot(tailWeightsToPlotPermutationPullApprox, unname(TeX("$T_{\\bar{Y}}(t)$")))
allErrorBarsApproxPermutationPull
ggsave(paste0(figures, "allErrorBarsApproxPermutationPull.pdf"), allErrorBarsApproxPermutationPull, width=10, height =6)
ggsave(paste0(figures, "allErrorBarsApproxPermutationPull.svg"), allErrorBarsApproxPermutationPull, width=10, height =6)



# HistMean
# =================

# Distance to Ground Truth
errorBars = c(10^(1:-2), seq(0.3, 0.9, 0.2))
tailWeightsGtHistMean <- tailWeightsByRound(ex1HistMean$approximationsData, ex1HistMean$groundTruths, errorBars)
tailWeightsToPlotHistMean <- tailWeightsGtHistMean %>%
filter(round <= 25)

allErrorBarsGtHistMean <- tailWeightPlot(tailWeightsToPlotHistMean, unname(TeX("$T_{gt}(t)$")))
allErrorBarsGtHistMean
ggsave(paste0(figures, "allErrorBarsGtHistMean.pdf"), allErrorBarsGtHistMean, width=10, height =6)
ggsave(paste0(figures, "allErrorBarsGtHistMean.svg"), allErrorBarsGtHistMean, width=10, height =6)

# Distance to Mean Approximation
errorBars = c(10^(1:-5))
tailWeightsApproxHistMean <- tailWeightsByRound(ex1HistMean$approximationsData, meanApproxByRound(ex1HistMean$approximationsData), errorBars)
tailWeightsToPlotHistMean <- tailWeightsApproxHistMean %>%
filter(round <= 25)
allErrorBarsApproxHistMean <- tailWeightPlot(tailWeightsToPlotHistMean, unname(TeX("$T_{\\bar{Y}}(t)$")))
allErrorBarsApproxHistMean
ggsave(paste0(figures, "allErrorBarsApproxHistMean.pdf"), allErrorBarsApproxHistMean, width=10, height =6)
ggsave(paste0(figures, "allErrorBarsApproxHistMean.svg"), allErrorBarsApproxHistMean, width=10, height =6)


# =================================================
# Tail Weights for one error bar for all algorithms
# Distance to the ground truth
# =================================================
selectedErrorBar = 0.22
rounds = 30

tailWeightsGtPushSumSingleErrorBar <- tailWeightsByRound(ex1PushSum$approximationsData, ex1PushSum$groundTruths, c(selectedErrorBar)) %>%
filter(round <= rounds)

tailWeightsGtPullSumSingleErrorBar <- tailWeightsByRound(ex1PullSum$approximationsData, ex1PullSum$groundTruths, c(selectedErrorBar)) %>%
filter(round <= rounds)

tailWeightsGtRandomCallPullSingleErrorBar <-  tailWeightsByRound(ex1RandomCallPull$approximationsData, ex1RandomCallPull$groundTruths, c(selectedErrorBar)) %>%
filter(round <= rounds)

tailWeightsGtPermutationPullSingleErrorBar <- tailWeightsByRound(ex1PermutationPull$approximationsData, ex1PermutationPull$groundTruths, c(selectedErrorBar)) %>%
filter(round <= rounds)

tailWeightsGtHistMeanSingleErrorBar <- tailWeightsByRound(ex1HistMean$approximationsData, ex1HistMean$groundTruths, c(selectedErrorBar)) %>%
filter(round <= rounds)


allAlgoOneErrorBarGt <- ggplot()+
geom_line(data=tailWeightsGtPushSumSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Push-Sum"), size=1)+
geom_point(data=tailWeightsGtPushSumSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Push-Sum"), size=2)+
geom_line(data=tailWeightsGtRandomCallPullSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Random-Call-Pull"), size=1)+
geom_point(data=tailWeightsGtRandomCallPullSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Random-Call-Pull"), size=2)+
geom_line(data=tailWeightsGtPermutationPullSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Permutation-Pull"), size=1)+
geom_point(data=tailWeightsGtPermutationPullSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Permutation-Pull"), size=2)+
geom_line(data=tailWeightsGtPullSumSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Pull-Sum"), size=1)+
geom_point(data=tailWeightsGtPullSumSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Pull-Sum"), size=2)+
geom_line(data=tailWeightsGtHistMeanSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Hist-Mean"), size=1)+
geom_point(data=tailWeightsGtHistMeanSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Hist-Mean"), size=2)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.9)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$T_{gt}(t)$")), color = NULL, title=NULL)+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)
allAlgoOneErrorBarGt
ggsave(paste0(figures, "allAlgoOneErrorBarGt.pdf"), allAlgoOneErrorBarGt, width=8, height =4)
ggsave(paste0(figures, "allAlgoOneErrorBarGt.svg"), allAlgoOneErrorBarGt, width=8, height =4)



# =================================================
# Tail Weights for one error bar for all algorithms
# Distance to the mean approximation
# =================================================
rounds = 30

# Calculate the mean approximation
meanApproxPushSum <- meanApproxByRound(ex1PushSum$approximationsData)
meanApproxPullSum <- meanApproxByRound(ex1PullSum$approximationsData)
meanApproxRandomCallPull <- meanApproxByRound(ex1RandomCallPull$approximationsData)
meanApproxPermutationPull <- meanApproxByRound(ex1PermutationPull$approximationsData)
meanApproxHistMean <- meanApproxByRound(ex1HistMean$approximationsData)


tailWeightsApproxPushSumSingleErrorBar <- tailWeightsByRound(ex1PushSum$approximationsData, meanApproxPushSum, c(selectedErrorBar)) %>%
filter(round <= rounds)

tailWeightsApproxPullSumSingleErrorBar <- tailWeightsByRound(ex1PullSum$approximationsData, meanApproxPullSum, c(selectedErrorBar)) %>%
filter(round <= rounds)

tailWeightsApproxRandomCallPullSingleErrorBar <-  tailWeightsByRound(ex1RandomCallPull$approximationsData, meanApproxRandomCallPull, c(selectedErrorBar)) %>%
filter(round <= rounds)

tailWeightsApproxPermutationPullSingleErrorBar <- tailWeightsByRound(ex1PermutationPull$approximationsData, meanApproxPermutationPull, c(selectedErrorBar)) %>%
filter(round <= rounds)

tailWeightsApproxHistMeanSingleErrorBar <- tailWeightsByRound(ex1HistMean$approximationsData, meanApproxHistMean, c(selectedErrorBar)) %>%
filter(round <= rounds)

allAlgoOneErrorBarMeanApprox <- ggplot()+
geom_line(data=tailWeightsApproxPushSumSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Push-Sum"), size=1)+
geom_point(data=tailWeightsApproxPushSumSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Push-Sum"), size=2)+
geom_line(data=tailWeightsApproxPullSumSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Pull-Sum"), size=1)+
geom_point(data=tailWeightsApproxPullSumSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Pull-Sum"), size=2)+
geom_line(data=tailWeightsApproxRandomCallPullSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Random-Call-Pull"), size=1)+
geom_point(data=tailWeightsApproxRandomCallPullSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Random-Call-Pull"), size=2)+
geom_line(data=tailWeightsApproxPermutationPullSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Permutation-Pull"), size=1, linetype="dashed")+
geom_point(data=tailWeightsApproxPermutationPullSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Permutation-Pull"), size=2)+
geom_line(data=tailWeightsApproxHistMeanSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Hist-Mean"), size=1)+
geom_point(data=tailWeightsApproxHistMeanSingleErrorBar, mapping=aes(x=round, y=tailWeight, color="Hist-Mean"), size=2)+
scale_colour_viridis_d(NULL, option="viridis", begin = 0, end = 0.9)+
labs(x=unname(TeX("$t$")), y=unname(TeX("$T_{\\bar{Y}}(t)$")), color = NULL, title=NULL)+
scale_y_log10(breaks=breaks_y, minor_breaks=minor_breaks_y)
allAlgoOneErrorBarMeanApprox
ggsave(paste0(figures, "allAlgoOneErrorBarMeanApprox.pdf"), allAlgoOneErrorBarMeanApprox, width=8, height =4)
ggsave(paste0(figures, "allAlgoOneErrorBarMeanApprox.svg"), allAlgoOneErrorBarMeanApprox, width=8, height =4)




















