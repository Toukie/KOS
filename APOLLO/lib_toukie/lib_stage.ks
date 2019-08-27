@lazyglobal off.

global TX_lib_stage is lexicon(
  "LaunchStage", LaunchStage@,
  "StageCheck", StageCheck@,
  "LastStage", LastStage@,
  "StageTillLastEngine", StageTillLastEngine@
).

Function LaunchStage {
  until ship:status <> "prelaunch" {
    stage.
    wait 0.5.
  }
}

Function StageCheck {
  global IgnoreStaging is false.
  if StagingActive = false {
    set StagingActive to true.
    when MaxThrust > 0 then {
      //HUDtext("staging now running", 5, 2, 30, white, true).
      local PrevThrust is MaxThrust.
      // make sure to have engines active?
      when MaxThrust < (PrevThrust - 10) then {
        if IgnoreStaging = false {
          local CurrentThrottle is Throttle.
          lock Throttle to 0.
          if stage:number <> 0 {
            wait until stage:ready.
            stage.
          }
          wait 0.
          lock Throttle to CurrentThrottle.
          set PrevThrust to MaxThrust.
        } else {
          wait 1.
          set PrevThrust to MaxThrust.
          print "prevented staging :)".
        }
          preserve.
        }
      }
  } else {
    //HUDtext( "prevented staging failure", 15, 2, 45, red, true).
    //log "stage failure prevented" to Stagelog.
  }
}

Function LastStage {
  until stage:number <= 1 {
    wait until stage:ready.
    stage.
    wait 1.
  }
}

// last liquid fuel engine

Function StageTillLastEngine {
  parameter DetectOnly is false. // only look if there are landinglegs in the current stage

  local EngStageList is list().
  local EngStage is 100.

  local englist is list().
  list engines in englist.

  for eng in englist {
    EngStageList:add(eng:stage).
  }

  for eng in EngStageList {
    if eng < EngStage {
      set EngStage to eng.
    }
  }

  if round(EngStage) <> round(stage:number) {
    if DetectOnly = true {
      return list(true, EngStage). // staging needed
    }

    // preventing floating point errors
  until round(stage:number) = round(EngStage) {
    wait until stage:ready.
    stage.
    wait 1.
  }
} else if DetectOnly = true {
  return list(false). // no staging needed
}
}

print "read lib_stage".
