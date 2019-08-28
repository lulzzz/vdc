[CmdletBinding()] 
param(
    [Parameter(Mandatory=$true)]
    [string]$KeyVaultName,
    [Parameter(Mandatory=$true)]
    [string]$KeyName,
    [Parameter(Mandatory=$true)]
    [string]$BashScriptPath
)

Import-Module -Name Az


$keyExists = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyName

if($null -eq $keyExists) {

    if($Env:OS -like "*windows*" -or $IsWindows -eq $true) {
        Write-Host "Generating Root Cert for Windows";
        # Run the script in PowerShell 5 or less. If you're running in PowerShell Core,
        # New-SelfSignedCertificate is not available. So, make sure your windows machine
        # has both PowerShell Core and PowerShell.
        $rootCertPublicKey = Powershell -Command {
            New-Item -Path "C:\" -Name "certs" -ItemType "directory" | Out-Null;
            $certFilePath = "C:\certs\rootCert.cer";
            $certPath = "Cert:\CurrentUser\My";
            $rootCert = Get-ChildItem -Path $certPath | Where-Object { $_.Subject -eq "CN=VPN CA" };
            if($null -eq $rootCert) {
                $rootCert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
                        -Subject "CN=VPN CA" -KeyExportPolicy Exportable `
                        -HashAlgorithm sha256 -KeyLength 2048 `
                        -CertStoreLocation $certPath -KeyUsageProperty Sign -KeyUsage CertSign;
            }
            Export-Certificate -Cert $rootCert.PSPath -FilePath $certFilePath | Out-Null;
            $rootCertPublicKey = $rootCert.GetRawCertData();
            $rootCertPublicKey = [Convert]::ToBase64String($rootCertPublicKey);
            if(Test-Path $certFilePath) {
                Remove-Item -Path $certFilePath;
                Remove-Item -Path "C:\certs";
            }
            return $rootCertPublicKey;
        }
    }
    else {
        Write-Host "Generating Root Cert for Linux";
        Get-Location | Write-Host;
        bash -c "chmod 755 $BashScriptPath"
        $rootCertPublicKey = (bash -c "$BashScriptPath $KeyVaultName $KeyName")[0];
    }
    $secureString = ConvertTo-SecureString -String $rootCertPublicKey -AsPlainText -Force;
    Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyName -SecretValue $secureString;
}
