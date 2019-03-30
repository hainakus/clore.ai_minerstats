#!/bin/bash
BLUE='\e[38;5;69m'
NC='\e[0;37m'
END='\e[0m'
echo -e "${BLUE}=============== msOS commands ==============="
echo ""
echo -e "${BLUE}miner${NC}\t\tShow mining client screen"
echo -e "${BLUE}mstart${NC}\t\t(Re)start mining"
echo -e "${BLUE}mstop${NC}\t\tStop mining"
echo -e "${BLUE}mrecovery${NC}\tRestore system to default"
echo -e "${BLUE}mupdate${NC}\t\tUpdate system (clients, fixes, ...)"
echo -e "${BLUE}mreconf${NC}\t\tSimulate first boot: configure DHCP, creating fake dummy"
echo -e "${BLUE}mclock${NC}\t\tFetch OC from the dashboard"
echo -e "${BLUE}mreboot${NC}\t\tReboot the rig"
echo -e "${BLUE}mshutdown${NC}\tShut down the rig"
echo -e "${BLUE}forcereboot${NC}\tForce Reboot the rig (<0.1 sec)"
echo -e "${BLUE}forceshutdown${NC}\tForce Shut down the rig (<0.1 sec)"
echo -e "${BLUE}mfind${NC}\t\tFind GPU (e.g. mfind 0 - will set fans to 0% except GPU0 for 5 seconds)"
echo -e "${BLUE}minfo${NC}\t\tShow welcome screen and msOS version"
echo -e "${BLUE}mlang${NC}\t\tSet keyboard layout (e.g. mlang de)"
echo -e "${BLUE}amdmemtool${NC}\tAMD Memory Tweak"
echo -e "${BLUE}nvflash${NC}\tNVIDIA VBIOS Flasher"
echo -e "${END}"
