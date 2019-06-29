TX_lib_dependencies["AllDepencies"](scriptpath()).
wait 5.
clearscreen.

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](250000).
  TX_lib_man_exe["Circularization"]().
}

TX_lib_transfer_moon["MoonTransfer"](mun, 20000, 0).
TX_lib_stage["StageCheck"]().
TX_lib_crew["WaitTillEVA"]().
//TX_lib_landing["SuicideBurn"]().
//TX_lib_ascent["MainLaunch"](150000).
//TX_lib_man_exe["Circularization"]().

TX_lib_transfer_moon["ReturnFromMoon"]().
TX_lib_man_exe["ChangeApoapsis"](list(80000)).
TX_lib_man_exe["Circularization"](periapsis).

TX_lib_man_exe["ChangePeriapsis"](list(30000)).
TX_lib_steering["SteeringOrbitNorm"]().
TX_lib_stage["LastStage"]().

lock steering to retrograde.
warpto(time:seconds + eta:periapsis).
wait until altitude < 10000.
stage.
unlock steering.
