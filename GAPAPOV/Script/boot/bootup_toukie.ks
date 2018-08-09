Function CopyAndRunFile {
  parameter TargetFile.
  parameter FileLocation is "0:/".
  set string1 to FileLocation + TargetFile.
  copypath(string1, "").
  runpath(TargetFile).
}

Function CopyFile {
  parameter TargetFile.
  parameter FileLocation is "0:/".
  set string1 to FileLocation + TargetFile.
  copypath(string1, "").
}

wait until ship:loaded.
wait until ship:unpacked.
wait 0.

set kuniverse:timewarp:warp to 0.
set PilotMainThrottle to 0.
sas off.
rcs off.
wait 0.

switch to 1.

CopyAndRunFile("missionscript", "0:/exe_toukie/").
