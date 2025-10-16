#!/bin/bash

# 快速检查公证状态

SUBMISSION_ID="b26d91a6-7e10-484c-a256-624a3de8d327"
APPLE_ID="james@jamesphotography.com.au"
TEAM_ID="JWR6FDB52H"
APP_SPECIFIC_PASSWORD="vfmy-vjcb-injx-guid"

xcrun notarytool info "$SUBMISSION_ID" \
    --apple-id "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID"
