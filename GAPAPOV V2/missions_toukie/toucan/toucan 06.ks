//Valentina Minmus rescue

TX_lib_dependencies["AllDepencies"](scriptpath()).
wait 1.
clearscreen.
set target to minmus.

if exists(SwitchedVessel) = false {
  if ship:status = "prelaunch" {
    TX_lib_ascent["MainLaunch"](250000).
    TX_lib_man_exe["Circularization"]().
  }

  TX_lib_stage["StageCheck"]().
  if body <> minmus {
    TX_lib_transfer_moon["MoonTransfer"](minmus, 50000, 0).
  }

  local TargetVessel is vessel("Valentina Kerman").
  wait 0.
  set target to TargetVessel.
  wait 0.
  TX_lib_rendezvous["FullRendezvous"](TargetVessel).

  log "" to SwitchedVessel.
  HUDtext("Now launch the tanker vessel (Frisian 09) if needed", 15, 2, 30, red, true).

} else {

  TX_lib_stage["StageCheck"]().
  TX_lib_transfer_moon["ReturnFromMoon"]().
  TX_lib_man_exe["ChangeApoapsis"](list(80000)).
  TX_lib_man_exe["Circularization"](periapsis).

  TX_lib_man_exe["ChangePeriapsis"](list(30000)).
  TX_lib_steering["SteeringOrbitNorm"]().
  TX_lib_stage["LastStage"]().

  lock steering to retrograde.
  wait 1.
  warpto(time:seconds + eta:periapsis).
  wait until altitude < 10000.
  stage.
  unlock steering.

}
