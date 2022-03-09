# Http Server
$http = [System.Net.HttpListener]::new() 

# Hostname and port to listen on
$http.Prefixes.Add("http://+:8080/")

# Start the Http Server 
$http.Start()



# Log ready message to terminal 
if ($http.IsListening) {
    write-host " HTTP Server Ready!  " -f 'black' -b 'gre'
    write-host "now try going to $($http.Prefixes)" -f 'y'
}


# INFINTE LOOP
# Used to listen for requests
try {
    while ($http.IsListening) {



        # Get Request Url
        # When a request is made in a web browser the GetContext() method will return a request object
        # Our route examples below will use the request object properties to decide how to respond
        $contextTask = $http.GetContextAsync()

        # Waits in 200ms increments for a request. We do this to allow pipeline stops to be processed (i.e. CTRL+C)
        # Credit: https://www.reddit.com/r/PowerShell/comments/9n2q03/comment/e7ju5w4/?utm_source=share&utm_medium=web2x&context=3
        while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) { }
        $context = $contextTask.GetAwaiter().GetResult()
		
        if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/') {
			$LastLog = Get-ChildItem C:\Bin\PhoenixMiner_5.9d_Windows\log*.txt | sort LastWriteTime | select -last 1
			$Lines = Get-Content $LastLog -Tail 100
			$LastLine = $Lines | Select-String -Pattern "main Eth speed" | select -last 1
			if ($LastLine -match "main Eth speed: (?<Speed>.+) MH/s") {
				$mining_speed_all = $Matches.Speed
			}
			$LastLine = $Lines | Select-String -Pattern "main GPUs" | select -last 1
			if ($LastLine -match "main GPUs: 1: (?<GPU1>.+) MH/s \(\d+\) 2: (?<GPU2>.+) MH/s") {
				$mining_speed_gpu1 = $Matches.GPU1
				$mining_speed_gpu2 = $Matches.GPU2
			}
			$LastLine = $Lines | Select-String -Pattern "main GPU1" | select -last 1
			if ($LastLine -match "main GPU1: (?<temp1>.+)C \d+% (?<pow1>.+)W, GPU2: (?<temp2>.+)C \d+% (?<pow2>.+)W") {
				$mining_core_temp_gpu1 = $Matches.temp1
				$mining_core_temp_gpu2 = $Matches.temp2
				$mining_power_gpu1 = $Matches.pow1
				$mining_power_gpu2 = $Matches.pow2
			}
			$LastLine = $Lines | Select-String -Pattern "GPU1: cclock" | select -last 1
			if ($LastLine -match "cclock (?<cclock>\d+) Mhz, cvddc (?<cvddc>\d+) mV, mclock (?<mclock>\d+) MHz, Tj (?<tj>\d+)C, Tmem (?<tmem>\d+)C, p-state P(?<pstate>\d+), pcap (?<pcap>.+), (?<eff>\d+) kH/J") {
				$mining_cclock_gpu1 = $Matches.cclock
				$mining_cvddc_gpu1 = $Matches.cvddc
				$mining_mclock_gpu1 = $Matches.mclock
				$mining_tj_gpu1 = $Matches.tj
				$mining_tmem_gpu1 = $Matches.tmem
				$mining_pstate_gpu1 = $Matches.pstate
				$mining_pcap_gpu1 = $Matches.pcap
				$mining_efficiency_gpu1 = $Matches.eff
			}
			$LastLine = $Lines | Select-String -Pattern "GPU2: cclock" | select -last 1
			if ($LastLine -match "cclock (?<cclock>\d+) Mhz, cvddc (?<cvddc>\d+) mV, mclock (?<mclock>\d+) MHz, (?<eff>\d+) kH/J") {
				$mining_cclock_gpu2 = $Matches.cclock
				$mining_cvddc_gpu2 = $Matches.cvddc
				$mining_mclock_gpu2 = $Matches.mclock
				$mining_efficiency_gpu2 = $Matches.eff
			}			
            # We can log the request to the terminal
            #write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

            [string]$html = "# HELP main_eth_speed Phoenixminer all Eth speed
# TYPE main_eth_speed gauge
mining_hashrate_all ${mining_speed_all}
# HELP mining_hashrate Phoenixminer mining hashrate
# TYPE mining_hashrate gauge
mining_hashrate{gpu=`"1`"} ${mining_speed_gpu1}
mining_hashrate{gpu=`"2`"} ${mining_speed_gpu2}

# HELP mining_core_temp GPU Core temp (C)
# TYPE mining_core_temp gauge
mining_core_temp{gpu=`"1`"} ${mining_core_temp_gpu1}
mining_core_temp{gpu=`"2`"} ${mining_core_temp_gpu2}
# HELP mining_power GPU Power load (W)
# TYPE mining_power gauge
mining_power{gpu=`"1`"} ${mining_power_gpu1}
mining_power{gpu=`"2`"} ${mining_power_gpu2}
# HELP mining_cclock GPU Core clock (MHz)
# TYPE mining_cclock gauge
mining_cclock{gpu=`"1`"} ${mining_cclock_gpu1}
mining_cclock{gpu=`"2`"} ${mining_cclock_gpu2}
# HELP mining_cvddc GPU Voltage (mV)
# TYPE mining_cvddc gauge
mining_cvddc{gpu=`"1`"} ${mining_cvddc_gpu1}
mining_cvddc{gpu=`"2`"} ${mining_cvddc_gpu2}
# HELP mining_mclock GPU Memory clock (MHz)
# TYPE mining_mclock gauge
mining_mclock{gpu=`"1`"} ${mining_mclock_gpu1}
mining_mclock{gpu=`"2`"} ${mining_mclock_gpu2}
# HELP mining_efficiency GPU mining efficiency (kH/J)
# TYPE mining_efficiency gauge
mining_efficiency{gpu=`"1`"} ${mining_efficiency_gpu1}
mining_efficiency{gpu=`"2`"} ${mining_efficiency_gpu2}
# HELP mining_tj GPU Junction temp (C)
# TYPE mining_tj gauge
mining_tj{gpu=`"1`"} ${mining_tj_gpu1}
# HELP mining_tmem GPU Memory temp (C)
# TYPE mining_tmem gauge
mining_tmem{gpu=`"1`"} ${mining_tmem_gpu1}
# HELP mining_pstate GPU Power state
# TYPE mining_pstate gauge
mining_pstate{gpu=`"1`"} ${mining_pstate_gpu1}
"
        
            #resposed to the request
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert htmtl to bytes
            $context.Response.ContentLength64 = $buffer.Length
            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
            $context.Response.OutputStream.Close() # close the response
    
        }
        # powershell will continue looping and listen for new requests...

    }
}
finally {
    $http.Stop()
}
