TX_lib_dependencies["AllDepencies"](scriptpath()).

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](755000).
  TX_lib_man_exe["Circularization"]().

  TX_lib_man_exe["ChangeApoapsis"](list(960300)).
  ag1 on.
}

// match AoP
