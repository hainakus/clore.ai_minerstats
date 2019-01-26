var monitorObject = {};
module.exports = {
    /*
    	DETECT VIDEO CARD TYPE
    */
    detect: function() {
        var exec = require('child_process').exec,
            child;
        global.gputype = "unknown";
        child = exec("nvidia-smi -L", function(error, stdout, stderr) {
            var response = stdout;
            if (response.indexOf("GPU 0:") > -1) {
                global.gputype = "nvidia";
            }
            if (error !== null) {
                console.log('Hardware Monitor: Nvidia GPU not found');
            }
        });
        child = exec(global.path + "/bin/amdcovc", function(error, stdout, stderr) {
            var response = stdout;
            if (response.indexOf("Adapter") !== -1) {
                global.gputype = "amd";
            }
            if (error !== null) {
                console.log('Hardware Monitor: AMD GPU not found');
            }
        });
    },
    /*
    	AMDCOVC - AMD
    */
    HWamd: function(gpuSyncDone, cpuSyncDone) {
        var exec = require('child_process').exec,
            query = exec(global.path + "/bin/amdcovc", function(error, stdout, stderr) {
                var amdResponse = stdout,
                    queryPower = exec("cd " + global.path + "/bin/; sudo ./rocm-smi -P | grep 'GPU Power' | sed 's/.*://' | sed 's/W/''/g' | xargs", function(error, stdout, stderr) {
                        isfinished(amdResponse, "amd", gpuSyncDone, cpuSyncDone, stdout);
                    });
            });
    },
    /*
    	NVIDIA-SMI - NVIDIA
    */
    HWnvidia: function(gpuSyncDone, cpuSyncDone) {
        var lstart = -1;
        exec = require('child_process').exec,
        gpunum = 0;
        gpunum = exec("nvidia-smi --query-gpu=count --format=csv,noheader | tail -n1", function(error, stdout, stderr) {
            var response = stdout;
            while (lstart != (response - 1)) {
                lstart++;
                processNvidia(lstart, gpuSyncDone, cpuSyncDone, response);
            }
        });
    }
}
async function processNvidia(lstart, gpuSyncDone, cpuSyncDone, gpuNum) {
    var idFix = lstart,
    	q2 = exec("nvidia-smi -i " + lstart + " --query-gpu=name,temperature.gpu,fan.speed,power.draw --format=csv,noheader | tail -n1", function(error, stdout, stderr) {
        // New Key - Value
        monitorObject[idFix] = stdout;
        if (idFix == (gpuNum - 1)) {
            //console.log(monitorObject);
            setTimeout(function() {
            	isfinished(monitorObject, "nvidia", gpuSyncDone, cpuSyncDone, "");
            }, 5 * 1000);
        }
    });
}

function isfinished(hwdatar, typ, gpuSyncDone, cpuSyncDone, powerResponse) {
    if (typ === "nvidia") {
        var hwdatas = JSON.stringify(hwdatar);
    } else {
        var hwdatas = hwdatar,
            hwPower = powerResponse;
    }
    /*
    	MAIN FUNCTIONS
    */
    console.log("[" + typ + "] Hardware Monitor: " + hwdatas);
    /*
    	SEND DATA TO ENDPOINT
    */
    // UNSET
    monitorObject = {};
    var main = require('./start.js');
    main.callBackHardware(hwdatas, gpuSyncDone, cpuSyncDone, hwPower);
}
