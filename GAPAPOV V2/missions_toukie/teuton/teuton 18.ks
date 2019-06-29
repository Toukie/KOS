// rendezvous program
TX_lib_dependencies["AllDepencies"](scriptpath()).

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](1300000).
  TX_lib_man_exe["Circularization"]().
}

local DoRendezVous is true.

if DoRendezVous = true {
  local TargetVessel is vessel("Teuton 18 A").
  set target to TargetVessel.
  TX_lib_rendezvous["FullRendezvous"](TargetVessel).
  TX_lib_docking["dock"](TargetVessel).
}
