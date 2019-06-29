TX_lib_dependencies["AllDepencies"](scriptpath()).


if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](250000).
  TX_lib_man_exe["Circularization"]().
}

clearscreen.
set target to mun.
TX_lib_transfer_moon["MoonTransfer"](Mun, 657000, 58.2, 340).
