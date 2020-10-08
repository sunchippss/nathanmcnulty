[CmdletBinding()]
param (
    $name,
    $prefix = "Nessus",
    $nessusOU = "OU=Nessus,OU=Service Accounts,DC=domain,DC=com"
)

begin {
    # Ensure valid name is provided, graceful catch when forgotten
    while ([string]::IsNullOrWhiteSpace($name)) { 
        Read-Host -Prompt "Enter name of service for scanning account and group (Ex. Networking)"
    }
    
    # Ensure OU exists and offer to create it if it doesn't exist
    if (!(Get-ADObject -Filter {distinguishedName -eq $nessusOU})) { 
        $createOU = Read-Host -Prompt "$nessusOU does not exist. Do you wan to create it? (y/n)"
        if ($createOU -eq "y") { 
            $OUName = $nessusOU.Split(",")[0]
            New-ADOrganizationalUnit -Name $OUName.Replace("OU=","") -Path $nessusOU.Replace("$OUName,","")
        } else { Write-Output "Exiting due to no valid OU for objects to be created"; exit }
    }
}

process {
    # Request password and create service account
    $pass = Read-Host "Enter scan account password" -AsSecureString
    if (!(Get-ADUser -Filter {name -eq "$prefix-$name"})) { 
        New-ADUser -Name "$prefix-$name" -Path $nessusOU -AccountPassword $pass -AccountNotDelegated $true -Enabled $true -KerberosEncryptionType AES128,AES256 
    } else { Write-Output "$prefix-$name already exists"}
    
    # Create security group
    if (!(Get-ADGroup -Filter {name -eq "$prefix - $name"})) { 
        New-ADGroup -Name "$prefix - $name" -Path $nessusOU -GroupCategory Security -GroupScope Global 
    } else { Write-Output "$prefix - $name already exists"}
}

end {
    # API call here to push this into a credential vault for automatic password rotation
    # No automation for GPO or scheduled tasks yet
}
