

{

global TX_lib_stage is lexicon(
  "StageCheck", StageCheck@,
  "EndStage", EndStage@,
  "LaunchStage", LaunchStage@
  ).
  local TXStopper is "[]".

global StageRunOnce is false.

Function StageCheck {

if StageRunOnce = false {

  when MaxThrust > 0 then {
    //HUDtext("staging now running", 5, 2, 30, white, true).
    set StageRunOnce to true.
    local PrevThrust is MaxThrust.
    // make sure to have engines active?

    when MaxThrust < (PrevThrust - 10) then {
          local CurrentThrottle is Throttle.
          lock Throttle to 0.
          wait until stage:ready.
          stage.
          wait 1.
          lock Throttle to CurrentThrottle.
          set PrevThrust to MaxThrust.
          preserve.
      }
    }
  }
}

Function EndStage {
  Parameter EndStage.

  until stage:number = EndStage {
    wait until stage:ready.
    stage.
  }

}

Function LaunchStage {
  local startheight is alt:radar.
  until ship:availablethrust > 0 {
      wait until stage:ready.
      stage.
      wait 1.
      if alt:radar < (startheight+1) {
        stage.
      }
    }
}
}
print "read lib_stage".
