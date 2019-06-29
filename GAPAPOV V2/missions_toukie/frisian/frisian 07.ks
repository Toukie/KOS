// collect science on the mun and go into orbit and transmit data

TX_lib_dependencies["AllDepencies"](scriptpath()).
wait 1.
set target to mun.
clearscreen.

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](200000).
  TX_lib_man_exe["Circularization"]().
  ag3 on. // toggle antenna

}
TX_lib_stage["StageCheck"]().
  TX_lib_transfer_moon["MoonTransfer"](mun, 70000, 10).

  TX_lib_landing["SuicideBurn"]().
  wait 5.
  ag1 on.
  wait 10.

  TX_lib_ascent["MainLaunch"](500000, 90).
  TX_lib_man_exe["Circularization"]().

//TX_lib_man_exe["ChangePeriapsis"](list(200000)).
//TX_lib_man_exe["Circularization"](periapsis).
