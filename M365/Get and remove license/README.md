# Get and Remove Microsoft 365 License via Microsoft Graph API

## Description
This PowerShell script connects securely to Microsoft Graph using a registered application with certificate-based authentication.
The script retrieves license details for a specified user and removes all assigned Microsoft 365 licenses from that user in the tenant.

---

## Features
- Connects to Microsoft Graph using:
  - App ID
  - Tenant ID
  - Certificate thumbprint
- Retrieves the full tenant license list using `Get-MgSubscribedSku`
- Gets assigned licenses for a specific user principal name
- Removes all assigned licenses from the user using `Set-MgUserLicense`
- Provides full script logging with `Start-Transcript`
- Supports optional email alerts via Microsoft Graph Mail without SMTP

---

## System Requirements
| Requirement             | Version or Details                                                                    |
|-------------------------|----------------------------------------------------------------------------------------|
| PowerShell Version      | 5.1.19041.2364 or later                                                                |
| Graph PowerShell SDK    | `Microsoft.Graph` modules                                                              |
| API Permissions         | `User.Read.All`, `Directory.ReadWrite.All`, `Organization.Read.All`                    |
| Optional API Permission | `Mail.Send`, required only if email alerts are enabled                                 |
| Authentication Type     | Certificate-based app registration                                                     |

---
## Input Parameters

```powershell
param(
    [Parameter(Mandatory = $true)]
    [string]$upn
)
```

| Parameter | Description                                                     |
|-----------|-----------------------------------------------------------------|
| `upn`     | The user's UPN/email address targeted for license removal        |

---

## Setup Requirements
Before running the script, make sure the following requirements are completed:
1. Register an application in Microsoft Entra ID.
2. Generate or obtain a certificate for authentication.
3. Upload the certificate public key to the app registration.
4. Grant admin consent for the required Microsoft Graph API permissions.
5. Update the following values in the script:

```powershell
$AppId = "your-app-id"
$TenantId = "your-tenant-id"
$CertificateThumbprint = "your-cert-thumbprint"
```

For email alerts, also configure:

```powershell
$To = "admin@domain.com"
$From = "graph-mail-user@domain.com"
```

---

