![minerstat logo](https://cdn.rawgit.com/minerstat/minerstat-asic/master/docs/logo_full.svg)

# minerstat OS

**minerstat OS** is the most advanced ***open source*** crypto [mining OS](https://minerstat.com/software/mining-os) available. It will automatically configure and optimize itself to mine with your ***AMD or NVIDIA*** cards. ***You only need to download, flash it, set your token in the config file and boot it!***

This software **only works with [my.minerstat.com](https://my.minerstat.com) interface**, it's **not in sync** with our old system

## Commands

```
miner         | show miner screen.

mstart        | (re)start mining progress.

mstop         | close mining progress.

mrecovery     | restore everything to default. (all data and miner config stay in safe)

mupdate       | update miners, clients. (Auto-update only starts on boot)

mreconf       | simulate first boot: configure DHCP, creating fake dummy for NVIDIA (ideal, if overclocking not work)

mclock        | Set clocks to match with the online interface.

mreboot       | Reboot

mshutdown     | Power off 

forcereboot   | Force Reboot (<0.1 sec)

forceshutdown | Power off (<0.1 sec)

mfind         | "Find my GPU" e.g. - mfind 0 (All fans to 0% except GPU0 for 5 seconds)

mlang         | Set temporary keyboard layout e.g. - mlang de

atiflash      | AMD - Bios (.rom) Flasher

atiflashall   | AMD - Flash .rom to all available GPUs on the system 

atidumpall    | AMD - Dump all bios from all available GPUs on the system.

mhelp         | List all available commands.

```

## Informations

You can see mining process by type `miner` to the terminal.

**Ctrl + A** | **Crtl + D** to safety close your running miner.

**Ctrl + C** command quit from the process / close minerstat.


## 

***© minerstat OÜ*** in 2018


***Contact:*** app [ @ ] minerstat.com 


***Mail:*** Sepapaja tn 6, Lasnamäe district, Tallinn city, Harju county, 15551, Estonia

## 
