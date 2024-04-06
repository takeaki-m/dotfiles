#!/bin/bash
# ================================
# toggle backgroundsounds
# ================================

# get current user id
USER_ID=`id -u`

# check if backgroundsounds state
if [ $( defaults read com.apple.ComfortSounds "comfortSoundsEnabled" ) == "0" ]
then
  defaults write com.apple.ComfortSounds "comfortSoundsEnabled" -bool "true"
else
  defaults write com.apple.ComfortSounds "comfortSoundsEnabled" -bool "false"
fi
# restart accessibility heard service
launchctl kill SIGHUP gui/$USER_ID/com.apple.accessibility.heard

