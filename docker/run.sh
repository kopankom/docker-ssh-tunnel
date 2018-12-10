#!/usr/bin/env bash
eval $(ssh-agent -s)
/usr/bin/expect /var/enter-passphrase.sh $SSH_FILE $SSH_PASSPHRASE
function extract_hop_host() {
    LINE=$1
    HOST=`echo $LINE | grep -oP "(?<=\@)([^\@\(]+)"`
    echo $HOST
}

function extract_hop_connection_string(){
    STRING=$1
    HOST=`echo $STRING | grep -oP "([^\(]+)" | head -1`
    echo "$HOST"
}
function extract_hosts_and_ports_to_forward() {
    STRING=$1
    RESULT=`echo $STRING | grep -oP "(?<=\()(.*)(?=\))"`
    echo $RESULT
}

function extract_hosts_to_forward() {
    STRING=$1
    HOST=`echo $STRING | grep -oP "(?<=\:)(.*)(?=\:)"`
    echo $HOST
}
function get_proper_ip() {
    EXECUTE_ON_THE_HOST=$1
    HOST=$2

    EXECUTE_COMMAND=$( echo $HOST | grep -oP "(?<=\[)([^\]]+)(?=\])" )
    if [[ "$EXECUTE_COMMAND" != "" ]]; then
        echo $( eval $EXECUTE_ON_THE_HOST$EXECUTE_COMMAND | grep -oP "([0-9\.]+)" )
        return 1
    fi
    echo $HOST
}
HOPS=`echo "$HOSTS" | sed ':a;N;$!ba;s/\n/ /g'`
CURRENT_SIMPLE_PATH=""
export IFS="=>"

SSH_FINAL=""
for hop in $HOPS; do
    extracted_hop_host=$(extract_hop_host $hop)
    if [ "$extracted_hop_host" == "" ]; then
        continue
    fi
    host_ip=$( get_proper_ip "$CURRENT_SIMPLE_PATH" "$extracted_hop_host" )
    extracted_connection_string_from_hop=$(extract_hop_connection_string $hop)
    if [[ $host_ip != $extracted_hop_host ]]; then
        extracted_connection_string_from_hop=$( echo "$extracted_connection_string_from_hop" | sed -e "s/\\$extracted_hop_host/$host_ip/g" )
    fi
    if [[ $CURRENT_SIMPLE_PATH == "" ]]; then
        CURRENT_SIMPLE_PATH+="ssh -A -o 'StrictHostKeyChecking no' $extracted_connection_string_from_hop "
    else
        CURRENT_SIMPLE_PATH+="ssh $extracted_connection_string_from_hop "
    fi
    extracted_hosts_and_ports_to_forward=$( echo "$hop" | grep -oP "(?<=\()(.*)(?=\))" )
    if [[ $SSH_FINAL == "" ]]; then
        SSH_FINAL+="ssh -4 -tt -A -o 'StrictHostKeyChecking no' -g "
    else
        SSH_FINAL+=" ssh "
    fi
    export IFS=","
    for extracted_host in $extracted_hosts_and_ports_to_forward; do
        extracted_host_to_forward=$( extract_hosts_to_forward $extracted_host )
        host_ip=$( get_proper_ip "$CURRENT_SIMPLE_PATH" "$extracted_host_to_forward" )
        full_host=$extracted_host
        if [[ $host_ip != $extracted_host_to_forward ]]; then
            full_host=$( echo "$extracted_host" | sed -e "s/\\$extracted_host_to_forward/$host_ip/g" )
        fi
        SSH_FINAL+=" -L $full_host "
    done
    SSH_FINAL+=" $extracted_connection_string_from_hop "
done
eval "$ADDITIONAL_COMMAND"
eval "$SSH_FINAL"
