#!/bin/bash

bash ./scripts/download-inputs.sh
bash ./scripts/assets-make-segments.sh
bash ./scripts/assets-make-variants.sh
bash ./scripts/assets-make-cmaf.sh
bash ./scripts/assets-make-encrypted.sh