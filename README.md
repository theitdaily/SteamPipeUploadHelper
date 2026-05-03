# Incremental Build Updater

A lightweight tool for generating incremental update archives by comparing two directories.

## 🚀 Features

- Detects **new and changed files** using size + SHA256 hash  
- Detects **deleted files** and shows a warning  
- Creates a **ZIP archive with only changed files**  
- Generates a **change log**  
- Keeps a mirrored copy of the last build (`- Steam Update`)  
- Simple CLI interface  

## 📁 How It Works

The script compares:

```

<Build Folder>
<Build Folder> - Steam Update
```

It:

1. Finds differences between them
2. Packs only changed/new files into an archive
3. Logs changes
4. Syncs the update folder to match the source

## ▶️ Usage

1. Place both files in any directory:

```
SteamUpdate.bat
SteamUpdate.ps1
```

2. Run:

```
SteamUpdate.bat
```

3. Select a folder to process

## 📦 Output

* Archive:

```
BuildName - yyyy-MM-dd HH-mm-ss.zip
```

* Change log:

```
BuildName - yyyy-MM-dd HH-mm-ss - changes.txt
```

## ⚠️ Notes

* If no changes are detected → archive is **not created**
* Deleted files are **not included in archive**, but listed in log
* The `- Steam Update` folder is always synchronized with the source

## 🎮 Unity Usage (Optional)

If you're using Unity:

* Place the scripts inside your `Builds` folder
* Store your builds as subfolders inside `Builds`

Example:

```
Builds/
├─ Client/
├─ Server/
├─ Client - Steam Update/
├─ SteamUpdate.bat
├─ SteamUpdate.ps1
```

You can then generate incremental update packages directly from your Unity builds.

## 🧰 Requirements

* Windows 10/11
* PowerShell (included by default)
