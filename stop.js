/*
	USER => mstop
*/
"use strict";
/*
	CATCH ERROR's
*/
process.on('SIGINT', function() {});
process.on('uncaughtException', function(err) {})
process.on('unhandledRejection', (reason, p) => {});
const fkill = require('fkill');
var exec = require('child_process').exec;
try {
  fkill('cpuminer').then(() => {});
  fkill('bminer').then(() => {});
  fkill('zm').then(() => {});
  fkill('zecminer64').then(() => {});
  fkill('ethminer').then(() => {});
  fkill('ethdcrminer64').then(() => {});
  fkill('miner').then(() => {});
  fkill('sgminer').then(() => {});
  fkill('nsgpucnminer').then(() => {});
  fkill('xmr-stak').then(() => {});
  fkill('t-rex').then(() => {});
  fkill('CryptoDredge').then(() => {});
  fkill('lolMiner').then(() => {});
  fkill('mkxminer').then(() => {});
  fkill('xmrig').then(() => {});
  fkill('xmrig').then(() => {}); // yes twice
  fkill('xmrig-amd').then(() => {});
  fkill('z-enemy').then(() => {});
  fkill('PhoenixMiner').then(() => {});
  fkill('wildrig-multi').then(() => {});
  fkill('progpowminer').then(() => {});
  fkill('teamredminer').then(() => {});
  fkill('cast_xmr-vega').then(() => {});
  fkill('zjazz_cuda').then(() => {});
  fkill('GrinProMiner').then(() => {});
} catch (e) {}
var killScreen = exec("SID=$(screen -list | grep minerstat-console | cut -f1 -d'.' | sed 's/[^0-9]*//g'); screen -X -S $SID'.minerstat-console'", function(error, stdout, stderr) {}),
  killNode = exec("killall node", function(error, stdout, stderr) {});