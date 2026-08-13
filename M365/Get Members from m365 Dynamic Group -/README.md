<!-- ABOUT THE PROJECT -->
# GetMemberFromM365DynamicsGroup

## System Requirements
- **PowerShell version**: 7+
- **Microsoft Graph PowerShell SDK**

---

## Description
This script connects to **Microsoft Graph** using a **certificate-based App Registration**, and exports all members of a specified **Entra ID (Azure AD) group** to a CSV file.
- Retrieves all users from a group (handles **pagination** for large groups).
- Collects user attributes:
 -- Name, email, mobile, business phone, department, location, etc.
- Attempts to fetch and include the **user's manager name**.



---

<!-- GETTING STARTED -->
## Configuration
Change in row 65
Change value 6000 in row to higher if you got more then 6000 users in group. $response = Get-MgGroupMember -GroupId $groupId -Top 6000
Add app-id settings files\MsGraph\MsGraphSettings.json
Example content:
```json
{
  "AppId": "<your-app-id>",
  "TenantId": "<your-tenant-id>",
  "CertificateThumbprint": "<your-cert-thumbprint>"
}
```








