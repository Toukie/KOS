global TX_lib_landing is lexicon(
  "SuicideBurn", SuicideBurn@,
  "KillHorizontalVel", KillHorizontalVel@
).

local TXStopper is "[]".

global boundingbox is ship:bounds.

Function SuicideBurn {
  parameter WarpOverride is false.

  if ship:status <> "SUB_ORBITAL" {
    TX_lib_man_exe["Decircularization"]().
  }

  // kill all horizontal velocity.
  KillHorizontalVel().


  lock pct to stoppingDistance() / distanceToGround().

  local DoneStaging is false.
  local WarpRunMode is 0.
  local KillHorCheck is 0.
  clearscreen.

  until pct > 0.9 {
    //clearscreen.
    print "Stopping Dist / Current Alt " + round(pct,3) + "                   " at(0,0).
    if WarpOverride = false {

      if pct > 0.3 {
        set steering to srfRetrograde.
      } else {
        set steering to srfRetrograde.
        wait 0.

        print "check 1                        " at(0,1).
        if pct > 0.05 {
          if WarpRunMode <= 2 {
            set warp to 0.
          }
          set WarpRunMode to 3.
          wait until kuniverse:timewarp:rate = 1. // wait until fully slowed down
          print "check 2" at(0,2).
          if DoneStaging = false {
            set DoneStaging to true.
            local StageNeeded is TX_lib_stage["StageTillLastEngine"](true).
            if StageNeeded[0] = true {
              print "check 3" at(0,3).
              local StartingRetVec is srfRetrograde:vector.
              lock steering to srfRetrograde.
              wait until vang(ship:facing:vector, srfRetrograde:vector) < 1.
              print round(vang(ship:facing:vector, srfRetrograde:vector),4) at(0,5).
              print "check 4" at(0,4).
              until ship:verticalSpeed > 0 or stage:number = StageNeeded[1] {
                if verticalSpeed > 0 {
                  break.
                }
                if vdot(StartingRetVec, srfRetrograde:vector) < 0 {
                  break.
                }
                wait 0.
                set throttle to 1.
              }
              wait 0.
              lock throttle to 0.
              wait 0.1.
              set IgnoreStaging to true.
              TX_lib_stage["StageTillLastEngine"]().
              wait 0.1.
              set IgnoreStaging to false.
            }

          }

          if pct < 0.1 {
            if KillHorCheck < 2 {
              KillHorizontalVel(0).
              set KillHorCheck to KillHorCheck + 1.
            }

            print "check 5" at(0,6).
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
    }
    wait 0.
  }
  set warp to 0.

  local DoneWithBurn is false.

  when DoneWithBurn = false then { // this prevents the automatic staging from messing lock throttle up
    set pct to stoppingDistance() / distanceToGround().
    print "Stopping Dist / Current Alt " + round(pct,3) + "                   " at(0,0).
    set steering to srfRetrograde.
    set throttle to pct.
    wait 0.
    preserve.
  }

  when distanceToGround() < 5000 then {
    gear on.
  }

  local ShipBounds is ship:bounds.
  wait until ship:verticalspeed > -2 or ShipBounds:bottomaltradar < 5.
  set throttle to pct/2.
  wait until ship:verticalSpeed > 0 or ShipBounds:bottomaltradar < 2.
  set DoneWithBurn to true.
  lock throttle to 0.
  lock steering to groundSlope().
  local DoneWaiting is false.
  until DoneWaiting = true {
    if  round(verticalSpeed, 1) = 0 {
      wait 10.
      if round(verticalSpeed, 1) = 0 {
        set DoneWaiting to true.
      }
    } else {
      wait 1.
    }
  }

  unlock steering.
}

Function distanceToGround {
  return boundingbox:bottomaltradar.
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
  parameter TimeTill is 30.

  local HorVelVec is vxcl(up:vector, -velocity:surface).

  if vdot(HorVelVec, -ship:velocity:orbit) < 0 {
    set HorVelVec to HorVelVec * -1.
  }

  local NodeList is TX_lib_man_exe["NodeFromVector"](HorVelVec, time:seconds + TimeTill).
  TX_lib_man_exe["ExecuteManeuver"](NodeList).
}

print "read lib_landing".
