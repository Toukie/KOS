TX_lib_dependencies["AllDepencies"](scriptpath()).
wait 1.
set target to mun.
clearscreen.

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](250000).
  TX_lib_man_exe["Circularization"]().

  TX_lib_transfer_moon["MoonTransfer"](mun, 30000, 0).

  TX_lib_landing["SuicideBurn"](true).
  wait 10.

  TX_lib_ascent["MainLaunch"](150000).
  TX_lib_man_exe["Circularization"]().
  TX_lib_transfer_moon["ReturnFromMoon"]().
  TX_lib_man_exe["Circularization"](periapsis).
}

TX_lib_man_exe["ChangePeriapsis"](list(30000)).
lock steering to retrograde.
wait until altitude < 30000.
stage.
