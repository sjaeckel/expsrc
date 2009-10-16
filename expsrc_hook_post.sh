#!/bin/sh
# Example post generate hook script for the export source
# If this script is placed in the base directory of the project to export,
# it is called with the following parameters:

echo "-------------------------------------------------------------------------"
echo "post update script ${0}"
echo "Generated version: $1"
echo "Input folder:      $2"
echo "Output folder:     $3"
echo "-------------------------------------------------------------------------"

# Note: the name of the script is by default expsrc_hook_post.sh but can be
# changed to another name by calling expsrc.sh --post-hook other.sh