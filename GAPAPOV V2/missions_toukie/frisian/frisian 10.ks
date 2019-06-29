// collect science on the mun and go into orbit and transmit data

TX_lib_dependencies["AllDepencies"](scriptpath()).
wait 1.
set target to mun.
clearscreen.

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](200000).
  ag2 on.
  wait 1.
  panels on.
  TX_lib_man_exe["Circularization"]().

}

stage.
panels on.
TX_lib_stage["StageCheck"]().
TX_lib_transfer_moon["MoonTransfer"](mun, 70000, 45).

TX_lib_landing["SuicideBurn"]().
wait 5.
ag1 on. // all science stuff
wait 5.

TX_lib_ascent["MainLaunch"](500000, 90).
TX_lib_man_exe["Circularization"]().
