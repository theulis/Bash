# Bash
This is a collection of Bash utility scripts for macOS

## Add Login Item 

```
Add-Login-Item.sh
```

A script that automatically adds specified applications to a user's login items (startup applications).
The application is hard-coded, but we can simply add another path if needed

## Cisco Secure Endpoint DMG to PKG for Kandji Installation

```
Cisco-Secure-Endpoint-PKG.sh
```

This Bash script automates the process of extracting and packaging Cisco Secure Endpoint (formerly AMP) installation files from DMG images. 

### User Instructions & Validation
- Displays clear, color-coded instructions with emojis for better readability
- Prompts user to type "continue" to proceed (with input validation)
- Requests the specific version number (e.g., 1.27.0.1046) from the user

### File Path Verification
- Constructs the expected file path: ~/Cisco-Secure-Endpoint-App-DB/{version}/amp_Protect.dmg
- Verifies that the DMG file exists at the specified location
- Provides clear error messages if the file is not found
- Allows multiple attempts if the file path is incorrect
### Output Structure
```
~/Cisco-Secure-Endpoint-App-DB/
└── {version}/
    ├── amp_Protect.dmg
    └── PKG-{version}/
        ├── ciscoampmac*.pkg
        ├── .policy.xml
        └── PKG-{version}.zip
```

## Cisco Secure Client Custom Package Creator

```
Cisco-Secure-Client-PKG.sh
```

This Bash script automates the creation of custom Cisco Secure Client installation packages by allowing users to selectively include specific modules and their corresponding configuration files. 

**Input Structure Required:**
```
~/Cisco-Secure-Client-App-DB/
├── Configuration-Files/
│   ├── anyconnectOGS.xml
│   ├── Cisco_Secure_Access_Root_CA.cer
│   ├── orgInfo.json
│   └── ThousandEyes Endpoint Agent Configuration.json
└── Cisco-Secure-Client-<version>/
    └── cisco-secure-client-macos-<version>-predeploy-k9.dmg
```

### What It Does

#### 1. **Version Validation & User Input**
- Prompts for Cisco Secure Client version number (e.g., 5.1.10.233)
- Validates version format using regex patterns
- Ensures proper version numbering structure

#### 2. **Module Selection Menu**
- **Always Included**: VPN and DART modules (mandatory components)
- **Optional Modules**: Umbrella, ThousandEyes, ZeroTrust, DUO
- Interactive menu system with numbered options
- Comma-separated selection for multiple modules
- Confirmation step before proceeding

**Example Menu Interface:**
```
================ Module Selection ================
VPN and DART are always included.
Select optional modules by typing numbers (comma-separated):
1) Umbrella
2) ThousandEyes
3) ZeroTrust
4) DUO
==================================================
Enter selection: 1,2,3

You selected:
 - VPN
 - DART
 - Umbrella
 - ThousandEyes
 - ZeroTrust
Confirm? (y/n): y
```

#### 3. **Configuration File Management**
- **VPN Module**: Requires `anyconnectOGS.xml`
- **Umbrella Module**: Requires `orgInfo.json` and `Cisco_Secure_Access_Root_CA.cer`
- **ThousandEyes Module**: Requires `ThousandEyes Endpoint Agent Configuration.json`
- **ZeroTrust, DART, DUO**: No configuration files required
- Validates existence of required configuration files before proceeding

#### 4. **DMG Processing & Package Extraction**
- Locates and mounts the Cisco Secure Client DMG file
- Extracts the base package using `pkgutil --expand`
- Identifies individual module packages within the expanded structure

#### 5. **Selective Module Package Creation**
- **Only processes selected modules** from the user's menu selection
- Creates flattened `.pkg` files with `_flat.pkg` suffix
- **Module Package Mappings**:
  - `vpn_module.pkg` → `vpn_module_flat.pkg` (VPN module - always included)
  - `umbrella_module.pkg` → `umbrella_module_flat.pkg` (Umbrella module)
  - `thousandeyes_module.pkg` → `thousandeyes_module_flat.pkg` (ThousandEyes module)
  - `zta_module.pkg` → `zta_module_flat.pkg` (ZeroTrust module)
  - `duo_module.pkg` → `duo_module_flat.pkg` (DUO module)
  - `dart_module.pkg` → `dart_module_flat.pkg` (DART module - always included)

#### 6. **Ignored/Unused Module Packages**
The following module packages are **ignored** and not included in the final package:
- `iseposture_module.pkg` - ISE Posture module (not currently supported)
- `nvm_module.pkg` - Network Visibility Module (not currently supported)
- `posture_module.pkg` - Posture module (not currently supported)

#### 7. **Final Package Assembly**
- Creates a staging directory with selected components
- Includes only the configuration files for selected modules
- Includes only the flattened module packages for selected modules
- Creates a flattened ZIP archive (no folder structure)
- ZIP contains files at root level for easy deployment

### Key Features

- **Selective Module Inclusion**: Only includes modules the user actually selected
- **Configuration File Validation**: Ensures required files exist before processing
- **Flattened Package Structure**: Creates individual `.pkg` files for each module
- **Clean Output**: No unnecessary files or complex folder structures
- **Error Handling**: Comprehensive validation and error checking
- **User-Friendly Interface**: Clear menu system with confirmation steps

### Use Cases

- **Selective Deployment**: Create packages with only required modules
- **Configuration Management**: Bundle specific configuration files with modules
- **Testing & Development**: Test different module combinations
- **Enterprise Deployment**: Standardize on specific module sets
- **Compliance**: Ensure only approved modules are included

### Requirements

- macOS system (uses `hdiutil` and `pkgutil`)
- Bash shell
- Cisco Secure Client DMG files in organized directory structure
- Required configuration files in `~/Cisco-Secure-Client-App-DB/Configuration-Files/`

### Output Structure
The final ZIP contains a flat structure (example all the Mdoules has been selected)
```
anyconnectOGS.xml
Cisco_Secure_Access_Root_CA.cer
OrgInfo.json
ThousandEyes Endpoint Agent Configuration.json
dart_module_flat.pkg
vpn_module_flat.pkg
umbrella_module_flat.pkg
thousandeyes_module_flat.pkg
zta_module_flat.pkg
duo_module_flat.pkg
```

**Note**: Only the modules and configuration files for selected components are included, plus the mandatory DART module. Unused module packages are ignored to keep the final package lean and focused.

This script provides a professional, controlled way to create custom Cisco Secure Client packages tailored to specific deployment requirements while maintaining clean, organized output structures.


# WiFi-Restart


```
WiFi-Restart.sh
```

🔌 A simple macOS shell script that restarts Wi-Fi by turning it **off**, waiting briefly, and turning it **back on again**.  
🚀 This can sometimes help when the device struggles with roaming or staying connected.

⚠️ **Note:**  
Apple has deprecated the `airport` command-line tool and is slowly restricting CLI access to Wi-Fi information.  
This script still works to toggle Wi-Fi, but **displaying the connected SSID may not be reliable anymore**.  
For diagnostics, Apple now recommends using **Wireless Diagnostics (`wdutil`)**, but it does not provide a direct replacement for all `airport` features.
