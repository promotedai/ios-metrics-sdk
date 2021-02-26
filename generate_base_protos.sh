#!/bin/zsh

Tools/generate_protos.sh \
  ../schema/proto/common/**/*.proto \
  ../schema/proto/event/**/*.proto \
  ../schema/proto/pacing/**/*.proto \
  ../schema/proto/promotion/**/*.proto
