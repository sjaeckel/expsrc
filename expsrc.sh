#!/bin/sh
#
# script to export the sourcecode of a repository

_usage() 
{
	echo -e
	echo -e "${0##*/} version `git describe --tags --always`"
	echo -e "Copyright Steinbeis Transfer Center Embedded Design and Networking, 2009"
	echo -e
	echo "This script exports the source of a repository with revision string in the code"
	echo -e
	echo -e "Usage: ${0##*/}[options] <destination> <source>"
	echo -e "\t-i|--repo\tBase directory of the repository to export"
	echo -e "\t-o|--output\tDirectory where to output the files"
  echo -e "\t-h|--help\tThis help"
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

_check_params()
{
	option=$1	
	
	case $option in
		"-h")
						_usage
						exit 0;;
		"--help")
						_usage
						exit 0;;
		"-p")
						echo "-p option"
						check_params_ret=2;;
            
    "-i")
            inFolder="$2"
            check_params_ret=2;;
    "-repo")
            inFolder="$2"
            check_params_ret=2;;
    "-o")
            outFolder="$2"
            check_params_ret=2;;

    "-output")
            outFolder="$2"
            check_params_ret=2;;
		*)				
						_colored_echo red Unknown option $1
						_usage
						exit -1;;
	esac

}

#-------------------------------------------------------------------------------
# This function checks, whether the given file should be parsed or not
#
# @param   1 name of the file to check against the patter
# @return  check_parse_ret set to 1, when the file is to be parsed, otherwise
#          set to 0
#-------------------------------------------------------------------------------
_check_parse()
{
  
  
  check_parse_ret=0
}

###############################################################################
#                               GLOBAL VARIABLES                              #
###############################################################################

# base directory
BASEFOLDER=$PWD

# rememeber my full name to call me later
THIS=${PWD}/${0##*/}

# input directory
# This is the directory of the project which is to be exported.
# If not given, the directory
inFolder=

# output directory
outFolder=


# array of patterns for files to include in parsing. If left empty
# all files are parsed
arr_parseFiles=



###############################################################################
#                                  MAIN BODY                                  #
###############################################################################


# Parse command line arguments
i=1
passes=$#

if [ $passes -gt 0 ]
then
	while [ $i -le $passes ]
	 do
		option="$1"
		param="$2"

    # Check if the option starts with a leading '-' then it is an 
		# option, otherwise we reached the end of the options and can
		# continue with the script
		
		if [[ $option == -* ]]
		then	
			_check_params "$option" "$param"
					
			i=$((check_params_ret+1))	
			shift $check_params_ret		
		else
			echo "end of options reached"
			break;
		fi

	done
fi

# choose folder from where to fetch input data
if [ -z "$inFolder" ]
then
  case "$#" in
    2)
      inFolder="$2"
      ;;
    1|0)
      inFolder=${PWD%/${PWD##*/}}
      ;;
    *)
      _usage
      ;;
  esac
fi

# choose folder where to put output data
if [ -z "$outFolder" ]
then
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
fi

_colored_echo green "*** Exporting repository : ${inFolder##*/}"
_colored_echo green "*** Target folder        : ${outFolder##*/}"

cd $inFolder

# fetch latest version, on fail print warning but continue
if [ `git fetch --tags 2>&1 | grep -c "fatal"` != "0" ]; then
  _colored_echo yellow "Warning: git fetch failed, continuing with possibly outdated version"
fi

# get version string
git_version=`git describe --tags --always`

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

# this will be the revision that is inserted in the files
REVSTRING="Revision: ${git_version}"

# fetch all files that have to be parsed
filesToParse=`git ls-files`

# read these files directly out of the repository and parse them to their destination
for i in $filesToParse; do
  if [ ! -n "$(echo ${i} | grep "expsrc")" ] && [ ! -d "${i%}" ]; then
    # check if we must generate directory before
    if [ -d "${i%/*}" ] && [ ! -e "${outFolder}/${i%/*}" ]; then
      mkdir -p "${outFolder}/${i%/*}"
    fi
    
    git show HEAD:"${i}" 2>/dev/null | \
      sed -c -e 's/\$Revision.*\$/'"$REVSTRING"'/Ig' > \
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
