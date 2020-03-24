#!/bin/bash
BLUE='\e[38;5;69m'
NC='\e[0;37m'
END='\e[0m'
echo -e "${BLUE}=============== msOS commands ==============="
echo ""
echo -e "${BLUE}miner${NC}\t\tShow mining client screen"
echo -e "${BLUE}agent${NC}\t\tShow mining client + agent screen"
echo -e "${BLUE}mstart${NC}\t\t(Re)start mining"
echo -e "${BLUE}mstop${NC}\t\tStop mining"
echo -e "${BLUE}mrecovery${NC}\tRestore system to default"
echo -e "${BLUE}mupdate${NC}\t\tUpdate system (clients, fixes, ...)"
echo -e "${BLUE}opencl${NC}\tSwitch between OpenCL versions. (amdgpu/rocm)"
echo -e "${BLUE}mreconf${NC}\t\tSimulate first boot: configure DHCP, creating fake dummy"
echo -e "${BLUE}mclock${NC}\t\tFetch OC from the dashboard"
echo -e "${BLUE}mreboot${NC}\t\tReboot the rig"
echo -e "${BLUE}mshutdown${NC}\tShut down the rig"
echo -e "${BLUE}forcereboot${NC}\tForce Reboot the rig (<0.1 sec)"
echo -e "${BLUE}forceshutdown${NC}\tForce Shut down the rig (<0.1 sec)"
echo -e "${BLUE}mfind${NC}\t\tFind GPU (e.g. mfind 03.00.0 will set fans to 0% except GPU with bus ID 03.00.0 for 5 seconds)"
echo -e "${BLUE}minfo${NC}\t\tShow welcome screen and msOS version"
echo -e "${BLUE}mlang${NC}\t\tSet keyboard layout (e.g. mlang de)"
echo -e "${BLUE}mswap${NC}\t\tTool for swap file creation"
echo -e "${BLUE}mworker${NC}\t\tChange ACCESSKEY & WORKERNAME"
echo -e "${BLUE}mwifi${NC}\t\tConnect to Wireless networks easily"
echo -e "${BLUE}mled${NC}\t\tToggle Nvidia LED Lights ON/OFF"
echo -e "${BLUE}mpill${NC}\t\tToggle ETHPill ON/OFF"
echo -e "${BLUE}static${NC}\t\tYou can now configure static IP with static command."
echo -e "${BLUE}dhcp${NC}\t\tSwitch back to Dynamic IP"
echo -e "${BLUE}amdmemtool${NC}\tAMD Memory Tweak"
echo -e "${BLUE}nvflash${NC}\t\tNVIDIA VBIOS Flasher"
echo -e "${BLUE}hugepages${NC}\t\tSet Custom Hugepages for CPU mining"
echo -e "${END}"
