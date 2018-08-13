{

global T_Stage is lexicon(
  "StageCheck", StageCheck@,
  "EndStage", EndStage@,
  "LaunchStage", LaunchStage@
  ).
  
Function StageCheck {

  set PrevThrust to MaxThrust.

  when MaxThrust < (PrevThrust - 10) then {
        set CurrentThrottle to Throttle.
        lock Throttle to 0.
        wait until stage:ready.
  	    stage.
  	    wait 1.
        lock Throttle to CurrentThrottle.
        set PrevThrust to MaxThrust.
  	    preserve.
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
  until ship:availablethrust > 0 {
      wait until stage:ready.
      stage.
    }
}
}
print "read lib_stage".
