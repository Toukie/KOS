{

print "waiting for a connection...".
wait until homeconnection:isconnected = true.
clearscreen.
set kuniverse:timewarp:warp to 0.
wait until kuniverse:timewarp:rate = 1.

local EngList is list().
list Engines in EngList.
for Eng in EngList {
  set Eng:thrustlimit to 100.
}

wait until ship:loaded.
wait until ship:unpacked.
wait 0.

set kuniverse:timewarp:warp to 0.
set PilotMainThrottle to 0.
lock throttle to 0.
unlock throttle.
sas off.
rcs off.
wait 0.

clearguis().
clearvecdraws().
until hasnode = false {
  remove nextnode.
  wait 0.
}

switch to 1.

global StagingActive is false.

list files in w.
for i in w {
  if i:name:contains("lib"){
    deletepath(i).
  }
}

copypath("0:/lib_toukie/fullreboot", "").

copypath("0:/lib_toukie/lib_copy_files", "").
runpath(lib_copy_files).

copypath("0:/lib_toukie/lib_dependencies", "").
runpath(lib_dependencies).

TX_lib_copy_files["CopyAndRunFile"]("mission_getter", "0:/exe_toukie/").
}
