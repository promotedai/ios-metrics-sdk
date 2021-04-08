#!/bin/zsh

Tools/generate_protos.sh PromotedAIMetricsSDK \
  ../schema/proto/common/common.proto \
  ../schema/proto/delivery/delivery.proto \
  ../schema/proto/event/event.proto \
  ../schema/proto/promotion/promotion.proto
