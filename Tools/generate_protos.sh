#!/bin/zsh

# Needs to be run manually to sync Swift protobufs when changes occur.
# TODO(yu-hong): Figure out a better way to bring in protobuf libraries.

set -e
setopt extended_glob

SCHEMA_OUT=Sources/$1/SchemaProtos
shift

rm -rf $SCHEMA_OUT
mkdir -p $SCHEMA_OUT
protoc --swift_opt=Visibility=Public \
       --swift_opt=FileNaming=PathToUnderscores \
       --swift_opt=ProtoPathModuleMappings=$(dirname "$0")/schema_proto_package_mapping.asciipb \
       --swift_out=$SCHEMA_OUT \
       -I ../schema \
       $@
