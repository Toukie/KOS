{

global TX_Boot is lexicon(
  "CopyAndRunFile", CopyAndRunFile@,
  "CopyFile", CopyFile@
  ).

global BootVersion is "1.5.0".

Function CopyFile {
  parameter TargetFile.
  parameter FileLocation is "0:/".
  set string1 to FileLocation + TargetFile.
  deletepath(TargetFile).
  if exists(string1) = true {
    if open(string1):size > core:volume:freespace {
      HUDtext( "Not enough storage! Need more storage", 15, 2, 45, red, true).
    }
    copypath(string1, "").
  } else {
      HUDtext( string1 + "doesn't exist", 15, 2, 45, red, true).
  }

}

Function CopyAndRunFile {
  parameter TargetFile.
  parameter FileLocation is "0:/".
  set string1 to FileLocation + TargetFile.
  deletepath(TargetFile).

  if exists(string1) = true {
    if open(string1):size > core:volume:freespace {
      HUDtext( "Not enough storage! Need more storage", 15, 2, 45, red, true).
    }
    copypath(string1, "").
    runpath(TargetFile).
  } else {
      HUDtext( string1 + "doesn't exist", 15, 2, 45, red, true).
  }
}

wait until ship:loaded.
wait until ship:unpacked.
wait 0.

set kuniverse:timewarp:warp to 0.
set PilotMainThrottle to 0.
sas off.
rcs off.
wait 0.

clearguis().
clearscreen.
until hasnode = false {
  remove nextnode.
}

switch to 1.

deletepath(CancelInclinationHillclimb).
deletepath(CancelPeriapsisHillclimb).
deletepath(CancelDvHillclimb).
deletepath(DeltaVPenaltyIncr10).
deletepath(DeltaVPenaltyIncr01).
deletepath(DeltaVPenaltyDecr01).
deletepath(DeltaVPenaltyDecr10).

CopyFile("boot_updater", "0:/boot/").
CopyAndRunFile("lib_dependencies", "0:/lib_toukie/").
CopyAndRunFile("mission_getter", "0:/exe_toukie/").

}
