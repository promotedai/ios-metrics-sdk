#!/bin/zsh

# Needs to be run manually to sync Swift protobufs when changes occur.
# TODO(yu-hong): Figure out a better way to bring in protobuf libraries.

set -e
setopt extended_glob

OBJC_OUT=Sources/SchemaProtos/objc
SWIFT_OUT=Sources/SchemaProtos/swift
mkdir -p $OBJC_OUT $SWIFT_OUT
protoc --objc_out=$OBJC_OUT \
       --swift_opt=Visibility=Public \
       --swift_opt=FileNaming=PathToUnderscores \
       --swift_out=$SWIFT_OUT \
       -I ../schema \
       ../schema/proto/**/*.proto

#perl -i -p0e \
#     's! #import <Protobuf/GPBProtocolBuffers.*.h>! #import <Protobuf/GPBProtocolBuffers_RuntimeSupport.h>\n#elif USE_SWIFT_PACKAGE_PROTOBUF_IMPORT\n \@import Protobuf;!g' \
#     $OBJC_OUT/**/*.m $OBJC_OUT/**/*.h

OBJC_HEADER_ROOT=$OBJC_OUT/headers
mkdir -p $OBJC_HEADER_ROOT
OBJC_PROTO_ROOT=$OBJC_OUT/proto
for file in $OBJC_PROTO_ROOT/**/*.h(.); do
  prefix=`echo $file | \
    sed -E 's!'"$OBJC_PROTO_ROOT"'/(([a-z]+/)*)[a-z]+/[^/]+!\1!g' | \
    awk 'BEGIN{FS="/"; OFS="";} {for (i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'`
  cp $file $OBJC_HEADER_ROOT/$prefix`basename $file`
done
