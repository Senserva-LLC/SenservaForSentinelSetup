#Senserva Intune Installation / Configuration Script
#Copyright: Senserva LLC
#Author: Senserva
#Requires -RunAsAdministrator
#Requires -Modules Az.Storage,Az.Accounts,Az.Resources

$config_SenservaPrimarySPName = "SenservaIntune"
$requiredResourceAccess = @(
	@{
		ResourceAppId = "00000003-0000-0000-c000-000000000000";
  		ResourceAccess = @(
			@{
				# offline_access
				Id = "7427e0e9-2fba-42fe-b0c0-848c9e6a8182";
				Type = "Scope"
      		},
      		@{
				# openid
				Id = "37f7f235-527c-4136-accd-4a02d197296e";
				Type = "Scope"
	      	},
      		@{
				# profile
				Id = "14dad69e-099b-42c9-810b-d002981feec1";
				Type = "Scope"
	      	},
      		@{
				# User.Read.All
				Id = "df021288-bdef-4463-88db-98f22de89214";
				Type = "Role"
	      	},
      		@{
				# DeviceManagementManagedDevices.Read.All
				Id = "2f51be20-0bb4-4fed-bf7b-db946066c75e";
				Type = "Role"
	      	},
      		@{
				# DeviceManagementConfiguration.Read.All
				Id = "dc377aa6-52d8-4e23-b271-2a7ae04cedf3";
				Type = "Role"
	      	},
      		@{
				# DeviceManagementServiceConfig.Read.All
				Id = "06a5fe6d-c49d-46a7-b082-56b1b14103c7";
				Type = "Role"
	      	},
            @{
				# Organization.Read.All
				Id = "498476ce-e0fe-48b0-b801-37ba7e2685c6";
				Type = "Role"
	      	}
  		)
	}
)

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
            $PrimarySP = New-AzADApplication -DisplayName $config_SenservaPrimarySPName -AvailableToOtherTenants:$False -Confirm:$False -ReplyUrls "https://admin.microsoft.com" -IdentifierUris "https://$($userUPN.Split("@")[1])" -RequiredResourceAccess $requiredResourceAccess -WarningAction SilentlyContinue -ErrorAction Stop -InformationAction SilentlyContinue
		$secPwd = Get-AzADApplication -ApplicationId $PrimarySP.AppId | New-AzADAppCredential
		Write-Host "Created app registration for the Parent Tenant" -ForegroundColor Green
            Write-Host "Please save the following information in Keyvault:" -ForegroundColor Green
            Write-Host "Primary tenant client id: $($PrimarySP.AppId)" -ForegroundColor Green
            Write-Host "Primary tenant client password: $($secPwd.SecretText)" -ForegroundColor Green
            $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
            $graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com").AccessToken
            Write-Host "Please wait 60 seconds for replication..."
            Start-Sleep -s 60
            $primarySPN = New-AzADServicePrincipal -ApplicationId $PrimarySP.AppId
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
Start-Process "https://login.microsoftonline.com/$tenantId/adminconsent?client_id=$($PrimarySP.AppId)" -Wait

Write-Host "App deployment process has completed" -ForegroundColor Green
Exit