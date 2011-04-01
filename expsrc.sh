#!/bin/sh
#
# script to export the sourcecode of a repository

_usage() 
{
  echo -e
  echo -e "expsrc.sh version $ExpSrcVersion$"
  echo -e "Copyright Steinbeis Transfer Center Embedded Design and Networking, 2010"
  echo
  echo -e "This script exports the source of a repository with revision string in the code"
  echo
  echo -e "Usage: ${0##*/} [options] <destination> <source>"
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
  echo
  echo -e "\t--config\tUse alternative config file than $expsrc_config"
  echo -e "\t\t\tInstead of specifying configuration options on the command line"
  echo -e "\t\t\ta configuration file can be placed in the root directory of"
  echo -e "\t\t\tof the given project to export the sources. The default name"
  echo -e "\t\t\tof this file is called \"expsrc.cfg\". If an alternative file"
  echo -e "\t\t\tis to be used, this parameter can be given with the given file name."
  echo
  echo -e "\t--override-cfg\tDo not use a config file"
  echo -e "\t\t\tThis will force me not to use a config file, even if given as parameter"
  echo
  echo -e "\t--post-hook\tName of a post-generate update script."
  echo -e "\t\t\tAfter generation of the output, a script in the base directory"
  echo -e "\t\t\tis called when available. This script can be used e.g. to copy"
  echo -e "\t\t\tnon-versioned files to the output folder."
  echo -e "\t\t\tThis option defaults to $expsrc_hook_post"
  echo
  echo -e "\t--tRev\t\tAlternative tag to replace with the revision string."
  echo -e "\t\t\tBy default, expsrc.sh parses the file for the tag \$Version.*\$."
  echo -e "\t\t\tWith this option, the name in the tag can be overridden, such"
  echo -e "\t\t\tas -tRev \"some_other_tag_name\". The dollar signs, however"
  echo -e "\t\t\tremain as delimiter for the tag."
  echo
  echo -e "\t--svntags\tParse more SVN tags of files"
  echo -e "\t\t\tParses the standard SVN Keywords: \$Revision\$, \$Author\$, \$Date\$ and \$Id\$"
  echo -e "\t\t\t\tand the custom Keyword: \$LatestVersion\$"
  echo -e "\t\t\tand inserts the fitting value as done by SVN."
  echo -e "\t\t\t\te.g.: \$Revision\$ will become \$Revision: MY_TAG \$"
  echo -e "\t\t\tThe parameter that is given to the option \"--tRev\" and the Keyword \$LatestVersion\$"
  echo -e "\t\t\twill simply be substituted by the most actual tag!"
  echo -e "\t\t\t\te.g.: option \"--tRev Version\" leads to replacement of \$Version\$ by MY_TAG"
  echo -e "\t\t\tThe parameter that is given to the option \"--tRev\" is considered first,"
  echo -e "\t\t\tso substitution of SVN Keywords by usage of \"--tRev\" is not recommended."
  echo
  echo -e "\t--original-tags\tLet the tag-name untouched"
  echo -e "\t\t\tStandard behavior is to strip all additional characters from the tag,"
  echo -e "\t\t\tthis option disables this behavior. Nonetheless, tags that are already"
  echo -e "\t\t\tin semver style will have removed the leading 'v'!"
  echo
  echo -e "\t--no-fetch\tDo not fetch the repository initially."
  echo  
  echo -e "\t--myself\tAllow export of myself, only required when this script should be exported."
  echo  
  echo -e "\t-v\t\tVerbosity level, 0=completely off, 1=default, 5=maximum"
  echo
  echo -e "\t-e\t\tOpen explorer window after export"
  echo
  echo -e "\t-h"
  echo -e "\t--help\t\tThis help"
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
        "-h" | "--help")
                _usage;;
                
        "--repo" | "-i")
                # convert the path to an absolute path and save it
                inFolder=$(cd "$2"; /bin/pwd)
                check_params_ret=2
                ;;
                
        "--output" | "-o")
                # check if the output folder exists already, if not create it
                [ -d "$2" ] || `/bin/mkdir -p "$2"`
                # convert the path to an absolute path and save it
                outFolder=$(cd "$2"; /bin/pwd)
                check_params_ret=2
                ;;
                
        "-p")
                arr_parseFiles[${#arr_parseFiles[*]}]="$2"
                check_params_ret=2;;
        "--tRev")
                if [ "$2" == "Revision" ] || [ "$2" == "Author" ] || [ "$2" == "Id" ] || [ "$2" == "Date" ] || [ "$2" == "HeadURL" ]; then
                  _colored_echo 1 yellow Warning: I hope you are sure that you want to replace a standard SVN Keyword
                fi
                tagRevision="$2"
                check_params_ret=2;;
                
        "--post-hook")
                expsrc_hook_post="$2"
                check_params_ret=2;;
        "--config")
                expsrc_config="$2"
                check_params_ret=2;;
        "--override-cfg")
                ignore_cfg=1
                check_params_ret=1;;
        "-v")
                verb_level="$2"
                check_params_ret=2;;
        "-e")
                open_explorer=1
                check_params_ret=1;;
        "--svntags")
                svntags_parse=1
                check_params_ret=1;;
        "--original-tags")
                clean_tags=0
                check_params_ret=1;;
                
        "--no-fetch")
                no_fetch=1
                check_params_ret=1;;
                
        "--myself")
                export_myself=1
                check_params_ret=1;;
                
        *)
                _colored_echo 1 red Unknown option $1
                _usage;;
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
  
  # If we reached this point, parsing is skipped
  _colored_echo 5 blue "Skip parsing for $1"
}

