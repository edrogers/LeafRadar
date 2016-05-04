#!/bin/bash

modelDir="/home/${USER}/LeafRadar"
cd ${modelDir}
Rscript ${modelDir}/testModel.R > /dev/null 2>&1

exit 0
