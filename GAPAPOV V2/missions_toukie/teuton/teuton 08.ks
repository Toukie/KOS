TX_lib_dependencies["AllDepencies"](scriptpath()).

TX_lib_ascent["MainLaunch"](85000).
set throtsetter to 0.
lock throttle to throtsetter.

wait 5.
lock steering to retrograde.
set throtsetter to 1.
wait until ship:periapsis < -30000.
set throtsetter to 0.
wait until alt:radar < 45000.
set throtsetter to 1.
wait until alt:radar < 7500.
stage.
