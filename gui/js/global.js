$(function() {

	var leftPosition = getCookie('navbarLeft');
	let navbar = document.querySelector(".navbar");

	if(typeof navbar != 'undefined' && navbar!=null){
		if(typeof leftPosition != 'undefined' && leftPosition!='') {
			$(".navbar").css({"left": "0"});
			$(".navbar").css({"position": "relative"});
			$(".navbar").css({"width": "100%"});
			navbar.scrollLeft = parseInt(leftPosition, 10);
		}

		window.addEventListener("beforeunload", () => {
			var d = new Date;
			d.setTime(d.getTime() + 1*60*1000);
			document.cookie = "navbarLeft=" + parseInt(navbar.scrollLeft) + ";path=/;expires=" + d.toGMTString();
		});
	}

	$('.valueCheck').each(function(){
		if($(this).html()==''){
			$(this).parent().hide();
			if($(this).hasClass('wifiUsername')){
				$('.wifiDivider').hide();
			}
		}
	});

	$(document.body).on('mouseover', '.localIPhover' ,function(event){
		var ipReal = $('.localIP').attr('data-ip');
		var ipMasked = ipReal.replace(/[0-9]/g, '*');
		$('.localIP').html(ipReal);
	});

	$(document.body).on('mouseout', '.localIPhover' ,function(event){
		var ipReal = $('.localIP').attr('data-ip');
		var ipMasked = ipReal.replace(/[0-9]/g, '*');
		$('.localIP').html(ipMasked);
	});

	$(document.body).on('mouseover', '.remoteIPhover' ,function(event){
		var ipReal = $('.remoteIP').attr('data-ip');
		var ipMasked = ipReal.replace(/[0-9]/g, '*');
		$('.remoteIP').html(ipReal);
	});

	$(document.body).on('mouseout', '.remoteIPhover' ,function(event){
		var ipReal = $('.remoteIP').attr('data-ip');
		var ipMasked = ipReal.replace(/[0-9]/g, '*');
		$('.remoteIP').html(ipMasked);
	});

	$(document.body).on('mouseover', '.wifiUsernameHover' ,function(event){
		var usernameReal = $('.wifiUsername').attr('data-username');
		var usernameMasked = ''; for (var i=0; i<usernameReal.length; i++){ usernameMasked += '*'; }
		$('.wifiUsername').html(usernameReal);
	});

	$(document.body).on('mouseout', '.wifiUsernameHover' ,function(event){
		var usernameReal = $('.wifiUsername').attr('data-username');
		var usernameMasked = ''; for (var i=0; i<usernameReal.length; i++){ usernameMasked += '*'; }
		$('.wifiUsername').html(usernameMasked);
	});

	$(document.body).on('mouseover', '.wifiPasswordHover' ,function(event){
		var passwordReal = $('.wifiPassword').attr('data-password');
		var passwordMasked = ''; for (var i=0; i<passwordReal.length; i++){ passwordMasked += '*'; }
		$('.wifiPassword').html(passwordReal);
	});

	$(document.body).on('mouseout', '.wifiPasswordHover' ,function(event){
		var passwordReal = $('.wifiPassword').attr('data-password');
		var passwordMasked = ''; for (var i=0; i<passwordReal.length; i++){ passwordMasked += '*'; }
		$('.wifiPassword').html(passwordMasked);
	});
	
	$(document.body).on('change', '#network_dhcp' ,function(event){
		if($('#network_dhcp').val()=="YES"){
			$('.dhcp_box').hide();
		}else{
			$('.dhcp_box').show();
		}
	});

	$(document.body).on('change', '#network_wifi' ,function(event){
		if($('#network_wifi').val()=="1"){
			$('.wifi_box').show();
		}else{
			$('.wifi_box').hide();
		}
	});

	if($('.activity_box .scroll_frame').length>0){
		var ps_activity = new PerfectScrollbar('.activity_box .scroll_frame', {
			wheelSpeed: 1,
			wheelPropagation: false,
			minScrollbarLength: 30,
			suppressScrollX: true
		});
		ps_activity.update();
	}

	if($('.amd_box .scroll_frame').length>0){
		var ps_amd = new PerfectScrollbar('.amd_box .scroll_frame', {
			wheelSpeed: 1,
			wheelPropagation: false,
			minScrollbarLength: 30,
			suppressScrollX: true
		});
		ps_amd.update();
	}

	if($('.nvidia_box .scroll_frame').length>0){
		var ps_nvidia = new PerfectScrollbar('.nvidia_box .scroll_frame', {
			wheelSpeed: 1,
			wheelPropagation: false,
			minScrollbarLength: 30,
			suppressScrollX: true
		});
		ps_nvidia.update();
	}

	if($('.reflash_versions .scroll_frame').length>0){
		var ps_reflash = new PerfectScrollbar('.reflash_versions .scroll_frame', {
			wheelSpeed: 1,
			wheelPropagation: false,
			minScrollbarLength: 30,
			suppressScrollX: true
		});
		ps_reflash.update();
	}

	$('.popup_background').on('click',function(event){
		closePopup();
	});
	
	$('.elements_info').on('click',function(event){
		$('.elements_group').toggle();
	});

	var accesskeyField = 0;
	$('.icon.eye').on('click',function(event){
		if(accesskeyField==0){
			$('#acceskeyField').get(0).type = 'text';
			accesskeyField = 1;
			$(this).addClass('closed');
		}else{
			$('#acceskeyField').get(0).type = 'password';
			accesskeyField = 0;
			$(this).removeClass('closed');
		}
	});

	$('#logsButton').on('click',function(event){
		$('#logsButton').addClass('disabled');
		$('#logsButton').children('.update').removeClass('icon_dark').addClass('icon');
		setTimeout(function() {
			$('#logsButton').removeClass('disabled');
			$('#logsButton').children('.update').addClass('icon_dark').removeClass('icon');
		}, 5000);			
	});

	$('#dmsegButton').on('click',function(event){
		$('#dmsegButton').addClass('disabled');
		$('#dmsegButton').children('.update').removeClass('icon_dark').addClass('icon');
		setTimeout(function() {
			$('#dmsegButton').removeClass('disabled');
			$('#dmsegButton').children('.update').addClass('icon_dark').removeClass('icon');
		}, 5000);			
	});
});

