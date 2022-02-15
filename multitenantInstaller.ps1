#Senserva Multi-Tenant installation / configuration script
#Copyright: Senserva LLC
#Author: Senserva
#Requires -RunAsAdministrator
#Requires -Modules Az.Storage,Az.Accounts,Az.Resources

$config_SenservaPrimarySPName = "SenservaMultiTenant"
$requiredResourceAccess = "{`"requiredResourceAccess`":[{`"resourceAppId`":`"00000003-0000-0000-c000-000000000000`",`"resourceAccess`":[{`"id`":`"7427e0e9-2fba-42fe-b0c0-848c9e6a8182`",`"type`":`"Scope`"},{`"id`":`"0e263e50-5827-48a4-b97c-d940288653c7`",`"type`":`"Scope`"},{`"id`":`"37f7f235-527c-4136-accd-4a02d197296e`",`"type`":`"Scope`"},{`"id`":`"14dad69e-099b-42c9-810b-d002981feec1`",`"type`":`"Scope`"},{`"id`":`"246dd0d5-5bd0-4def-940b-0421030a5b68`",`"type`":`"Role`"},{`"id`":`"bf394140-e372-4bf9-a898-299cfc7564e5`",`"type`":`"Role`"},{`"id`":`"6e472fd1-ad78-48da-a0f0-97ab2c6b769e`",`"type`":`"Role`"},{`"id`":`"dc5007c0-2d7d-4c42-879c-2dab87571379`",`"type`":`"Role`"},{`"id`":`"df021288-bdef-4463-88db-98f22de89214`",`"type`":`"Role`"},{`"id`":`"b0afded3-3588-46d8-8b3d-9842eff778da`",`"type`":`"Role`"},{`"id`":`"230c1aed-a721-4c5d-9cb4-a90514e508ef`",`"type`":`"Role`"},{`"id`":`"40f97065-369a-49f4-947c-6a255697ae91`",`"type`":`"Role`"},{`"id`":`"7ab1d382-f21e-4acd-a863-ba3e13f7da61`",`"type`":`"Role`"},{`"id`":`"4cdc2547-9148-4295-8d11-be0db1391d6b`",`"type`":`"Role`"},{`"id`":`"5df6fe86-1be0-44eb-b916-7bd443a71236`",`"type`":`"Role`"},{`"id`":`"38d9df27-64da-44fd-b7c5-a6fbac20248f`",`"type`":`"Role`"},{`"id`":`"2f51be20-0bb4-4fed-bf7b-db946066c75e`",`"type`":`"Role`"},{`"id`":`"dc377aa6-52d8-4e23-b271-2a7ae04cedf3`",`"type`":`"Role`"},{`"id`":`"06a5fe6d-c49d-46a7-b082-56b1b14103c7`",`"type`":`"Role`"},{`"id`":`"c7fbd983-d9aa-4fa7-84b8-17382c103bc4`",`"type`":`"Role`"}]},{`"resourceAppId`":`"05a65629-4c1b-48c1-a78b-804c4abdd4af`",`"resourceAccess`":[{`"id`":`"e9aa7b67-ea0d-435b-ab36-592cd9b23d61`",`"type`":`"Role`"},{`"id`":`"83bc8d83-2679-44ef-b813-d5f556fc4474`",`"type`":`"Role`"},{`"id`":`"8e41f311-31d5-43aa-bb79-8fd4e14a8745`",`"type`":`"Role`"}]},{`"resourceAppId`":`"c5393580-f805-4401-95e8-94b7a6ef2fc2`",`"resourceAccess`":[{`"id`":`"4807a72c-ad38-4250-94c9-4eabfe26cd55`",`"type`":`"Role`"},{`"id`":`"594c1fb6-4f81-4475-ae41-0c394909246c`",`"type`":`"Role`"},{`"id`":`"e2cea78f-e743-4d8f-a16a-75b629a038ae`",`"type`":`"Role`"}]},{`"resourceAppId`":`"8ee8fdad-f234-4243-8f3b-15c294843740`",`"resourceAccess`":[{`"id`":`"a7deff90-e2f5-4e4e-83a3-2c74e7002e28`",`"type`":`"Role`"},{`"id`":`"a9790345-4595-42e4-971a-ccdc79f19b7c`",`"type`":`"Role`"},{`"id`":`"7734e8e5-8dde-42fc-b5ae-6eafea078693`",`"type`":`"Role`"},{`"id`":`"8d90f441-09cf-4fdc-ab45-e874fa3a28e8`",`"type`":`"Role`"}]}]}" | ConvertFrom-Json

Write-Host "Welcome to Senserva!" -ForegroundColor Green
Write-Host "This script will guide you as CSP to set up your main and child tenants" -ForegroundColor Green


Write-Host "We'll now check if you have already installed Senserva in the Parent Tenant. Please log in to a global admin or Application administrator account in the Parent Tenant" -ForegroundColor Green
$userUPN = Read-Host "Username / UPN"
if(!$userUPN){Throw "You must supply a username of an admin in the parent tenant"}

$tenantId = (Invoke-RestMethod "https://login.windows.net/$($userUPN.Split("@")[1])/.well-known/openid-configuration" -Method GET).userinfo_endpoint.Split("/")[3]

try{
    $connection = Login-AzAccount -Force -Confirm:$False -SkipContextPopulation -Tenant $tenantId -ErrorAction Stop
    $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
}catch{
    Write-Host "Failed to log in and/or retrieve token, aborting" -ForegroundColor Red
    Write-Host $_
    Exit
}

Write-Host "Logged in, detecting if Senserva is already installed..." -ForegroundColor Green

$PrimarySP = Get-AzADApplication -displayname $config_SenservaPrimarySPName

if(!$PrimarySP){
    $response = Read-Host "Primary tenant not yet set up, do you wish to set up Senserva for this tenant? (Y/N)"
    if($response -ne "Y" -and $response -ne "Yes"){
        Throw "Cannot continue without a primary tenant"
    }else{
        try{
            $pwd = ""
            $rand = New-Object System.Random
            1..96 | ForEach { $pwd = $pwd + [char]$rand.next(33,127) }
            $secPwd = ConvertTo-SecureString -String $pwd -AsPlainText -Force
            $PrimarySP = New-AzADApplication -DisplayName $config_SenservaPrimarySPName -AvailableToOtherTenants:$True -Password $secPwd -Confirm:$False -ReplyUrls "https://admin.microsoft.com" -IdentifierUris "https://$($userUPN.Split("@")[1])" -WarningAction SilentlyContinue -ErrorAction Stop -InformationAction SilentlyContinue
            Write-Host "Created app registration for the Parent Tenant" -ForegroundColor Green
            Write-Host "Please save the following information in Keyvault:" -ForegroundColor Green
            Write-Host "Primary tenant client id: $($PrimarySP.ApplicationId.Guid)" -ForegroundColor Green
            Write-Host "Primary tenant client password: $pwd" -ForegroundColor Green
            $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
            $graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com").AccessToken
            Write-Host "Please wait 60 seconds for replication..."
            Start-Sleep -s 60
            $patchBody = $requiredResourceAccess
            $patchBody | Add-Member -MemberType NoteProperty -Name id -Value $($PrimarySP.ObjectId)
            $res = Invoke-RestMethod -Method PATCH -body ($patchBody | convertto-json -Depth 16) -Uri "https://graph.microsoft.com/v1.0/myorganization/applications/$($PrimarySP.ObjectId)" -Headers @{"Authorization"="Bearer $graphToken"} -ContentType "application/json"
            Write-Host "Please wait 60 seconds for additional replication..."
            Start-Sleep -s 60
            $primarySPN = New-AzADServicePrincipal -ApplicationId $PrimarySP.ApplicationId.Guid -SkipAssignment
        }catch{
            Write-Host $_ -ForegroundColor Red
            Throw "Failed to set up primary tenant!"
        }
    }
}

Write-Host "Senserva app registration detected, verifying config..." -ForegroundColor Green
Write-Host "Please wait 60 seconds for additional replication..."
Start-Sleep -s 60
Try{
    $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
    $graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com").AccessToken
    foreach($resource in $requiredResourceAccess.requiredResourceAccess){
        try{
            $resourceLocalInstance = Get-AzAdServicePrincipal -ApplicationId $resource.resourceAppId
            $patchBody = @{
                "clientId"= $primarySPN.Id
                "consentType"= "AllPrincipals"
                "principalId"= $Null
                "resourceId"= $resourceLocalInstance.Id
                "scope"= "$($resource.resourceAccess.id -Join " ")"
                "startTime"= (Get-Date).ToString("yyy-MM-ddTHH:MM:ss")
                "expiryTime"= (Get-Date).AddYears(5).ToString("yyy-MM-ddTHH:MM:ss")
            }
            try{
                $res = Invoke-RestMethod -Method POST -body ($patchBody | convertto-json) -Uri "https://graph.microsoft.com/beta/oauth2PermissionGrants" -Headers @{"Authorization"="Bearer $graphToken"} -ContentType "application/json"
                Write-Host "Permission for instance $($resourceLocalInstance.Id) set" -ForegroundColor Green
            }catch{
                Write-Host "Failed to set permission for instance $($resourceLocalInstance.Id)" -ForegroundColor Red
            }
        }catch{
            Write-Host "Failed to retrieve local instance of $($resource.resourceAppId)" -ForegroundColor Red
        }
    }

    Write-Host "Parent tenant is correctly set up!" -ForegroundColor Green
}catch{
    Write-Host "Failed to verify parent tenant, cannot continue" -ForegroundColor Red
    Throw $_
}

$response = Read-Host "A browser will now open and ask you to consent, press the Enter key to open your browser and come back here when you have consented."
Start-Process "https://login.microsoftonline.com/$tenantId/adminconsent?client_id=$($PrimarySP.ApplicationId)" -Wait

$response = Read-Host "Do you wish to install any Child Tenants? Y/N"
if($response -ne "Y" -and $response -ne "Yes"){
    Write-Host "App deployment process has completed" -ForegroundColor Green
    Exit
}

Write-Host "Checking registered CSP child tenants..." -ForegroundColor Green
Try{
    $graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken
    $childTenants = invoke-restmethod -Method GET -Uri "https://graph.windows.net/$($context.Tenant.Id)/contracts?api-version=1.6" -Headers @{"Authorization"="Bearer $graphToken"} -ContentType "application/json"
    if(!$childTenants.value -or $childTenants.value.count -le 0){
        Throw "No child tenants detected"
    }
}catch{
    Write-Host "Failed to retrieve child tenants, cannot continue" -ForegroundColor Red
    Write-Host $_
    Exit
}
$childTenants = $childTenants.value

$response = Read-Host "Detected $($childTenants.Count) customers under your CSP tenant, do you wish to continue? Y/N"
if($response -ne "Y" -and $response -ne "Yes"){
    Write-Host "App deployment process has completed" -ForegroundColor Green
    Exit
}

foreach($tenant in $childTenants){
    $response = Read-Host "Installing in tenant $($tenant.displayName), press Y to proceed, N to skip"
    if($response -ne "Y" -and $response -ne "Yes"){
        Write-Host "$($tenant.displayName) skipped" -ForegroundColor Yellow
        continue
    }
    Write-Host "Please login using $userUPN" -ForegroundColor Green
    $connection = Login-AzAccount -Confirm:$False -SkipContextPopulation -Tenant $tenant.customerContextId -ErrorAction Stop
    $secondarySP = Get-AzADServicePrincipal -DisplayName $config_SenservaPrimarySPName -DefaultProfile $connection
    if(!$secondarySP){
        Write-Host "No child service principal found in $($tenant.customerContextId), creating..." -ForegroundColor Green
        try{
            $secondarySP = New-AzADServicePrincipal -ApplicationId $PrimarySP.ApplicationId.Guid -DisplayName $config_SenservaPrimarySPName -SkipAssignment -DefaultProfile $connection
            Write-Host "SPN created successfully" -ForegroundColor Green
            Write-Host "Please save the following information in Keyvault:" -ForegroundColor Green
            Write-Host "Secondary tenant id: $($tenant.customerContextId)" -ForegroundColor Green
        }catch{
            Write-Host "Failed to create SPN!" -ForegroundColor Red
            Write-Host $_
            continue
        }
    }
              

    $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
    $graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com").AccessToken
    Write-Host "Please wait 10 seconds for replication..."
    Start-Sleep -s 10
    Write-Host "Senserva child SPN detected in $($tenant.displayName), configuring permissions" -ForegroundColor Green
    $permissions = Invoke-RestMethod -Method GET -Uri "https://graph.microsoft.com/beta/oauth2PermissionGrants?`$filter=clientId eq '$($secondarySP.id)'" -Headers @{"Authorization"="Bearer $graphToken"} -ContentType "application/json"
    if($permissions.value){
        foreach($permission in $permissions.value){
            $res = Invoke-RestMethod -Method DELETE -Uri "https://graph.microsoft.com/beta/oauth2PermissionGrants/$($permission.id)" -Headers @{"Authorization"="Bearer $graphToken"} -ContentType "application/json"          
        }
    }

    foreach($resource in $requiredResourceAccess.requiredResourceAccess){
        try{
            $resourceLocalInstance = Get-AzAdServicePrincipal -ApplicationId $resource.resourceAppId
            $patchBody = @{
                "clientId"= $secondarySP.id
                "consentType"= "AllPrincipals"
                "principalId"= $Null
                "resourceId"= $resourceLocalInstance.Id
                "scope"= "$($resource.resourceAccess.id -Join " ")"
                "startTime"= (Get-Date).ToString("yyy-MM-ddTHH:MM:ss")
                "expiryTime"= (Get-Date).AddYears(5).ToString("yyy-MM-ddTHH:MM:ss")
            }
            try{
                $res = Invoke-RestMethod -Method POST -body ($patchBody | convertto-json) -Uri "https://graph.microsoft.com/beta/oauth2PermissionGrants" -Headers @{"Authorization"="Bearer $graphToken"} -ContentType "application/json"
                Write-Host "Permission $($api.id) for instance $($resourceLocalInstance.Id) set" -ForegroundColor Green
            }catch{
                Write-Host "Failed to set permission $($api.id) for instance $($resourceLocalInstance.Id)" -ForegroundColor Red
            }
        }catch{
            Write-Host "Failed to retrieve local instance of $($resource.resourceAppId)" -ForegroundColor Red
        }
    }
    Write-Host "$($tenant.displayName) completed" -ForegroundColor Green
}

Write-Host "App deployment process has completed"