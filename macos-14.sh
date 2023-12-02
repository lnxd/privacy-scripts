#!/bin/bash

# Check if run as admin
if [ "$EUID" -ne 0 ]; then
    script_path=$([[ "$0" = /* ]] && echo "$0" || echo "$PWD/${0#./}")
    sudo "$script_path" || (
        echo 'Administrator privileges are required.'
        exit 1
    )
    exit 0
fi

## Office

echo '- Disabling Microsoft Office telemetry'

# Disable sending diagnostic data to Microsoft
defaults write com.microsoft.office DiagnosticDataTypePreference -string ZeroDiagnosticData

# Disable Office features that analyze your content
defaults write com.microsoft.office OfficeExperiencesAnalyzingContentPreference -bool FALSE

# Disable Office features that download online content
defaults write com.microsoft.office OfficeExperiencesDownloadingContentPreference -bool FALSE

# Disable most connected experiences in Office
defaults write com.microsoft.office ConnectedOfficeExperiencesPreference -bool FALSE

# Set Microsoft AutoUpdate data collection policy to only required data
defaults write com.microsoft.autoupdate2 AcknowledgedDataCollectionPolicy -string RequiredDataOnly

echo 'Press any key to exit.'
read -n 1 -s
