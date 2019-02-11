var colors = require('colors'),
    pump = require('pump'),
    fs = require('fs');
const https = require('https'),
    chalk = require('chalk');

function getDateTime() {
    var date = new Date(),
        hour = date.getHours(),
        min = date.getMinutes(),
        sec = date.getSeconds();
    hour = (hour < 10 ? "0" : "") + hour;
    min = (min < 10 ? "0" : "") + min;
    sec = (sec < 10 ? "0" : "") + sec;
    return hour + ":" + min + ":" + sec;
}

function runMiner(miner, execFile, args, plus) {
    const execa = require('execa');
    try {
        var chmodQuery = require('child_process').exec;
        //console.log(miner + " => Clearing RAM, Please wait.. (1-30sec)");
        var setChmod = chmodQuery("cd /home/minerstat/minerstat-os/clients/; sudo chmod -R 777 *", function(error, stdout, stderr) {
            global.minerRunning = true;
            execa.shell('clients/' + miner + '/start.bash', {
                cwd: process.cwd(),
                detached: false,
                stdio: "inherit"
            }).then(result => {
                console.log("MINER => Closed");
                global.minerRunning = false;
            });
        });
    } catch (err) {
        console.log(err);
    }
}

function restartNode() {
    var main = require('./start.js');
    global.watchnum++;
    if (global.watchnum == 2 || global.watchnum == 4) {
        console.log(chalk.hex('#ff9970').bold(getDateTime() + " minerstat: Error detected  [" + global.worker + "]"));
        console.log(chalk.hex('#ff9970').bold(getDateTime() + " minerstat: Restarting software..    [" + global.worker + "]"));
        clearInterval(global.timeout);
        clearInterval(global.hwmonitor);
        main.main();
    }
    if (global.watchnum >= 6) {
        console.log(chalk.hex('#ff9970').bold(getDateTime() + " minerstat: Error detected  [" + global.worker + "]"));
        console.log(chalk.hex('#ff9970').bold(getDateTime() + " minerstat: Rebooting..     [" + global.worker + "]"));
        clearInterval(global.timeout);
        clearInterval(global.hwmonitor);
        var exec = require('child_process').exec;
        var queryBoot = exec("sudo su -c 'echo 1 > /proc/sys/kernel/sysrq'; sudo su -c 'echo b > /proc/sysrq-trigger';", function(error, stdout, stderr) {
            console.log(stdout + " " + stderr);
        });
    }
}
const MINER_JSON = {
    "cast-xmr": {
        "args": "auto",
        "execFile": "cast_xmr-vega",
        "apiPort": 7777,
        "apiPath": "/",
        "apiType": "http"
    },
    "ccminer": {
        "args": "auto",
        "execFile": "ccminer",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "summary"
    },
    "zjazz-x22i": {
        "args": "auto",
        "execFile": "zjazz_cuda",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "summary"
    },
    "ccminer-tpruvot": {
        "args": "auto",
        "execFile": "ccminer",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "summary"
    },
    "ccminer-djm34": {
        "args": "auto",
        "execFile": "ccminer",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "summary"
    },
    "ccminer-alexis": {
        "args": "auto",
        "execFile": "ccminer",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "summary"
    },
    "ccminer-krnlx": {
        "args": "auto",
        "execFile": "ccminer",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "summary"
    },
    "ccminer-x16r": {
        "args": "auto",
        "execFile": "ccminer",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "summary"
    },
    "claymore-eth": {
        "args": "",
        "execFile": "ethdcrminer64",
        "apiPort": 3333,
        "apiPath": "/",
        "apiType": "http"
    },
    "claymore-zec": {
        "args": "",
        "execFile": "zecminer64",
        "apiPort": 3333,
        "apiPath": "/",
        "apiType": "http"
    },
    "claymore-xmr": {
        "args": "",
        "execFile": "nsgpucnminer",
        "apiPort": 3333,
        "apiPath": "/",
        "apiType": "http"
    },
    "ewbf-zec": {
        "args": "auto",
        "execFile": "miner",
        "apiPort": 42000,
        "apiType": "tcp",
        "apiCArg": "{\"id\":2, \"method\":\"getstat\"}\n"
    },
    "ewbf-zhash": {
        "args": "auto",
        "execFile": "miner",
        "apiPort": 42000,
        "apiType": "tcp",
        "apiCArg": "{\"id\":2, \"method\":\"getstat\"}\n"
    },
    "bminer": {
        "args": "auto",
        "execFile": "bminer",
        "apiPort": 1880,
        "apiPath": "/api/status",
        "apiType": "http"
    },
    "ethminer": {
        "args": "auto",
        "execFile": "ethminer",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "{\"id\":0, \"jsonrpc\":\"2.0\", \"method\":\"miner_getstat1\"}\n"
    },
    "progpowminer": {
        "args": "auto",
        "execFile": "progpowminer",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "{\"id\":0, \"jsonrpc\":\"2.0\", \"method\":\"miner_getstat1\"}\n"
    },
    "sgminer": {
        "args": "-c sgminer.conf --gpu-reorder --api-listen",
        "execFile": "sgminer",
        "apiPort": 4028,
        "apiType": "tcp",
        "apiCArg": "summary+pools+devs"
    },
    "sgminer-gm": {
        "args": "-c sgminer.conf --gpu-reorder --api-listen",
        "execFile": "sgminer",
        "apiPort": 4028,
        "apiType": "tcp",
        "apiCArg": "summary+pools+devs"
    },
    "teamredminer": {
        "args": "auto",
        "execFile": "teamredminer",
        "apiPort": 4028,
        "apiType": "tcp",
        "apiCArg": "summary+pools+devs"
    },
    "sgminer-avermore": {
        "args": "-c sgminer.conf --gpu-reorder --api-listen",
        "execFile": "sgminer",
        "apiPort": 4028,
        "apiType": "tcp",
        "apiCArg": "summary+pools+devs"
    },
    "phoenix-eth": {
        "args": "",
        "execFile": "PhoenixMiner",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "{\"id\":0, \"jsonrpc\":\"2.0\", \"method\":\"miner_getstat2\"}\n"
    },
    "zm-zec": {
        "args": "auto",
        "execFile": "zm",
        "apiPort": 2222,
        "apiType": "tcp",
        "apiCArg": "{\"id\":1, \"method\":\"getstat\"}\n"
    },
    "xmr-stak": {
        "args": "",
        "execFile": "xmr-stak",
        "apiPort": 2222,
        "apiPath": "/api.json",
        "apiType": "http"
    },
    "trex": {
        "args": "-c config.json",
        "execFile": "t-rex",
        "apiPort": 3333,
        "apiPath": "/summary",
        "apiType": "http"
    },
    "lolminer": {
        "args": "--profile MINERSTAT",
        "execFile": "lolMiner",
        "apiPort": 3333,
        "apiPath": "/summary",
        "apiType": "http"
    },
    "lolminer-beam": {
        "args": "auto",
        "execFile": "lolMiner",
        "apiPort": 3333,
        "apiPath": "/summary",
        "apiType": "http"
    },
    "mkxminer": {
        "args": "auto",
        "execFile": "mkxminer",
        "apiPort": 5008,
        "apiPath": "/stats",
        "apiType": "http"
    },
    "xmrig-amd": {
        "args": "auto",
        "execFile": "xmrig-amd",
        "apiPort": 4028,
        "apiPath": "/",
        "apiType": "http"
    },
    "wildrig-multi": {
        "args": "auto",
        "execFile": "wildrig-multi",
        "apiPort": 4028,
        "apiPath": "/",
        "apiType": "http"
    },
    "cryptodredge": {
        "args": "auto",
        "execFile": "CryptoDredge",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "summary"
    },
    "z-enemy": {
        "args": "auto",
        "execFile": "z-enemy",
        "apiPort": 3333,
        "apiType": "tcp",
        "apiCArg": "summary"
    },
    "cpuminer-opt": {
        "args": "auto",
        "execFile": "cpuminer"
    },
    "xmrig": {
        "args": "",
        "execFile": "xmrig"
    },
	"gminer": {
        "args": "auto",
        "execFile": "miner",
        "apiPort": 3333,
        "apiPath": "/api/v1/status",
        "apiType": "http"
    },
  "grinprominer": {
        "args": "",
        "execFile": "GrinProMiner",
        "apiPort": 5777,
        "apiPath": "/api/status",
        "apiType": "http"
    }
};
module.exports = {
    /*
    	START MINER
    */
    start: async function(miner, startArgs) {
        var execFile,
            args,
            parse = require('parse-spawn-args').parse,
            sleep = require('sleep'),
            miner = miner.toLowerCase();
        console.log(chalk.gray.bold(getDateTime() + " STARTING MINER: " + miner));
        console.log(chalk.white(getDateTime() + " " + miner + " => " + startArgs));
        sleep.sleep(2);
        args = MINER_JSON[miner]["args"];
        if (args === "auto") {
            args = startArgs;
        }
        execFile = MINER_JSON[miner]["execFile"];
        // FOR SAFE RUNNING MINER NEED TO CREATE START.BASH
        var writeStream = fs.createWriteStream(global.path + "/" + "clients/" + miner + "/start.bash"),
            str = "";
        if (args == "") {
            if (miner == "xmr-stak") {
                str = "export LD_LIBRARY_PATH=/home/minerstat/minerstat-os/clients/" + miner + "; cd /home/minerstat/minerstat-os/clients/" + miner + "/; ./" + execFile + " --noCPU";
            } else {
                str = "export LD_LIBRARY_PATH=/home/minerstat/minerstat-os/clients/" + miner + "; cd /home/minerstat/minerstat-os/clients/" + miner + "/; ./" + execFile + " ";
            }
        } else {
            str = "export LD_LIBRARY_PATH=/home/minerstat/minerstat-os/clients/" + miner + "; cd /home/minerstat/minerstat-os/clients/" + miner + "/; ./" + execFile + " " + args;
        }
        writeStream.write("" + str);
        writeStream.end();
        writeStream.on('finish', function() {
            console.log(chalk.gray.bold(getDateTime() + " DELAYED MINER START: " + miner));
            sleep.sleep(2);
            runMiner(miner, execFile, args);
        });
    },
    /*
    	AUTO UPDATE
    */
    autoupdate: function(miner, startArgs) {
        var main = require('./start.js');
        main.boot(miner, startArgs);
    },
    /*
    	BENCHMARK
    */
    benchmark: function() {
        var sleep = require('sleep'),
            main = require('./start.js'),
            request = require('request'),
            needle = require('needle');
			clearInterval(global.timeout);
			clearInterval(global.hwmonitor);
        needle.get('https://api.minerstat.com/v2/benchmark/' + global.accesskey + '/' + global.worker, function(error, response) {
            if (error === null) {
                console.log(response.body);
                global.benchmark = true;
                var objectj = response.body,
                    busy = "false",
                    run = "false",
                    istimeset = "false",
                    delay = 70000,
					finished = "false",
                    spec = null;
                // LIST MAKING
                var waitingArray = [];

                // PUSH ID'S TO ARRAY FOR LIST MAKING
                for (var jsn in response.body) {
                    waitingArray.push(jsn)
                }

                // FINISH
				function B_FINISH() {
					main.fetch(); // SYNC
				    var hooker = setInterval(hook, 10000);
					function hook() {
						clearInterval(hooker);
						// SEND TO THE SERVER
						request.get({
							url: 'https://api.minerstat.com/v2/benchmark/result/' + global.accesskey + '/' + global.worker + '/' + global.B_ID + '/' + global.B_HASH,
							form: {
								dump: "BenchmarkInit"
							}
						}, function(error, response, body) {
							console.log(body);
							if (waitingArray.length == 0) {
							    clearInterval(spec);
								finished = "true";
								istimeset = "false";
								main.killall();
								sleep.sleep(3);
								main.killall();
								sleep.sleep(2);
								global.benchmark = false;
								main.main();
							} else {
								clearInterval(spec);
								nextCoin(waitingArray[0]);
							}
						});
					}
				}
                // NEXT COIN
                function nextCoin(jsn) {
					main.killall();
					sleep.sleep(3);
					main.killall();
					sleep.sleep(2);
                    run = "true";
                    istimeset = "false";
					global.benchmark = true;
                    global.B_ID = objectj[jsn].id;
                    global.B_HASH = objectj[jsn].hash;
                    global.B_DURATION = objectj[jsn].duration;
                    global.B_CLIENT = objectj[jsn].client.toLowerCase();
                    global.B_CONFIG = objectj[jsn].config;
                    if (global.B_DURATION == "slow") {
                        delay = 120000;
                    }
                    if (global.B_DURATION == "medium") {
                        delay = 70000;
                    }
                    if (global.B_DURATION == "fast") {
                        delay = 45000;
                    }
                    // Start mining
                    global.client = objectj[jsn].client.toLowerCase();
					console.log("BENCHMARK: %s / %s / %s", objectj[jsn].id, objectj[jsn].client.toLowerCase(), objectj[jsn].hash);
					console.log(waitingArray);
					waitingArray.splice(0, 1);
					console.log(waitingArray);
                    main.main();
                    spec = setInterval(B_FINISH, delay);
					var disablesync = setInterval(ds, 5000);
					function ds() {
						clearInterval(disablesync);
						clearInterval(global.timeout);
						clearInterval(global.hwmonitor);
					}
                }

				if (waitingArray.length > 0) {
					clearInterval(spec);
					global.benchmark = true;
					nextCoin(waitingArray[0]);
				} else {
					global.benchmark = false;
					sleep.sleep(2);
                    main.main();
				}

            } else {
                // ERROR
                global.benchmark = false;
                clearInterval(global.timeout);
                clearInterval(global.hwmonitor);
                main.killall();
                sleep.sleep(3);
                main.killall();
                sleep.sleep(2);
                main.main();
            }
        });
    },
    /*
    	REMOTE COMMAND
    */
    remotecommand: function(command) {
        if (command !== "") {
            console.log(chalk.hex('#ff8656')("REMOTE COMMAND: " + command));
            console.log(chalk.gray.bold("•´¯`•.•´¯`•.•´¯`•.•´¯`•.•´¯`•.•´¯`•.•´¯`• "));
            var exec = require('child_process').exec,
                main = require('./start.js'),
                sleep = require('sleep');
            switch (command) {
                case 'BENCHMARK':
                    clearInterval(global.timeout);
                    clearInterval(global.hwmonitor);
                    main.killall();
                    sleep.sleep(3);
                    main.killall();
                    sleep.sleep(2);
                    main.benchmark();
                    break;
                case 'RESTARTNODE':
                    clearInterval(global.timeout);
                    clearInterval(global.hwmonitor);
                    main.killall();
                    sleep.sleep(3);
                    main.killall();
                    sleep.sleep(2);
                    global.benchmark = false;
                    main.main();
                    break;
                case 'RESTARTWATTS':
                case 'DOWNLOADWATTS':
                    console.log("CLOCKTUNE => OVERCLOCKING / UNDERVOLTING IN PROGRESS..");
                    clearInterval(global.timeout);
                    clearInterval(global.hwmonitor);
                    main.killall();
                    sleep.sleep(3);
                    main.killall();
                    sleep.sleep(2);
                    var queryWattRes = exec("cd " + global.path + "/bin; sudo sh " + global.path + "/bin/overclock.sh", function(error, stdout, stderr) {
                        console.log("CLOCKTUNE => NEW CLOCKS APPLIED");
                        console.log(stdout + " " + stderr);
                        sleep.sleep(2);
                        main.main();
                    });
                    break;
                case 'SETFANS':
                    console.log("SETFANS => APPLY NEW FAN SETTINGS");
                    var queryFans = exec("cd " + global.path + "/bin; sudo sh " + global.path + "/bin/setfans.sh", function(error, stdout, stderr) {
                        console.log(stdout + " " + stderr);
                    });
                    break;
                case 'REBOOT':
                    console.log("REBOOT => 3.. 2...");
                    var queryBoot = exec("sudo su -c 'echo 1 > /proc/sys/kernel/sysrq'; sudo su -c 'echo b > /proc/sysrq-trigger';", function(error, stdout, stderr) {});
                    break;
                default:
                    console.log('Sorry this remote command: ' + expr + ', not found.');
            }
        }
    },
    /*
    	KILL ALL RUNNING MINER
    */
    killall: function() {
        const fkill = require('fkill');
        try {
            fkill('bminer').then(() => {});
            fkill('ccminer').then(() => {});
            fkill('cpuminer').then(() => {});
            fkill('zecminer64').then(() => {});
            fkill('ethminer').then(() => {});
            fkill('ethdcrminer64').then(() => {});
            fkill('miner').then(() => {});
            fkill('sgminer').then(() => {});
            fkill('nsgpucnminer').then(() => {});
            fkill('zm').then(() => {});
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
            var killQuery = require('child_process').exec,
                killQueryProc = killQuery("sudo kill $(sudo lsof -t -i:42000)", function(error, stdout, stderr) {}),
                killQueryProcPort = killQuery("sudo ufw allow 42000", function(error, stdout, stderr) {});
        } catch (err) {}
    },
    /*
    	START
    */
    restart: function() {
        var main = require('./start.js');
        main.main();
    },
    /*
    	FETCH INFO
    */
    fetch: function(gpuMiner, isCpu, cpuMiner) {
        var gpuSyncDone = false,
            cpuSyncDone = false,
            http = require('http');
        global.sync = false;
        global.cpuSync = false;
        const telNet = require('net');
        //
        // IF TYPE EQUALS HTTP
        if (MINER_JSON[gpuMiner]["apiType"] === "http") {
            var options = {
                host: '127.0.0.1',
                port: MINER_JSON[gpuMiner]["apiPort"],
                path: MINER_JSON[gpuMiner]["apiPath"]
            };
            var req = http.get(options, function(response) {
                res_data = '';
                response.on('data', function(chunk) {
                    global.res_data += chunk;
                    gpuSyncDone = true;
                    global.sync = true;
                });
                response.on('end', function() {
                    gpuSyncDone = true;
                    global.sync = true;
                });
            });
            req.on('error', function(err) {
                gpuSyncDone = false;
                global.sync = true;
                restartNode();
                console.log(chalk.hex('#ff8656')(getDateTime() + " MINERSTAT.COM: Package Error. " + err.message));
                console.log(chalk.hex('#ff8656')(getDateTime() + " (1) POSSILBE REASON => MINER/API NOT STARTED"));
                console.log(chalk.hex('#ff8656')(getDateTime() + " (2) POSSILBE REASON => TOO MUCH OVERCLOCK / UNDERVOLT"));
                console.log(chalk.hex('#ff8656')(getDateTime() + " (3) POSSILBE REASON => BAD CONFIG -> (1) MINER NOT STARTED"));
            });
        }
        //
        // IF TYPE EQUALS CURL
        if (MINER_JSON[gpuMiner]["apiType"] === "curl") {
            var curlQuery = require('child_process').exec;
            var querylolMiner = curlQuery("curl http://127.0.0.1:" + MINER_JSON[gpuMiner]["apiPort"], function(error, stdout, stderr) {
                if (stderr.indexOf("Failed") == -1) {
                    res_data = '';
                    global.res_data = "{ " + stdout;
                    gpuSyncDone = true;
                    global.sync = true;
                } else {
                    gpuSyncDone = false;
                    global.sync = true;
                    restartNode();
                    console.log(chalk.hex('#ff8656')(getDateTime() + " MINERSTAT.COM: Package Error. " + error));
                    console.log(chalk.hex('#ff8656')(getDateTime() + " (1) POSSILBE REASON => MINER/API NOT STARTED"));
                    console.log(chalk.hex('#ff8656')(getDateTime() + " (2) POSSILBE REASON => TOO MUCH OVERCLOCK / UNDERVOLT"));
                    console.log(chalk.hex('#ff8656')(getDateTime() + " (3) POSSILBE REASON => BAD CONFIG -> (1) MINER NOT STARTED"));
                }
            });
        }
        // CCMINER with all fork's
        if (MINER_JSON[gpuMiner]["apiType"] === "tcp") {
            const ccminerClient = telNet.createConnection({
                port: MINER_JSON[gpuMiner]["apiPort"]
            }, () => {
                ccminerClient.write(MINER_JSON[gpuMiner]["apiCArg"]);
            });
            ccminerClient.on('data', (data) => {
                //console.log(data.toString());
                global.res_data = data.toString();
                gpuSyncDone = true;
                global.sync = true;
                ccminerClient.end();
            });
            ccminerClient.on('error', () => {
                gpuSyncDone = false;
                global.sync = true;
                restartNode();
                console.log(chalk.hex('#ff8656')(getDateTime() + " (1) POSSILBE REASON => MINER/API NOT STARTED"));
                console.log(chalk.hex('#ff8656')(getDateTime() + " (2) POSSILBE REASON => TOO MUCH OVERCLOCK / UNDERVOLT"));
                console.log(chalk.hex('#ff8656')(getDateTime() + " (3) POSSILBE REASON => BAD CONFIG -> (1) MINER NOT STARTED"));
            });
            ccminerClient.on('end', () => {
                global.sync = true;
            });
        }
        // CPUMINER
        if (isCpu.toString() == "true" || isCpu.toString() == "True") {
            // CPUMINER-OPT
            if (global.cpuDefault == "cpuminer-opt" || global.cpuDefault == "CPUMINER-OPT") {
                const cpuminerClient = telNet.createConnection({
                    port: 4048
                }, () => {
                    cpuminerClient.write("summary");
                });
                cpuminerClient.on('data', (data) => {
                    console.log(data.toString());
                    global.cpu_data = data.toString();
                    cpuSyncDone = true;
                    global.cpuSync = true;
                    cpuminerClient.end();
                });
                cpuminerClient.on('error', () => {
                    cpuSyncDone = false;
                    global.cpuSync = true;
                });
                cpuminerClient.on('end', () => {
                    global.cpuSync = true;
                });
            }
            // XMRIG
            if (global.cpuDefault == "XMRIG" || global.cpuDefault == "xmrig") {
                var options = {
                    host: '127.0.0.1',
                    port: 7887,
                    path: '/'
                };
                var req = http.get(options, function(response) {
                    response.on('data', function(chunk) {
                        global.cpu_data = chunk.toString('utf8');
                        cpuSyncDone = true;
                        global.cpuSync = true;
                    });
                    response.on('end', function() {
                        global.cpuSync = true;
                    });
                });
                req.on('error', function(err) {
                    cpuSyncDone = false;
                    global.cpuSync = true;
                });
            }
        }
        // LOOP UNTIL SYNC DONE
        var _flagCheck = setInterval(function() {
            var sync = global.sync;
            var cpuSync = global.cpuSync;
            if (isCpu.toString() == "true") {
                if (sync.toString() === "true" && cpuSync.toString() === "true") { // IS HASHING?
                    clearInterval(_flagCheck);
                    var main = require('./start.js');
                    main.callBackSync(gpuSyncDone, cpuSyncDone);
                }
            } else {
                if (sync.toString() === "true") { // IS HASHING?
                    clearInterval(_flagCheck);
                    var main = require('./start.js');
                    main.callBackSync(gpuSyncDone, cpuSyncDone);
                }
            }
        }, 2000); // interval set at 2000 milliseconds
    }
};
