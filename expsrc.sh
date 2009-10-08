#!/bin/sh
#
# script to export the sourcecode of a repository

_usage() 
{
  echo "This script exports the source of a repository with revision string in the code"
  echo "usage: ${0##*/} <to> <from>"
  exit -1
}

_colored_echo()
{

  if [ $# -lt  2 ]
  then
    echo "error in function _colored_echo ... to few arguments."
    exit -1
  fi  
  
  #the text color
  color=$1
  
  shift 1
  local cei=1
  cepasses=$#

  #check which color was used snd set it
  case $color in
    "black")        echo -e -n "\033[47;30m" ;;
    "red")          echo -e -n "\033[1;40;31m" ;;
    "green")        echo -e -n "\033[1;40;32m" ;;
    "dgreen")       echo -e -n "\033[0;40;32m" ;;
    "yellow")       echo -e -n "\033[1;40;33m" ;;
    "brown")        echo -e -n "\033[0;40;33m" ;;
    "blue")         echo -e -n "\033[1;40;34m" ;;
    "magenta")      echo -e -n "\033[1;40;35m" ;;
    "cyan")         echo -e -n "\033[1;40;36m" ;;
    "white")        echo -e -n "\033[1;40;37m" ;;
  esac
  
   while [ $cei -le $cepasses ]
   do
    #print the given text
    echo -n "$1 "
    cei=$((cei+1))
    #  in den nächsten Parameter springen
        shift        
    done
  #reset default color
  echo -e -n "\033[0m"
  echo
}

###############################################################################
#                               GLOBAL VARIABLES                              #
###############################################################################

# base directory
BASEFOLDER=$PWD

# rememeber my full name to call me later
THIS=${PWD}/${0##*/}

###############################################################################
#                                  MAIN BODY                                  #
###############################################################################

# choose folder from where to fetch input data
case "$#" in
  2)
    inFolder="$2"
    ;;
  1|0)
    inFolder=${PWD%/${PWD##*/}}
    echo ""
    _colored_echo green "*** Exporting repository ${inFolder##*/}"
    ;;
  *)
    _usage
    ;;
esac

cd $inFolder

# fetch latest version, on fail print warning but continue
if [ `git fetch --tags 2>&1 | grep -c "fatal"` != "0" ]; then
  _colored_echo yellow "Warning: git fetch failed, continuing with possibly outdated version"
fi

# get version string
git_version=`git describe --tags --always`

# check if the working tree is clean, if not add "-dirty" to versionstring
test -z "$(git diff-index --name-only HEAD --)" ||
  git_version="${git_version}-dirty"

# choose folder where to put output data
case "$#" in
  2|1)
    outFolder="$1"
    ;;
  0)
    outFolder="$BASEFOLDER/expsrc_${git_version}_`date -u +%y%m%d_%H%M%S`"
    ;;
  *)
    _usage
    ;;
esac

# create this folder if necessary, suppress error
mkdir -p $outFolder 2>/dev/null

# fetch all submodules
subModules=`git submodule | awk '{print $2}'`

# call me for all submodules besides myself
for s in $subModules; do
  if [ ! -n "$(echo ${s} | grep "expsrc")" ]; then
    echo ""
    _colored_echo brown "submodule ${s##*/} will be processed now"
    $THIS "${outFolder}/${s}" "${PWD}/${s}"
  fi
done

if [ "$#" != "2" ]; then
  _colored_echo dgreen "root project ${inFolder##*/} will be processed now"
fi
echo "Generating version: $git_version"

# create subdirectories that will be filled in the next step, but since I will not be exported, not for me
for d in `ls -R | grep ":$" | sed -e 's/:$//' -e 's/^.//' -e 's/^\///' | grep -v "expsrc"`; do
  test -n "$(echo ${s} | grep "expsrc\/")" ||
    mkdir -p "${outFolder}/${d}" 2>/dev/null
done

# this will be the revision that is inserted in the files
REVSTRING="Revision: ${git_version}"

# fetch all files that have to be parsed
filesToParse=`git ls-files`

# read these files directly out of the repository and parse them to their destination
for i in $filesToParse; do
  if ([ ! -n "$(echo ${i} | grep "expsrc")" ] && [ ! -e "${outFolder}/${i}" ]); then
    git show HEAD:"${i}" 2>/dev/null | \
      sed -e 's/\$Revision.*\$/'"$REVSTRING"'/Ig' > \
        "${outFolder}/${i}"
  fi
done

cd $outFolder

# finally remove possible existent .gitmodules/.gitgnore files
for g in `find . \( -name .gitmodules -or -name .gitignore \)`; do
  rm -rf $g
done

case "$#" in
  2)
    echo ""
    ;;
  1|0)
    echo ""
    _colored_echo green "*** Finished Export"
    _colored_echo green "**** output can be found in $outFolder"
    echo ""
    ;;
  *)
    _usage
    ;;
esac
