import http.server, socketserver
from urllib.parse import urlparse, parse_qs
import sys, os, socket, re, requests, base64, ssl, threading, urllib, signal, codecs
from urllib.request import urlopen, HTTPError, URLError, urlretrieve
from os import path
import subprocess, ipaddress, glob, shutil, time

def checkIfmsOS(ip):
	try:
		response = urlopen('http://' + ip + ":4200", timeout=2)
	except: 
		return False
	else:
		return True

def postCacheAdd(action):
    f = open('/home/minerstat/minerstat-os/gui/cache/cache-' + action + '.txt', 'w+')
    f.write('0')
    f.close()

def postCacheCheck(action):
    if os.path.exists('/home/minerstat/minerstat-os/gui/cache/cache-' + action + '.txt'):
        return False
    else:
        return True

def postCacheClear(action):
    if os.path.exists('/home/minerstat/minerstat-os/gui/cache/cache-' + action + '.txt'):
        os.remove('/home/minerstat/minerstat-os/gui/cache/cache-' + action + '.txt')

class MyHttpRequestHandler(http.server.SimpleHTTPRequestHandler):

    def do_POST(self):
        length = int(self.headers.get('Content-length', 0))
        data = self.rfile.read(length).decode()
        message = parse_qs(data)["action"][0]
        self.send_response(200)
        self.send_header('Content-type', 'text/plain; charset=utf-8')
        self.end_headers()

        # Receive command
        if message == 'expand':
            if postCacheCheck(message) == True:
                postCacheAdd(message)
                action_status = os.popen("sudo bash /home/minerstat/minerstat-os/core/expand.sh")
                action_status = action_status.read()
                if "it cannot be grown" in action_status:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))
                else:
                    postCacheAdd(message)
                    self.wfile.write(bytes("wait", "utf8"))
            else:
                expand_status = os.popen("pidof resize2fs")
                if int(expand_status.read().strip()) >= 0:
                    self.wfile.write(bytes("wait", "utf8"))
                else:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))
                    
        elif message == 'update':
            if postCacheCheck(message) == True:
                postCacheAdd(message)
                action_status = os.popen("sudo bash /home/minerstat/minerstat-os/git.sh")
                action_status = action_status.read()
                if "Already up to date" in action_status:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))
                else:
                    postCacheAdd(message)
                    self.wfile.write(bytes("wait", "utf8"))
            else:
                update_status = os.popen("sudo ps aux | grep -c git.sh")
                if int(update_status.read().strip()) > 2:
                    self.wfile.write(bytes("wait", "utf8"))
                else:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))

        elif message == 'netcheck':
            if postCacheCheck(message) == True:
                postCacheAdd(message)
                if os.path.exists('/home/minerstat/minerstat-os/gui/cache/netcheck_result.txt'):
                    os.remove('/home/minerstat/minerstat-os/gui/cache/netcheck_result.txt')
                    time.sleep(1)
                action_status = os.popen("sudo /home/minerstat/minerstat-os/core/netcheck > /home/minerstat/minerstat-os/gui/cache/netcheck_result.txt")
                time.sleep(2)
                if os.path.exists('/home/minerstat/minerstat-os/gui/cache/netcheck_result.txt'):
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))
                else:
                    postCacheAdd(message)
                    self.wfile.write(bytes("wait", "utf8"))
            else:
                update_status = os.popen("sudo ps aux | grep -c netcheck.sh")
                if int(update_status.read().strip()) > 2:
                    self.wfile.write(bytes("wait", "utf8"))
                else:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))                    
                    
        elif message == 'start' or message == 'restart':
            if postCacheCheck(message) == True:
                postCacheAdd(message)
                action_status = os.popen('sudo su minerstat -c "screen -X -S minerstat-console quit" > /dev/null 2>&1; cd /home/minerstat/minerstat-os/; sudo node stop > /dev/null 2>&1; sudo rm /tmp/stop.pid > /dev/null 2>&1; sudo rm /dev/shm/maintenance.pid > /dev/null 2>&1; sleep 1; sudo bash /home/minerstat/minerstat-os/validate.sh; screen -A -m -d -S minerstat-console sudo bash start.sh;')
                action_status = action_status.read()
                if "Terminated" in action_status:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))
                else:
                    postCacheAdd(message)
                    self.wfile.write(bytes("wait", "utf8"))
            else:
                update_status = os.popen("sudo ps aux | grep -c validate.sh")
                if int(update_status.read().strip()) > 2:
                    self.wfile.write(bytes("wait", "utf8"))
                else:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))

        elif message == 'stop':
            if postCacheCheck(message) == True:
                postCacheAdd(message)
                action_status = os.popen("sudo /home/minerstat/minerstat-os/core/stop")
                action_status = action_status.read()
                if "agent successfully stopped" in action_status:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))
                else:
                    postCacheAdd(message)
                    self.wfile.write(bytes("wait", "utf8"))
            else:
                update_status = os.popen("sudo ps aux | grep -c stop.sh")
                if int(update_status.read().strip()) > 2:
                    self.wfile.write(bytes("wait", "utf8"))
                else:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))                    

        elif message == 'reboot':
            if postCacheCheck(message) == True:
                postCacheAdd(message)
                action_status = os.popen("sudo bash /home/minerstat/minerstat-os/bin/reboot.sh")
                action_status = action_status.read()
                if "null" in action_status:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))
                else:
                    postCacheAdd(message)
                    self.wfile.write(bytes("wait", "utf8"))
            else:
                update_status = os.popen("sudo ps aux | grep -c reboot.sh")
                if int(update_status.read().strip()) > 2:
                    self.wfile.write(bytes("wait", "utf8"))
                else:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))                    

        elif message == 'shutdown':
            if postCacheCheck(message) == True:
                postCacheAdd(message)
                action_status = os.popen("sudo bash /home/minerstat/minerstat-os/bin/reboot.sh shutdown")
                action_status = action_status.read()
                if "null" in action_status:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))
                else:
                    postCacheAdd(message)
                    self.wfile.write(bytes("wait", "utf8"))
            else:
                update_status = os.popen("sudo ps aux | grep -c reboot.sh")
                if int(update_status.read().strip()) > 2:
                    self.wfile.write(bytes("wait", "utf8"))
                else:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))                    

        elif 'reflash' in message:
            messageArray = message.split(' ')
            message = messageArray[0]
            reflashTo = messageArray[1]
            reflashToCleared = reflashTo.split('msos-v')[1]
            if '-K' in reflashToCleared:
                reflashToCleared = reflashToCleared.split('-K')[0]
            elif '.zip' in reflashToCleared:
                reflashToCleared = reflashToCleared.split('.zip')[0]
            reflashToCleared = reflashToCleared.replace('-','.')
            msos_version = os.popen("cat /etc/lsb-release | grep DISTRIB_RELEASE= | sed 's/[^0-9.]*//g'")
            msos_version = msos_version.read().strip()
            if reflashToCleared == msos_version:
                postCacheClear(message)
                self.wfile.write(bytes("done", "utf8"))
            elif reflashTo:
                if postCacheCheck(message) == True:
                    postCacheAdd(message)
                    action_status = os.popen("sudo bash /home/minerstat/minerstat-os/bin/migrate.sh --version " + reflashTo + "")
                    action_status = action_status.read()
                    if "0 bytes copied" in action_status:
                        postCacheClear(message)
                        self.wfile.write(bytes("fail", "utf8"))
                    elif "Error: At least" in action_status:
                        postCacheClear(message)
                        self.wfile.write(bytes("fail", "utf8"))
                    elif "msOS essentials" in action_status:
                        postCacheClear(message)
                        self.wfile.write(bytes("wait", "utf8"))
                    else:
                        postCacheAdd(message)
                        self.wfile.write(bytes("wait", "utf8"))
                else:
                    update_status = os.popen("ps aux | grep -c migrate.sh")
                    if int(update_status.read().strip()) > 2:
                        self.wfile.write(bytes("wait", "utf8"))
                    else:
                        postCacheClear(message)
                        self.wfile.write(bytes("done", "utf8"))
            else:
                self.wfile.write(bytes("fail", "utf8"))
                
        elif 'amd-update' in message:
            messageArray = message.split(' ')
            message = messageArray[0]
            updateTo = messageArray[1]
            updateToCleared = message

            # AMD
            drivers_amd = os.popen("timeout 5 dpkg -l | grep amdgpu-dkms | head -n1 | awk '{print $3}' | xargs | sed 's/.*://g' | cut -f1 -d\"-\"")
            drivers_amd = drivers_amd.read().strip()
            if updateToCleared == drivers_amd:
                postCacheClear(message)
                self.wfile.write(bytes("done", "utf8"))
            elif updateTo:
                if postCacheCheck(message) == True:
                    postCacheAdd(message)
                    action_status = os.popen("cd /home/minerstat; sudo /home/minerstat/minerstat-os/bin/amd-update --install " + updateTo + " --silent --reboot")
                    action_status = action_status.read()
                    if "Something went wrong" in action_status:
                        postCacheClear(message)
                        self.wfile.write(bytes("fail", "utf8"))
                    elif "Driver successfully installed" in action_status:
                        postCacheClear(message)
                        self.wfile.write(bytes("wait", "utf8"))
                    else:
                        postCacheAdd(message)
                        self.wfile.write(bytes("wait", "utf8"))
                else:
                    update_status = os.popen("ps aux | grep -c amd-update.sh")
                    if int(update_status.read().strip()) > 2:
                        self.wfile.write(bytes("wait", "utf8"))
                    else:
                        postCacheClear(message)
                        self.wfile.write(bytes("done", "utf8"))
            else:
                self.wfile.write(bytes("fail", "utf8"))

        elif 'nvidia-update' in message:
            messageArray = message.split(' ')
            message = messageArray[0]
            updateTo = messageArray[1]
            updateToCleared = message

            # Nvidia
            drivers_nvidia = os.popen("modinfo nvidia | grep 'version:' | sed 's/[^0-9.]*//g'")
            drivers_nvidia = drivers_nvidia.read().strip().split('\n')[0]
            if updateToCleared == drivers_nvidia:
                postCacheClear(message)
                self.wfile.write(bytes("done", "utf8"))
            elif updateTo:
                if postCacheCheck(message) == True:
                    postCacheAdd(message)
                    action_status = os.popen("cd /home/minerstat; sudo /home/minerstat/minerstat-os/core/nvidia-update --install " + updateTo + " --silent --reboot")
                    action_status = action_status.read()
                    if "Something went wrong" in action_status:
                        postCacheClear(message)
                        self.wfile.write(bytes("fail", "utf8"))
                    elif "Driver successfully installed" in action_status:
                        postCacheClear(message)
                        self.wfile.write(bytes("wait", "utf8"))
                    else:
                        postCacheAdd(message)
                        self.wfile.write(bytes("wait", "utf8"))
                else:
                    update_status = os.popen("ps aux | grep -c nvidia-update.sh")
                    if int(update_status.read().strip()) > 2:
                        self.wfile.write(bytes("wait", "utf8"))
                    else:
                        postCacheClear(message)
                        self.wfile.write(bytes("done", "utf8"))
            else:
                self.wfile.write(bytes("fail", "utf8"))

        elif 'rename' in message:
            messageArray = message.split(' ')
            message = messageArray[0]
            workerKey = messageArray[1]
            workerName = messageArray[2]
            if workerKey and workerName:
                if postCacheCheck(message) == True:
                    postCacheAdd(message)
                    action_status = os.popen("sudo /home/minerstat/minerstat-os/core/mworker " + workerKey + " " + workerName + "")
                    action_status = action_status.read()
                    if "You are done" in action_status:
                        postCacheClear(message)
                        self.wfile.write(bytes("done", "utf8"))
                    else:
                        postCacheAdd(message)
                        self.wfile.write(bytes("wait", "utf8"))
                else:
                    update_status = os.popen("ps aux | grep -c mworker")
                    if int(update_status.read().strip()) > 2:
                        self.wfile.write(bytes("wait", "utf8"))
                    else:
                        postCacheClear(message)
                        self.wfile.write(bytes("done", "utf8"))
            else:
                self.wfile.write(bytes("fail", "utf8"))

        elif 'network' in message:
            messageArray = message.split(';;')
            message = messageArray[0]
            networkIp = messageArray[1]
            networkNetmask = messageArray[2]
            networkGateway = messageArray[3]
            networkDhcp = messageArray[4]
            networkWifiUsername = messageArray[5]
            networkWifiPassword = messageArray[6]

            # Get current configuration
            with open('/media/storage/network.txt') as f:
                network = f.read()
                network_ip = ''
                network_netmask = ''
                network_dhcp = ''
                network_gateway = ''
                if 'IPADDRESS' in network:
                    network_ip = network.split('IPADDRESS="')[1].split('"')[0]
                if 'NETMASK' in network:    
                    network_netmask = network.split('NETMASK="')[1].split('"')[0]
                if 'DHCP' in network:
                    network_dhcp = network.split('DHCP="')[1].split('"')[0]
                if 'GATEWAY' in network:
                    network_gateway = network.split('GATEWAY="')[1].split('"')[0]

                wifi_username = ''
                wifi_password = ''
                if 'WIFISSID' in network:
                    wifi_username = network.split('WIFISSID="')[1].split('"')[0]
                    wifi_password = network.split('WIFIPASS="')[1].split('"')[0]

            if postCacheCheck(message) == True:
                postCacheAdd(message)

                # Check if Wifi setting changed
                dhcp_called = False
                if wifi_username != networkWifiUsername or wifi_password != networkWifiPassword:
                    if not networkWifiUsername or not networkWifiPassword:
                        # Disable wifi
                        os.popen("sudo bash /home/minerstat/minerstat-os/core/dhcp")
                        dhcp_called = True
                    else:
                        # Enable wifi or change user/pass
                        os.popen("sudo /home/minerstat/minerstat-os/core/mwifi " + networkWifiUsername + " " + networkWifiPassword)

                # Check if DHCP settings changed
                if networkDhcp == 'YES' and dhcp_called == False:
                    os.popen("sudo bash /home/minerstat/minerstat-os/core/dhcp")
                elif networkIp and networkNetmask and networkGateway:
                    if networkIp != network_ip or networkNetmask != network_netmask or networkGateway != network_gateway:
                        os.popen("sudo bash /home/minerstat/minerstat-os/core/mstatic " + networkIp + " " + networkNetmask + " " + networkGateway)
   
                postCacheAdd(message)
                self.wfile.write(bytes("wait", "utf8"))
            else:
                if networkIp == network_ip and networkNetmask == network_netmask and networkGateway == network_gateway and networkWifiUsername == wifi_username and networkWifiPassword == wifi_password:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))
                else:
                    self.wfile.write(bytes("wait", "utf8"))

        elif 'logging' in message:
            if postCacheCheck(message) == True:
                postCacheAdd(message)
                action_status = os.popen("sudo /home/minerstat/minerstat-os/core/logs")
                action_status = action_status.read()
                if "Now saving to" in action_status:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))
                else:
                    postCacheAdd(message)
                    self.wfile.write(bytes("wait", "utf8"))
            else:
                update_status = os.popen("ps aux | grep -c logs")
                if int(update_status.read().strip()) > 2:
                    self.wfile.write(bytes("wait", "utf8"))
                else:
                    postCacheClear(message)
                    self.wfile.write(bytes("done", "utf8"))

    def do_GET(self):

        # Include files
        pathUrl = self.path

        # Extract query param
        query_components = parse_qs(urlparse(self.path).query)
        if 'delete' in query_components:
            client_name = query_components["delete"][0]
            os.popen("rm -rf /home/minerstat/minerstat-os/clients/" + client_name)
        if 'command' in query_components:
            command = query_components["command"][0]
            os.popen("sudo bash /home/minerstat/minerstat-os/bin/commands m" + command)

        # Validate request path, and set type
        if pathUrl == '/index' or pathUrl == '/console' or pathUrl == '/software' or pathUrl == '/logs' or pathUrl == '/hardware' or pathUrl == '/network' or pathUrl == '/tools':
            type = "text/html"
            if "?" in pathUrl:
                pathUrl = pathUrl.split('?')[0]
        elif pathUrl == "/styles.css":
            type = "text/css"
        elif pathUrl == "/images/favicon/favicon.ico":
            type = "image/x-icon"
        elif ".png" in pathUrl:
            type = "image/png"
        elif ".zip" in pathUrl:
            type = "application/zip"
            if 'logs' in pathUrl:
                if os.path.exists('/home/minerstat/minerstat-os/logs') == False:
                    os.mkdir('/home/minerstat/minerstat-os/logs')
                    sleep(1)
                shutil.make_archive("/home/minerstat/minerstat-os/gui/logs", "zip", "/home/minerstat/minerstat-os/logs")
                time.sleep(2)
            elif 'dmesg' in pathUrl:
                os.popen("sudo dmesg > /home/minerstat/minerstat-os/gui/dmesg.txt")
                time.sleep(2)
                shutil.make_archive("/home/minerstat/minerstat-os/gui/dmesg", "zip", "/home/minerstat/minerstat-os/gui","dmesg.txt")
        elif ".js" in pathUrl:
            type = "application/javascript"
        elif ".svg" in pathUrl:
            type = "image/svg+xml"
        elif ".ttf" in pathUrl:
            type = "application/octet-stream"
        else:
            if not pathUrl == "/":
                self.send_response(404)
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.wfile.write(bytes("404", "utf8"))
                return

            pathUrl = "/index"
            type = "text/html"
            
        # Set header with content type
        self.send_response(200)
        self.send_header("Content-type", type)
        if type != "text/html":
            self.send_header('Cache-Control', 'max-age=1000')
        self.end_headers()
        
        # Open the file, read bytes, serve
        with open(pathUrl[1:], 'rb') as file: 
            if type == "text/html":

                # Get Hostname (worker name)
                worker_name = os.popen("cat /proc/sys/kernel/hostname")
                worker_name = worker_name.read().strip()

                # Access Key
                access_key = os.popen("cat /media/storage/config.js")
                access_key = access_key.read().strip()
                access_key = access_key.split('"')
                access_key = access_key[1]

                # Get Local IP
                msos_local = os.popen("ifconfig | grep 'inet' | grep -v 'inet6' | grep -vE '127.0.0.1|169.254|172.17.' | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | head -n 1 | grep -o -E '[.0-9]+'")
                msos_local = msos_local.read().strip()

                # Get Remote IP
                msos_remote = os.popen("curl ifconfig.me")
                msos_remote = msos_remote.read().strip()

                # Get msOS version
                msos_version = os.popen("cat /etc/lsb-release | grep DISTRIB_RELEASE= | sed 's/[^0-9.]*//g'")
                msos_version = msos_version.read().strip()

                # Check network
                network_check = os.popen('timeout 10 ping -c 1 -W 1 api.minerstat.com >/dev/null 2>&1 && echo "ok" || echo "fail"')
                network_check = network_check.read().strip()
                if network_check == "fail":
                    network_check = '<div class="check red">OFF</div>'
                else:
                    network_check = '<div class="check green">OK</div>'
                
                # Get RAM free
                ram_free = os.popen("timeout 5 free -m | grep 'Mem' | awk '{print $7}'")
                ram_free = float(ram_free.read().strip()) / 1000

                if ram_free <= 0.5:
                    ram_status = '<div class="check red">FULL</div>'
                else:
                    ram_status = '<div class="check green">OK</div>'

                # Get drive free space
                drive_space = os.popen("df -h --total | grep total | sed 's/[^0-9G,]*//g'")
                drive_space = drive_space.read().strip().split('G')
                drive_total = drive_space[0].replace(',','.')
                drive_used = drive_space[1].replace(',','.')
                drive_free = drive_space[2].replace(',','.')

                if float(drive_free) <= 0.5:
                    drive_status = '<div class="check red">FULL</div>'
                else:
                    drive_status = '<div class="check green">OK</div>'

                # Include header
                html = f'<!DOCTYPE html><html><head><title>' + worker_name + '</title><link href="/styles.css" id="css" rel="stylesheet" type="text/css" /><script type="text/javascript" src="/js/jquery.js"></script><script type="text/javascript" src="/js/perfect-scrollbar.js"></script><script type="text/javascript" src="/js/global.js"></script><meta charset="UTF-8"><link rel="shortcut icon" href="/images/favicon/favicon.ico"><meta name="robots" content="noindex,nofollow"><meta name="theme-color" content="#191d29"><meta name="viewport" content="width=device-width, initial-scale=1"></head><body><div class="header"><div class="element"><div class="label">Worker</div><div class="value">' + worker_name + '</div><div class="action_button" onclick="editWorker();"><div class="tiny_icon edit"></div></div></div><div class="elements_info">i</div><div class="elements_group"><div class="element"><div class="label">msOS</div><div class="value">v' + msos_version + '</div></div><div class="element localIPhover"><div class="label">Local IP</div><div data-ip="' + msos_local + '" class="value localIP">' + msos_local.translate(str.maketrans('0123456789', '**********')) + '</div></div><div class="element remoteIPhover"><div class="label">Remote IP</div><div data-ip="' + msos_remote + '" class="value remoteIP">' + msos_remote.translate(str.maketrans('0123456789', '**********')) + '</div></div><div class="element"><div class="label">Drive</div><div class="value">' + drive_status + '</div></div><div class="element"><div class="label">RAM</div><div class="value">' + ram_status + '</div></div><div class="element"><div class="label">Network</div><div class="value">' + network_check + '</div></div></div></div><div class="floating_menu"><div class="menu"><div class="button" onclick="rigAction(\'stop\');"><div class="icon stop"></div> Stop</div><div class="button" onclick="rigAction(\'start\');"><div class="icon start"></div> Start</div><div class="button" onclick="rigAction(\'restart\');"><div class="icon restart"></div> Restart</div><div class="button yellow" onclick="rigAction(\'reboot\');"><div class="icon_dark reboot"></div> Reboot</div><div class="button red" onclick="rigAction(\'shutdown\');"><div class="icon_dark shutdown"></div> Shut down</div></div></div><div class="popup_background"></div><div class="popup" id="editWorkerData"><div class="popup_header"><div>Rename worker</div><div class="icon_box" onclick="closePopup();"><div class="icon close"></div></div></div><div class="popup_text"><div class="popup_row"><label>Access key</label><input id="acceskeyField" type="password" value="' + access_key + '"/><div class="icon eye"></div></div><div class="popup_row"><label>Worker name</label><input type="text" id="workernameField" value="' + worker_name + '"/></div></div><div class="popup_loader" id="popupLoaderWorker"><div id="popupLoaderWorkerSpinner" class="loader_spinner"></div><div class="loader_text">Please wait ...</div></div><div class="popup_buttons"><div class="button" onclick="closePopup();">Cancel</div><div class="button blue" onclick="mworker();">Change</div></div></div><div class="popup" id="sendCommand"><div class="popup_header"><div id="popupTitle">Title</div><div class="icon_box" onclick="closePopup();"><div class="icon close"></div></div></div><div class="popup_text" id="popupText">Text</div><div class="popup_loader" id="popupLoader"><div id="popupLoaderSpinner" class="loader_spinner"></div><div id="popupLoaderProgress" class="loader_progress"><div class="loader_bar" style="width:30%;"></div></div><div class="loader_text">Please wait ...</div></div><div class="popup_buttons"><div class="button" onclick="closePopup();">No, cancel</div><div class="button red" onclick="modalConfirm();">Yes, confirm</div></div></div>'

                # Continue only if config.js file is changed
                if "changeme" in worker_name.lower(): 

                    html = '<!DOCTYPE html><html><head><title>msOS Setup</title><link href="/styles.css" id="css" rel="stylesheet" type="text/css" /><script type="text/javascript" src="/js/jquery.js"></script><script type="text/javascript" src="/js/global.js"></script><meta charset="UTF-8"><link rel="shortcut icon" href="/images/favicon/favicon.ico"><meta name="robots" content="noindex,nofollow"><meta name="theme-color" content="#191d29"><meta name="viewport" content="width=device-width, initial-scale=1"></head><body><div class="changeme_content"><div class="logo"></div><div class="title">Hello miner!</div><div class="text">Enter your Access Key and Worker Name to connect this rig with your minerstat dashboard.</div><div class="form"><div class="form_row"><label>Access key</label><input id="acceskeyField" type="text" value=""/></div><div class="form_row"><label>Worker name</label><input type="text" id="workernameField" value=""/></div><div class="form_loader" id="formLoader"><div id="formSpinner" class="loader_spinner"></div><div class="loader_text">Please wait ...</div></div><div class="form_buttons" onclick="rename();"><div class="button blue">Connect</div></div></div></div>'
   
                    # Writing the HTML contents with UTF-8
                    self.wfile.write(bytes(html, "utf8"))
                    return

                # HARDWARE PAGE:
                if pathUrl == "/index":
                    # Get motherboard
                    motherboard_name = os.popen("sudo timeout 5 dmidecode --string baseboard-product-name")
                    motherboard_name = motherboard_name.read().strip()

                    # Get MAC address
                    mac_address = os.popen("cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address")
                    mac_address = mac_address.read().strip()

                    # Get RAM total
                    ram_total = os.popen("timeout 5 free -m | grep 'Mem' | awk '{print $2}'")
                    ram_total = float(ram_total.read().strip()) / 1000

                    # RAM usage percent
                    ram_used = float(ram_total) - float(ram_free)
                    ram_percent_used = (float(ram_total) - float(ram_used)) / float(ram_total) * 100
                    ram_percent_free = 100 - ram_percent_used

                    # GPUs
                    gpus_array = os.popen("sudo bash /home/minerstat/minerstat-os/core/gputable")
                    gpus_array = os.popen("cat /dev/shm/gpudata_sort_nc.txt")
                    gpus_array = gpus_array.read().strip().split('\n')
                    gpus_array.pop(0)
                    gpus_list = ''
                    gpus_count = 0
                    for gpu in gpus_array:
                        gpu_data = gpu.split(',')
                        gpus_list = gpus_list + '<div class="tr gpu"><div class="td flexTag"><div class="tag">#' + str(gpus_count) + '</div></div><div class="td flexName"><div class="name">' + str(gpu_data[1]) + '</div><div class="data_row"><div class="label">Bus</div><div class="value">' + str(gpu_data[0]) + '</div></div></div><div class="td flexInfo"><div class="data_row"><div class="tiny_icon temperature"></div><div class="value">' + str(gpu_data[4]) + '</div></div><div class="data_row"><div class="tiny_icon fans"></div><div class="value">' + str(gpu_data[3]) + '</div></div><div class="data_row"><div class="tiny_icon power"></div><div class="value">' + str(gpu_data[2]) + '</div></div></div><div class="td flexClocks"><div class="data_row"><div class="label">Mem</div><div class="value">' + str(gpu_data[6]) + '</div></div><div class="data_row"><div class="label">Core</div><div class="value">' + str(gpu_data[5]) + '</div></div></div></div>'
                        gpus_count = gpus_count + 1

                    # CPU name
                    cpu_name = os.popen("cat /proc/cpuinfo  | grep 'name'| uniq")
                    cpu_name = cpu_name.read().replace('model name','').replace(':','').strip()

                    # CPU load
                    cpu_load = os.popen("timeout 5 grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage \"\"}'")
                    cpu_load = cpu_load.read().strip()
                    cpu_load = round(float(cpu_load),2)

                    # CPU temperature
                    cpu_temperature = os.popen("timeout 5 sudo sensors 2> /dev/null | grep -A 2 k10temp-pci | grep -E 'temp1|Tdie' | awk '{print $2}' | sed 's/[^0-9.]//g'")
                    cpu_temperature = cpu_temperature.read().strip()
                    if bool(cpu_temperature) <= 0:
                        cpu_temperature = os.popen("timeout 5 sudo sensors 2> /dev/null | grep -A 2 zenpower-pci | grep -E 'temp1|Tdie' | awk '{print $2}' | sed 's/[^0-9.]//g'")
                        cpu_temperature = cpu_temperature.read().strip()
                        if bool(cpu_temperature) <= 0:
                            cpu_temperature = os.popen("timeout 5 cat /sys/class/thermal/thermal_zone*/temp 2> /dev/null | column -s $'\t' -t | sed 's/\(.\)..$/.\1/' | tac | head -n 1")
                            cpu_temperature = cpu_temperature.read().strip()

                    # Drive name
                    drive_name = os.popen("sudo lshw -class disk |grep 'logical name'")
                    drive_name = drive_name.read().replace('logical name:','').strip()

                    # Ubuntu version release
                    ubuntu_version = os.popen("cat /etc/lsb-release | grep DISTRIB_DESCRIPTION= | sed 's/[^0-9a-zA-Z. ]*//g'")
                    ubuntu_version = ubuntu_version.read().strip().replace('DISTRIBDESCRIPTIONUbuntu','')

                    # Check UEFI/Legacy
                    if path.exists("/sys/firmware/efi") == True:
                        boot_mode = 'UEFI'
                    else:
                        boot_mode = 'Legacy'
                    ubuntu_version = ubuntu_version + ' [' + boot_mode + ']'

                    # Drive usage percent
                    drive_percent_used = (float(drive_total) - float(drive_used)) / float(drive_total) * 100
                    drive_percent_free = 100 - drive_percent_used

                    # Template - replace placeholders
                    template = file.read().decode('UTF-8')
                    template = template.replace("{motherboard_name}", motherboard_name, 1)
                    template = template.replace("{mac_address}", mac_address, 1)
                    template = template.replace("{ram_free}", str(ram_free), 1)
                    template = template.replace("{ram_percent_free}", str(drive_percent_free), 1)
                    template = template.replace("{ram_percent_used}", str(drive_percent_used), 1)
                    template = template.replace("{cpu_name}", str(cpu_name), 1)
                    template = template.replace("{cpu_load}", str(cpu_load), 1)
                    template = template.replace("{cpu_temperature}", str(cpu_temperature), 1)
                    template = template.replace("{gpus_list}", str(gpus_list), 1)
                    template = template.replace("{drive_free}", drive_free, 1)
                    template = template.replace("{drive_percent_free}", str(drive_percent_free), 1)
                    template = template.replace("{drive_percent_used}", str(drive_percent_used), 1)
                    template = template.replace("{drive_name}", drive_name, 1)

                # SOFTWARE PAGE:
                if "/software" in pathUrl:

                    # Ubuntu version release
                    ubuntu_version = os.popen("cat /etc/lsb-release | grep DISTRIB_DESCRIPTION= | sed 's/[^0-9a-zA-Z. ]*//g'")
                    ubuntu_version = ubuntu_version.read().strip().replace('DISTRIBDESCRIPTIONUbuntu','')

                    # Kernel version
                    kernel_version = os.popen("uname -r")
                    kernel_version = kernel_version.read().strip()

                    # AMD
                    drivers_amd = os.popen("timeout 5 dpkg -l | grep amdgpu-dkms | head -n1 | awk '{print $3}' | xargs | sed 's/.*://g' | cut -f1 -d\"-\"")
                    drivers_amd = drivers_amd.read().strip()
                    drivers_amd_current = drivers_amd
                    drivers_amd_list = '<div class="flex_row"><div class="label">' + drivers_amd + '</div><div class="tag">Current</div></div>'                    
                    lines = requests.get('https://static-ssl.minerstat.farm/drivers/amd/1804/amdlist.txt', verify=False)
                    lines = lines.content.decode("utf-8")
                    lines = lines.split('\n')
                    lines = lines[:-1]
                    for line in lines:
                        line = line.split('amdgpu-pro-')[1]
                        line = line.split('-ubuntu')[0]
                        if line != drivers_amd_current:
                            drivers_amd_list = drivers_amd_list + '<div class="flex_row"><div class="label">' + line + '</div><div class="button" onclick="amdUpdate(\'' + line + '\');"><div class="icon upgrade"></div>Select</div></div>'
                    
                    # Nvidia
                    drivers_nvidia = os.popen("modinfo nvidia | grep 'version:' | sed 's/[^0-9.]*//g'")
                    drivers_nvidia = drivers_nvidia.read().strip().split('\n')[0]
                    drivers_nvidia_current = drivers_nvidia
                    drivers_nvidia_list = '<div class="flex_row"><div class="label">' + drivers_nvidia + '</div><div class="tag">Current</div></div>'                    
                    lines = requests.get('https://static-ssl.minerstat.farm/drivers/nvidia/nvlist.txt', verify=False)
                    lines = lines.content.decode("utf-8")
                    lines = lines.split('\n')
                    lines = lines[:-1]
                    for line in lines:
                        line = line.split('x86_64-')[1]
                        line = line.split('.run')[0]
                        if line != drivers_nvidia_current:
                            drivers_nvidia_list = drivers_nvidia_list + '<div class="flex_row"><div class="label">' + line + '</div><div class="button" onclick="nvidiaUpdate(\'' + line + '\');"><div class="icon upgrade"></div>Select</div></div>'

                    # Reflash versions of msOS
                    reflash_versions = '<div class="flex_row"><div class="label">' + msos_version + '</div><div class="tag">Current</div></div>'                    
                    lines = requests.get('https://archive.minerstat.com/list.txt', verify=False)
                    lines = lines.content.decode("utf-8")
                    lines = lines.split('\n')
                    lines = lines[:-1]
                    for line in lines:
                        original = line
                        line = line.split('msos-v')[1]
                        if '-K' in line:
                            line = line.split('-K')[0]
                        elif '.zip' in line:
                            line = line.split('.zip')[0]
                        line = line.replace('-','.')
                        if line != msos_version:
                            reflash_versions = reflash_versions + '<div class="flex_row"><div class="label">' + line + '</div><div class="button" onclick="reflashOS(\'' + original + '\');"><div class="icon reflash"></div>Reflash</div></div>'

                    # Get local clients list
                    clients = glob.glob("/home/minerstat/minerstat-os/clients/*")
                    clients.sort(key=os.path.getmtime, reverse=True)

                    clients_list = ""
                    for client in clients:
                        if path.exists(client + '/msVersion.txt'):
                            with open(client + '/msVersion.txt') as f:
                                client_version = f.read()
                            client_name = client.rsplit('/',1)[1]

                            # Check if client is currently in use
                            client_used = os.popen("ps aux | grep /clients/" + client_name + "/ | grep SCREEN")
                            if "minew" in client_used.read().strip(): 
                                clients_list = clients_list + '<div class="tr ips"><div class="td flexTagIP"><div class="tag tagip">v' + str(client_version) + '</div></div><div class="td flexIP"><div class="ip">' + client_name + ' v' + str(client_version) + '</div></div><div class="td flexButtons"><div class="label">Currently used</div></div></div>'
                            else:
                                clients_list = clients_list + '<div class="tr ips"><div class="td flexTagIP"><div class="tag tagip">v' + str(client_version) + '</div></div><div class="td flexIP"><div class="ip">' + client_name + ' v' + str(client_version) + '</div></div><div class="td flexButtons"><a href="?delete=' + client_name + '" class="button"><div class="icon bin"></div>Delete</a></div></div>'

                    # Template - replace placeholders
                    template = file.read().decode('UTF-8')
                    template = template.replace("{clients_list}", clients_list, 1)
                    template = template.replace("{msos_version}", msos_version, 1)
                    template = template.replace("{ubuntu_version}", ubuntu_version, 1)
                    template = template.replace("{drivers_nvidia}", drivers_nvidia, 1)
                    template = template.replace("{drivers_nvidia_list}", drivers_nvidia_list, 1)
                    template = template.replace("{drivers_amd}", drivers_amd, 1)
                    template = template.replace("{drivers_amd_list}", drivers_amd_list, 1)
                    template = template.replace("{kernel_version}", kernel_version, 1)
                    template = template.replace("{reflash_versions}", reflash_versions, 1)

                # TOOLS:
                if pathUrl == "/tools":

                    # Template - replace placeholders
                    template = file.read().decode('UTF-8')
                    template = template.replace("{worker_name}", worker_name, 2)
                
                # CONSOLE:
                if pathUrl == "/console":

                    # Template - replace placeholders
                    template = file.read().decode('UTF-8')
                    #template = template.replace("{clients_list}", clients_list, 1)
                
                # LOGS:
                if pathUrl == "/logs":

                    # Check if logs are ON/OFF - ON = storage | OFF = ram
                    logs_status = os.popen("cat /media/storage/logs.txt")
                    logs_status = logs_status.read().strip()
                    if logs_status == 'storage':
                        logs_status = '<div class="button" onclick="logging();"><div class="icon disable"></div> Disable logs</div>'
                    else:
                        logs_status = '<div class="button" onclick="logging();"><div class="icon enable"></div> Enable logs</div>'
 
                    # Template - replace placeholders
                    template = file.read().decode('UTF-8')
                    template = template.replace("{logs_status}", logs_status, 1)

                # NETWORK PAGE:
                if pathUrl == "/network":

                    # Find msOS rigs on the network
                    msos_local = re.sub("\d{1,3}$","",str(msos_local))
                    try:
                        res = os.popen('for i in $(seq 254) ;do (sudo ping ' + str(msos_local) + '$i -i 0.1 -c 1 -W 1  >/dev/null && echo "' + str(msos_local) + '$i" &) ;done')
                    except IOError:
                        print("ISPerror: popen")

                    msos_results = res.read().strip()
                    res.close()

                    msos_results = msos_results.split("\n")
                    msos_list = ""
                    for ipCheck in msos_results:
                        if checkIfmsOS(ipCheck) == True:
                            # IPs of other msOS rigs in teh same network
                            msos_list = msos_list + '<div class="tr ips"><div class="td flexTagIP"><div class="tag tagip">msOS</div></div><div class="td flexIP"><div class="ip"><a target="_blank" href="http://' + ipCheck + '">' + ipCheck + '</a><br></div></div></div>'
   
                    # Netcheck results
                    if os.path.exists('/home/minerstat/minerstat-os/gui/cache/netcheck_result.txt') == False:
                        action_status = os.popen("sudo /home/minerstat/minerstat-os/core/netcheck > /home/minerstat/minerstat-os/gui/cache/netcheck_result.txt")
                        time.sleep(2)

                    with open('/home/minerstat/minerstat-os/gui/cache/netcheck_result.txt') as f:
                        netcheck = f.read()

                        # Ping check
                        ping_check = netcheck.split('Resolve check')[0]
                        if "[[0;32m OK [0m]" in ping_check:
                            ping_result = 'check'
                        else:
                            ping_result = 'cross'
                            
                        # DNS check
                        dns_check = netcheck.split('Resolve check')[1].split('Hosts check')[0]
                        if "[[0;32m OK [0m]" in dns_check:
                            dns_check = 'check'
                        else:
                            dns_check = 'cross'

                        # Minerstat check
                        if "[[0;32m OK [0m] minerstat.com" in netcheck and "[[0;32m OK [0m] api.minerstat.com" in netcheck and "[[0;32m OK [0m] static-ssl.minerstat.farm" in netcheck:
                            minerstat_check = 'check'
                        else:
                            minerstat_check = 'cross'

                        # Pools check
                        if "[[0;32m OK [0m] sandbox.pool.ms" in netcheck:
                            pools_check = 'check'
                        else:
                            pools_check = 'cross'

                    netcheck = '<div class="netcheck_row"><div class="tiny_symbol ' + ping_result + '"></div><div class="value">Ping check</div></div><div class="netcheck_row"><div class="tiny_symbol ' + dns_check + '"></div><div class="value">Global DNS check</div></div><div class="netcheck_row"><div class="tiny_symbol ' + minerstat_check + '"></div><div class="value">minerstat check</div></div><div class="netcheck_row"><div class="tiny_symbol ' + pools_check + '"></div><div class="value">Pools check</div></div>'

                    # WiFi & Network
                    with open('/media/storage/network.txt') as f:
                        network = f.read()
                        if 'IPADDRESS' in network:
                            network_ip = network.split('IPADDRESS="')[1].split('"')[0]
                        if 'NETMASK' in network:    
                            network_netmask = network.split('NETMASK="')[1].split('"')[0]
                        if 'DHCP' in network:
                            network_dhcp = network.split('DHCP="')[1].split('"')[0]
                        if 'GATEWAY' in network:
                            network_gateway = network.split('GATEWAY="')[1].split('"')[0]

                        wifi_username = ''
                        wifi_password = ''
                        if 'WIFISSID' in network:
                            wifi_username = network.split('WIFISSID="')[1].split('"')[0]
                            wifi_password = network.split('WIFIPASS="')[1].split('"')[0]

                    if network_dhcp == 'YES':
                        network_dhcp_select = '<select name="network_dhcp" id="network_dhcp"><option value="YES" selected="selected">Enabled</option><option value="NO">Disabled</option></select>'
                    else:
                        network_dhcp_select = '<select name="network_dhcp" id="network_dhcp"><option value="YES">Enabled</option><option value="NO" selected="selected">Disabled</option></select>'

                    if wifi_username and wifi_password:
                        network_wifi_select = '<select name="network_wifi" id="network_wifi"><option value="1" selected="selected">Enabled</option><option value="0">Disabled</option></select>'
                    else:
                        network_wifi_select = '<select name="network_wifi" id="network_wifi"><option value="1">Enabled</option><option value="0" selected="selected">Disabled</option></select>'

                    # Template - replace placeholders
                    template = file.read().decode('UTF-8')
                    template = template.replace("{msos_list}", msos_list, 2)
                    template = template.replace("{netcheck}", netcheck, 2)
                    template = template.replace("{network_ip}", network_ip, 2)
                    template = template.replace("{network_netmask}", network_netmask, 2)
                    template = template.replace("{network_gateway}", network_gateway, 2)
                    template = template.replace("{network_dhcp}", network_dhcp, 1)
                    template = template.replace("{network_dhcp_select}", network_dhcp_select, 1)
                    template = template.replace("{wifi_username}", wifi_username, 2)
                    template = template.replace("{wifi_username_stars}", '***********', 2)
                    template = template.replace("{wifi_password}", wifi_password, 2)
                    template = template.replace("{wifi_password_stars}", '***********', 2)
                    template = template.replace("{network_wifi_select}", network_wifi_select, 1)

                # Load inclued html page
                html = html + template

                # Writing the HTML contents with UTF-8
                self.wfile.write(bytes(html, "utf8"))

                return

            else:
                self.wfile.write(file.read())
 
# Start the server
def create_server():
    handler_object = MyHttpRequestHandler
    socketserver.TCPServer.allow_reuse_address = True    
    my_server = socketserver.TCPServer(("", 80), handler_object)
    my_server.serve_forever()

threading.Thread(target=create_server).start()