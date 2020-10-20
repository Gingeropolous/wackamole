#!/bin/bash


# Parameters to modify
rpc_ip=127.0.0.1
rpc_p=18081
call_monerod=monerod
p2pstate=~/.bitmonero/p2pstate.bin # This is the default, only change if you've changed yours


cnct_monerod="$call_monerod --rpc-bind-ip $rpc_ip --rpc-bind-port $rpc_p"
work_dir=~/wacky_work
#Could get fancy with this and make it a systemd service as well
start_fake="$call_monerod --data-dir $work_dir --no-sync --p2p-bind-port 18060 --rpc-bind-port 18061 --zmq-rpc-bind-port 18062 --out-peers 512"

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

# This goddamned variable kept on getting special characters and shit. This is shit. 
$cnct_monerod print_height | tail -1 > $work_dir/cur_height.txt
cat $work_dir/cur_height.txt
cur_height="$(cat $work_dir/cur_height.txt | tr -dc '[:print:]' | sed 's/0m//' | tr -d '\n')"
cur_height=$(clean $cur_height)
echo $cur_height
echo "$cur_height"|od -xc


cp $p2pstate $work_dir

echo "Starting fake"

$start_fake --detach --pidfile $work_dir/save_pid.txt

echo "Waiting...."
sleep 30
echo "Done waiting"
# Fake directory is empty, fake is not syncing. Get output of sync_info and parse it for moles
$start_fake sync_info > $work_dir/sync_info.txt
# Delete the last line because there are brackets. 
sed -n '5,$p' -i $work_dir/sync_info.txt
sed -i '$d' $work_dir/sync_info.txt

# This could be done by storing the sync_info into an array and then comparing cur_height to the values, but....
# This will need to be changed to an array comparison if we need to wait 10 minutes to avoid false positives
echo "grepping"
grep -F "$cur_height" $work_dir/sync_info.txt | cut -f 1 -d ":" > $work_dir/new_moles.txt

echo "new moles"
cat $work_dir/new_moles.txt

cat $work_dir/new_moles.txt >> $work_dir/old_moles.txt
sort $work_dir/old_moles.txt | uniq > $work_dir/new_moles.txt


# For end of accessing fake monero
echo "Killing monerod"
$start_fake exit
#kill -15 `cat $work_dir/save_pid.txt`
sleep 3
cat $work_dir/sync_info.txt
echo "and the new_moles"
cat $work_dir/new_moles.txt

echo "Adding new moles to monerod ban list"
cat $work_dir/new_moles.txt | while read ip
do
$cnct_monerod ban $ip
done 

echo "Starting over #####################"
echo "kill script now to stop. otherwise have to hunt down and kill monerod"
sleep 2
done
