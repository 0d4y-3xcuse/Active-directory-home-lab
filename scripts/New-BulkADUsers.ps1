# --- Import & Validate CSV ---
if (-not (Test-Path $CSVPath)) {
    Write-Host "[ERROR] CSV file not found at: $CSVPath" -ForegroundColor Red
    exit 1
}

$users = Import-Csv -Path $CSVPath
Write-Host "[INFO] Found $($users.Count) users to provision." -ForegroundColor Cyan

# --- Loop Through Each User ---
foreach ($user in $users) {

    $fullName    = "$($user.FirstName) $($user.LastName)"
    $username    = ($user.FirstName[0] + $user.LastName).ToLower()  # e.g. jsmith
    $ouPath      = "OU=$($user.OU),OU=_Users,DC=corp,DC=jallow,DC=local"
    $securePass  = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force

    # Check if user already exists
    if (Get-ADUser -Filter {SamAccountName -eq $username} -ErrorAction SilentlyContinue) {
        Write-Host "[SKIP] $username already exists. Skipping." -ForegroundColor Yellow
        continue
    }

    try {
        New-ADUser `
            -SamAccountName       $username `
            -UserPrincipalName    "$username@corp.jallow.local" `
            -Name                 $fullName `
            -GivenName            $user.FirstName `
            -Surname              $user.LastName `
            -DisplayName          $fullName `
            -Title                $user.JobTitle `
            -Department           $user.Department `
            -Path                 $ouPath `
            -AccountPassword      $securePass `
            -ChangePasswordAtLogon $true `
            -Enabled              $true

        Write-Host "[SUCCESS] Created user: $username ($fullName)" -ForegroundColor Green

    } catch {
        Write-Host "[ERROR] Failed to create $username - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n[DONE] User provisioning complete." -ForegroundColor Cyan
