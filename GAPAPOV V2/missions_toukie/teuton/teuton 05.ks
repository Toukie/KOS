lock steering to heading(320,45).
lock throttle to 1.
stage.
wait 3.
toggle ag1.
wait until ship:liquidfuel = 0.
stage.
wait until ship:status <> "flying".
toggle ag2.
