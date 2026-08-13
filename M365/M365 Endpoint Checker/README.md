# Microsoft 365 Endpoints Checker
## Overview
This PowerShell script connects to the official [Microsoft 365 endpoints web service](https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges?view=o365-worldwide) and retrieves the **Optimize**, **Allow**, and **Default** endpoint categories.
The result includes IP addresses and URLs that Microsoft 365 services depend on. The script saves the collected data to separate `.txt` files for firewall, proxy, routing, and traffic-control planning.
The script uses the newer REST-based Microsoft 365 endpoint service, which replaced the downloadable XML files that were deprecated in 2018.

---


---

## Requirements

| Requirement         | Value                                      |
|--------------------|--------------------------------------------|
| PowerShell Version | 5.x                                        |
| Internet Access    | Required                                   |
| External Modules   | Not required. Pure PowerShell script        |
| Endpoint Docs      | [Microsoft Docs](http://aka.ms/ipurlws)    |

---

## Output Files
All files are saved in the `Files` directory under the script root.
| File Name Format                                    | Description                              |
|-----------------------------------------------------|------------------------------------------|
| `Microsoft Optimize Endpoints data <timestamp>.txt` | Raw Optimize endpoint data               |
| `Microsoft Optimize Endpoints <timestamp>.txt`      | Filtered IPv4 Optimize addresses         |
| `Microsoft Allow Endpoints data <timestamp>.txt`    | Raw Allow endpoint data                  |
| `Microsoft Allow Endpoints IPv4 <timestamp>.txt`    | Filtered IPv4 Allow addresses            |
| `Microsoft Default data Endpoints <timestamp>.txt`  | Raw Default endpoint data                |
| `Microsoft Default Endpoints <timestamp>.txt`       | Filtered Default service URLs            |
| `Logs/<ScriptName> - <timestamp>.txt`               | Full execution log from Start-Transcript |


---

## Output Preview
Example of Optimize IPv4 data:

```text
40.96.0.0/13
52.96.0.0/14
13.107.128.0/22
...
