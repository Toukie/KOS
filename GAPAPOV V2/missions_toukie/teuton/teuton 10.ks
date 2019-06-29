// NOT BEING ABLE TO LOAD STUFF IS A STORAGE SPACE ISSUE, GET A BETTER KOS PROCESSOR

TX_lib_dependencies["AllDepencies"](scriptpath()).

if ship:status = "prelaunch" {
  //TX_lib_ascent["MainLaunch"](470000).  // remove this if theres too little space
}

TX_lib_man_exe["Circularization"]().

TX_lib_inclination["InclinationSetter"](10).
wait 9999.

//TX_lib_man_exe["ChangeApoapsis"](ScoreList).