function editWorker(){
	$('.popup_background').show();
	$('.popup#editWorkerData').show();
}

var modalSelection = '';
function closePopup(){
	$('.popup_background').hide();
	$('.popup').hide();
	modalSelection = '';
	msOSVersion = '';
}

function expandDrive(){
	modalSelection = 'expand';
	$('.popup_background').show();
	$('.popup#sendCommand').show();
	$('#popupTitle').html('Expand drive');
	$('#popupText').html('You are about to expand free space on your drive. The process can take some time and it depends on the speed and total size of your drive. Please be patient and do not interrupt the process. Do you want to continue?');
}

function updateOS(){
	modalSelection = 'update';
	$('.popup_background').show();
	$('.popup#sendCommand').show();
	$('#popupTitle').html('Update msOS');
	$('#popupText').html('You are about to check for msOS updates and automatically install them if they are available. Please be patient and do not interrupt the process. Do you want to continue?');
}

var msOSVersion = '';
function reflashOS(reflashVersion){
	modalSelection = 'reflash';
	$('.popup_background').show();
	$('.popup#sendCommand').show();
	$('#popupTitle').html('Reflash msOS');
	$('#popupText').html('You are about to reflash msOS to a different version. This process can take a long time and it depends on the speed of your drive. After process is finished your rig will reboot and you will lose connection to this dashboard. Please be patient and do not interrupt the process. Do you want to continue?');
	msOSVersion = reflashVersion;
}

var nvidiaVersion = '';
function nvidiaUpdate(updateVersion){
	modalSelection = 'nvidia-update';
	$('.popup_background').show();
	$('.popup#sendCommand').show();
	$('#popupTitle').html('Update drivers');
	$('#popupText').html('You are about to update Nvidia drivers. This process can take a long time and it depends on the speed of your drive. After process is finished your rig will reboot and you will lose connection to this dashboard. Please be patient and do not interrupt the process. Do you want to continue?');
	nvidiaVersion = updateVersion;
}

