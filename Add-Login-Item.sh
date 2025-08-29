#!/bin/bash

# This script will add the specified apps to the login items of the specified user 

#### From the list of users we will get our main user - theo - in the example below
# ~$sudo ls -l /Users
# total 0
# -rw-r--r--   1 root              wheel     0 16 Aug 19:44 .localized
# drwxrwx---   4 root              admin   128 23 Jul  2024 Deleted Users
# drwxr-xr-x   3 root              admin    96 11 Dec  2024 root
# drwxrwxrwt  26 root              wheel   832 21 Aug 01:20 Shared
# drwxr-x---+ 12 KandjiAdmin      staff   384 18 Dec  2024 KandjiAdmin
# drwxr-xr-x+ 73 theo             staff  2336 29 Aug 12:01 theo


## We need to remove the first line total and from the Row 3, we will also exclude any root and any Admins
local_user=$(sudo ls -l /Users | grep -v '^total' | awk '{print $3}'| grep -v -e 'root' | grep -v -i 'admin')

## Here we need to specify the full path of the apps we want to add to the login items

app_paths=(
    "/Applications/Cursor.app"
)

echo "Debug: local_user = $local_user"

for app_path in "${app_paths[@]}"; do
    echo "Debug: Processing app_path = $app_path"
    
    if [ -d "$app_path" ]; then
        echo "Debug: App path exists, attempting to add to login items..."
        echo "Debug: Running command: sudo -u $local_user osascript -e 'tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:false}'"
        result=$(sudo -u "$local_user" osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:false}" 2>&1)
        echo "Debug: AppleScript result: $result"
        if [ $? -eq 0 ]; then
            echo "Application $(basename "$app_path" .app) added to login items of user: $local_user"
        else
            echo "Failed to add application $(basename "$app_path" .app) to login items of user: $local_user"
        fi
    else
        echo "Application not found at: $app_path"
    fi
    echo "---"
done