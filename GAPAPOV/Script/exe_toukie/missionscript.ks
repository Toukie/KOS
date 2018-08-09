set kuniverse:timewarp:warp to 0.
clearscreen.
clearvecdraws().
clearguis().

T_Other["RemoveAllNodes"]().

unlock throttle.

set terminal:width  to 60.
set terminal:height to 40.

core:doaction("Open Terminal", true).

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
 T_Boot["CopyAndRunFile"]("lib_rendezvous", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_science", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_stage", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_steering", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_transfer", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_transfer_burns", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_true_anomaly", "0:/lib_toukie/").
 T_Boot["CopyAndRunFile"]("lib_warp", "0:/lib_toukie/").
}

clearscreen.

T_Boot["CopyAndRunFile"]("gapapov", "0:/exe_toukie/").
