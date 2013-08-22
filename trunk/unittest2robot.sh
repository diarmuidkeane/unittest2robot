#!/bin/bash

CUR_OS=$(uname -s)

if [ ${CUR_OS} == "Darwin" ]; then
#   echo "Mac OS X"
   export ALIAS_SED=`which gsed`
   export ALIAS_PYTHON=`which python2.7`
else
#   echo "nix (NOT MAC)"
   export ALIAS_SED=`which gsed`
   export ALIAS_PYTHON=`which python2.7`
fi

underscore2camel() {
  local command="import robot_util;print robot_util.underscoreToCamel('$1')"
  local camelVal=$("$ALIAS_PYTHON" -c "$command")
  echo "${camelVal}"
}

camel2underscore() {
  local command="import robot_util;print robot_util.camelToUnderscore('$1')"
  local underscoreVal=$("$ALIAS_PYTHON" -c "$command")
  echo "${underscoreVal}"
}

buildLibrary() {
  local basicName=$(basename $1)
  local fileName=${basicName%%.*}
  classVars=$("$ALIAS_SED" -n "/^class/ s/^class[ ]*\([A-Za-z]*\)(\([^)]*\))[ ]*:/className=\1;superClass=\2/p" $basicName)
  eval `echo ${classVars}` 
  if [[ "${superClass}" != "unittest.TestCase" && "${superClass}" != "TestCase" ]]
  then 
    return
  fi
"$ALIAS_SED" -e "1i\
from $fileName import ${className}\n\nclass ${className}Library(object):\n    def __init__(self):\n        self._result = \'\'\n" -ne  "s/^[^#].*def[ ]*\(test[A-Z_a-z0-9]*\).*/    def \1(self):\n        o=$className(\'\1\')\n        o.setUp()\n        o.\1()\n        o.tearDown()\n/p" $basicName | "$ALIAS_SED" '/def/ s/\([A-Z]\)/_\l\1/g' | "$ALIAS_SED" '/def/ s/^_\([a-z]\)/\1/g' > ${className}Library.py
#  "$ALIAS_SED" -n "/^class/ s/^class[ ]*\([A-Za-z]*\).*/from $fileName import ${className}\n\nclass ${className}Library(object):\n    def __init__(self):\n        self._result = \'\'\n/gp;s/^[^#].*def[ ]*\(test[A-Z_a-z0-9]*\).*/    def \1(self):\n        o=$className(\'\1\')\n        o.setUp()\n        o.\1()\n        o.tearDown()\n/p" $basicName | "$ALIAS_SED" '/def/ s/\([A-Z]\)/_\l\1/g' | "$ALIAS_SED" '/def/ s/^_\([a-z]\)/\1/g' > ${className}Library.py
}

buildTest(){
  local basicName=$(basename $1)
  local fileName=${basicName%%.*}

  cat $basicName | "$ALIAS_SED" -e "1i\
*** Settings ***\n\
Library           $fileName\n\
\n\
*** Test Cases ***" -ne '/init/ d;s/\(([^)]*):\)//;/def/ s/_/ /g;/def/ s/^[ ]*def[ ]*\(.*\)$/\1/;/^test/p;s/^test/     test/p' > ${fileName}.txt

}

export -f buildLibrary 
export -f buildTest
export -f underscore2camel 

target=$1
find . -name "*Library.txt" -exec rm -rf {} \;
find . -name "*Library.py" -exec rm -rf {} \;
find . \! -size 0c -name "${target}*.py" -exec bash -c 'buildLibrary "$0"' {} \;
find . -name "*Library.py" -exec bash -c 'buildTest "$0"' {} \;

