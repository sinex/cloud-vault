#!/bin/sh
set -e

ERROR=0
missing_parameter(){
    echo "Parameter required: $1";
    ERROR=1
}
if [ -z "$TFC_TOKEN" ]; then missing_parameter token ; fi
if [ -z "$TFC_ORG" ]; then missing_parameter org ; fi
if [ -z "$TFC_WORKSPACE" ]; then missing_parameter workspace ; fi
if [ -z "$TFC_VARIABLES" ]; then missing_parameter variables ; fi
if [ $ERROR -eq 1 ]; then exit 1; fi

extract_key(){
    echo "$2" | sed "s/.*\"$1\": *\"\([^\"]*\).*/\1/"
}

set -u

echo "$TFC_VARIABLES" | sed -n 1'p' | tr ',' '\n' | while read -r variable; do
    if [ -z "$variable" ]; then continue; fi
    response=$(tfc-cli stateversions current getoutput -workspace "$TFC_WORKSPACE" -name "$variable")
    echo "::set-output name=$(extract_key name "$response")::$(extract_key value "$response")"
done
