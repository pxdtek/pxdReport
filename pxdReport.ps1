<#
    pxd Report: everything about this PC on one private link.

    Run from the pxd Toolkit console (irm pxdtek.com/tk|iex, then R). Collects a read-only report (the PC, drive and
    crash health, security, network, startup items, programs and updates), encrypts it on this PC and puts it on
    pxdtek.com for 48 hours. You get a short link (and a QR code) to open on your own PC, with Copy and Download
    buttons: made for remote sessions such as ScreenConnect Backstage, where the clipboard doesn't come back.

    The link's key (after the #) never leaves this window: pxdtek.com stores only bytes it can't read. Nothing on
    this PC is changed and nothing is saved here unless you say so.

    Testing: $env:PXDR_SITE = 'http://127.0.0.1:8080' sends it to a local copy of the site; -Json <file> writes the
    report as JSON and uploads nothing; -Yes skips the question.

    Windows PowerShell 5.1 and PowerShell 7. ASCII only, so irm | iex never trips.
#>
param([string]$Json = '', [switch]$Yes)

& {
    $ErrorActionPreference = 'Continue'
    $ProgressPreference = 'SilentlyContinue'
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }

    $version = '1.1.0'
    $site = if ($env:PXDR_SITE) { $env:PXDR_SITE.TrimEnd('/') } else { 'https://pxdtek.com' }

    function Say([string]$Text, [string]$Color = 'Gray') { Write-Host $Text -ForegroundColor $Color }

    # ---- PD header ---------------------------------------------------------------------------------------------------
    # The pxd logo beside the tool's name, shown when a pxdtek CLI tool starts. The master copy is cli/PdHeader.ps1 in the
    # pxdtek repo; each tool carries a copy (they run through irm | iex, so they can't load it). tools/sync-header.ps1
    # copies it into them.
    # Ten drawings of the logo, from tools/pdlogos.mjs: solid blocks, braille dots, shades and plain ASCII, tilted like the
    # logo or upright, the pxd in white and the ring in cyan. They're stored as gzip + base64 so this stays ASCII and
    # irm | iex never trips on encoding. Each time, one is picked at random from those that fit the window (braille only
    # in Windows Terminal or VS Code, whose fonts have the dots); a window too narrow for any gets a one-line header.
    # Nothing is kept between runs: under irm | iex the script scope is the caller's own session.

    # A random logo no wider than $Room (@{ Style; Width; Text = lines; Color = lines }), or $null if none fits.
    function Get-PdLogo([int]$Room = [int]::MaxValue) {
        $logos = @(
            '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'
        ) -join ''
        $all = @()
        try {
            $gz = New-Object IO.Compression.GZipStream((New-Object IO.MemoryStream(, [Convert]::FromBase64String($logos))), ([IO.Compression.CompressionMode]::Decompress))
            $body = (New-Object IO.StreamReader($gz, [Text.Encoding]::UTF8)).ReadToEnd()
            foreach ($chunk in ($body -split "`n~`n")) {
                $l = $chunk -split "`n"
                $head = $l[0] -split ' '
                $n = [int]$head[2]
                $all += @{ Style = $head[0]; Width = [int]$head[1]; Text = $l[1..$n]; Color = $l[($n + 1)..(2 * $n)] }
            }
        } catch { return $null }
        $dots = [bool]($env:WT_SESSION -or $env:TERM_PROGRAM -eq 'vscode')
        $fit = @($all | Where-Object { ($dots -or $_.Style -ne 'd') -and $_.Width -le $Room })
        if (-not $fit.Count) { return $null }
        $fit[(Get-Random -Maximum $fit.Count)]
    }

    # Line $Row of a logo in its colours (W the pxd, C the ring, D its faint edge), no newline; -Pad fills it to the
    # logo's width. A row past the logo's end writes only the padding.
    function Write-PdLogoLine($Logo, [int]$Row, [switch]$Pad) {
        $line = ''; $mask = ''
        if ($Row -ge 0 -and $Row -lt $Logo.Text.Count) { $line = [string]$Logo.Text[$Row]; $mask = [string]$Logo.Color[$Row] }
        $colors = @{ 'W' = 'White'; 'C' = 'Cyan'; 'D' = 'DarkCyan' }
        # one colour run at a time; spaces join whichever run they're in
        $run = ''; $col = 'Cyan'
        for ($k = 0; $k -lt $line.Length; $k++) {
            $c = $col
            if ($line[$k] -ne ' ' -and $k -lt $mask.Length -and $colors.ContainsKey([string]$mask[$k])) { $c = $colors[[string]$mask[$k]] }
            if ($c -ne $col -and $run) { Write-Host $run -NoNewline -ForegroundColor $col; $run = '' }
            $col = $c; $run += $line[$k]
        }
        if ($run) { Write-Host $run -NoNewline -ForegroundColor $col }
        if ($Pad -and $line.Length -lt $Logo.Width) { Write-Host (' ' * ($Logo.Width - $line.Length)) -NoNewline }
    }

    function Show-PdHeader {
        param([string]$Name, [string]$Version = '', [string[]]$About = @(), [string]$Command = '')
        $text = New-Object System.Collections.Generic.List[object]
        $text.Add(@($Name, 'White'))
        $text.Add(@(((@($Version, 'pxdtek.com') | Where-Object { $_ }) -join '  -  '), 'DarkGray'))
        if ($About) { $text.Add(@('', 'Gray')); foreach ($a in $About) { $text.Add(@($a, 'Gray')) } }
        if ($Command) { $text.Add(@('', 'Gray')); $text.Add(@($Command, 'DarkCyan')) }
        $textWidth = ($text | ForEach-Object { $_[0].Length } | Measure-Object -Maximum).Maximum

        $w = 0
        try { $w = $Host.UI.RawUI.WindowSize.Width } catch {}
        $logo = Get-PdLogo $(if ($w -gt 0) { $w - $textWidth - 7 } else { [int]::MaxValue })

        Write-Host ''
        if (-not $logo) {
            Write-Host '  (pd) ' -NoNewline -ForegroundColor Cyan
            Write-Host $Name -NoNewline -ForegroundColor White
            Write-Host $(if ($Version) { "  $Version" } else { '' }) -ForegroundColor DarkGray
            Write-Host ''
            return
        }
        $rows = $logo.Text.Count
        $top = [Math]::Max(0, [Math]::Floor(($rows - $text.Count) / 2))
        for ($i = 0; $i -lt [Math]::Max($rows, $top + $text.Count); $i++) {
            $j = $i - $top
            $say = $j -ge 0 -and $j -lt $text.Count -and $text[$j][0]
            Write-Host '  ' -NoNewline
            Write-PdLogoLine $logo $i -Pad:$say
            if ($say) { Write-Host ('    ' + $text[$j][0]) -NoNewline -ForegroundColor $text[$j][1] }
            Write-Host ''
        }
        Write-Host ''
    }
    # ---- end of PD header --------------------------------------------------------------------------------------------

    # ---- the report ------------------------------------------------------------------------------------------------
    $report = [ordered]@{ v = 1; tool = "pxd Report $version"; at = (Get-Date).ToUniversalTime().ToString('o'); pc = $env:COMPUTERNAME; by = ''; problems = @(); sections = @() }
    $problems = New-Object System.Collections.Generic.List[object]
    $sections = New-Object System.Collections.Generic.List[object]
    function Add-Problem([string]$Level, [string]$Text) { $problems.Add([ordered]@{ level = $Level; text = $Text }) }
    function New-Section([string]$Title) {
        $s = [ordered]@{ title = $Title; rows = (New-Object System.Collections.Generic.List[object]); lines = (New-Object System.Collections.Generic.List[string]); note = ''; chart = $null }
        $sections.Add($s); $s
    }
    function Add-Row($Section, [string]$Key, $Value, [string]$Flag = '') {
        if ($null -eq $Value -or "$Value" -eq '') { return }
        $Section.rows.Add(@($Key, [string]$Value, $Flag))
    }
    function Get-Size([double]$Bytes) {
        if ($Bytes -ge 1TB) { return '{0:0.#} TB' -f ($Bytes / 1TB) }
        if ($Bytes -ge 1GB) { return '{0:0.#} GB' -f ($Bytes / 1GB) }
        if ($Bytes -ge 1MB) { return '{0:0} MB' -f ($Bytes / 1MB) }
        '{0:0} KB' -f ($Bytes / 1KB)
    }
    function Get-Ago([datetime]$When) {
        $d = (Get-Date) - $When
        if ($d.TotalDays -ge 2) { return '{0} days ago' -f [int][math]::Floor($d.TotalDays) }
        if ($d.TotalHours -ge 2) { return '{0} hours ago' -f [int][math]::Floor($d.TotalHours) }
        '{0} minutes ago' -f [int][math]::Max(0, [math]::Floor($d.TotalMinutes))
    }
    function Get-Events([hashtable]$Filter, [int]$Max = 200) {
        try { @(Get-WinEvent -FilterHashtable $Filter -MaxEvents $Max -ErrorAction Stop) } catch { @() }
    }
    function Get-Reg([string]$Path, [string]$Name) {
        try { $v = (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name; return $v } catch { return $null }
    }

    # Who is signed in, and where their part of the registry is. Run as SYSTEM (ScreenConnect Backstage, a remote
    # shell), HKCU is SYSTEM's own, so the signed-in user's hive is read from HKEY_USERS instead.
    $me = [Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal($me)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $isSystem = $me.User.Value -eq 'S-1-5-18'
    $userName = ''; $userHive = 'Registry::HKEY_CURRENT_USER'; $userProfile = $env:USERPROFILE
    try { $userName = [string](Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).UserName } catch { }
    if (-not $userName) {
        # a Remote Desktop session: whoever owns an explorer.exe
        try {
            $ex = Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" -ErrorAction Stop | Select-Object -First 1
            if ($ex) { $o = Invoke-CimMethod -InputObject $ex -MethodName GetOwner -ErrorAction Stop; if ($o.User) { $userName = "$($o.Domain)\$($o.User)" } }
        } catch { }
    }
    if ($isSystem) {
        $userHive = $null; $userProfile = $null
        if ($userName) {
            try {
                $sid = (New-Object Security.Principal.NTAccount($userName)).Translate([Security.Principal.SecurityIdentifier]).Value
                if (Test-Path -LiteralPath "Registry::HKEY_USERS\$sid") { $userHive = "Registry::HKEY_USERS\$sid" }
                $userProfile = Get-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid" 'ProfileImagePath'
            } catch { }
        }
    }
    $report.by = if ($isSystem) { 'SYSTEM' } else { $me.Name }
    $rel = @{ Metrics = $null; Records = $null }   # Reliability Monitor's data, read once (Read-ReliabilityData)

    # ---- this PC ---------------------------------------------------------------------------------------------------
    function Read-PC {
        $s = New-Section 'This PC'
        $os = $cs = $bios = $null
        try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch { }
        try { $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop } catch { }
        try { $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop } catch { }
        Add-Row $s 'Computer name' $env:COMPUTERNAME
        Add-Row $s 'Signed in' $(if ($userName) { $userName } else { 'nobody' })
        Add-Row $s 'Report run as' $(if ($isSystem) { 'SYSTEM' } elseif ($isAdmin) { "$($me.Name) (administrator)" } else { "$($me.Name) (not administrator: some checks were skipped)" }) $(if (-not $isAdmin) { 'warn' } else { '' })
        # Home-built PCs carry the board maker's placeholders ("System Product Name", "To be filled by O.E.M."):
        # then the motherboard says more.
        $blank = '^\s*$|System (Product Name|Serial Number|manufacturer)|To be filled|Default string|^O\.?E\.?M\.?$|^0+$|^None$|Not Applicable|Not Specified'
        $board = $null; try { $board = Get-CimInstance Win32_BaseBoard -ErrorAction Stop | Select-Object -First 1 } catch { }
        if ($cs) {
            $model = if ("$($cs.Model)" -notmatch $blank -and "$($cs.Manufacturer)" -notmatch $blank) { "$($cs.Manufacturer) $($cs.Model)" }
                     elseif ($board) { "$($board.Manufacturer) $($board.Product) (motherboard)" } else { "$($cs.Manufacturer) $($cs.Model)" }
            Add-Row $s 'Make and model' ($model -replace '\s+', ' ').Trim()
            Add-Row $s $(if ($cs.PartOfDomain) { 'Domain' } else { 'Workgroup' }) $(if ($cs.PartOfDomain) { $cs.Domain } else { $cs.Workgroup })
        }
        if ($bios) {
            $serial = ([string]$bios.SerialNumber).Trim()
            if ($serial -match $blank -and $board -and "$($board.SerialNumber)" -notmatch $blank) { $serial = ([string]$board.SerialNumber).Trim() + ' (motherboard)' }
            if ($serial -notmatch $blank) { Add-Row $s 'Serial number' $serial }
            $bd = ''; try { $bd = ' (' + $bios.ReleaseDate.ToString('yyyy-MM-dd') + ')' } catch { }
            Add-Row $s 'BIOS' ("$($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)$bd").Trim()
        }
        if ($os) {
            $cv = $null; try { $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop } catch { }
            $build = $os.BuildNumber; if ($cv -and $null -ne $cv.UBR) { $build = "$($os.BuildNumber).$($cv.UBR)" }
            $dv = if ($cv -and $cv.DisplayVersion) { "$($cv.DisplayVersion), " } else { '' }
            Add-Row $s 'Windows' (($os.Caption -replace '^Microsoft\s+', '') + " ($dv" + "build $build, $($os.OSArchitecture))")
            try { Add-Row $s 'Windows installed' $os.InstallDate.ToString('yyyy-MM-dd') } catch { }
            $up = (Get-Date) - $os.LastBootUpTime
            $flag = ''
            if ($up.TotalDays -ge 14) { $flag = 'warn'; Add-Problem 'warn' ('Not restarted for {0} days.' -f [int][math]::Floor($up.TotalDays)) }
            Add-Row $s 'Last restart' ($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm') + '  (' + (Get-Ago $os.LastBootUpTime) + ')') $flag
            if ($cs) {
                $total = [double]$cs.TotalPhysicalMemory; $free = [double]$os.FreePhysicalMemory * 1KB
                $used = if ($total) { [int](100 * ($total - $free) / $total) } else { 0 }
                $f = ''; if ($used -ge 90) { $f = 'warn'; Add-Problem 'warn' "Memory is $used% used." }
                Add-Row $s 'Memory' ('{0} ({1} free, {2}% used)' -f (Get-Size $total), (Get-Size $free), $used) $f
            }
            try { Add-Row $s 'Time zone' ([TimeZoneInfo]::Local.DisplayName) } catch { }
        }
        try {
            foreach ($c in @(Get-CimInstance Win32_Processor -ErrorAction Stop)) {
                Add-Row $s 'CPU' ((($c.Name -replace '\s+', ' ').Trim()) + " ($($c.NumberOfCores) cores, $($c.NumberOfLogicalProcessors) threads)")
            }
        } catch { }
        try {
            foreach ($g in @(Get-CimInstance Win32_VideoController -ErrorAction Stop | Where-Object { $_.Name -notmatch 'Remote|Virtual Display|Parsec|Meta Virtual' })) {
                $dd = ''; try { $dd = ', ' + $g.DriverDate.ToString('yyyy-MM-dd') } catch { }
                Add-Row $s 'Graphics' "$($g.Name.Trim()) (driver $($g.DriverVersion)$dd)"
            }
        } catch { }
        try {
            foreach ($d in @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop)) {
                if (-not $d.Size) { continue }
                $pct = [int](100 * $d.FreeSpace / $d.Size)
                $f = ''
                if ($pct -lt 5 -or $d.FreeSpace -lt 5GB) { $f = 'bad'; Add-Problem 'bad' "Drive $($d.DeviceID) is nearly full: $(Get-Size $d.FreeSpace) free." }
                elseif ($pct -lt 10 -or $d.FreeSpace -lt 15GB) { $f = 'warn'; Add-Problem 'warn' "Drive $($d.DeviceID) is getting full: $(Get-Size $d.FreeSpace) free." }
                $label = if ($d.VolumeName) { " $($d.VolumeName)" } else { '' }
                Add-Row $s "Drive $($d.DeviceID)$label" ('{0} free of {1} ({2}%), {3}' -f (Get-Size $d.FreeSpace), (Get-Size $d.Size), $pct, $d.FileSystem) $f
            }
        } catch { }
    }

    # ---- health ------------------------------------------------------------------------------------------------------
    $stopNames = @{
        '0x0000000a' = 'IRQL_NOT_LESS_OR_EQUAL'; '0x0000001a' = 'MEMORY_MANAGEMENT'; '0x0000001e' = 'KMODE_EXCEPTION_NOT_HANDLED'
        '0x0000003b' = 'SYSTEM_SERVICE_EXCEPTION'; '0x00000050' = 'PAGE_FAULT_IN_NONPAGED_AREA'; '0x0000007e' = 'SYSTEM_THREAD_EXCEPTION_NOT_HANDLED'
        '0x0000007f' = 'UNEXPECTED_KERNEL_MODE_TRAP'; '0x0000009f' = 'DRIVER_POWER_STATE_FAILURE'; '0x000000d1' = 'DRIVER_IRQL_NOT_LESS_OR_EQUAL'
        '0x000000ef' = 'CRITICAL_PROCESS_DIED'; '0x00000116' = 'VIDEO_TDR_FAILURE'; '0x00000124' = 'WHEA_UNCORRECTABLE_ERROR'
        '0x00000133' = 'DPC_WATCHDOG_VIOLATION'; '0x00000139' = 'KERNEL_SECURITY_CHECK_FAILURE'; '0x0000013a' = 'KERNEL_MODE_HEAP_CORRUPTION'
        '0x00000154' = 'UNEXPECTED_STORE_EXCEPTION'; '0x0000018b' = 'SECURE_KERNEL_ERROR'; '0x000001a8' = 'BUGCODE_ID_DRIVER'
        '0x00000019' = 'BAD_POOL_HEADER'; '0x000000c2' = 'BAD_POOL_CALLER'; '0x0000004e' = 'PFN_LIST_CORRUPT'
    }
    $pnpCodes = @{ 1 = 'not set up correctly'; 3 = 'driver may be damaged'; 10 = "can't start"; 12 = 'not enough resources'; 14 = 'needs a restart'; 18 = 'needs its drivers reinstalled'; 19 = 'registry damaged'; 21 = 'being removed'; 22 = 'disabled'; 24 = 'missing or not working'; 28 = 'no driver installed'; 29 = 'disabled in firmware'; 31 = "driver can't load"; 32 = 'driver service disabled'; 37 = 'driver failed'; 39 = 'driver missing or damaged'; 43 = 'reported a problem'; 45 = 'not connected'; 47 = 'safely removed'; 48 = 'blocked driver'; 52 = 'unsigned driver' }

    function Read-Health {
        $s = New-Section 'Health'
        $since30 = (Get-Date).AddDays(-30)
        # drives' own health (the counters need administrator)
        try {
            foreach ($p in @(Get-PhysicalDisk -ErrorAction Stop | Sort-Object DeviceId)) {
                $bits = @("$($p.MediaType)", "$($p.BusType)", (Get-Size $p.Size)) | Where-Object { $_ -and $_ -ne 'Unspecified' }
                $health = [string]$p.HealthStatus
                $f = ''
                if ($health -and $health -ne 'Healthy') { $f = 'bad'; Add-Problem 'bad' "Drive '$($p.FriendlyName)' reports its health as $health. Back it up and replace it." }
                $more = @()
                if ($isAdmin) {
                    try {
                        $rc = $p | Get-StorageReliabilityCounter -ErrorAction Stop
                        if ($rc.Temperature) { $more += "$($rc.Temperature) C" }
                        if ($null -ne $rc.Wear) { $more += "$($rc.Wear)% worn"; if ($rc.Wear -ge 80) { if (-not $f) { $f = 'warn' }; Add-Problem 'warn' "Drive '$($p.FriendlyName)' is $($rc.Wear)% worn." } }
                        if ($rc.PowerOnHours) { $more += "$($rc.PowerOnHours) hours on" }
                        if ($rc.ReadErrorsUncorrected) { $more += "$($rc.ReadErrorsUncorrected) read errors"; $f = 'bad'; Add-Problem 'bad' "Drive '$($p.FriendlyName)' has $($rc.ReadErrorsUncorrected) read errors it couldn't fix." }
                    } catch { }
                }
                Add-Row $s "Drive: $($p.FriendlyName)" ((@($health) + $bits + $more) -join ', ') $f
            }
        } catch { Add-Row $s 'Drives' "couldn't read drive health" 'warn' }
        if (-not $isAdmin) { Add-Row $s 'Drive counters' 'temperature, wear and errors need administrator' 'warn' }

        # blue screens
        $bsod = Get-Events @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'; Id = 1001; StartTime = $since30 } 20
        if ($bsod.Count) {
            Add-Problem 'bad' "$($bsod.Count) blue screen(s) in the last 30 days."
            foreach ($e in $bsod | Select-Object -First 8) {
                $code = if ($e.Message -match '0x[0-9a-fA-F]{8}') { $Matches[0].ToLower() } else { '' }
                $name = if ($code -and $stopNames.ContainsKey($code)) { " $($stopNames[$code])" } else { '' }
                Add-Row $s 'Blue screen' ($e.TimeCreated.ToString('yyyy-MM-dd HH:mm') + "  stop code $code$name") 'bad'
            }
        } else { Add-Row $s 'Blue screens' 'none in the last 30 days' 'ok' }
        try {
            $dumps = @(Get-ChildItem -LiteralPath "$env:SystemRoot\Minidump" -Filter *.dmp -ErrorAction Stop | Sort-Object LastWriteTime -Descending)
            if ($dumps.Count) { Add-Row $s 'Crash dumps' "$($dumps.Count) in $env:SystemRoot\Minidump, newest $($dumps[0].LastWriteTime.ToString('yyyy-MM-dd HH:mm'))" }
        } catch { }

        $off = Get-Events @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-Power'; Id = 41; StartTime = $since30 } 50
        if ($off.Count) {
            Add-Problem 'warn' "$($off.Count) unexpected shutdown(s) in the last 30 days (power loss, a hang or a hard reset)."
            Add-Row $s 'Unexpected shutdowns' "$($off.Count) in the last 30 days, last $($off[0].TimeCreated.ToString('yyyy-MM-dd HH:mm'))" 'warn'
        } else { Add-Row $s 'Unexpected shutdowns' 'none in the last 30 days' 'ok' }

        $whea = Get-Events @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WHEA-Logger'; StartTime = $since30 } 50
        if ($whea.Count) {
            Add-Problem 'bad' "$($whea.Count) hardware error(s) logged in the last 30 days (CPU, memory or PCIe)."
            Add-Row $s 'Hardware errors' "$($whea.Count) in the last 30 days, last $($whea[0].TimeCreated.ToString('yyyy-MM-dd HH:mm'))" 'bad'
        }
        $disk = @(Get-Events @{ LogName = 'System'; ProviderName = 'disk'; Id = 7, 51, 153; StartTime = $since30 } 100) + @(Get-Events @{ LogName = 'System'; ProviderName = 'Ntfs'; Id = 55; StartTime = $since30 } 50)
        if ($disk.Count) {
            Add-Problem 'warn' "$($disk.Count) disk or file system error(s) in the last 30 days."
            Add-Row $s 'Disk errors' "$($disk.Count) in the last 30 days" 'warn'
        }

        # programs that crashed this week: Reliability Monitor's own list when Windows keeps one, else the event log
        if ($rel.Records) {
            $week = @($rel.Records | Where-Object { $_.TimeGenerated -gt (Get-Date).AddDays(-7) -and ($_.SourceName -eq 'Application Error' -or $_.SourceName -eq 'Application Hang') })
            if ($week.Count) {
                $top = $week | ForEach-Object { if ($_.ProductName) { $_.ProductName } else { 'unknown' } } | Group-Object | Sort-Object Count -Descending | Select-Object -First 6
                Add-Row $s 'Program crashes' ("$($week.Count) this week: " + (($top | ForEach-Object { "$($_.Name) x$($_.Count)" }) -join ', '))
            } else { Add-Row $s 'Program crashes' 'none this week' 'ok' }
            $apps = $null
        } else { $apps = Get-Events @{ LogName = 'Application'; ProviderName = 'Application Error'; Id = 1000; StartTime = (Get-Date).AddDays(-7) } 200 }
        if ($null -eq $apps) { }
        elseif ($apps.Count) {
            $top = $apps | ForEach-Object { if ($_.Properties.Count) { [string]$_.Properties[0].Value } } | Where-Object { $_ } | Group-Object | Sort-Object Count -Descending | Select-Object -First 6
            Add-Row $s 'Program crashes' ("$($apps.Count) this week: " + (($top | ForEach-Object { "$($_.Name) x$($_.Count)" }) -join ', '))
        } else { Add-Row $s 'Program crashes' 'none this week' 'ok' }

        # devices with a problem (Device Manager's yellow marks)
        try {
            $bad = @(Get-CimInstance Win32_PnPEntity -Filter 'ConfigManagerErrorCode <> 0' -ErrorAction Stop)
            $offDev = @()
            foreach ($d in $bad) {
                $code = [int]$d.ConfigManagerErrorCode
                $what = if ($pnpCodes.ContainsKey($code)) { $pnpCodes[$code] } else { "code $code" }
                $name = if ($d.Name) { $d.Name } else { $d.DeviceID }
                # disabled on purpose, unplugged or removed: worth knowing, not a problem
                if ($code -eq 22 -or $code -eq 45 -or $code -eq 47) { $offDev += $name; continue }
                Add-Row $s 'Device problem' "$name - $what (code $code)" 'warn'
                Add-Problem 'warn' "Device '$name': $what (code $code)."
            }
            if (-not ($bad | Where-Object { @(22, 45, 47) -notcontains [int]$_.ConfigManagerErrorCode })) { Add-Row $s 'Devices' 'all working' 'ok' }
            if ($offDev) { Add-Row $s 'Disabled or unplugged' ("$($offDev.Count): " + (($offDev | Sort-Object -Unique) -join ', ')) }
        } catch { }
    }

    # ---- reliability (Reliability Monitor's data: Win32_ReliabilityStabilityMetrics and Win32_ReliabilityRecords) -------
    # Windows scores the PC 1-10 every hour from its crashes and failures; the records are what pulled the score down.
    # No administrator needed. Windows Server doesn't collect it unless it's turned on.
    function Read-ReliabilityData {
        try { $rel.Metrics = @(Get-CimInstance Win32_ReliabilityStabilityMetrics -ErrorAction Stop | Sort-Object TimeGenerated) } catch { }
        try { $rel.Records = @(Get-CimInstance Win32_ReliabilityRecords -ErrorAction Stop | Where-Object { $_.TimeGenerated -gt (Get-Date).AddDays(-30) } | Sort-Object TimeGenerated -Descending) } catch { }
    }
    function Read-Reliability {
        $s = New-Section 'Reliability'
        if (-not $rel.Metrics -and -not $rel.Records) { Add-Row $s 'Reliability Monitor' 'no data (Windows is not collecting it on this PC)' 'warn'; return }
        if ($rel.Metrics) {
            $now = $rel.Metrics[-1]
            $score = [math]::Round([double]$now.SystemStabilityIndex, 1)
            $f = if ($score -lt 5) { 'bad' } elseif ($score -lt 7) { 'warn' } else { 'ok' }
            if ($score -lt 7) { Add-Problem $(if ($score -lt 5) { 'bad' } else { 'warn' }) "Reliability Monitor scores this PC $score out of 10 (from its recent crashes and failures)." }
            Add-Row $s 'Stability now' "$score out of 10" $f
            # the lowest score of each of the last 30 days, for the page's chart
            $days = $rel.Metrics | Where-Object { $_.TimeGenerated -gt (Get-Date).Date.AddDays(-29) } | Group-Object { $_.TimeGenerated.ToString('yyyy-MM-dd') } | Sort-Object Name
            $points = @($days | ForEach-Object { , @($_.Name, [math]::Round(($_.Group | Measure-Object SystemStabilityIndex -Minimum).Minimum, 2)) })
            if ($points.Count) {
                $low = $points | Sort-Object { $_[1] } | Select-Object -First 1
                Add-Row $s 'Lowest this month' "$([math]::Round($low[1], 1)) out of 10, on $($low[0])" $(if ($low[1] -lt 5) { 'warn' } else { '' })
                $s.chart = [ordered]@{ title = 'Stability, lowest of each day (1 to 10)'; min = 1; max = 10; points = $points }
            }
        }
        $kinds = [ordered]@{}
        $changes = @{ installed = 0; removed = 0 }
        foreach ($r in $rel.Records) {
            $what = $null
            switch ($r.SourceName) {
                'Application Error' { $what = "stopped working: $($r.ProductName)" }
                'Application Hang' { $what = "stopped responding: $($r.ProductName)" }
                'EventLog' { if ($r.EventIdentifier -eq 6008) { $what = 'Windows shut down unexpectedly' } }
                'Microsoft-Windows-WER-SystemErrorReporting' { $what = 'Windows stopped (blue screen)' }
                'Windows Error Reporting' {
                    if ("$($r.Message)" -match 'Event Name:\s*(BlueScreen|LiveKernelEvent)') { $what = $(if ($Matches[1] -eq 'BlueScreen') { 'Windows stopped (blue screen)' } else { 'Windows hardware or driver problem (LiveKernelEvent)' }) }
                }
                'MsiInstaller' { if ($r.EventIdentifier -eq 11707 -or $r.EventIdentifier -eq 1033) { $changes.installed++ } elseif ($r.EventIdentifier -eq 11724 -or $r.EventIdentifier -eq 1034) { $changes.removed++ } }
            }
            if (-not $what) { continue }
            $kind = ($what -split ':')[0]
            if (-not $kinds.Contains($kind)) { $kinds[$kind] = 0 }
            $kinds[$kind]++
            if ($s.lines.Count -lt 25) { $s.lines.Add($r.TimeGenerated.ToString('yyyy-MM-dd HH:mm') + "  $what") }
        }
        Add-Row $s 'Failures, 30 days' $(if ($kinds.Count) { ($kinds.Keys | ForEach-Object { "$($kinds[$_]) $_" }) -join ', ' } else { 'none' }) $(if ($kinds.Count) { '' } else { 'ok' })
        if ($changes.installed -or $changes.removed) { Add-Row $s 'Programs changed, 30 days' "$($changes.installed) installed, $($changes.removed) removed" }
    }

    # ---- security ----------------------------------------------------------------------------------------------------
    function Read-Security {
        $s = New-Section 'Security'
        $av = @()
        try { $av = @(Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction Stop) } catch { }
        $others = @($av | Where-Object { $_.displayName -notmatch 'Windows Defender|Microsoft Defender' })
        if ($others) { Add-Row $s 'Antivirus' (($others | ForEach-Object { $_.displayName } | Select-Object -Unique) -join ', ') }
        try {
            $mp = Get-MpComputerStatus -ErrorAction Stop
            $rt = [bool]$mp.RealTimeProtectionEnabled
            $f = if ($rt) { 'ok' } elseif ($others) { '' } else { 'bad' }
            if (-not $rt -and -not $others) { Add-Problem 'bad' 'Microsoft Defender real-time protection is off and no other antivirus was found.' }
            Add-Row $s 'Defender' $(if ($rt) { 'real-time protection on' } elseif ($others) { 'off (another antivirus is in charge)' } else { 'real-time protection OFF' }) $f
            if ($rt -and $mp.AntivirusSignatureLastUpdated) {
                $age = ((Get-Date) - $mp.AntivirusSignatureLastUpdated).TotalDays
                $f = ''; if ($age -gt 7) { $f = 'warn'; Add-Problem 'warn' ('Defender signatures are {0} days old.' -f [int]$age) }
                Add-Row $s 'Defender signatures' ($mp.AntivirusSignatureLastUpdated.ToString('yyyy-MM-dd') + ' (' + (Get-Ago $mp.AntivirusSignatureLastUpdated) + ')') $f
            }
            if ($mp.QuickScanEndTime) { Add-Row $s 'Last quick scan' ($mp.QuickScanEndTime.ToString('yyyy-MM-dd') + ' (' + (Get-Ago $mp.QuickScanEndTime) + ')') }
        } catch { if (-not $others) { Add-Row $s 'Defender' "couldn't read its status" 'warn' } }
        try {
            $threats = @(Get-MpThreatDetection -ErrorAction Stop | Where-Object { $_.InitialDetectionTime -gt (Get-Date).AddDays(-30) })
            if ($threats.Count) { Add-Row $s 'Threats found' "$($threats.Count) in the last 30 days" 'warn'; Add-Problem 'warn' "Defender found $($threats.Count) threat(s) in the last 30 days." }
        } catch { }
        try {
            $fw = @(Get-NetFirewallProfile -ErrorAction Stop)
            $offp = @($fw | Where-Object { -not $_.Enabled } | ForEach-Object { $_.Name })
            if ($offp) { Add-Problem 'bad' "Windows Firewall is off for: $($offp -join ', ')." }
            Add-Row $s 'Firewall' (($fw | ForEach-Object { "$($_.Name) " + $(if ($_.Enabled) { 'on' } else { 'OFF' }) }) -join ', ') $(if ($offp) { 'bad' } else { 'ok' })
        } catch { }
        if ($isAdmin) {
            try {
                $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
                $on = "$($bl.ProtectionStatus)" -eq 'On'
                Add-Row $s "BitLocker ($env:SystemDrive)" $(if ($on) { "on ($($bl.EncryptionMethod))" } else { "off ($($bl.VolumeStatus))" }) $(if ($on) { 'ok' } else { 'warn' })
            } catch { Add-Row $s 'BitLocker' 'not available' }
            try { $sb = Confirm-SecureBootUEFI -ErrorAction Stop; Add-Row $s 'Secure Boot' $(if ($sb) { 'on' } else { 'off' }) $(if ($sb) { 'ok' } else { 'warn' }) }
            catch { Add-Row $s 'Secure Boot' 'not supported (legacy BIOS)' 'warn' }
            try {
                $tpm = Get-Tpm -ErrorAction Stop
                $tv = ''; try { $tv = ' ' + (([string](Get-CimInstance -Namespace root\cimv2\security\microsofttpm -ClassName Win32_Tpm -ErrorAction Stop).SpecVersion) -split ',')[0].Trim() } catch { }
                Add-Row $s 'TPM' $(if ($tpm.TpmPresent) { "present$tv" + $(if ($tpm.TpmReady) { ', ready' } else { ', not ready' }) } else { 'none' }) $(if ($tpm.TpmPresent -and $tpm.TpmReady) { 'ok' } else { 'warn' })
            } catch { }
        } else { Add-Row $s 'BitLocker, Secure Boot, TPM' 'need administrator' 'warn' }
        $lua = Get-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'EnableLUA'
        if ($null -ne $lua) {
            if ($lua -eq 0) { Add-Problem 'bad' 'User Account Control (UAC) is turned off.' }
            Add-Row $s 'User Account Control' $(if ($lua -eq 0) { 'OFF' } else { 'on' }) $(if ($lua -eq 0) { 'bad' } else { 'ok' })
        }
        try {
            $grp = ((New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([Security.Principal.NTAccount]).Value -split '\\')[-1]
            $members = @(([ADSI]"WinNT://./$grp,group").psbase.Invoke('Members') | ForEach-Object {
                $p = $_.GetType().InvokeMember('ADsPath', 'GetProperty', $null, $_, $null)
                ($p -replace '^WinNT://', '' -replace '/', '\')
            })
            Add-Row $s 'Administrators' ($members -join ', ')
        } catch { }
        $rdp = Get-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' 'fDenyTSConnections'
        if ($null -ne $rdp) { Add-Row $s 'Remote Desktop' $(if ($rdp -eq 0) { 'on (this PC accepts Remote Desktop)' } else { 'off' }) $(if ($rdp -eq 0) { 'warn' } else { '' }) }
        try {
            $smb1 = (Get-SmbServerConfiguration -ErrorAction Stop).EnableSMB1Protocol
            if ($smb1) { Add-Problem 'warn' 'SMBv1 (an old, unsafe file-sharing protocol) is turned on.' }
            Add-Row $s 'SMBv1' $(if ($smb1) { 'ON' } else { 'off' }) $(if ($smb1) { 'warn' } else { 'ok' })
        } catch { }
        try {
            $lic = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" -ErrorAction Stop | Select-Object -First 1
            if ($lic) {
                $st = @{ 0 = 'not activated'; 1 = 'activated'; 2 = 'grace period'; 3 = 'grace period'; 4 = 'not genuine grace'; 5 = 'not activated'; 6 = 'extended grace' }[[int]$lic.LicenseStatus]
                if ([int]$lic.LicenseStatus -ne 1) { Add-Problem 'warn' "Windows is $st." }
                Add-Row $s 'Windows activation' $st $(if ([int]$lic.LicenseStatus -eq 1) { 'ok' } else { 'warn' })
            }
        } catch { }
        $why = @()
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') { $why += 'Windows components' }
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { $why += 'Windows Update' }
        if ($why) { Add-Problem 'warn' "A restart is waiting ($($why -join ', '))." }
        Add-Row $s 'Restart waiting' $(if ($why) { 'yes: ' + ($why -join ', ') } else { 'no' }) $(if ($why) { 'warn' } else { 'ok' })
    }

    # ---- network -----------------------------------------------------------------------------------------------------
    function Test-Ping([string]$Target, [int]$Count = 4) {
        $p = New-Object System.Net.NetworkInformation.Ping
        $ok = @()
        for ($i = 0; $i -lt $Count; $i++) {
            try { $r = $p.Send($Target, 1000); if ($r.Status -eq 'Success') { $ok += $r.RoundtripTime } } catch { }
        }
        $p.Dispose()
        [pscustomobject]@{ Sent = $Count; Got = $ok.Count; Avg = $(if ($ok.Count) { [int](($ok | Measure-Object -Average).Average) } else { 0 }) }
    }
    function Read-Network {
        $s = New-Section 'Network'
        $gateway = ''
        try {
            $adapters = @{}
            foreach ($a in @(Get-NetAdapter -ErrorAction Stop)) { $adapters[[int]$a.ifIndex] = $a }
            foreach ($c in @(Get-NetIPConfiguration -ErrorAction Stop | Where-Object { $_.NetAdapter.Status -eq 'Up' })) {
                $a = $adapters[[int]$c.InterfaceIndex]
                $ip = @($c.IPv4Address | ForEach-Object { "$($_.IPAddress)/$($_.PrefixLength)" }) -join ', '
                $gw = @($c.IPv4DefaultGateway | ForEach-Object { $_.NextHop }) -join ', '
                if (-not $gateway -and $gw) { $gateway = ($gw -split ', ')[0] }
                $dns = @($c.DNSServer | Where-Object { $_.AddressFamily -eq 2 } | ForEach-Object { $_.ServerAddresses }) -join ', '
                $dhcp = ''; try { $dhcp = if ((Get-NetIPInterface -InterfaceIndex $c.InterfaceIndex -AddressFamily IPv4 -ErrorAction Stop).Dhcp -eq 'Enabled') { 'DHCP' } else { 'fixed address' } } catch { }
                $bits = @($ip, $(if ($gw) { "gateway $gw" }), $(if ($dns) { "DNS $dns" }), $dhcp, $(if ($a) { $a.LinkSpeed }), $(if ($a) { "MAC $($a.MacAddress)" })) | Where-Object { $_ }
                Add-Row $s "$($c.InterfaceAlias)" (($bits -join ', ') + $(if ($a) { "  ($($a.InterfaceDescription))" } else { '' }))
            }
        } catch {
            try {
                foreach ($c in @(Get-CimInstance Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE' -ErrorAction Stop)) {
                    if (-not $gateway -and $c.DefaultIPGateway) { $gateway = @($c.DefaultIPGateway)[0] }
                    Add-Row $s $c.Description ((@($c.IPAddress) -join ', ') + $(if ($c.DefaultIPGateway) { ", gateway $(@($c.DefaultIPGateway) -join ', ')" } else { '' }))
                }
            } catch { }
        }
        # Wi-Fi, from netsh (its labels are English only on English Windows; elsewhere this is skipped)
        try {
            $w = @{}
            foreach ($l in @(netsh wlan show interfaces 2>$null)) { if ($l -match '^\s+([^:]+?)\s+:\s(.*)$') { if (-not $w.ContainsKey($Matches[1])) { $w[$Matches[1]] = $Matches[2].Trim() } } }
            if ($w['State'] -eq 'connected' -and $w['SSID']) {
                $sig = 0; [void][int]::TryParse(($w['Signal'] -replace '%', ''), [ref]$sig)
                $f = ''; if ($sig -and $sig -lt 50) { $f = 'warn'; Add-Problem 'warn' "Wi-Fi signal is weak ($sig%)." }
                Add-Row $s 'Wi-Fi' ((@("'$($w['SSID'])'", "signal $($w['Signal'])", $w['Radio type'], $(if ($w['Channel']) { "channel $($w['Channel'])" }), $(if ($w['Receive rate (Mbps)']) { "$($w['Receive rate (Mbps)']) Mbps" })) | Where-Object { $_ }) -join ', ') $f
            }
        } catch { }
        if ($gateway) {
            $g = Test-Ping $gateway
            $f = if ($g.Got -eq 0) { 'bad' } elseif ($g.Got -lt $g.Sent) { 'warn' } else { 'ok' }
            if ($g.Got -lt $g.Sent -and $g.Got -gt 0) { Add-Problem 'warn' "Packets to the router are being lost ($($g.Sent - $g.Got) of $($g.Sent))." }
            Add-Row $s 'Router' $(if ($g.Got) { "answers in $($g.Avg) ms ($($g.Got) of $($g.Sent))" } else { "doesn't answer ping (some routers don't)" }) $f
        }
        $i = Test-Ping '1.1.1.1'
        $f = if ($i.Got -eq 0) { 'warn' } elseif ($i.Got -lt $i.Sent) { 'warn' } else { 'ok' }
        if ($i.Got -lt $i.Sent -and $i.Got -gt 0) { Add-Problem 'warn' "Packets to the internet are being lost ($($i.Sent - $i.Got) of $($i.Sent))." }
        Add-Row $s 'Internet' $(if ($i.Got) { "answers in $($i.Avg) ms ($($i.Got) of $($i.Sent))" } else { "no answer to ping (it may be blocked here)" }) $f
        $t = [Diagnostics.Stopwatch]::StartNew()
        try { [void][Net.Dns]::GetHostAddresses('www.microsoft.com'); Add-Row $s 'DNS' "works ($($t.ElapsedMilliseconds) ms)" 'ok' }
        catch { Add-Row $s 'DNS' "can't look up names" 'bad'; Add-Problem 'bad' "DNS doesn't work: names can't be looked up." }
        try {
            $wan = ([string](Invoke-RestMethod -Uri "$site/ip" -UserAgent 'pxdReport' -TimeoutSec 6)).Trim()
            if ($wan -match '^[0-9a-fA-F:.]{3,45}$') { Add-Row $s 'Public address' $wan }
        } catch { }
        if ($userHive) {
            if ((Get-Reg "$userHive\Software\Microsoft\Windows\CurrentVersion\Internet Settings" 'ProxyEnable') -eq 1) {
                Add-Row $s 'Proxy' ("on: " + (Get-Reg "$userHive\Software\Microsoft\Windows\CurrentVersion\Internet Settings" 'ProxyServer')) 'warn'
            }
            $pac = Get-Reg "$userHive\Software\Microsoft\Windows\CurrentVersion\Internet Settings" 'AutoConfigURL'
            if ($pac) { Add-Row $s 'Proxy script' $pac 'warn' }
        }
        try {
            $hosts = @(Get-Content -LiteralPath "$env:SystemRoot\System32\drivers\etc\hosts" -ErrorAction Stop | Where-Object { $_ -match '^\s*[^#\s]' })
            if ($hosts.Count) {
                Add-Row $s 'Hosts file' "$($hosts.Count) entr$(if ($hosts.Count -eq 1) { 'y' } else { 'ies' })" 'warn'
                foreach ($h in $hosts | Select-Object -First 15) { $s.lines.Add('hosts: ' + ($h.Trim() -replace '\s+', ' ')) }
            }
        } catch { }
    }

    # ---- software ----------------------------------------------------------------------------------------------------
    function Read-Software {
        $s = New-Section 'Starts with Windows'
        $places = @(
            @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'all users'),
            @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run', 'all users, 32-bit'),
            @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce', 'all users, once')
        )
        if ($userHive) { $places += , @("$userHive\Software\Microsoft\Windows\CurrentVersion\Run", 'signed-in user'); $places += , @("$userHive\Software\Microsoft\Windows\CurrentVersion\RunOnce", 'signed-in user, once') }
        $n = 0
        foreach ($p in $places) {
            try {
                $k = Get-Item -LiteralPath $p[0] -ErrorAction Stop
                foreach ($name in $k.GetValueNames()) { if ($name) { $s.lines.Add("$name  ($($p[1])): $($k.GetValue($name))"); $n++ } }
            } catch { }
        }
        $folders = @(@("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup", 'all users folder'))
        if ($userProfile) { $folders += , @("$userProfile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup", 'signed-in user folder') }
        foreach ($f in $folders) {
            try { foreach ($i in @(Get-ChildItem -LiteralPath $f[0] -File -ErrorAction Stop | Where-Object { $_.Name -ne 'desktop.ini' })) { $s.lines.Add("$($i.Name)  ($($f[1]))"); $n++ } } catch { }
        }
        try {
            $tasks = @(Get-ScheduledTask -ErrorAction Stop | Where-Object { $_.TaskPath -notlike '\Microsoft\*' -and $_.State -ne 'Disabled' })
            foreach ($t in $tasks | Sort-Object TaskName) { $s.lines.Add("task: $($t.TaskPath.TrimStart('\'))$($t.TaskName)") }
            $n += $tasks.Count
        } catch { }
        if (-not $userHive) { $s.note = "The signed-in user's own startup items couldn't be read." }
        Add-Row $s 'Items' $n

        $s = New-Section 'Programs'
        $roots = @(@('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', ''), @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall', ''))
        if ($userHive) { $roots += , @("$userHive\Software\Microsoft\Windows\CurrentVersion\Uninstall", ' (signed-in user only)') }
        $list = @{}
        $recent = @()
        foreach ($r in $roots) {
            try {
                foreach ($k in @(Get-ChildItem -LiteralPath $r[0] -ErrorAction Stop)) {
                    try {
                        $v = Get-ItemProperty -LiteralPath $k.PSPath -ErrorAction Stop
                        if (-not $v.DisplayName -or $v.SystemComponent -eq 1 -or $v.ParentKeyName -or $v.ReleaseType -match 'Update|Hotfix') { continue }
                        $name = ([string]$v.DisplayName).Trim()
                        if ($list.ContainsKey($name)) { continue }
                        $date = $null
                        if ($v.InstallDate -match '^\d{8}$') { try { $date = [datetime]::ParseExact($v.InstallDate, 'yyyyMMdd', $null) } catch { } }
                        $list[$name] = "$name" + $(if ($v.DisplayVersion) { " $($v.DisplayVersion)" } else { '' }) + $(if ($v.Publisher) { " - $(([string]$v.Publisher).Trim())" } else { '' }) + $(if ($date) { ", $($date.ToString('yyyy-MM-dd'))" } else { '' }) + $r[1]
                        if ($date -and $date -gt (Get-Date).AddDays(-7)) { $recent += $name }
                    } catch { }
                }
            } catch { }
        }
        Add-Row $s 'Installed' $list.Count
        if ($recent) { Add-Row $s 'Installed this week' (($recent | Sort-Object) -join ', ') }
        foreach ($k in $list.Keys | Sort-Object) { $s.lines.Add($list[$k]) }

        $s = New-Section 'Windows Update'
        try {
            $wu = Get-Service wuauserv -ErrorAction Stop
            Add-Row $s 'Update service' "$($wu.Status), starts $($wu.StartType)" $(if ("$($wu.StartType)" -eq 'Disabled') { 'bad' } else { '' })
            if ("$($wu.StartType)" -eq 'Disabled') { Add-Problem 'bad' 'The Windows Update service is disabled.' }
        } catch { }
        $ok = Get-Events @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WindowsUpdateClient'; Id = 19 } 1
        if ($ok.Count) {
            $f = ''; if ($ok[0].TimeCreated -lt (Get-Date).AddDays(-45)) { $f = 'warn'; Add-Problem 'warn' "No update has installed for $([int]((Get-Date) - $ok[0].TimeCreated).TotalDays) days." }
            Add-Row $s 'Last update installed' ($ok[0].TimeCreated.ToString('yyyy-MM-dd') + ' (' + (Get-Ago $ok[0].TimeCreated) + ')') $f
        }
        # event 20: [0] the error code, [1] what was being installed (an update's title, or a Store app's id)
        $failed = Get-Events @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WindowsUpdateClient'; Id = 20; StartTime = (Get-Date).AddDays(-30) } 50
        if ($failed.Count) {
            $seen = @{}
            foreach ($e in $failed) {
                if ($e.Properties.Count -lt 2) { continue }
                $what = ([string]$e.Properties[1].Value) -replace '^[0-9A-Z]{12}-', 'Store app '
                if ($seen.ContainsKey($what)) { continue }
                $code = ''; try { $code = ' (0x{0:X8})' -f ([uint32]([int64]$e.Properties[0].Value -band 0xFFFFFFFF)) } catch { }
                $seen[$what] = "failed $($e.TimeCreated.ToString('yyyy-MM-dd')): $what$code"
            }
            $store = @($seen.Keys | Where-Object { $_ -like 'Store app *' }).Count
            $windows = $seen.Count - $store
            if ($windows) { Add-Problem 'warn' "$windows Windows update(s) failed to install in the last 30 days." }
            Add-Row $s 'Failed updates' ("$($failed.Count) in the last 30 days" + $(if ($store -and -not $windows) { ' (Store apps only)' } elseif ($store) { " ($store Store app$(if ($store -ne 1) { 's' }))" } else { '' })) $(if ($windows) { 'warn' } else { '' })
            foreach ($v in $seen.Values | Select-Object -First 12) { $s.lines.Add($v) }
        } else { Add-Row $s 'Failed updates' 'none in the last 30 days' 'ok' }
        try {
            foreach ($h in @(Get-HotFix -ErrorAction Stop | Where-Object { $_.InstalledOn } | Sort-Object InstalledOn -Descending | Select-Object -First 8)) {
                $s.lines.Add("$($h.HotFixID)  $($h.Description), $($h.InstalledOn.ToString('yyyy-MM-dd'))")
            }
        } catch { }
    }

    # ---- the report as text (the same layout as the page's Copy button) ------------------------------------------
    function Get-ReportText {
        $o = New-Object System.Collections.Generic.List[string]
        $o.Add("pxd Report: $($report.pc)  ($((Get-Date).ToString('yyyy-MM-dd HH:mm')))"); $o.Add(''); $o.Add('Problems found:')
        if ($problems.Count) { foreach ($p in $problems) { $o.Add("  - $($p.text)") } } else { $o.Add('  none') }
        foreach ($sec in $sections) {
            $o.Add(''); $o.Add("== $($sec.title) ==")
            foreach ($r in $sec.rows) { $o.Add('  ' + $(if ($r[0]) { "$($r[0]): " } else { '' }) + $r[1] + $(if ($r[2] -eq 'bad') { '  [!]' } elseif ($r[2] -eq 'warn') { '  [?]' } else { '' })) }
            foreach ($l in $sec.lines) { $o.Add("  $l") }
            if ($sec.note) { $o.Add("  ($($sec.note))") }
        }
        $o.Add(''); $o.Add("Made by pxd Report $version, pxdtek.com")
        $o -join "`r`n"
    }

    # ---- encrypt and upload ------------------------------------------------------------------------------------------
    # A random 128-bit key (only the link holds it) makes three keys: AES-256 for the report, HMAC-SHA256 to seal it,
    # and a delete token. The report is gzipped JSON; the upload is version byte 1 + IV + ciphertext + HMAC.
    function New-Sealed([byte[]]$Plain) {
        $k = New-Object byte[] 16
        $rng = [Security.Cryptography.RandomNumberGenerator]::Create(); $rng.GetBytes($k); $rng.Dispose()
        $h = New-Object Security.Cryptography.HMACSHA256(, $k)
        $encKey = $h.ComputeHash([Text.Encoding]::UTF8.GetBytes('pxd-report-enc'))
        $macKey = $h.ComputeHash([Text.Encoding]::UTF8.GetBytes('pxd-report-mac'))
        $delTok = -join ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes('pxd-report-del')) | ForEach-Object { $_.ToString('x2') })
        $h.Dispose()
        $ms = New-Object IO.MemoryStream
        $gz = New-Object IO.Compression.GZipStream($ms, [IO.Compression.CompressionMode]::Compress)
        $gz.Write($Plain, 0, $Plain.Length); $gz.Dispose()
        $packed = $ms.ToArray()
        $aes = [Security.Cryptography.Aes]::Create()
        $aes.KeySize = 256; $aes.Key = $encKey; $aes.Mode = 'CBC'; $aes.Padding = 'PKCS7'; $aes.GenerateIV()
        $e = $aes.CreateEncryptor(); $ct = $e.TransformFinalBlock($packed, 0, $packed.Length); $e.Dispose()
        $head = New-Object byte[] (17 + $ct.Length)
        $head[0] = 1; [Array]::Copy($aes.IV, 0, $head, 1, 16); [Array]::Copy($ct, 0, $head, 17, $ct.Length)
        $aes.Dispose()
        $m = New-Object Security.Cryptography.HMACSHA256(, $macKey); $tag = $m.ComputeHash($head); $m.Dispose()
        $body = New-Object byte[] ($head.Length + 32)
        [Array]::Copy($head, $body, $head.Length); [Array]::Copy($tag, 0, $body, $head.Length, 32)
        $sha = [Security.Cryptography.SHA256]::Create()
        $delHash = -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($delTok)) | ForEach-Object { $_.ToString('x2') }); $sha.Dispose()
        [pscustomobject]@{ Body = $body; Key = ([Convert]::ToBase64String($k).TrimEnd('=').Replace('+', '-').Replace('/', '_')); DeleteHash = $delHash }
    }

    # ---- QR code (byte mode, error correction M, versions 1-9), so the link can be read off the screen by phone ----
    function Get-QrMul([int]$x, [int]$y) {
        $z = 0
        for ($i = 7; $i -ge 0; $i--) { $z = (($z -shl 1) -bxor (($z -shr 7) * 0x11D)) -band 0xFF; if ((($y -shr $i) -band 1) -eq 1) { $z = $z -bxor $x } }
        $z
    }
    function Get-QrEcc([int[]]$Data, [int]$Degree) {
        $div = New-Object int[] $Degree; $div[$Degree - 1] = 1; $root = 1
        for ($i = 0; $i -lt $Degree; $i++) {
            for ($j = 0; $j -lt $Degree; $j++) { $div[$j] = Get-QrMul $div[$j] $root; if ($j + 1 -lt $Degree) { $div[$j] = $div[$j] -bxor $div[$j + 1] } }
            $root = Get-QrMul $root 2
        }
        $res = New-Object int[] $Degree
        foreach ($b in $Data) {
            $f = $b -bxor $res[0]
            for ($j = 0; $j -lt $Degree - 1; $j++) { $res[$j] = $res[$j + 1] }
            $res[$Degree - 1] = 0
            for ($j = 0; $j -lt $Degree; $j++) { $res[$j] = $res[$j] -bxor (Get-QrMul $div[$j] $f) }
        }
        $res
    }
    function New-QrCode([string]$Text) {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        $eccLen = @(0, 10, 16, 26, 18, 24, 16, 18, 22, 22); $blocks = @(0, 1, 1, 1, 2, 2, 4, 4, 4, 5)
        $align = @($null, @(), @(6, 18), @(6, 22), @(6, 26), @(6, 30), @(6, 34), @(6, 22, 38), @(6, 24, 42), @(6, 26, 46))
        $ver = 0
        for ($v = 1; $v -le 9; $v++) {
            $raw = (16 * $v + 128) * $v + 64
            if ($v -ge 2) { $na = [math]::Floor($v / 7) + 2; $raw -= (25 * $na - 10) * $na - 55; if ($v -ge 7) { $raw -= 36 } }
            $dataCw = [math]::Floor($raw / 8) - $eccLen[$v] * $blocks[$v]
            if (4 + 8 + 8 * $bytes.Length -le 8 * $dataCw) { $ver = $v; $rawCw = [math]::Floor($raw / 8); break }
        }
        if (-not $ver) { return $null }
        $size = 17 + 4 * $ver
        # the data bits: mode 0100, 8-bit count, the bytes, terminator, pad
        $bits = New-Object System.Collections.Generic.List[int]
        function AddBits([int]$val, [int]$n) { for ($i = $n - 1; $i -ge 0; $i--) { $bits.Add(($val -shr $i) -band 1) } }
        AddBits 4 4; AddBits $bytes.Length 8; foreach ($b in $bytes) { AddBits $b 8 }
        $cap = 8 * $dataCw
        AddBits 0 ([math]::Min(4, $cap - $bits.Count))
        AddBits 0 ((8 - $bits.Count % 8) % 8)
        $pad = 0xEC; while ($bits.Count -lt $cap) { AddBits $pad 8; $pad = $pad -bxor (0xEC -bxor 0x11) }
        $data = New-Object int[] ($bits.Count / 8)
        for ($i = 0; $i -lt $data.Length; $i++) { $x = 0; for ($j = 0; $j -lt 8; $j++) { $x = ($x -shl 1) -bor $bits[$i * 8 + $j] }; $data[$i] = $x }
        # split into blocks, add error correction, interleave
        $nb = $blocks[$ver]; $ecl = $eccLen[$ver]
        $short = $nb - $rawCw % $nb; $shortLen = [math]::Floor($rawCw / $nb)
        $bl = @(); $k = 0
        for ($i = 0; $i -lt $nb; $i++) {
            $len = $shortLen - $ecl + $(if ($i -lt $short) { 0 } else { 1 })
            $dat = $data[$k..($k + $len - 1)]; $k += $len
            $ecc = Get-QrEcc $dat $ecl
            $blk = @($dat)
            if ($i -lt $short) { $blk += 0 }   # a placeholder, skipped when interleaving
            $bl += , ($blk + @($ecc))
        }
        $all = New-Object System.Collections.Generic.List[int]
        for ($i = 0; $i -lt $bl[0].Count; $i++) {
            for ($j = 0; $j -lt $bl.Count; $j++) {
                if ($i -ne $shortLen - $ecl -or $j -ge $short) { $all.Add($bl[$j][$i]) }
            }
        }
        # the grid: function patterns first
        $m = New-Object 'bool[,]' $size, $size; $fn = New-Object 'bool[,]' $size, $size
        function SetF([int]$x, [int]$y, [bool]$dark) { $m[$y, $x] = $dark; $fn[$y, $x] = $true }
        for ($i = 0; $i -lt $size; $i++) { SetF 6 $i ($i % 2 -eq 0); SetF $i 6 ($i % 2 -eq 0) }
        foreach ($c in @(@(3, 3), @(($size - 4), 3), @(3, ($size - 4)))) {
            for ($dy = -4; $dy -le 4; $dy++) { for ($dx = -4; $dx -le 4; $dx++) {
                $xx = $c[0] + $dx; $yy = $c[1] + $dy
                if ($xx -ge 0 -and $xx -lt $size -and $yy -ge 0 -and $yy -lt $size) { $d = [math]::Max([math]::Abs($dx), [math]::Abs($dy)); SetF $xx $yy ($d -ne 2 -and $d -ne 4) }
            } }
        }
        $ap = $align[$ver]
        for ($i = 0; $i -lt $ap.Count; $i++) { for ($j = 0; $j -lt $ap.Count; $j++) {
            if (($i -eq 0 -and $j -eq 0) -or ($i -eq 0 -and $j -eq $ap.Count - 1) -or ($i -eq $ap.Count - 1 -and $j -eq 0)) { continue }
            for ($dy = -2; $dy -le 2; $dy++) { for ($dx = -2; $dx -le 2; $dx++) { SetF ($ap[$i] + $dx) ($ap[$j] + $dy) ([math]::Max([math]::Abs($dx), [math]::Abs($dy)) -ne 1) } }
        } }
        function SetFormat([int]$mask) {
            $d = (0 -shl 3) -bor $mask   # error correction M = 00
            $r = $d; for ($i = 0; $i -lt 10; $i++) { $r = ($r -shl 1) -bxor (($r -shr 9) * 0x537) }
            $b = (($d -shl 10) -bor $r) -bxor 0x5412
            $g = { param($i) ((($b -shr $i) -band 1) -eq 1) }
            for ($i = 0; $i -le 5; $i++) { SetF 8 $i (& $g $i) }
            SetF 8 7 (& $g 6); SetF 8 8 (& $g 7); SetF 7 8 (& $g 8)
            for ($i = 9; $i -lt 15; $i++) { SetF (14 - $i) 8 (& $g $i) }
            for ($i = 0; $i -lt 8; $i++) { SetF ($size - 1 - $i) 8 (& $g $i) }
            for ($i = 8; $i -lt 15; $i++) { SetF 8 ($size - 15 + $i) (& $g $i) }
            SetF 8 ($size - 8) $true
        }
        SetFormat 0
        if ($ver -ge 7) {
            $r = $ver; for ($i = 0; $i -lt 12; $i++) { $r = ($r -shl 1) -bxor (($r -shr 11) * 0x1F25) }
            $b = ($ver -shl 12) -bor $r
            for ($i = 0; $i -lt 18; $i++) { $bit = ((($b -shr $i) -band 1) -eq 1); $a = $size - 11 + $i % 3; $c = [math]::Floor($i / 3); SetF $a $c $bit; SetF $c $a $bit }
        }
        # the codewords, in the zigzag
        $i = 0; $total = $all.Count * 8
        for ($right = $size - 1; $right -ge 1; $right -= 2) {
            if ($right -eq 6) { $right = 5 }
            for ($vert = 0; $vert -lt $size; $vert++) {
                for ($j = 0; $j -lt 2; $j++) {
                    $x = $right - $j; $up = (($right + 1) -band 2) -eq 0
                    $y = if ($up) { $size - 1 - $vert } else { $vert }
                    if (-not $fn[$y, $x] -and $i -lt $total) { $m[$y, $x] = ((($all[$i -shr 3] -shr (7 - ($i -band 7))) -band 1) -eq 1); $i++ }
                }
            }
        }
        # try each mask, keep the one with the lowest penalty
        $maskTest = {
            param($mk, $x, $y)
            switch ($mk) {
                0 { ($x + $y) % 2 -eq 0 } 1 { $y % 2 -eq 0 } 2 { $x % 3 -eq 0 } 3 { ($x + $y) % 3 -eq 0 }
                4 { ([math]::Floor($x / 3) + [math]::Floor($y / 2)) % 2 -eq 0 } 5 { ($x * $y) % 2 + ($x * $y) % 3 -eq 0 }
                6 { (($x * $y) % 2 + ($x * $y) % 3) % 2 -eq 0 } 7 { ((($x + $y) % 2) + (($x * $y) % 3)) % 2 -eq 0 }
            }
        }
        function ApplyMask([int]$mk) { for ($y = 0; $y -lt $size; $y++) { for ($x = 0; $x -lt $size; $x++) { if (-not $fn[$y, $x] -and (& $maskTest $mk $x $y)) { $m[$y, $x] = -not $m[$y, $x] } } } }
        function Get-Penalty {
            $p = 0; $dark = 0
            $pat1 = '10111010000'; $pat2 = '00001011101'
            for ($a = 0; $a -lt $size; $a++) {
                $row = New-Object Text.StringBuilder; $col = New-Object Text.StringBuilder
                for ($b = 0; $b -lt $size; $b++) { [void]$row.Append($(if ($m[$a, $b]) { '1' } else { '0' })); [void]$col.Append($(if ($m[$b, $a]) { '1' } else { '0' })); if ($m[$a, $b]) { $dark++ } }
                foreach ($line in @($row.ToString(), $col.ToString())) {
                    foreach ($run in [regex]::Matches($line, '0{5,}|1{5,}')) { $p += 3 + $run.Length - 5 }
                    $padded = '0000' + $line + '0000'
                    for ($q = 0; $q -le $padded.Length - 11; $q++) { $w = $padded.Substring($q, 11); if ($w -eq $pat1 -or $w -eq $pat2) { $p += 40 } }
                }
            }
            for ($y = 0; $y -lt $size - 1; $y++) { for ($x = 0; $x -lt $size - 1; $x++) { $c = $m[$y, $x]; if ($m[$y, ($x + 1)] -eq $c -and $m[($y + 1), $x] -eq $c -and $m[($y + 1), ($x + 1)] -eq $c) { $p += 3 } } }
            $p += 10 * [math]::Floor([math]::Abs($dark * 20 - $size * $size * 10) / ($size * $size))
            $p
        }
        $best = 0; $bestP = [int]::MaxValue
        for ($mk = 0; $mk -lt 8; $mk++) {
            ApplyMask $mk; SetFormat $mk
            $pp = Get-Penalty
            if ($pp -lt $bestP) { $bestP = $pp; $best = $mk }
            ApplyMask $mk   # undo (XOR again)
        }
        ApplyMask $best; SetFormat $best
        [pscustomobject]@{ Size = $size; Version = $ver; Mask = $best; Modules = $m }
    }
    # Light modules drawn in white on black, two rows per line, with a quiet zone, so a phone camera reads it.
    function Show-QrCode($Qr) {
        $q = 4; $n = $Qr.Size + 2 * $q   # the 4-module light border the QR spec asks for
        $light = { param($x, $y) $xx = $x - $q; $yy = $y - $q; if ($xx -lt 0 -or $yy -lt 0 -or $xx -ge $Qr.Size -or $yy -ge $Qr.Size) { $true } else { -not $Qr.Modules[$yy, $xx] } }
        for ($y = 0; $y -lt $n; $y += 2) {
            $sb = New-Object Text.StringBuilder
            for ($x = 0; $x -lt $n; $x++) {
                $t = & $light $x $y; $b = if ($y + 1 -lt $n) { & $light $x ($y + 1) } else { $false }
                [void]$sb.Append($(if ($t -and $b) { [char]0x2588 } elseif ($t) { [char]0x2580 } elseif ($b) { [char]0x2584 } else { ' ' }))
            }
            Write-Host '    ' -NoNewline
            Write-Host $sb.ToString() -ForegroundColor White -BackgroundColor Black
        }
    }

    # ---- run ---------------------------------------------------------------------------------------------------------
    if ($env:PXDR_QRTEST) { return (New-QrCode $env:PXDR_QRTEST) }

    Show-PdHeader -Name 'pxd Report' -Version "v$version"
    if (-not $Json) {
        Say '  Collects a read-only report of this PC (hardware, drive, crash and reliability history, security, network, startup' 'Gray'
        Say '  items, programs and updates), encrypts it here and puts it on pxdtek.com for 48 hours behind a private' 'Gray'
        Say '  link. Only someone with the link can open it. Nothing on this PC is changed.' 'Gray'
        if (-not $isAdmin) { Say '  Not running as administrator: drive health, BitLocker, Secure Boot and TPM will be skipped.' 'DarkYellow' }
        Write-Host ''
        if (-not $Yes) {
            $go = ''
            try { $go = (Read-Host '  Make the report? (Y/n)').Trim().ToLower() } catch { $go = 'n' }
            if ($go -eq 'n' -or $go -eq 'no' -or $go -eq 'q') { return }
        }
    }
    $clock = [Diagnostics.Stopwatch]::StartNew()
    foreach ($step in @(@('This PC', ${function:Read-PC}), @('Health and reliability', { Read-ReliabilityData; Read-Health; Read-Reliability }), @('Security', ${function:Read-Security}), @('Network', ${function:Read-Network}), @('Programs and updates', ${function:Read-Software}))) {
        Write-Host ('  ' + $step[0] + '...') -ForegroundColor DarkGray
        try { & $step[1] } catch { Add-Problem 'warn' "Part of the report failed ($($step[0])): $($_.Exception.Message)" }
    }
    # problems first: the bad ones, then the rest
    $report.problems = @($problems | Where-Object { $_.level -eq 'bad' }) + @($problems | Where-Object { $_.level -ne 'bad' })
    $report.sections = @($sections | ForEach-Object { [ordered]@{ title = $_.title; rows = $_.rows.ToArray(); lines = $_.lines.ToArray(); note = $_.note; chart = $_.chart } })
    $jsonText = $report | ConvertTo-Json -Depth 8 -Compress
    Write-Host ('  Done in {0:0} seconds.' -f $clock.Elapsed.TotalSeconds) -ForegroundColor DarkGray
    Write-Host ''

    if ($Json) { [IO.File]::WriteAllText($Json, $jsonText, (New-Object Text.UTF8Encoding($false))); Say "  Wrote $Json" 'Green'; return }

    Say '  Problems found' 'White'
    if ($report.problems.Count) { foreach ($p in $report.problems) { Say "   - $($p.text)" $(if ($p.level -eq 'bad') { 'Red' } else { 'Yellow' }) } }
    else { Say '   Nothing stood out.' 'Green' }
    Write-Host ''

    Say '  Encrypting and sending to pxdtek.com...' 'DarkGray'
    $link = $null
    try {
        $sealed = New-Sealed ([Text.Encoding]::UTF8.GetBytes($jsonText))
        $res = Invoke-RestMethod -Method Post -Uri "$site/r" -Body $sealed.Body -ContentType 'application/octet-stream' -Headers @{ 'x-pxd-delete-hash' = $sealed.DeleteHash } -UserAgent 'WindowsPowerShell pxdReport' -TimeoutSec 30
        if ($res -and $res.url) { $link = "$($res.url)#$($sealed.Key)" }
        else { Say "  pxdtek.com didn't take it (a web filter may be in the way)." 'Red' }
    } catch {
        $why = $_.Exception.Message
        try { $j = $_.ErrorDetails.Message | ConvertFrom-Json; if ($j.error) { $why = $j.error } } catch { }
        Say "  Couldn't send it: $why" 'Red'
    }

    if ($link) {
        Write-Host ''
        Say '  Open this on your own PC (it works for 48 hours):' 'Gray'
        Write-Host ''
        Write-Host "    $link" -ForegroundColor Cyan
        Write-Host ''
        $qr = $null; try { $qr = New-QrCode $link } catch { }
        if ($qr) { Say '  Or scan it with your phone:' 'Gray'; Write-Host ''; Show-QrCode $qr; Write-Host '' }
        Say '  The page has Copy and Download buttons, and Delete now when you are done.' 'DarkGray'
    } else {
        $save = ''
        try { $save = (Read-Host '  Save the report as a text file on this PC instead? (y/N)').Trim().ToLower() } catch { }
        if ($save -eq 'y' -or $save -eq 'yes') {
            $dir = Join-Path $env:ProgramData 'pxd\Reports'
            try {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                $file = Join-Path $dir ("pxd-report-$env:COMPUTERNAME-" + (Get-Date -Format 'yyyy-MM-dd-HHmm') + '.txt')
                [IO.File]::WriteAllText($file, (Get-ReportText), (New-Object Text.UTF8Encoding($true)))
                Say "  Saved: $file" 'Green'
            } catch { Say "  Couldn't save it: $($_.Exception.Message)" 'Red' }
        }
    }
    Write-Host ''
    try { [void](Read-Host '  Press Enter to go back') } catch { }
}