var amdVersion = '';
function amdUpdate(updateVersion){
	modalSelection = 'amd-update';
	$('.popup_background').show();
	$('.popup#sendCommand').show();
	$('#popupTitle').html('Update drivers');
	$('#popupText').html('You are about to update AMD drivers. This process can take a long time and it depends on the speed of your drive. After process is finished your rig will reboot and you will lose connection to this dashboard. Please be patient and do not interrupt the process. Do you want to continue?');
	amdVersion = updateVersion;
}

var toClear = false; var modalInterval = 0;
function modalConfirm(){
	$('#popupLoader').show();
	$('#popupLoaderSpinner').show();
	$('.popup_buttons .button').addClass('disabled');

	if(msOSVersion!='' && modalSelection.indexOf(' ') < 0){ 
		modalSelection = modalSelection + ' ' + msOSVersion; 
	}else if(nvidiaVersion!='' && modalSelection.indexOf(' ') < 0){
		modalSelection = modalSelection + ' ' + nvidiaVersion;
	}else if(amdVersion!='' && modalSelection.indexOf(' ') < 0){
		modalSelection = modalSelection + ' ' + amdVersion;
	}
	var postData = {
		'action': modalSelection 
	};

	$.ajax({
		url : window.location,
		type: 'post',
		data: postData,
		success: function(data){
			if(data=='done'){
				if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
				setTimeout(function() {
					$('#popupLoaderSpinner').addClass('finished');
					$('#popupLoader .loader_text').addClass('finished');
					$('#popupLoader .loader_text').html('Finished');
					setTimeout(function() {
						location.reload();
					}, 500);
				}, 1000);			
			}else if(data=='wait'){
				if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
				modalInterval = setInterval(modalConfirm, 5000);
				toClear = true;
			}else if(data=='fail'){
				if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
				alert('Process failed');
			}
		},
		error: function(error){
			if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
			modalInterval = setInterval(modalConfirm, 5000);
			toClear = true;
		}
	});
}

function mworker(){
	var accessKey = $('#acceskeyField').val();
	var workerName = $('#workernameField').val();
	if(accessKey!='' && workerName!=''){
		if(accessKey.toLowerCase()!='changeme' && workerName.toLowerCase()!='changeme'){
			$('#popupLoaderWorker').show();
			$('#popupLoaderWorkerSpinner').show();
			$('.popup_buttons .button').addClass('disabled');
			var postData = {
				'action': 'rename ' + accessKey + ' ' + workerName
			};
			$.ajax({
				url : window.location,
				type: 'post',
				data: postData,
				success: function(data){
					if(data=='done'){
						if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
						setTimeout(function() {
							$('#popupLoaderWorkerSpinner').addClass('finished');
							$('#popupLoaderWorker .loader_text').addClass('finished');
							$('#popupLoaderWorker .loader_text').html('Finished');
							setTimeout(function() {
								window.location.replace("http://" + workerName + ".local");
							}, 500);
						}, 1000);			
					}else if(data=='wait'){
						if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
						modalInterval = setInterval(mworker, 5000);
						toClear = true;
					}else if(data=='fail'){
						if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
						alert('Process failed');
					}
				},
				error: function(error){
					if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
					modalInterval = setInterval(mworker, 5000);
					toClear = true;
				}
			});
		}
	}
}

function setNetwork(){
	var networkIp = $('#network_ip').val();
	var networkNetmask = $('#network_netmask').val();
	var networkGateway = $('#network_gateway').val();
	var networkDhcp = $('#network_dhcp').val();
	var networkWifiUsername = $('#network_wifi_username').val();
	var networkWifiPassword = $('#network_wifi_password').val();
	$('#popupLoaderNetwork').show();
	$('#popupLoaderNetworkSpinner').show();
	$('.popup_buttons .button').addClass('disabled');
	var postData = {
		'action': 'network;;' + networkIp + ';;' + networkNetmask + ';;' + networkGateway + ';;' + networkDhcp + ';;' + networkWifiUsername + ';;' + networkWifiPassword
	};
	$.ajax({
		url : window.location,
		type: 'post',
		data: postData,
		success: function(data){
			if(data=='done'){
				if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
				setTimeout(function() {
					$('#popupLoaderNetworkSpinner').addClass('finished');
					$('#popupLoaderNetwork .loader_text').addClass('finished');
					$('#popupLoaderNetwork .loader_text').html('Finished');
					setTimeout(function() {
						location.reload();
					}, 500);
				}, 1000);			
			}else if(data=='wait'){
				if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
				modalInterval = setInterval(setNetwork, 5000);
				toClear = true;
			}else if(data=='fail'){
				if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
				alert('Process failed');
			}
		},
		error: function(error){
			if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
			modalInterval = setInterval(setNetwork, 5000);
			toClear = true;
		}
	});
}

