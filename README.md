# Bash
This is a collection of Bash utility scripts for macOS

## Add Login Item 

```
Add-Login-Item.sh
```

A script that automatically adds specified applications to a user's login items (startup applications).
The application is hard-coded, but we can simply add another path if needed

## Add Login Item 

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

