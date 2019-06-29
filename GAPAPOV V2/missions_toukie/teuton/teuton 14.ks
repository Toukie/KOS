TX_lib_dependencies["AllDepencies"](scriptpath()).

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](250000, 90).
  TX_lib_man_exe["Circularization"]().
}

TX_lib_man_exe["ChangePeriapsis"](list(30000000)).
ag1 on.