#-------------------------------------------------------------------------------
# This function removes the trailing v of a semver-style tag
#
# @param   1 name of the tag to parse
# @return  parse_semver_ret set to the parsed value
#-------------------------------------------------------------------------------
_parse_semver()
{
    local param=${1}
    case ${param} in
        v*)
            parse_semver_ret=${param:1}
            ;;
        *)
            parse_semver_ret=${param}
    esac
}

###############################################################################
#                               GLOBAL VARIABLES                              #
###############################################################################

# disable wildcard epansion
set -f

# base directory
BASEFOLDER=$PWD

# rememeber my full name to call me later
THIS=${0##*/}

# input directory
# This is the directory of the project which is to be exported.
# By default it is assumed, that the expsrc is a subproject of the project 
# to be exported. Therefore the input folder is the parent directory
# of the expsrc.sh script
inFolder="$PWD/../"

# output directory
outFolder=

# array of patterns for files to include in parsing. If left empty
# all files are parsed
arr_parseFiles=()

#Default verbosity level is 1, basic output
verb_level=1

#Default explorer behavior is disabled
open_explorer=0

#Default behavior of svntags parsing is disabled
svntags_parse=0

# Default post generate hook script
expsrc_hook_post="expsrc_hook_post.sh"

# Default config file in root directory of project to be exported
expsrc_config="expsrc.cfg"

# Default behavior is to use a config file if found
ignore_cfg=0

# Default tag of the version to replace.
tagRevision="Version"

# Default behavior of cleaning tags is on
clean_tags=1

# By default fetch the repository from the server before exporting
no_fetch=0

# By default we don't want to export ourself, but sometimes...
export_myself=0

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
            _colored_echo 5 blue Process option $option
            _check_params "$option" "$param"

            let i=i+$((check_params_ret))
            shift $check_params_ret
        else
            _colored_echo 0 red Invalid option $option
            let i=i+1
            shift 1
            continue;
        fi

    done
else
    _colored_echo 5 blue "no parameters given, continue"
fi

# continue working now in the input folder
cd "$inFolder"
_colored_echo 1 yellow "Start exporting project in \"$inFolder\""

# check if a config file exists which defines additional rules
# other than the rules passed as command line arguments
if [ -f "$expsrc_config" ] && [ $ignore_cfg == 0 ]
then
  _colored_echo 1 yellow "Config file \"$expsrc_config\" found, start to read configuration which may override command line parameters"

  oldIFS=$IFS
  IFS='
'
  initial=( $( cat "$expsrc_config" ) )
  IFS=$oldIFS
  
  for i in "${initial[@]}"
  do
    # Strip leading and trailing spaces
    cfgLine="${i#"${i%%[![:space:]]*}"}"
    cfgLine="${cfgLine%"${cfgLine##*[![:space:]]}"}"
    
    # Check if the line starts with a leading '#' which would be a comment
    if [[ "${cfgLine}" != \#* ]]
    then
      _colored_echo 5 blue "${cfgLine} : configuration from config file"
      _check_params ${cfgLine}
    fi
  done
fi

# check whether the input directory is dirty, if so, issue a warning that
# the user knows, that the export will not be based on the current working
# tree
test -z "$(git diff-index --name-only HEAD --)" ||
  _colored_echo 1 yellow "Warning: your working tree is dirty! Export is based on HEAD and will not include changes from current working tree!"

# Update the index of the current working tree. This is important to get the
# tags and to generate the version string correctly.
# If it fails, a warning is issued
if [ $no_fetch -lt 1 ]
then
  if [ `git fetch --tags 2>&1 | grep -c "fatal"` != "0" ]; then
    _colored_echo 1 yellow "Warning: git fetch failed, continuing with possibly outdated version"
  fi
else
  _colored_echo 1 yellow "Fetching git git repository skipped"
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
    _colored_echo 0 red "When we're here, we should have no more parameters"
    _usage
    ;;
esac

# Check which files are to be parsed and 
if [ ${#arr_parseFiles[*]} -gt 0 ]
then
  _colored_echo 1 green "The following files will be parsed: "
  for i in "${arr_parseFiles[@]}"
  do
    _colored_echo 1 green "   $i"
  done
else
  _colored_echo 1 yellow "No files are parsed since no parsing options specified"
fi

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
    # If svntags parsing has been enabled, do it in submodules as well
    if [ $svntags_parse -gt 0 ]
    then
        locParseRulesCmdLine="${locParseRulesCmdLine} --svntags"
    fi
    
    # If cleaning tags is disabled, disable it in submodules as well
    if [ $clean_tags -eq 0 ]
    then
        locParseRulesCmdLine="${locParseRulesCmdLine} --original-tags"
    fi
    
    "$THIS" -v "$verb_level" $locParseRulesCmdLine "--tRev" "${tagRevision}" "-o" "${outFolder}/${s}" "-i" "${PWD}/${s}"
  fi
done

# this will be the revision that is inserted in the files when option "--svntags" is not given
REVSTRING="${git_version}"

# this will be the revision that is inserted in the files for the tag $LatestVersion$
_parse_semver "${git_version}"
LATEST_VERSION="${parse_semver_ret}"

# Let Git tell us the list of files in the repository. In order to be able
# to get files with spaces, read the output from git ls-files into an array.
# The Internal Field Separator (IFS) must be set to a newline.
oldIFS="$IFS"
IFS='
'
filesToExport=($(git ls-files))

# Restore Internal Field Separator to its default value
IFS="$oldIFS"

# Choose the correct format of the command for sed
SEDVERSION=`sed --version | grep "version" | tr "GNU sed version" ' ' | tr '.' ' '`
SEDVERSION=($SEDVERSION)

if [ ${SEDVERSION[0]}="4" ];
then
    SEDPARAM="-b"
elif [ ${SEDVERSION[0]}="3" ];
then
    SEDPARAM="-c"
else
    SEDVERSION=`sed --version | grep "version"`
    _colored_echo 0 red "Unknown version of sed $SEDVERSION"
    exit -1
fi

# search for the semver tag in all tags
ALLTAGS=(`git tag`)
SEMVERALTERNATIVE=""
for (( i=0; i<${#ALLTAGS[@]}; i++ ));
do
    # if it's in the list, choose the next tag to be the alternative
    if [ ${ALLTAGS[${i}]} == "semver" ]; then
        if [ "${#ALLTAGS[@]}" -lt "$((i+1))" ]; then
            _colored_echo 0 red "semver tag occurs, but not any further tag! Exit since this can't be handled"
            exit -1
        fi
        _parse_semver "${ALLTAGS[${i}+1]}"
        SEMVERALTERNATIVE=$parse_semver_ret
        break
    fi
done

# Walk through the files to export
for (( i=0; i<${#filesToExport[@]}; i++ ));
do
  
  fileToExport=${filesToExport[${i}]}
  
  if ( [ ! -n "$(echo ${fileToExport} | grep "expsrc")" ] || [ $export_myself -eq 1 ] ) && [ ! -d "${fileToExport%}" ]; then
    
    # check if we must generate directory before
    if [ -d "${fileToExport%/*}" ] && [ ! -e "${outFolder}/${fileToExport%/*}" ]; then
      mkdir -p "${outFolder}/${fileToExport%/*}"
    fi
    
    # Check if the file must be parsed
    # The function _check_parse checks the file name against the mapping
    # of the -p or --parse attributes
    _check_parse "${fileToExport}"
    
    if [ $check_parse_ret -gt 0 ]
    then
        if [ $svntags_parse -gt 0 ]
        then
          # get the SHA1 commit ID of the last modification of this file
          REVSTRING=`git log -1 --format="%H" -- ${fileToExport}`
          # get the first tag that includes this commit
          REVSTRING=(`git describe --always --contains ${REVSTRING}`)
          REVSTRING=${REVSTRING[0]}
          # Check if the semver tag already contains the tag of this file
          SEMVERCHECK=(`git describe --always --contains --match "semver" ${REVSTRING} | tr '~^_' ' '`)
          if [ ${SEMVERCHECK[0]} == "semver" ]; then
            # The semver tag already contains this files' tag
            #  so check if the tag of this file is the semver tag itself
            #  and if this is the case, replace it with the alternative tag that has been chosen before
            if [ $REVSTRING == "semver" ]; then
                REVSTRING=${SEMVERALTERNATIVE}
            fi
            _colored_echo 4 blue "NOT YET \"semver\" tagged: ${fileToExport} version: ${REVSTRING}"
          else
            # This files' tag is not yet included in the semver tag
            #  so this files' tag is alread semver tagged
            case ${REVSTRING} in
                v*)
                    REVSTRING=${REVSTRING:1}
                    ;;
            esac
            _colored_echo 4 blue "already \"semver\" tagged: ${fileToExport} version: ${REVSTRING}"
          fi
          # check if the tagname should be cleaned before it is inserted
          if [ $clean_tags -eq 1 ]; then
            REVSTRING=(`echo ${REVSTRING} | tr '~^_[:alpha:]' ' '`)
            REVSTRING=${REVSTRING[0]}
            _colored_echo 4 blue "final tag is: ${REVSTRING}"
          fi
          # get the date of the last modification of this file
          REVDATE=`git log -1 --format="%ai" -- ${fileToExport}`
          # get the author of the last modification of this file
          REVAUTHOR=`git log -1 --format="%an" -- ${fileToExport}`
          # Read the file out of the repository and parse the CVS/SVN tags
          # 1. check if there's a '$"--tRev Parameter"$' tag and replace it with 'MY_TAG'
          # 2. check if there's a '$Revision$' tag left and replace this one with '$Revision: MY_TAG $'
          # 3. check if there's a '$Date$' tag and replace it with '$Date: COMMIT_DATE $'
          # 4. check if there's a '$Id$ tag and replace it with '$Id: fileToExport MY_TAG COMMIT_DATE COMMITTER $'
          git show HEAD:"${fileToExport}" 2>/dev/null | \
            sed $SEDPARAM -e 's@\$'"$tagRevision"'.*\$@'"$REVSTRING"'@Ig' \
                             -e 's@\$Revision.*\$@\$Revision: '"$REVSTRING"' \$@Ig' \
                                -e 's@\$Date.*\$@'"\$Date: $REVDATE \$"'@Ig' \
                                    -e 's@\$Id.*\$@'"\$Id: $fileToExport $REVSTRING $REVDATE $REVAUTHOR \$"'@Ig' \
                                        -e 's@\$LatestVersion.*\$@'"$LATEST_VERSION"'@Ig' \
                                            > "${outFolder}/${fileToExport}"
        else
          SEDSTRING='s/\$'"$tagRevision"'.*\$/'"$REVSTRING"'/Ig'
          # Read the file out of the repository and replace the $Revision$ tag with 'MY_TAG'
          git show HEAD:"${fileToExport}" 2>/dev/null | \
            sed $SEDPARAM -e $SEDSTRING > \
              "${outFolder}/${fileToExport}"
        fi
    else
      git show HEAD:"${fileToExport}" 2>/dev/null > \
          "${outFolder}/${fileToExport}"
    fi
  fi
done

cd "$outFolder"

# finally remove possible existent .gitmodules/.gitgnore/.gitattributes files
for g in `find . \( -name .gitmodules -or -name .gitignore -or -name .gitattributes \)`; do
  rm -rf $g
done

# Remove the configuration file in case it was exported. Care must be taken
# when the configuration file is passed as absolute path, in this case, the
# file must not be deleted!
expsrc_cfg_to_delete="${expsrc_config##*[/|\\]}"
rm -f "$outFolder/$expsrc_cfg_to_delete"

# Check if in the input folder the script '$expsrc_hook_post' exists, then
# call this script with the argument version and output folder
if [ -f "${inFolder}/${expsrc_hook_post}" ]
  then
        _colored_echo 5 green "Call post create script $expsrc_hook_post"
      "${inFolder}"/${expsrc_hook_post} "$git_version" "$inFolder" "$outFolder"
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
    #Check if the explorer should be opened automatically
    if [ $open_explorer -eq 1 ]
    then
        outFolder=`cmd //c echo "$outFolder"`
        outFolder=$(echo "$outFolder" | sed -e 's@/@\\@Ig')
        explorer.exe "$outFolder"
    fi
    
    ;;
  *)
    _usage
    ;;
esac
