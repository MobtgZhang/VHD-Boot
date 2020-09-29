#!/bin/sh
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )" 
# grab per revision, eg @81014
# check with https://www.virtualbox.org/browser/vbox/trunk be careful about
# bleeding edge versions!
svn co http://www.virtualbox.org/svn/vbox/trunk/include@81014 ${SCRIPT_DIR}/include/
