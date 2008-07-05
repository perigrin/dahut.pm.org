#!/bin/bash 
# check.cgi - Validate Referer
# Author: Sean B. Palmer, inamidst.com
# Source: http://inamidst.com/proj/valid/source

DOCTYPE='XHTML 1.0 Transitional'
URI=${HTTP_REFERER:-'-'}

function serve() { 
   echo Content-Type: image/png
   echo && cat $1
}

case $URI in 
   http://$SERVER_NAME/*) :;;
   *) serve images/logo.png; exit;;
esac

QUERY="?
   uri = ${URI//;/%3B};
   doctype = ${DOCTYPE// /+};
   output = xml
"

curl -Is http://validator.w3.org/check$(tr -d " \n" <<<$QUERY) | \
   grep -q 'X-W3C-Validator-Status: Valid'

STATUS=${?/1/in}valid
STATUS=${STATUS#0}

echo X-Validation-Status: $STATUS
serve images/$STATUS.png

# [EOF]
