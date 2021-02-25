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
       --swift_opt=ProtoPathModuleMappings=schema_proto_package_mapping.asciipb \
       --swift_out=$SWIFT_OUT \
       -I ../schema \
       ../schema/proto/**/*.proto

OBJC_HEADER_ROOT=$OBJC_OUT/headers
mkdir -p $OBJC_HEADER_ROOT
OBJC_PROTO_ROOT=$OBJC_OUT/proto
for file in $OBJC_PROTO_ROOT/**/*(.); do
  prefix=`echo $file | \
    sed -E 's!'"$OBJC_PROTO_ROOT"'/(([a-z]+/)*)[a-z]+/[^/]+!\1!g' | \
    awk 'BEGIN{FS="/"; OFS="";} {for (i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'`
  case $file in
  *.h) 
    cp $file $OBJC_HEADER_ROOT/$prefix`basename $file`
    ;;
  *.m)
    mv $file `dirname $file`/$prefix`basename $file`
    ;;
  esac
done
