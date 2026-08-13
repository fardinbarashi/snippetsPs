# Duplicate File Remover (PowerShell)

## 📦 Overview
This PowerShell script helps you identify and remove duplicate files in a specified folder (and its subfolders), allowing you to free up valuable disk space. It checks for files with identical names and prompts you for each duplicate, giving you control over what to delete.

---

## ✅ Features
- 🔍 Recursively scans a folder and its subfolders
- 📂 Detects duplicate files based on file names
- 🧾 Displays file paths and sizes for better decision-making
- 🗑️ Prompts before deleting each duplicate
- 🧠 Built-in logging via transcript for auditing
- 💥 Force delete option for quick cleanup

---

## 💻 System Requirements
Make sure your system meets the following requirements:

- **PowerShell Version:** 5.1.19041.2364  

<!-- LICENSE -->
## License
Distributed under the GPL-3.0 License. See `LICENSE.txt` for more information.
<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 🚀 Usage

1. **Clone this repo or copy the script to your local machine.**
2. **Open PowerShell as Administrator** (optional but recommended if system files may be involved).
3. **Edit the script**:
   Replace the line:
   ```powershell
   $folderPath = "ADD YOUR FOLDER"
   ```
   with the path to the folder you want to scan, for example:
   ```powershell
   $folderPath = "C:\Users\YourName\Documents"
   ```
4. **Run the script**:
   It will scan for duplicate filenames and prompt you before deleting each duplicate.
  Change line 56 - FolderPath
---

## 📓 Notes

- **Script version:** 1.0  
- **Author:** Fardin Barashi  
- **Release date:** 2023-01-31  
- **GitHub:** [https://github.com/fardinbarashi](https://github.com/fardinbarashi)

---

## ⚠️ Disclaimer
This script identifies duplicates based on **file names only**, not content hash. Be cautious when deleting files—ensure they are truly duplicates!

---

## 🛠️ Example Output

```plaintext
Duplicate files found for the name: report.pdf
Source file: C:\Docs\Reports\report.pdf, Size: 1.25 MB
Duplicate file: C:\Backup\report.pdf, Size: 1.25 MB
Do you want to delete the duplicate file: C:\Backup\report.pdf? (Y/N)
```

Happy cleaning! 🧹





