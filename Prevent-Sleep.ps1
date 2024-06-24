# https://gist.github.com/CMCDragonkai/bf8e8b7553c48e4f65124bc6f41769eb
# powercfg -requests

#!/usr/bin/env powershell

# This script can keep the computer awake
# There are 3 different ways of staying awake:
#     Away Mode - Enable away mode (https://blogs.msdn.microsoft.com/david_fleischman/2005/10/21/what-does-away-mode-do-anyway/)
#     Display Mode - Keep the display on and don't go to sleep or hibernation
#     System Mode - Don't go to sleep or hibernation
# The default mode is the System Mode.
# Away mode is only available when away mode is enabled in the advanced power options.
# These commands are advisory, the option to allow programs to request to disable 
# sleep or display off is in advanced power options.
# The above options will need to be first enabled in the registry before you can 
# see them in the advanced power options.
# An alternative to this script is using presentation mode, but this is more flexible.

param (
    [ValidateSet('Away', 'Display', 'System')]$Option = 'System'
)

Register-EngineEvent PowerShell.Exiting -Action { stopStayingAwake }

$Code=@'
[DllImport("kernel32.dll", CharSet = CharSet.Auto,SetLastError = true)]
public static extern void SetThreadExecutionState(uint esFlags);
'@

$ste = Add-Type -memberDefinition $Code -name System -namespace Win32 -passThru

# Requests that the other EXECUTION_STATE flags set remain in effect until
# SetThreadExecutionState is called again with the ES_CONTINUOUS flag set and
# one of the other EXECUTION_STATE flags cleared.
# The thread that turns it on must be the same thread that turns it off !.
$ES_CONTINUOUS = [uint32]"0x80000000"
$ES_AWAYMODE_REQUIRED = [uint32]"0x00000040"
$ES_DISPLAY_REQUIRED = [uint32]"0x00000002"
$ES_SYSTEM_REQUIRED = [uint32]"0x00000001"

Switch ($Option) {
    "Away"    {$Setting = $ES_AWAYMODE_REQUIRED}
    "Display" {$Setting = $ES_DISPLAY_REQUIRED}
    "System"  {$Setting = $ES_SYSTEM_REQUIRED}
}

# https://stackoverflow.com/a/70497925
# Even when the event does fire, -Action { FunctionName } will only work if the function is defined in the global scope 
# (or inside the -Action script block itself, before invocation), because the script block runs in a dynamic module.
# The script block executes at a time when all PowerShell modules except Microsoft.PowerShell.Utility have already 
# been unloaded, which severely limits what operations you can perform.
function Global:stopStayingAwake {
    Write-Verbose "Stopping Staying Awake" -Verbose
    $ste::SetThreadExecutionState($ES_CONTINUOUS)
}

try {
    while ($true) {
        Write-Verbose "Staying Awake with ``${Option}`` Option" -Verbose
        Write-Verbose "Press CTRL + C to stop staying awake." -Verbose
        Write-Verbose "DON'T CLICK THE X BUTTON as we are not dealing with it at the moment." -Verbose
        Write-Verbose "For more information, see here https://github.com/PowerShell/PowerShell/issues/8000" -Verbose
        $ste::SetThreadExecutionState($ES_CONTINUOUS -bor $Setting)
        Start-Sleep -Seconds 60
        Clear-Host
    }
} finally {
    Write-Verbose "Stopping Staying Awake" -Verbose
    stopStayingAwake
}
