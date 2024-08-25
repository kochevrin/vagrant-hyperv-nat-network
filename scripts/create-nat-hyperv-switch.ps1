# Get the current directory
$currentDir = Get-Location

# Specify the path to the .env file one level up
$envFile = Join-Path $currentDir.Path "\.env"

# Check if the file exists
if (Test-Path $envFile) {
    # Read the content of the .env file and load environment variables
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+?)\s*=\s*(.+)\s*$") {
            $name = $matches[1]
            $value = $matches[2]
            [System.Environment]::SetEnvironmentVariable($name, $value)
        }
    }

} else {
    Write-Host "The .env file was not found at: $envFile"
}

# Check if the virtual switch exists
If ($env:HPV_SWITCH -in (Get-VMSwitch | Select-Object -ExpandProperty Name) -eq $FALSE) {
    Write-Host "Creating Internal-only switch named '$env:HPV_SWITCH' on Windows Hyper-V host..."

    # Create an internal virtual switch
    New-VMSwitch -SwitchName $env:HPV_SWITCH -SwitchType Internal

    # Assign an IP address
    New-NetIPAddress -IPAddress $env:IP_ADDRESS -PrefixLength $env:PREFIX_LENGTH -InterfaceAlias "vEthernet ($env:HPV_SWITCH)"

    # Create a NAT adapter
    New-NetNAT -Name $env:NAT_NAME -InternalIPInterfaceAddressPrefix $env:NAT_NETWORK
}
else {
    Write-Host "$env:HPV_SWITCH for static IP configuration already exists; skipping"
}

# Check if the IP address exists
If ($env:IP_ADDRESS -in (Get-NetIPAddress | Select-Object -ExpandProperty IPAddress) -eq $FALSE) {
    Write-Host "Registering new IP address $env:IP_ADDRESS on Windows Hyper-V host..."

    # Assign an IP address
    New-NetIPAddress -IPAddress $env:IP_ADDRESS -PrefixLength $env:PREFIX_LENGTH -InterfaceAlias "vEthernet ($env:HPV_SWITCH)"
}
else {
    Write-Host "$env:IP_ADDRESS for static IP configuration already registered; skipping"
}

# Check if the NAT adapter exists
If ($env:NAT_NETWORK -in (Get-NetNAT | Select-Object -ExpandProperty InternalIPInterfaceAddressPrefix) -eq $FALSE) {
    Write-Host "Registering new NAT adapter for $env:NAT_NETWORK on Windows Hyper-V host..."

    # Create a new NAT adapter
    New-NetNAT -Name $env:NAT_NAME -InternalIPInterfaceAddressPrefix $env:NAT_NETWORK
}
else {
    Write-Host "$env:NAT_NETWORK for static IP configuration already registered; skipping"
}
