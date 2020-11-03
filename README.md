## As of 2020-11-03, the malicious peers have stopped using the mirror height tactic, so this script will no longer be effective. 
# wackamole

All the bash, all the glory.

## Description:

There are currently peers on the monero network that simply mirror the height you tell them. 
These peers don't relay txs or blocks or provide blocks for download.
For whatever reason, they will still show your height if you connect with a shorter chain. 
Thus, this script identifies those peers that mirror your height and bans them.
This will probably only work for a short amount of time until They change Their approach. 

## Considerations

Currently designed to be run in a screen session. Could probably be daemonized easily enough. 
Only bans peers for the current monerod instance. You will need to modify the script to copy
the ban list somewhere else and then point your monerod conf file to this list (once 6920 is merged). 

## Setup

Modify the parameters at the top to point the script to your monerod bins and ports

## Only you can prevent entropy 

Fork. Build. Make better. Make in other languages. 
but bash is the best. 

# persistence is all
