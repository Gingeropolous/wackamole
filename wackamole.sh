#!/bin/bash


# Parameters to modify
rpc_ip=127.0.0.1
rpc_p=18081
p2p_ip=127.0.0.1
p2p_port=18080
call_monerod=monerod
p2pstate=~/.bitmonero/p2pstate.bin # This is the default, only change if you've changed yours
blockpopper=/home/user/monero/build/Linux/_HEAD_detached_at_v0.17.1.0_/release/bin/monero-blockchain-import
pop_height=15000 # Set lower to reduce size impact of script. Set higher to presumably avoid detection

# You can rename this if you want or put somewhere else
work_dir=~/wacky_work



cnct_monerod="$call_monerod --rpc-bind-ip $rpc_ip --rpc-bind-port $rpc_p"
#Could get fancy with this and make it a systemd service as well
start_fake="$call_monerod --data-dir $work_dir --no-sync --p2p-bind-port 18060 --rpc-bind-port 18061 --zmq-rpc-bind-port 18062 --out-peers 512"
sync_fake="$call_monerod --data-dir $work_dir --p2p-bind-port 18060 --rpc-bind-port 18061 --zmq-rpc-bind-port 18062 --add-exclusive-node $p2p_ip:$p2p_port"
pop_fake_blocks="$blockpopper --data-dir $work_dir "

# Set up environment

rm -r $work_dir
mkdir $work_dir

while true
do

cp $work_dir/new_moles.txt $work_dir/old_moles.txt

echo "Synchronizing fake"
$sync_fake --detach --pidfile $work_dir/save_pid.txt
sleep 25
fake_height=$($call_monerod --rpc-bind-port 18061 print_height | tail -1 | sed 's/\x1b\[[0-9;]*m//g')
echo "fake height: "$fake_height
$sync_fake exit
sleep 3

if [ "$fake_height" -gt "$pop_height" ]
then
echo "back with another one of those block poppin beats!"
$pop_fake_blocks --pop-blocks $pop_height
fi

cp $p2pstate $work_dir

echo "Starting no-sync fake"

$start_fake --detach --pidfile $work_dir/save_pid.txt

echo "Waiting...."
sleep 100
echo "Done waiting"
# Fake directory is empty, fake is not syncing. Get output of sync_info and parse it for moles
fake_height=$($call_monerod --rpc-bind-port 18061 print_height | tail -1 | sed 's/\x1b\[[0-9;]*m//g')
echo "fake height: "$fake_height
echo "$fake_height"|od -xc

$start_fake sync_info | grep normal >  $work_dir/sync_info.txt
#cat $work_dir/sync_info.txt

all_peers_heights=$(awk -v OFS="\t" '$1=$1' $work_dir/sync_info.txt | cut -f 5)
declare -a all_peers_heights_a=($all_peers_heights)
echo "all peers"
echo ${all_peers_heights_a[@]}

c=0
for i in "${all_peers_heights_a[@]}"
do
#echo "in loop"
c=$((c+1))
#echo "peer: "$i
#echo "us: "$fake_height
if [[ "$i" == "$fake_height" ]]
then
#echo "in if"
sed "${c}q;d" $work_dir/sync_info.txt | cut -f 1 -d ":" >> $work_dir/new_moles.txt
fi
done

#echo "new moles"
#cat $work_dir/new_moles.txt

cat $work_dir/new_moles.txt >> $work_dir/old_moles.txt
sort $work_dir/old_moles.txt | uniq > $work_dir/new_moles.txt

# For end of accessing fake monero
echo "Killing monerod"
$start_fake exit
sleep 3
#echo "and all the moles"
#cat $work_dir/new_moles.txt
echo "########## TOTAL MOLES: "
wc -l $work_dir/new_moles.txt
echo "Adding new moles to monerod ban list"

cat $work_dir/new_moles.txt | while read ip
do # think this will work in parallel?
$cnct_monerod ban $ip
done 

echo "Starting over #####################"
echo "kill script now to stop. otherwise have to hunt down and kill monerod"
sleep 3
done
