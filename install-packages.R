install.packages(c(
  'Rserve',
  'ptw',
  'gplots',
  'baseline',
  'hyperSpec',
  'ggplot2',
  'erah',
  'mclust', 'matrixStats',
  'glmnet'))

source("https://bioconductor.org/biocLite.R")

biocLite(c(
  'xcms',
  'CAMERA',
  'PROcess',
  'targetSearch',
  'limma',
  'RUVnormalize',
  'RUVSeq',
  'sva'))

# show installed packges

ip = as.data.frame(installed.packages()[,c(1,3:4)])
ip = ip[is.na(ip$Priority),1:2, drop=FALSE]
print(ip[order(ip$Package),c(1,2)], row.names=FALSE)
