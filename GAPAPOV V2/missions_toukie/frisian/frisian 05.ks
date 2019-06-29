TX_lib_dependencies["AllDepencies"](scriptpath()).
wait 1.

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](250000).
  TX_lib_man_exe["Circularization"]().
}

set target to mun.
TX_lib_transfer_moon["MoonTransfer"](Mun, 100000, 0).
clearscreen.
TX_lib_landing["SuicideBurn"]().
