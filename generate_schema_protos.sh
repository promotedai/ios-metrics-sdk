#!/bin/zsh

Tools/generate_protos.sh PromotedCore \
  ../schema/proto/common/common.proto \
  ../schema/proto/delivery/blender.proto \
  ../schema/proto/delivery/delivery.proto \
  ../schema/proto/event/event.proto
