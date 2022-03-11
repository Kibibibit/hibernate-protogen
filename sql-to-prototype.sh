#!/bin/bash

SQL_TYPE=$1
VAR=$2
KEY=$3



declare -A types

types=(
    ["varchar"]="string"
    ["bigint"]="int64"
    ["datetime"]="int64"
    ["date"]="int64"
    ["int"]="int32"
    ["bit"]="bool"
    ["double"]="double"
    ["longtext"]="string"
    ["time"]="int64"
    ## Possibly change to something better
    ["tinyblob"]="int64"

)

PROTO_TYPE="${types[$SQL_TYPE]}"

if  [ ! "$KEY" = "PRI" ] && [ ! "$VAR" = "dtype" ]
then
    PROTO_TYPE="optional $PROTO_TYPE"
fi

if [ -z "$PROTO_TYPE" ]
then
    PROTO_TYPE="$SQL_TYPE?"
fi


echo $PROTO_TYPE 