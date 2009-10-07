#!/bin/sh
#
# script to export the sourcecode of a repository

function usage {
  echo "This script exports the source of a repository with revision string in the code"
  echo "usage: ${0##*/} <to> <from>"
  exit -1
}

echo "I've been called with params"
echo "1: $1"
echo "2: $2"

BASEFOLDER=$PWD

THIS=${PWD}/${0##*/}

case "$#" in
  2)
    inFolder="$2"
    ;;
  1|0)
    inFolder=${PWD%/${PWD##*/}}
    ;;
  *)
    usage
    ;;
esac

echo "doing stuff based in $inFolder"
cd $inFolder

if [ `git fetch --tags 2>&1 | grep -c "fatal"` != "0" ]; then
  echo "git fetch failed"
fi

git_version=`git describe --tags --always`

test -z "$(git diff-index --name-only HEAD --)" ||
	git_version="${git_version}-dirty"

echo "Generating version: $git_version"

case "$#" in
  2|1)
    outFolder="$1"
    ;;
  0)
    outFolder="$BASEFOLDER/expsrc_${git_version}_`date -u +%y%m%d_%H%M%S`"
    ;;
  *)
    usage
    ;;
esac

echo $outFolder

mkdir -p $outFolder

subModules=`git submodule | awk '{print $2}'`

for s in $subModules; do
  $THIS "${outFolder}/${s}" "${PWD}/${s}"
done

cp --parents `git ls-files` $outFolder

cd $outFolder

for g in `find . -name .gitignore`; do
  rm -rf $g
done

for h in `find . -name .gitmodules`; do
  rm -rf $h
done

filesToParse=`find . -name *.h -type f`

TEMPFILE="$TMP/tmp.$$"

REVSTRING="Revision: ${git_version}"

echo $REVSTRING

for i in $filesToParse; do
  sed -e 's/\$Revision\$/'"$REVSTRING"'/g' "$i" > "$TEMPFILE" && cat "$TEMPFILE" > "${i}"
done

rm -rf "$TEMPFILE"

echo "I returned"