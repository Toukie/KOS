clearscreen.
set kuniverse:timewarp:warp to 0.
clearvecdraws().
clearguis().
set config:ipu to 200.
core:doaction("Open Terminal", true).

local LibVersion is "1.3.0".
local ContinueStart is true.

if defined BootVersion = false {
  T_Boot["CopyFile"]("boot_updater", "0:/exe_toukie/").
  set ContinueStart to false.
  if exists("1:/boot_updater") and exists("BootCheck") = false {
    run boot_updater.
  } else {
    HUDtext("WARNING: BOOT VERSION OR MAIN SCRIPT OUT OF DATE, CHECK THE README.txt FILE", 15, 2, 30, red, true).
  }
} else if BootVersion <> LibVersion {
  T_Boot["CopyFile"]("boot_updater", "0:/exe_toukie/").
  set ContinueStart to false.
  if exists("1:/boot_updater") and exists("BootCheck") = false {
    run boot_updater.
  } else {
    HUDtext("WARNING: BOOT VERSION OR MAIN SCRIPT OUT OF DATE, CHECK THE README.txt FILE", 15, 2, 30, red, true).
  }
}

deletepath(BootCheck).

if ContinueStart = true {
if true=true  {
 T_Boot["CopyAndRunFile"]("lib_closest_approach", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_docking", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_gapapov_main", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_gui", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_hillclimb_man_exe", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_hillclimb_scoring", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_hillclimb_universal", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_inclination", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_other", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_phase_angle", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_readout", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_rendezvous", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_stage", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_steering", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_transfer", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_transfer_burns", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_true_anomaly", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_warp", "0:/lib_toukie/").
}

T_Other["RemoveAllNodes"]().

lock throttle to 0.
unlock throttle.

local EngList is list().
list Engines in EngList.
for Eng in EngList {
  set Eng:thrustlimit to 100.
}

clearscreen.

T_Boot["CopyAndRunFile"]("gapapov", "0:/exe_toukie/").
}
