// mun tanker rendezvous vessel

TX_lib_dependencies["AllDepencies"](scriptpath()).
wait 1.
set target to mun.
clearscreen.

wait 1.
local CheckDocked is TX_lib_docking["CheckIfDocked"]().
wait 1.
if CheckDocked = true {
  wait until false.
}

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](200000).
  TX_lib_man_exe["Circularization"]().
  ag3 on. // toggle antenna

  TX_lib_stage["StageCheck"]().
  TX_lib_transfer_moon["MoonTransfer"](mun, 150000, 0).

  // FIRST LAUNCH TOUCAN 04

}

local TargetVessel is vessel("Toucan 04").
set target to TargetVessel.
TX_lib_rendezvous["FullRendezvous"](TargetVessel).
TX_lib_docking["dock"](TargetVessel).










//
