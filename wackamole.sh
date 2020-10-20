#!/bin/bash

rpc_ip=127.0.0.1
rpc_p=18081
call_monerod=monerod
cnct_monerod="$call_monerod --rpc-bind-ip $rpc_ip --rpc-bind-port=$rpc_p"
mon_service=MON_daemon
work_dir=~/wacky_work
p2pstate=~/.bitmonero/p2pstate.bin
#Could get fancy with this and make it a systemd service as well
start_fake="$call_monerod --data-dir $work_dir --no-sync --p2p-bind-port 18060 --rpc-bind-port 18061 --zmq-rpc-bind-port 18062"

#Function
# https://stackoverflow.com/questions/23816264/remove-all-special-characters-and-case-from-string-in-bash
clean() {
    local a=${1//[^[:alnum:]]/}
    echo "${a,,}"
}

# Set up environment

rm -r $work_dir
mkdir $work_dir

### would be start of infinite loop
while true
do

cp $work_dir/new_moles.txt $work_dir/old_moles.txt

cur_height="$($cnct_monerod print_height | tail -1)"
echo $cur_height
#cur_height=$(echo $cur_height | sed 's/[^a-zA-Z0-9]//g')
#cur_height=$(clean $cur_height)
echo $cur_height
cp $p2pstate $work_dir

#sync_info
#/monero-blockchain-import --pop-blocks 200

# Need to call fake monerod in background
echo "Starting fake"

$start_fake --detach --pidfile $work_dir/save_pid.txt
# echo $! > $work_dir/save_pid.txt

sleep 5
echo "Done waiting"
# Fake directory is empty, fake is not syncing. Get output of sync_info and parse it for moles
$start_fake sync_info > $work_dir/sync_info.txt
cat $work_dir/sync_info.txt
# Delete the last line because there are brackets. 
sed -n '5,$d' -i $work_dir/sync_info.txt

cat $work_dir/sync_info.txt

# This could be done by storing the sync_info into an array and then comparing cur_height to the values, but....
grep $cur_height $work_dir/sync_info.txt | cut -f 1 -d ":" > $work_dir/new_moles.txt

echo "new moles"
cat $work_dir/new_moles.txt

cat $work_dir/new_moles.txt >> $work_dir/old_moles.txt
sort $work_dir/old_moles.txt | uniq > $work_dir/new_moles.txt


# For end of accessing fake monero
kill -9 `cat $work_dir/save_pid.txt`
rm $work_dir/save_pid.txt

cat $work_dir/sync_info.txt
echo "and the new_moles"
cat $work_dir/new_moles.txt

echo "Starting over #####################"
sleep 2
done