function rigAction(action){
	modalSelection = action;
	$('.popup_background').show();
	$('.popup#sendCommand').show();
	$('#popupTitle').html('Rig action');
	$('#popupText').html('You are about to <b>' + action + '</b> your worker! Do you want to continue?');
}

function netcheck(){
	modalSelection = 'netcheck';
	$('.popup_background').show();
	$('.popup#sendCommand').show();
	$('#popupTitle').html('Netcheck');
	$('#popupText').html('You are about to run network diagnostics. Do you want to continue?');
}

function rename(){
	var accessKey = $('#acceskeyField').val();
	var workerName = $('#workernameField').val();
	if(accessKey!='' && workerName!=''){
		if(accessKey.toLowerCase()!='changeme' && workerName.toLowerCase()!='changeme'){
			$('#formLoader').show();
			$('#formSpinner').show();
			$('.form_buttons .button').addClass('disabled');
			var postData = {
				'action': 'rename ' + accessKey + ' ' + workerName
			};
			$.ajax({
				url : window.location,
				type: 'post',
				data: postData,
				success: function(data){
					if(data=='done'){
						if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
						setTimeout(function() {
							$('#formSpinner').addClass('finished');
							$('#formLoader .loader_text').addClass('finished');
							$('#formLoader .loader_text').html('Finished');
							setTimeout(function() {
								window.location.replace("http://" + workerName + ".local");
							}, 500);
						}, 1000);			
					}else if(data=='wait'){
						if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
						modalInterval = setInterval(rename, 5000);
						toClear = true;
					}else if(data=='fail'){
						if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
						alert('Process failed');
					}
				},
				error: function(error){
					if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
					modalInterval = setInterval(rename, 5000);
					toClear = true;
				}
			});
		}
	}
}

function logging(){
	var postData = {
		'action': 'logging'
	};
	$.ajax({
		url : window.location,
		type: 'post',
		data: postData,
		success: function(data){
			if(data=='done'){
				if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
				if ($(".disable")[0]){
					$('.disable').parent('.button').html('<div class="icon enable"></div> Enable logs');
				} else {
					$('.enable').parent('.button').html('<div class="icon disable"></div> Disable logs');
				}		
			}else if(data=='wait'){
				if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
				modalInterval = setInterval(logging, 5000);
				toClear = true;
			}else if(data=='fail'){
				if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
				alert('Process failed');
			}
		},
		error: function(error){
			if(toClear){ clearInterval(modalInterval); modalInterval = 0; }
			modalInterval = setInterval(logging, 5000);
			toClear = true;
		}
	});
}

function openNetworkConfiguration(){

	var dhcp_val = $('#network_dhcp').val();
	var wifi_val = $('#network_wifi').val();

	if(dhcp_val=="YES"){
		$('.dhcp_box').hide();
	}else{
		$('.dhcp_box').show();
	}

	if(wifi_val=="1"){
		$('.wifi_box').show();
	}else{
		$('.wifi_box').hide();
	}

	$('.popup_background').show();
	$('.popup#networkConfiguration').show();
}

function getCookie(cname) {
	let name = cname + "=";
	let decodedCookie = decodeURIComponent(document.cookie);
	let ca = decodedCookie.split(';');
	for(let i = 0; i <ca.length; i++) {
		let c = ca[i];
		while (c.charAt(0) == ' ') {
		c = c.substring(1);
		}
		if (c.indexOf(name) == 0) {
		return c.substring(name.length, c.length);
		}
	}
	return "";
}