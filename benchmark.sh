#!/bin/zsh
# FIXME Find a way to break up long command calls into multiple lines without inserting line breaks

DATASET_NAME=$1
RELATIVE_PATH_TO_DATASET=$2
TIMEOUT=$3

# Experiments 1-6, one-way in both directions
## DOPLER (alias "dm" = decision model)
for run in {1..5}; do
#rm -rfv /tmp/${DATASET_NAME}_out-dopler
mkdir ${DATASET_NAME}_results${run}
retry --until=success --delay 1 -- mvn exec:java \
 -Dexec.args="-v transform $RELATIVE_PATH_TO_DATASET /tmp/${DATASET_NAME}_out-dopler --sourceType=uvl --targetType=DOPLER --benchmark=modelSize,transformationTime,complexity --strategy=ONE_WAY -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_uvl2dm.csv --timeout $TIMEOUT"

## FeatureIDE (alias "fide")
retry --until=success --delay 1 -- mvn exec:java \
  -Dexec.args="-v transform $RELATIVE_PATH_TO_DATASET . --sourceType=uvl --targetType=FeatureIDE --benchmark=modelSize,transformationTime,complexity --strategy=ONE_WAY -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_uvl2fide.csv --timeout $TIMEOUT --no-serialize"

## Kconfig (alias "kc")
retry --until=success --delay 1 -- mvn exec:java \
  -Dexec.args="-v transform $RELATIVE_PATH_TO_DATASET .  --sourceType=uvl --targetType=Kconfig --benchmark=modelSize,transformationTime,complexity --strategy=ONE_WAY -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_uvl2kc.csv --timeout $TIMEOUT --no-serialize"

# Reverse transformations for each plugin
# For DOPLER, use previously generated DOPLER files (in-place reverse transformation doesn't work!)
retry --until=success --delay 1 -- mvn exec:java \
  -Dexec.args="-v transform /tmp/${DATASET_NAME}_out-dopler . --sourceType=DOPLER --targetType=uvl --benchmark=modelSize,transformationTime,complexity --strategy=ONE_WAY -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_dm2uvl.csv --timeout $TIMEOUT --no-serialize"

## FeatureIDE
retry --until=success --delay 1 -- mvn exec:java \
  -Dexec.args="-v transform $RELATIVE_PATH_TO_DATASET . --sourceType=uvl --targetType=FeatureIDE --benchmark=modelSize,transformationTime,complexity --strategy=ONE_WAY -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_fide2uvl.csv --timeout $TIMEOUT --no-serialize --reverse-transformation"

## Kconfig
retry --until=success --delay 1 -- mvn exec:java \
  -Dexec.args="-v transform $RELATIVE_PATH_TO_DATASET . --sourceType=uvl --targetType=Kconfig --benchmark=modelSize,transformationTime,complexity --strategy=ONE_WAY -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_kc2uvl.csv --timeout $TIMEOUT --no-serialize --reverse-transformation"

# Experiments 7-9, roundtrip over different plugins
# For DOPLER, two partial transformations with serialization inbetween, somehow merge dataset manually?
rm -rfv /tmp/${DATASET_NAME}_out-dopler_roundtrip
retry --until=success --delay 1 -- mvn exec:java \
  -Dexec.args="-v transform $RELATIVE_PATH_TO_DATASET /tmp/${DATASET_NAME}_out-dopler_roundtrip --sourceType=uvl --targetType=DOPLER --benchmark=modelSize,transformationTime,complexity --strategy=ROUNDTRIP -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_roundtrip@dopler_forward.csv --timeout $TIMEOUT"

retry --until=success --delay 1 -- mvn exec:java \
  -Dexec.args="-v transform /tmp/${DATASET_NAME}_out-dopler_roundtrip . --sourceType=DOPLER --targetType=uvl --benchmark=modelSize,transformationTime,complexity --strategy=ROUNDTRIP -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_roundtrip@dopler_backward.csv --timeout $TIMEOUT --no-serialize"

## FeatureIDE (forward+backward)
retry --until=success --delay 1 -- mvn exec:java \
  -Dexec.args="-v transform $RELATIVE_PATH_TO_DATASET . --sourceType=uvl --targetType=FeatureIDE --benchmark=modelSize,transformationTime,complexity --strategy=ROUNDTRIP -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_roundtrip@fide_forward.csv --timeout $TIMEOUT --no-serialize"

retry --until=success --delay 1 -- mvn exec:java \
  -Dexec.args="-v transform $RELATIVE_PATH_TO_DATASET . --sourceType=uvl --targetType=FeatureIDE --benchmark=modelSize,transformationTime,complexity --strategy=ROUNDTRIP -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_roundtrip@fide_backward.csv --timeout $TIMEOUT --no-serialize --reverse-transformation"

## Kconfig (forward+backward)
retry --until=success --delay 1 -- mvn exec:java \
  -Dexec.args="-v transform $RELATIVE_PATH_TO_DATASET . --sourceType=uvl --targetType=Kconfig --benchmark=modelSize,transformationTime,complexity --strategy=ROUNDTRIP -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_roundtrip@kc_forward.csv --timeout $TIMEOUT --no-serialize"

retry --until=success --delay 1 -- mvn exec:java \
  -Dexec.args="-v transform $RELATIVE_PATH_TO_DATASET . --sourceType=uvl --targetType=Kconfig --benchmark=modelSize,transformationTime,complexity --strategy=ROUNDTRIP -wb ${DATASET_NAME}_results${run}/${DATASET_NAME}_roundtrip@kc_backward.csv --timeout $TIMEOUT --no-serialize --reverse-transformation"

done

### Additional experiments 10-15? Random combination of x-to-y transformations
