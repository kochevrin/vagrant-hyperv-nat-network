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
    exit
}

# Remove the NAT adapter if it exists
if ($env:NAT_NAME -in (Get-NetNAT | Select-Object -ExpandProperty Name)) {
    Write-Host "Removing NAT adapter '$env:NAT_NAME'..."
    Remove-NetNAT -Name $env:NAT_NAME -Confirm:$false
} else {
    Write-Host "NAT adapter '$env:NAT_NAME' not found; skipping"
}

# Remove the IP address if it exists
if ($env:IP_ADDRESS -in (Get-NetIPAddress | Select-Object -ExpandProperty IPAddress)) {
    Write-Host "Removing IP address $env:IP_ADDRESS..."
    Remove-NetIPAddress -IPAddress $env:IP_ADDRESS -InterfaceAlias "vEthernet ($env:HPV_SWITCH)" -Confirm:$false
} else {
    Write-Host "IP address $env:IP_ADDRESS not found; skipping"
}

# Remove the virtual switch if it exists
if ($env:HPV_SWITCH -in (Get-VMSwitch | Select-Object -ExpandProperty Name)) {
    Write-Host "Removing virtual switch '$env:HPV_SWITCH'..."
    Remove-VMSwitch -Name $env:HPV_SWITCH -Force -Confirm:$false
} else {
    Write-Host "Virtual switch '$env:HPV_SWITCH' not found; skipping"
}
