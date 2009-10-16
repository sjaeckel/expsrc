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
  echo
	echo -e "\t-i"
  echo -e "\t--repo\t\tBase directory of the repository to export"
  echo
	echo -e "\t-o"
  echo -e "\t--output\tDirectory where to output the files"
  echo
	echo -e "\t-p"
  echo -e "\t--parse\t\tFile to parse for the revision tag."
  echo -e "\t\t\tA pattern of files to parse. If this option is not given,"
  echo -e "\t\t\ttags in all files are replaced. Example option would be -p *.c parses"
  echo -e "\t\t\tonly tags in *.c files. This option must be passed for every type of file"
  echo -e
  echo -e "\t--post-hook\tName of a post-generate update script."
  echo -e "\t\t\tAfter generation of the output, a script in the base directory"
  echo -e "\t\t\tis called when available. This script can be used e.g. to copy"
  echo -e "\t\t\tnon-versioned files to the output folder."
  echo -e "\t\t\tThis option defaults to $expsrc_hook_post"
  echo
  echo -e "\t-v\t\tVerbosity level, 0=completely off, 1=default, 5=maximum"
  echo
  echo -e "\t-h"
  echo
  echo -e "\t--help\tThis help"
  echo
  echo -e "<destination> and <source> are optional. The options -i, --repo or -o, --output are"
  echo -e "not taken in account, when the output directories are specified"
  
	exit -1
}

#-------------------------------------------------------------------------------
# Checks the parameter whether it is valid and sets the corresponding global
# variables
#
# @param 1  Verbosity level 1 ... 5
# @param 2  Color of the text
# @param 3 and following  The text to output
# @return   check_params_ret set to the number of values that this option
#           "consumed" including the option specifier.
#-------------------------------------------------------------------------------
_colored_echo()
{

  if [ $# -lt  3 ]
  then
    echo "error in function _colored_echo ... to few arguments."
    return
  fi
  
  #if an verbosity level is passed then check against the given level
  if [ $verb_level -lt $1 ]
  then
    return
  fi
  
  #Check if the verbosity level is 0, then no output is generated at all
  if [ $verb_level -eq 0 ]
  then
    return
  fi
  
  #the text color
  color=$2
  
  shift 1
  local cei=1
  cepasses=$#

  #check which color was used and set it
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
    echo -n "$2 "
    cei=$((cei+1))
    #  in den nächsten Parameter springen
        shift        
    done
  #reset default color
  echo -e -n "\033[0m"
  echo
}

#-------------------------------------------------------------------------------
# Checks the parameter whether it is valid and sets the corresponding global
# variables
#
# @param 1  Option specifier such as '-h', '--repo' anything else
# @param 2  Option value
# @return   check_params_ret set to the number of values that this option
#           "consumed" including the option specifier.
#-------------------------------------------------------------------------------
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
            
    "-p")
            arr_parseFiles[${#arr_parseFiles[*]}]="$2"
            check_params_ret=2;;
            
    "--post-hook")
            expsrc_hook_post="$2"
            check_params_ret=2;;
    "-v")
            verb_level="$2"
            check_params_ret=2;;
            
		*)				
						_colored_echo 1 red Unknown option $1
						_usage
						exit -1;;
	esac

}

#-------------------------------------------------------------------------------
# This function checks, whether the given file should be parsed or not
#
# @param   1 name of the file to check against the pattern
# @return  check_parse_ret set to 1, when the file is to be parsed, otherwise
#          set to 0
#-------------------------------------------------------------------------------
_check_parse()
{
  # Assume file is not to be parsed
  check_parse_ret=0
  
  # Check whether the arrays of patterns is set. If so, the file name
  # must be found in the array in order to be parsed.
  # If the array is empty, all files will be parsed
  if [ ${#arr_parseFiles[*]} -gt 0 ]
  then
    # Iterate through array and check whether the file name matches
    local i
    for i in "${arr_parseFiles[@]}"
    do
       :
       if [[ $1 == $i ]]
       then
         check_parse_ret=1
         _colored_echo 5 blue "OK to parse $1"
         return
       fi
    done
  else
    # Parse pattern array is empty, therefore all files are parsed
    _colored_echo 5 blue "No parse rules, parse $1"
    check_parse_ret=1
    return
  fi
  
  # If we reached this point, parsing is skipped
  _colored_echo 5 blue "Skip parsing for $1"
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
arr_parseFiles=()

#Default verbosity level is 1, basic output
verb_level=1

# Default post generate hook script
expsrc_hook_post="expsrc_hook_post.sh"

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
			break;
		fi

	done
fi

# choose folder from where to fetch input data
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

# continue working now in the input folder
cd $inFolder

# check whether the input directory is dirty, if so, issue a warning that
# the user knows, that the export will not be based on the current working
# tree
test -z "$(git diff-index --name-only HEAD --)" ||
  _colored_echo 1 yellow "Warning: your working tree is dirty! Export is based on HEAD and will not include changes from current working tree!"

# Update the index of the current working tree. This is important to get the
# tags and to generate the version string correctly.
# If it fails, a warning is issued
if [ `git fetch --tags 2>&1 | grep -c "fatal"` != "0" ]; then
  _colored_echo 1 yellow "Warning: git fetch failed, continuing with possibly outdated version"
fi
  
# get version string
git_version=`git describe --tags --always`

# Generate the folder, where to output the content.
# If the outFolder was not explicitely set, generate the name of the
# output folder according to the following pattern:
# expsrc_<Revision>_<yymmdd><HHMMSS>
# where yy: two digit of year
#       mm: two digit of month
#       dd: two digit of day
#       HH: hour of current time
#       MM: minutes of current time
#       SS: seconds of current time
case "$#" in
  2|1)
    outFolder="$1"
    ;;
  0)
    if [ -z "$outFolder" ]
    then
      outFolder="$BASEFOLDER/expsrc_${git_version}_`date -u +%y%m%d_%H%M%S`"
      _colored_echo 5 green "No output folder set, generate folder name"
    else
      _colored_echo 5 green "Use given output folder name"
    fi
    ;;
  *)
    _usage
    ;;
