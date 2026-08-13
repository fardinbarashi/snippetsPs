# MIM combine CSV files to a third csv

<!-- LICENSE -->
## License
Distributed under the GPL-3.0 License. See `LICENSE.txt` for more information.


## 🧾 Overview

This PowerShell script automates the process of extracting, cleaning, and combining **active user data** from both **Microsoft Identity Manager (MIM)** and **Active Directory (AD)**. The resulting output is a combined `.csv` file containing key user attributes such as usernames, full names, managers, and UserPrincipalNames.

---

## ✅ Features

- 🔎 Queries MIM for all active users with EmployeeID
- 🧹 Filters out system accounts (e.g. `XXX`, `ZZZ`, `OOO`)
- 🗃 Retrieves matching AD users and their managers
- 🔗 Combines MIM and AD records via manager linkage
- 💾 Exports all outputs to structured CSV files
- 🧾 Logs all activity using `Start-Transcript`

---

## 🛠️ Requirements

| Component           | Required            |
|--------------------|---------------------|
| PowerShell Version | 5.1 or later         |
| Modules            | `ActiveDirectory`, `LithnetRMA` |
| Access             | Localhost FIM/MIM Web Service |
| Permissions        | Read access to MIM and AD |

---

## 🗂️ File Output Locations

```powershell
$FromMim       = .\CsvFiles\FromMim\FromMim.csv
$FromAD        = .\CsvFiles\FromAD\FromAD.csv
$CombinedCsv   = .\CsvFiles\CombinedCsv\Allusers.csv
```

---

## 📑 Output Example (Allusers.csv)

| FirstName | LastName | Username | MimManager | UserPrincipalName       |
|-----------|----------|----------|------------|--------------------------|
| John      | Doe      | jdoe     | mgr123     | mgr123@domain.local      |
| Jane      | Smith    | jsmith   | mgr456     | mgr456@domain.local      |

---

## 📦 Script Flow

### 1. **Module Import**
- Loads `LithnetRMA` (for MIM) and `ActiveDirectory` modules.

### 2. **File Preparation**
- Cleans up previous export files if they exist:
  - `FromMim.csv`
  - `FromAD.csv`
  - `Allusers.csv`

### 3. **Query MIM**
- Uses XPath to find all users starting with `EmployeeID`
- Filters system/service accounts
- Exports clean list to `FromMim.csv`

### 4. **Query AD**
- Grabs all enabled AD users
- Filters out predefined accounts
- Extracts `ADManager` and `UserPrincipalName`
- Saves result to `FromAD.csv`

### 5. **Combine Data**
- For each MIM user:
  - Matches manager with AD to enrich with `UserPrincipalName`
  - Appends the record to `Allusers.csv`

---

## 🧪 Sample XPath Used

```powershell
$XPath = "/Person[starts-with(EmployeeID,'%')]"
```

---

## 📤 Example Log Output

```plaintext
Import Module LithnetRMA
Import Module ActiveDirectory
Querying MIM for active users
Querying AD for active users
200 People added to export
180 People added to FromAD.csv
Combining records...
Allusers.csv created with enriched data
```

---

## 📓 Script Metadata

| Field           | Value                                           |
|----------------|-------------------------------------------------|
| **Title**       | MIM CSV Combiner                               |
| **Author**      | Fardin Barashi                                 |
| **Version**     | 1.0                                             |
| **Release Date**| 2023-01-31                                      |
| **GitHub**      | [github.com/fardinbarashi](https://github.com/fardinbarashi) |

---

## 🧠 Tips & Customization

- 🔄 Change `SELECT YOUR OU` in the AD query to your actual OU path.
- 🔍 Adjust account filtering logic if you have different naming standards.
- ✏️ You can modify export paths or add more attributes as needed.
- 🛡️ Always test in a dev environment before running on production.

---

## 🧰 Prerequisites

Make sure you have:

- `Lithnet Resource Management PowerShell Module` installed:  
  [https://github.com/lithnet/resourcemanagement-powershell](https://github.com/lithnet/resourcemanagement-powershell)

- Access to MIM Web Service (`http://localhost:5725`)

---


