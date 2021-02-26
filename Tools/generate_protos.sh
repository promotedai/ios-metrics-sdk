#!/bin/zsh

# Needs to be run manually to sync Swift protobufs when changes occur.
# TODO(yu-hong): Figure out a better way to bring in protobuf libraries.

set -e
setopt extended_glob

SCHEMA_OUT=Sources/SchemaProtos
rm -rf $SCHEMA_OUT

OBJC_OUT=$SCHEMA_OUT/objc
SWIFT_OUT=$SCHEMA_OUT/swift
mkdir -p $OBJC_OUT $SWIFT_OUT
protoc --objc_out=$OBJC_OUT \
       --swift_opt=Visibility=Public \
       --swift_opt=FileNaming=PathToUnderscores \
       --swift_opt=ProtoPathModuleMappings=$(dirname "$0")/schema_proto_package_mapping.asciipb \
       --swift_out=$SWIFT_OUT \
       -I ../schema \
       $@

OBJC_HEADER_ROOT=$OBJC_OUT/headers
mkdir -p $OBJC_HEADER_ROOT
OBJC_PROTO_ROOT=$OBJC_OUT/proto
for file in $OBJC_PROTO_ROOT/**/*.h(.); do
  cp $file $OBJC_HEADER_ROOT/`basename $file`
done
