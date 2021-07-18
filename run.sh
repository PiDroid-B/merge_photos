#!/bin/bash

DIR_IN="/my/input/"
DIR_OUT="/my/output/"

LOOP_DELAY=1
LOOP_INTERVAL=100

cmd_merge="cp"
# cmd_merge="mv"

forloop=0

find "$DIR_IN"* -type f -print0 | while IFS= read -r -d '' fullpath; do
        do_continue=0

        filename=$(basename -- "$fullpath")

        re='^\w{3}[-_]([0-9]{4})([0-9]{2}).*$' ; [[ $a =~ $re ]]
        [[ $filename =~ $re ]] && filename="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/${BASH_REMATCH[0]}" && mkdir -p "${DIR_OUT}${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"

        filebase="${filename%.[^.]*}"
        extension="${filename:${#filebase} + 1}"
        [ ${#extension} -ne 0 ] && extension=".${extension}"

        i=0
        suffix=""
        dest="${DIR_OUT}${filebase}${extension}"
        while [ -e "${dest}" ]; do
                if cmp -s "${fullpath}" "${dest}"; then
                        do_continue=1
                        break
                fi
                suffix=$((i++))
                dest="${DIR_OUT}${filebase}_${suffix}${extension}"
        done

        ((forloop++))

        if ! ((forloop % LOOP_INTERVAL)) ; then
                echo "wait for sync (prevent iowait)"
                sync
                sleep $LOOP_DELAY
        fi

        [ $do_continue -eq 1 ] && echo "${fullpath} > duplicate detected" && continue

        echo "$cmd_merge ${fullpath}" "${dest}"
        $cmd_merge "${fullpath}" "${dest}"

done

