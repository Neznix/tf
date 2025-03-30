# Set variables
$tmpFolder = [System.Environment]::GetEnvironmentVariable('TEMP', 'Machine')
$psCorePath = "C:\Program Files\PowerShell\7\pwsh.exe"
$mainFolderPath = "C:\Script"
$logFolderPath = "C:\Script\Log"

# Configure log folders
if (-Not (Test-Path -Path $mainFolderPath)) {
    New-Item -ItemType Directory -Path $mainFolderPath -Force
}
if (-Not (Test-Path -Path $logFolderPath)) {
    New-Item -ItemType Directory -Path $logFolderPath -Force
}

# Create a log file in the folder
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFileName = "Log_$timestamp`_Base_Install.txt"
$logfile = New-Item -ItemType File -Path (Join-Path -Path $logfolderPath -ChildPath $logFileName) -Force

# Get the username of the user running the script
$username = $env:USERNAME
$logfile | Add-Content -Value "Script executed by user: $username`n"

#Install chocolatey
try {
    if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey is not installed. Installing Chocolatey..."
        $installScript = "https://chocolatey.org/install.ps1"
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($installScript))
        Write-Host "Chocolatey installation completed."
        "Chocolatey installation completed." | Out-File -FilePath $logfile -Append -Encoding UTF8
    }
    else {
        Write-Host "Chocolatey is already installed."
        "Chocolatey is already installed." | Out-File -FilePath $logfile -Append -Encoding UTF8
    }
}
catch {
    Write-host "Error installing Chocolatey: $_"
    "Error installing Chocolatey: $_" | Out-File -FilePath $logfile -Append -Encoding UTF8
}

# Define the list of programs to install
$programs = @(
    "notepadplusplus"
    "git"
    "azure-cli"
    "terraform"
    "oh-my-posh"
    "powershell-core"
    "vscode"
)

foreach ($program in $programs) {
    try {
        # Check if the program is already installed
        $installed = & choco list -e $program | Select-String -Pattern $program

        if ($installed) {
            $message = "$program is already installed."
            Write-Host $message
            $message | Out-File -FilePath $logfile -Append -Encoding UTF8
        }
        else {
            # Install the program using chocolatey
            $message = "Installing $program..."
            Write-Host $message
            $message | Out-File -FilePath $logfile -Append -Encoding UTF8

            & choco install $program -y | Out-File -FilePath $logfile -Append -Encoding UTF8

            $message = "$program installation completed."
            Write-Host $message
            $message | Out-File -FilePath $logfile -Append -Encoding UTF8
        }
    }
    catch {
        $errorMessage = "Error processing $program`: $_"
        Write-Host $errorMessage
        $errorMessage | Out-File -FilePath $logfile -Append -Encoding UTF8
    }
}

# Download and install CascadiaCode Nerd Font
try {
    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/CascadiaCode.zip"
    $fontZipPath = "$tmpFolder\CascadiaCode.zip"
    $fontExtractPath = "$tmpFolder\CascadiaCode"

    Invoke-WebRequest -Uri $fontUrl -OutFile $fontZipPath
    Expand-Archive -Path $fontZipPath -DestinationPath $fontExtractPath

    $fontFiles = Get-ChildItem -Path $fontExtractPath -Filter *.ttf
    $fontsFolder = "$env:SystemRoot\Fonts"

    foreach ($fontFile in $fontFiles) {
        Copy-Item -Path $fontFile.FullName -Destination $fontsFolder
        New-ItemProperty -Name $FontFile.BaseName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.name
    }

    $message = "CascadiaCode Nerd Font installation completed successfully."
    Write-Host $message
    $message | Out-File -FilePath $logfile -Append -Encoding UTF8
}
catch {
    $errorMessage = "Error installing CascadiaCode Nerd Font: $_"
    Write-Host $errorMessage
    $errorMessage | Out-File -FilePath $logfile -Append -Encoding UTF8
}

#Install NuGet provider for PowerShell modules
try {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-File -FilePath $logfile -Append -Encoding UTF8
    $message = "NuGet provider installation completed."
    Write-Host $message
    $message | Out-File -FilePath $logfile -Append -Encoding UTF8
}
catch {
    $errorMessage = "Error installing NuGet provider: $_"
    Write-Host $errorMessage
    $errorMessage | Out-File -FilePath $logfile -Append -Encoding UTF8
}

#refreshenv
refreshenv

# List of PowerShell modules to install
$modules = @(
    "Terminal-Icons"
    "ExchangeOnlineManagement"
    "Microsoft.Graph"
)

# Install PowerShell modules
foreach ($module in $modules) {
    try {
        # Check if the module is already installed
        $installedModule = & $psCorePath -Command "get-module -ListAvailable -Name '$module'" | Select-String -Pattern $module
        if ($installedModule) {
            $message = "$module is already installed."
            Write-Host $message
            $message | Out-File -FilePath $logfile -Append -Encoding UTF8
        }
        else {
            # Install the module using PowerShell
            $message = "Installing $module..."
            Write-Host $message
            $message | Out-File -FilePath $logfile -Append -Encoding UTF8

            & $psCorePath -Command "Install-Module -Name '$module' -Repository PSGallery -Scope AllUsers -Force" | Out-File -FilePath $logfile -Append -Encoding UTF8

            $message = "$module installation completed."
            Write-Host $message
            $message | Out-File -FilePath $logfile -Append -Encoding UTF8
        }
    }
    catch {
        $errorMessage = "Error processing $module`: $_"
        Write-Host $errorMessage
        $errorMessage | Out-File -FilePath $logfile -Append -Encoding UTF8
    }
}

# Set the registry key to show file extensions in Windows Explorer
try {
    reg load HKLM\DefaultUser C:\Users\Default\NTUSER.DAT
    $regpath = "HKLM:\Defaultuser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    New-ItemProperty -Path $regpath -Name HideFileExt -Value "0" -PropertyType DWord
    reg unload HKLM\DefaultUser

    Write-Host $message
    $message | Out-File -FilePath $logfile -Append -Encoding UTF8
}
catch {
    $errorMessage = "Register was not set: $_"
    Write-Host $errorMessage
    $errorMessage | Out-File -FilePath $logfile -Append -Encoding UTF8
}
