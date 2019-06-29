global TX_lib_landing is lexicon(
  "SuicideBurn", doHoverslam@
).

local TXStopper is "[]".

Function doHoverslam {
  parameter WarpOverride is false.

  if ship:status <> "SUB_ORBITAL" {
    TX_lib_man_exe["Decircularization"]().
  }

  // kill all horizontal velocity.
  KillHorizontalVel().


  lock steering to srfRetrograde.
  lock pct to stoppingDistance() / distanceToGround().

  local DoneStaging is false.
  local WarpRunMode is 0.

  until pct > 0.9 {
    clearscreen.
    print "Stopping Dist / Current Alt " + round(pct,3).
    if WarpOverride = false {

      if pct > 0.05 {
        if WarpRunMode <= 2 {
          set warp to 0.
        }
        set WarpRunMode to 3.
        wait until kuniverse:timewarp:rate = 1. // wait until fully slowed down
        if DoneStaging = false {
          set DoneStaging to true.
          local StageNeeded is TX_lib_stage["StageTillLastEngine"](true).
          if StageNeeded[0] = true {
            local StartingRetVec is srfRetrograde:vector.
            until ship:verticalSpeed > 0 or stage:number = StageNeeded[1] {
              wait until vang(ship:facing:vector, StartingRetVec) < 1.
              if vdot(StartingRetVec, srfRetrograde:vector) < 0 {
                break.
              }
              lock throttle to 1.
            }
            wait 0.
            lock throttle to 0.
            TX_lib_stage["StageTillLastEngine"]().
          }
        }
      } else if pct > 0.01 {
        if WarpRunMode <= 1 {
          set warp to 2.
        }
        set WarpRunMode to 2.
      } else if pct > 0 {
        if WarpRunMode = 0 {
          set warp to 2.
        }
        set WarpRunMode to 1.
      }
    }
    wait 0.
  }
  set warp to 0.

  local DoneWithBurn is false.

  when DoneWithBurn = false then { // this prevents the automatic staging from messing lock throttle up
    lock throttle to pct.
    wait 0.
    preserve.
  }

  when distanceToGround() < 500 then {
    gear on.
  }

  wait until ship:verticalSpeed > 0.
  set DoneWithBurn to true.
  lock throttle to 0.
  lock steering to groundSlope().
  wait 10.
  unlock steering.
}

Function distanceToGround {
  return altitude - body:geopositionOf(ship:position):terrainHeight - 4.7.
}

Function stoppingDistance {
  local grav is constant():g * (body:mass / body:radius^2).
  local maxDeceleration is (ship:availableThrust / ship:mass) - grav.
  return ship:verticalSpeed^2 / (2 * maxDeceleration).
}

Function groundSlope {
  local east is vectorCrossProduct(north:vector, up:vector).

  local center is ship:position.

  local a is body:geopositionOf(center + 5 * north:vector).
  local b is body:geopositionOf(center - 3 * north:vector + 4 * east).
  local c is body:geopositionOf(center - 3 * north:vector - 4 * east).

  local a_vec is a:altitudePosition(a:terrainHeight).
  local b_vec is b:altitudePosition(b:terrainHeight).
  local c_vec is c:altitudePosition(c:terrainHeight).

  return vectorCrossProduct(c_vec - a_vec, b_vec - a_vec):normalized.
}

Function KillHorizontalVel {
  local VecDir is vectorexclude(up:vector, srfretrograde:vector).
  local VecMag is vectorexclude(up:vector, velocity:surface):mag.
  print VecDir.
  print VecMag.
  local VecTot is VecMag * VecDir.

  if vdot(VecTot, -ship:velocity:orbit) < 0 {
    set VecTot to VecTot * -1.
  }

  local NodeList is TX_lib_man_exe["NodeFromVector"](VecTot, time:seconds+30).
  TX_lib_man_exe["ExecuteManeuver"](NodeList).
}

print "read lib_landing".
