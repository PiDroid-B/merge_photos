#!/bin/bash                                                                                                                                                                             
                                                                                                                                                                                        
DIR_IN="/mnt/nas/photo/"                                                                                                                                                                
DIR_OUT="/mnt/nas/photo_out/"                                                                                                                                                           
                                                                                                                                                                                        
LOOP_DELAY=1                                                                                                                                                                            
LOOP_INTERVAL=100

cmd_merge="cp"
# cmd_merge="mv"

forloop=0

for fullpath in $(find "$DIR_IN"* -type f); do
        do_continue=0

        filename=$(basename -- "$fullpath")

        re='^\w{3}[-_]([0-9]{4})([0-9]{2}).*$' ; [[ $a =~ $re ]]
        [[ $filename =~ $re ]] && filename="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/${BASH_REMATCH[0]}" && mkdir -p "${DIR_OUT}${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"

        extension="${filename##*.}"
        filename="${filename%.*}"

        i=0
        suffix=""
        dest="${DIR_OUT}${filename}.${extension}"
        while [ -e "${dest}" ]; do
                if cmp -s "${fullpath}" "${dest}"; then
                        # echo "${dest} exists, ${fullpath} skipped"
                        do_continue=1
                        break
                fi
                suffix=$((i++))
                dest="${DIR_OUT}${filename}_${suffix}.${extension}"
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

