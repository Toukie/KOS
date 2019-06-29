TX_lib_dependencies["AllDepencies"](scriptpath()).

when alt:radar > 25000 then {
  toggle ag1.
  wait 3.
  toggle ag3.
}

TX_lib_ascent["MainLaunch"](85000).
local throtsetter is 0.
lock throttle to throtsetter.

wait 5.
toggle ag2.
lock steering to retrograde.
set throtsetter to 1.
wait until ship:periapsis < -30000.
set throtsetter to 0.
wait until alt:radar < 45000.
set throtsetter to 1.
wait 1.
wait until alt:radar < 7500.
stage.
