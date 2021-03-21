#!/bin/zsh

Tools/generate_protos.sh PromotedAIMetricsSDK \
  ../schema/proto/common/**/*.proto \
  ../schema/proto/event/**/*.proto \
  ../schema/proto/promotion/**/*.proto
