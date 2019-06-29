Function Science {
  toggle ag1.
  wait 1.
  toggle ag2.
  wait 1.
}

stage.
lock steering to heading(90,90).
wait until stage:solidfuel = 0.
stage.
wait until stage:solidfuel = 0.
stage.
lock throttle to 1.
wait until alt:radar > 20000.
Science().
wait until altitude > 71000.
Science().