esac

_colored_echo 1 green "Generating version: $git_version"

_colored_echo 1 green "*** Exporting repository : ${inFolder##*/} (${inFolder})"
_colored_echo 1 green "*** Target folder        : ${outFolder##*/} (${outFolder})"

# create this folder if necessary, suppress error
mkdir -p "$outFolder" 2>/dev/null

# fetch all submodules
subModules=`git submodule | awk '{print $2}'`

# call me for all submodules besides myself
for s in $subModules; do
  if [ ! -n "$(echo ${s} | grep "expsrc")" ]; then
    echo ""
    _colored_echo 1 brown "submodule ${s##*/} will be processed now"
    
    # Build a string that can be passed to the command line containing the
    # parsing rules, if any were set
    locParseRulesCmdLine=""
    if [ ${#arr_parseFiles[*]} -gt 0 ]
    then
       # Iterate through array and check whether the file name matches
      locParseRule=
      for locParseRule in "${arr_parseFiles[@]}"
      do
         locParseRulesCmdLine="${locParseRulesCmdLine} -p $locParseRule"
      done
    fi
    
    $THIS -v "$verb_level" $locParseRulesCmdLine "${outFolder}/${s}" "${PWD}/${s}"
  fi
done

# this will be the revision that is inserted in the files
REVSTRING="${git_version}"

# fetch all files that have to be parsed
filesToParse=`git ls-files`

# read these files directly out of the repository and parse them to their destination
for i in $filesToParse; do
  if [ ! -n "$(echo ${i} | grep "expsrc")" ] && [ ! -d "${i%}" ]; then
    
    # check if we must generate directory before
    if [ -d "${i%/*}" ] && [ ! -e "${outFolder}/${i%/*}" ]; then
      mkdir -p "${outFolder}/${i%/*}"
    fi
    
    # Check if the file must be parsed
    # The function _check_parse checks the file name against the mapping
    # of the -p or --parse attributes
    _check_parse "${i}"
    
    if [ $check_parse_ret -gt 0 ]
    then
      git show HEAD:"${i}" 2>/dev/null | \
        sed -c -e 's/\$Revision.*\$/'"$REVSTRING"'/Ig' > \
          "${outFolder}/${i}"
    else
      git show HEAD:"${i}" 2>/dev/null > \
          "${outFolder}/${i}"
    fi
  fi
done

cd $outFolder

# finally remove possible existent .gitmodules/.gitgnore files
for g in `find . \( -name .gitmodules -or -name .gitignore \)`; do
  rm -rf $g
done

# Check if in the input folder the script '$expsrc_hook_post' exists, then
# call this script with the argument version and output folder
if [ -f "${inFolder}/${expsrc_hook_post}" ]
  then
        _colored_echo 5 green "Call post create script $expsrc_hook_post"
      ${inFolder}/${expsrc_hook_post} "$git_version" "$inFolder" "$outFolder"
  else
      _colored_echo 5 green "No post create script found, skip this step"
fi


case "$#" in
  2)
    echo ""
    ;;
  1|0)
    echo ""
    _colored_echo 1 green "*** Finished Export"
    _colored_echo 1 green "**** output can be found in $outFolder"
    echo ""
    ;;
  *)
    _usage
    ;;
esac
