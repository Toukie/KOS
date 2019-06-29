// to minmus
// ended up crashing Val in orbit with eva

TX_lib_dependencies["AllDepencies"](scriptpath()).
wait 1.
clearscreen.

if exists(SwitchedVessel) = false {
  if ship:status = "prelaunch" {
    TX_lib_ascent["MainLaunch"](250000).
    TX_lib_man_exe["Circularization"]().
  }

  if ship:status <> "landed" {

    TX_lib_stage["StageCheck"]().
    if body <> minmus {
      TX_lib_transfer_moon["MoonTransfer"](minmus, 50000, 0).
    }

    TX_lib_landing["SuicideBurn"]().
    TX_lib_crew["WaitTillEVA"]().
  }

  TX_lib_ascent["MainLaunch"](300000).
  TX_lib_man_exe["Circularization"]().

  log "" to SwitchedVessel.
  HUDtext("Now launch the tanker vessel (Frisian 09)", 15, 2, 30, red, true).
  // now in orbit and in need of fuel
  // frisian 09 as refuel vessel
  // switch to frisian 09 to continue
} else {
  local CheckDocked is TX_lib_docking["CheckIfDocked"]().

  until CheckDocked = true {
    set CheckDocked to TX_lib_docking["CheckIfDocked"]().
    print "waiting" at(1,20).
    wait 1.
    print "-------" at(1,20).
    wait 0.3.
  }

  local EList is list().
  list elements in EList.
  local FromParts is "x".
  local ToParts is "x".

  if EList[0]:name:contains("toucan 05") {
    set FromParts to EList[1].
    // fuel goes to this craft
    set ToParts to EList[0].
  } else {
    set FromParts to EList[0].
    // fuel goes to this craft
    set ToParts to EList[1].
  }

  TX_lib_docking["FuelTransfer"](FromParts, ToParts).
  TX_lib_docking["Undock"](ToParts).

  set KUniverse:activevessel to vessel("Frisian 09").
  wait 1.
  TX_lib_docking["MoveAway"]().
  set KUniverse:activevessel to vessel("Toucan 05").


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
