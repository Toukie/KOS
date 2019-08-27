if exists("lib_dependencies") = false {
  TX_lib_copy_files["CopyAndRunFile"]("lib_dependencies", "0:/lib_toukie/").
}

set terminal:charheight to 15.
set terminal:height to 45.
set terminal:width  to 81.

clearscreen.
set config:ipu to 2000.
core:doaction("Open Terminal", true).

local ShipName is ship:name.
local ShipSeries is Shipname:substring(0, ShipName:length - 3).
// Apollo 11 becomes Apollo
local FolderList is open("0:/missions_toukie/").

local FoundSeries is false.

// checks if naming series is present in mission script folder
For Folder in FolderList {
  if Folder = ShipSeries {
    set FoundSeries to true.
  }
}

local FoundCurrentMission is false.

if FoundSeries = true {
  local FileList is open("0:/missions_toukie/" + ShipSeries + "/").
  local FoundFiles is list().
  local ShipNamePlus is Ship:Name + ".ks".
  for File in FileList {
    if File:name = ShipNamePlus {
      set FoundCurrentMission to true.
    }
  }
} else {
  local MissionList is open("0:/missions_toukie/").
  for Mission in MissionList {

    if ship:name:contains(Mission:tostring) {
      set FoundSeries to true.
      set ShipSeries to Mission:tostring.
    }
  }
}


// checks if name of vessel is a mission script

if FoundCurrentMission = true {
  HUDtext("Running " + ShipName + ".ks", 15, 2, 30, green, true).
  deletepath(ShipName).
  wait 1.
  TX_lib_copy_files["CopyAndRunFile"](ShipName, "0:/missions_toukie/" + ShipSeries + "/").
} else if FoundSeries = true {
  HUDtext("Specific mission script not found, choose different script", 15, 2, 30, yellow, true).
  TX_lib_copy_files["CopyAndRunFile"]("lib_gui_file_picker", "0:/lib_toukie/").
  TX_lib_gui_file_picker["MenuPicker"](ShipSeries).
} else {
  HUDtext("no suitable script found, choose different script", 15, 2, 30, red, true).
  TX_lib_copy_files["CopyAndRunFile"]("lib_gui_file_picker", "0:/lib_toukie/").
  TX_lib_gui_file_picker["MenuPicker"]().
}
