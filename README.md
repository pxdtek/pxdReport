# pxd Report

Everything about a PC on one private link. Made for remote support: in a session such as ScreenConnect Backstage the clipboard doesn't come back to you, so the report goes to a short link you open on your own PC instead, with **Copy** and **Download** buttons.

It runs from the pxd Toolkit console:

```powershell
irm pxdtek.com/tk | iex
```

then **R** (*Report on this PC*). It takes about 15 seconds, changes nothing on the PC and saves nothing there.

## What's in it

- **Problems found**, first: the things worth a look, worst first.
- **This PC:** name, who's signed in, make and model (the motherboard on home-built PCs), serial number, BIOS, Windows version and build, when it was installed and last restarted, CPU, memory, graphics and driver, every drive's free space.
- **Health:** each drive's own health (plus temperature, wear, hours and read errors as administrator), blue screens with their stop codes, crash dumps, unexpected shutdowns, hardware (WHEA) errors, disk errors, programs that crashed this week, devices with a problem (Device Manager's yellow marks).
- **Reliability:** Reliability Monitor's own data: the 1-10 stability score now and its lowest this month (with a chart of each day on the page), and the failures behind it: programs that stopped working or responding, unexpected shutdowns, blue screens and LiveKernelEvents, plus programs installed and removed. No administrator needed; Windows Server collects it only when it's turned on.
- **Security:** Defender or the antivirus in charge, signature age, threats found, firewall, BitLocker, Secure Boot, TPM, UAC, who's an administrator, Remote Desktop, SMBv1, Windows activation, whether a restart is waiting.
- **Network:** each connected adapter (address, gateway, DNS, DHCP, speed, MAC), Wi-Fi signal and channel, router and internet response, DNS, the public address, a proxy, the hosts file.
- **Starts with Windows**, **Programs** (with what was installed this week) and **Windows Update** (last install, failures and why, recent updates).

Run as SYSTEM (Backstage, a remote shell), it finds the signed-in user and reads their own startup items, programs and proxy settings too. Some checks need administrator; without it they're marked as skipped.

## The link

```
https://pxdtek.com/r/K7QX-29PM#<key>
```

- The report is **encrypted on the PC** before it's sent: AES-256 with an HMAC-SHA256 seal, from a random 128-bit key that only the link holds. The key is the part after `#`, which browsers never send to a server, so pxdtek.com stores bytes it can't read.
- It lasts **48 hours**, then it's deleted. **Delete now** on the page removes it straight away (only the link can do that).
- The console also draws the link as a **QR code**, to open it on a phone.
- If pxdtek.com can't be reached, it offers to save the report as a text file on the PC instead.

## Testing

```powershell
# the report as JSON, nothing uploaded
& ([scriptblock]::Create((Get-Content .\pxdReport.ps1 -Raw))) -Json report.json
# against a local copy of pxdtek.com
$env:PXDR_SITE = 'http://localhost:8080'
```

Windows PowerShell 5.1 and PowerShell 7. The script is ASCII only, so `irm | iex` never trips on encoding.
