#!/bin/bash

modelDir="/home/ed/Documents/LeafRadar"
cd ${modelDir}
Rscript ${modelDir}/testModel.R > /dev/null 2>&1

exit 0
