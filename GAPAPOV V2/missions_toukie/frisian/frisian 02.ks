// going to the mun for real (intercept)

local RunMode is 1.

TX_lib_dependencies["AllDepencies"](scriptpath()).

if RunMode = 0 {
if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](250000).
  TX_lib_man_exe["Circularization"]().
}

clearscreen.
TX_lib_transfer_moon["MoonTransfer"](Mun, 100000, 0).
ag1 on.
warpto(time:seconds+eta:transition).
wait 10.
}

if RunMode = 1 {
  //warpto(time:seconds+eta:periapsis).
  TX_lib_man_exe["ChangeApoapsis"](list(100000)).
}
