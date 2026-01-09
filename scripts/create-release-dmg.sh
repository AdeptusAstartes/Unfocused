#!/bin/bash

# create-release-dmg.sh
# Creates a DMG and publishes a GitHub release for Unfocused
#
# Prerequisites:
# - brew install create-dmg gh
# - gh auth login
# - Notarized app exported from Xcode to releases/Unfocused.app
#
# Usage:
#   ./scripts/create-release-dmg.sh [app-path] [version]
#
# Examples:
#   ./scripts/create-release-dmg.sh                    # Uses releases/Unfocused.app, auto-detects version
#   ./scripts/create-release-dmg.sh releases/Unfocused.app 1.0.1  # Override version
#
# The script will:
# 1. Create a DMG with the app
# 2. Open your editor to write release notes
# 3. Create a GitHub release and upload the DMG
# 4. Clean up local files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for create-dmg
if ! command -v create-dmg &> /dev/null; then
    echo -e "${RED}Error: create-dmg not found${NC}"
    echo "Install it with: brew install create-dmg"
    exit 1
fi

# Check for gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: gh CLI not found${NC}"
    echo "Install it with: brew install gh"
    exit 1
fi

# Check gh auth status
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default app path is releases/Unfocused.app within the repo
APP_PATH="${1:-$PROJECT_ROOT/releases/Unfocused.app}"

# Extract version from Xcode project if not provided
if [ -z "$2" ]; then
    VERSION=$(grep -m1 "MARKETING_VERSION" "$PROJECT_ROOT/Unfocused.xcodeproj/project.pbxproj" | sed 's/.*= *\(.*\);/\1/' | tr -d ' ')
    if [ -z "$VERSION" ]; then
        echo -e "${YELLOW}Warning: Could not extract version, using date${NC}"
        VERSION=$(date +%Y%m%d)
    fi
else
    VERSION="$2"
fi

# Validate app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: App not found at $APP_PATH${NC}"
    exit 1
fi

# Output paths
OUTPUT_DIR="$PROJECT_ROOT/releases"
DMG_NAME="Unfocused-${VERSION}.dmg"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Remove existing DMG if present
if [ -f "$DMG_PATH" ]; then
    echo -e "${YELLOW}Removing existing DMG...${NC}"
    rm "$DMG_PATH"
fi

echo -e "${GREEN}Creating DMG for Unfocused v${VERSION}...${NC}"
echo "App source: $APP_PATH"
echo "Output: $DMG_PATH"
echo ""

# Create the DMG
create-dmg \
    --volname "Unfocused" \
    --volicon "$PROJECT_ROOT/assets/icon-screenshot.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "Unfocused.app" 150 185 \
    --hide-extension "Unfocused.app" \
    --app-drop-link 450 185 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_PATH"

echo ""
echo -e "${GREEN}✓ DMG created successfully!${NC}"
echo "  Path: $DMG_PATH"
echo "  Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""

# Create release notes
NOTES_FILE=$(mktemp)
cat > "$NOTES_FILE" << 'EOF'

# Enter release notes for Unfocused v{VERSION}
# Lines starting with # will be ignored.
# Save and close the editor to continue.
# Leave empty (only comments) to abort the release.

EOF
sed -i '' "s/{VERSION}/$VERSION/" "$NOTES_FILE"

# Open editor for release notes
EDITOR="${EDITOR:-nano}"
$EDITOR "$NOTES_FILE"

# Extract non-comment lines
RELEASE_NOTES=$(grep -v '^#' "$NOTES_FILE" | sed '/^[[:space:]]*$/d')
rm "$NOTES_FILE"

if [ -z "$RELEASE_NOTES" ]; then
    echo -e "${YELLOW}Release notes empty, skipping GitHub release${NC}"
    echo "DMG is ready at: $DMG_PATH"
    exit 0
fi

echo ""
echo -e "${GREEN}Creating GitHub release v${VERSION}...${NC}"

# Create the release and upload DMG
gh release create "v${VERSION}" \
    --repo "AdeptusAstartes/Unfocused" \
    --title "Unfocused v${VERSION}" \
    --notes "$RELEASE_NOTES" \
    "$DMG_PATH"

echo ""
echo -e "${GREEN}✓ Release published!${NC}"
echo "  https://github.com/AdeptusAstartes/Unfocused/releases/tag/v${VERSION}"

# Clean up
rm -f "$DMG_PATH"
rm -rf "$APP_PATH"
echo ""
echo "Cleaned up local release files."
