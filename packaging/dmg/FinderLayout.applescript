on run {mountPath}
    set rootFolder to POSIX file mountPath as alias
    tell application "Finder"
        open rootFolder
        set installerWindow to Finder window 1
        if (target of installerWindow as alias) is not rootFolder then error "Installer Finder window did not open."
        tell installerWindow
            set current view to icon view
            set toolbar visible to false
            set statusbar visible to false
            set pathbar visible to false
            set bounds to {112, 104, 832, 568}
        end tell
        set options to icon view options of installerWindow
        tell options
            set arrangement to not arranged
            set icon size to 112
            set text size to 13
            set label position to bottom
        end tell
        set background picture of options to file ".background:background.tiff" of rootFolder
        set position of item "Pokelet.app" of rootFolder to {210, 249}
        set position of item "Applications" of rootFolder to {510, 249}
        delay 1
        close installerWindow
    end tell
end run
