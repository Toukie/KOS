// final prep for mun missions

TX_lib_dependencies["AllDepencies"](scriptpath()).

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](250000).
  TX_lib_man_exe["Circularization"]().
}

clearscreen.
TX_lib_transfer_moon["MoonTransfer"](Mun, 100000, 0).
