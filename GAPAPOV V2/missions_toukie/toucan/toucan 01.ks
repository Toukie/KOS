TX_lib_dependencies["AllDepencies"](scriptpath()).
wait 5.
clearscreen.

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](250000).
  TX_lib_man_exe["Circularization"]().
}

TX_lib_crew["WaitTillEVA"]().

TX_lib_man_exe["ChangePeriapsis"](list(30)).
TX_lib_steering["SteeringOrbitNorm"]().
until stage:number = 1 {
  wait until stage:ready.
  stage.
  wait 1.
}

lock steering to retrograde.
warpto(time:seconds + eta:periapsis).
wait until altitude < 10000.
stage.
unlock steering.
