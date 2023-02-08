#Senserva Full Installation / Configuration Script
#Copyright: Senserva LLC
#Author: Senserva
#Requires -RunAsAdministrator
#Requires -Modules Az.Storage,Az.Accounts,Az.Resources

$config_SenservaPrimarySPName = "SenservaFull"
$requiredResourceAccess = @(
	@{
		# Microsoft Graph
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
				# Policy.Read.All
				Id = "246dd0d5-5bd0-4def-940b-0421030a5b68";
				Type = "Role"
	      	},
      		@{
				# SecurityEvents.Read.All
				Id = "bf394140-e372-4bf9-a898-299cfc7564e5";
				Type = "Role"
	      	},
      		@{
				# IdentityRiskEvent.Read.All
				Id = "6e472fd1-ad78-48da-a0f0-97ab2c6b769e";
				Type = "Role"
	      	},
      		@{
				# IdentityRiskyUser.Read.All
				Id = "dc5007c0-2d7d-4c42-879c-2dab87571379";
				Type = "Role"
	      	},
      		@{
				# User.Read.All
				Id = "df021288-bdef-4463-88db-98f22de89214";
				Type = "Role"
	      	},
      		@{
				# AuditLog.Read.All
				Id = "b0afded3-3588-46d8-8b3d-9842eff778da";
				Type = "Role"
	      	},
      		@{
				# Reports.Read.All
				Id = "230c1aed-a721-4c5d-9cb4-a90514e508ef";
				Type = "Role"
	      	},
      		@{
				# MailboxSettings.Read
				Id = "40f97065-369a-49f4-947c-6a255697ae91";
				Type = "Role"
	      	},
      		@{
				# Directory.Read.All
				Id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61";
				Type = "Role"
	      	},
      		@{
				# PrivilegedAccess.Read.AzureAD
				Id = "4cdc2547-9148-4295-8d11-be0db1391d6b";
				Type = "Role"
	      	},
      		@{
				# PrivilegedAccess.Read.AzureResources
				Id = "5df6fe86-1be0-44eb-b916-7bd443a71236";
				Type = "Role"
	      	},
      		@{
				# UserAuthenticationMethod.Read.All
				Id = "38d9df27-64da-44fd-b7c5-a6fbac20248f";
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
				# RoleManagement.Read.All
				Id = "c7fbd983-d9aa-4fa7-84b8-17382c103bc4";
				Type = "Role"
	      	},
			@{
				# Organization.Read.All
				Id = "498476ce-e0fe-48b0-b801-37ba7e2685c6";
				Type = "Role"
	      	}
  		)
	},
	@{
		# Microsoft Defender for Cloud Apps
		ResourceAppId = "05a65629-4c1b-48c1-a78b-804c4abdd4af";
  		ResourceAccess = @(
			@{
				# discovery.read
				Id = "e9aa7b67-ea0d-435b-ab36-592cd9b23d61";
				Type = "Role"
      		},
			@{
				# investigation.read
				Id = "83bc8d83-2679-44ef-b813-d5f556fc4474";
				Type = "Role"
      		},
			@{
				# settings.read
				Id = "8e41f311-31d5-43aa-bb79-8fd4e14a8745";
				Type = "Role"
      		}
  		)
	},
	@{
		# Office 365 Management APIs
		ResourceAppId = "c5393580-f805-4401-95e8-94b7a6ef2fc2";
  		ResourceAccess = @(
			@{
				# ActivityFeed.ReadDlp
				Id = "4807a72c-ad38-4250-94c9-4eabfe26cd55";
				Type = "Role"
      		},
			@{
				# ActivityFeed.Read
				Id = "594c1fb6-4f81-4475-ae41-0c394909246c";
				Type = "Role"
      		},
			@{
				# ServiceHealth.Read
				Id = "e2cea78f-e743-4d8f-a16a-75b629a038ae";
				Type = "Role"
      		}
  		)
	},
	@{
		# Microsoft 365 Defender
		ResourceAppId = "8ee8fdad-f234-4243-8f3b-15c294843740";
  		ResourceAccess = @(
			@{
				# CustomDetections.ReadWrite.All
				Id = "a7deff90-e2f5-4e4e-83a3-2c74e7002e28";
				Type = "Role"
      		},
			@{
				# Incident.Read.All
				Id = "a9790345-4595-42e4-971a-ccdc79f19b7c";
				Type = "Role"
      		},
			@{
				# AdvancedHunting.Read.All
				Id = "7734e8e5-8dde-42fc-b5ae-6eafea078693";
				Type = "Role"
      		},
			@{
				# Incident.ReadWrite.All
				Id = "8d90f441-09cf-4fdc-ab45-e874fa3a28e8";
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
            $PrimarySP = New-AzADApplication -DisplayName $config_SenservaPrimarySPName -AvailableToOtherTenants:$True -Confirm:$False -ReplyUrls "https://admin.microsoft.com" -IdentifierUris "https://$($userUPN.Split("@")[1])" -RequiredResourceAccess $requiredResourceAccess -WarningAction SilentlyContinue -ErrorAction Stop -InformationAction SilentlyContinue
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