global TX_lib_rendezvous is lexicon (
  "MatchOrbit", MatchOrbit@,
  "RendezvousSetup", RendezvousSetup@,
  "FinalApproach", FinalApproach@,
  "FullRendezvous", FullRendezvous@
).

local TXStopper is "[]".

Function MatchOrbit {
  Parameter TargetVessel.

  local ThetaChange is TX_lib_inclination["RelativeAngleCalculation"](TargetVessel).

  until ThetaChange < 0.04 {
    TX_lib_inclination["InclinationMatcher"](TargetVessel).
    set ThetaChange to TX_lib_inclination["RelativeAngleCalculation"](TargetVessel).
  }

  print "Circularizing".

  if abs(ship:orbit:apoapsis + body:radius - TargetVessel:orbit:semimajoraxis) < abs(ship:orbit:periapsis + body:radius - TargetVessel:orbit:semimajoraxis) {
    TX_lib_man_exe["Circularization"](apoapsis).
  } else {
    TX_lib_man_exe["Circularization"](periapsis).
  }

  RendezvousSetup(TargetVessel).

  // ship has either Pe or Ap at Targets Ap
  if abs(ship:orbit:apoapsis - TargetVessel:orbit:apoapsis) < abs(ship:orbit:periapsis - TargetVessel:orbit:apoapsis) {
    local DvNeeded is TX_lib_calculations["VisViva"](ship:orbit:apoapsis, (ship:orbit:apoapsis + TargetVessel:orbit:periapsis)/2 + body:radius).
    local BestNode is list(time:seconds + eta:apoapsis, 0, 0, DvNeeded).
    TX_lib_man_exe["ExecuteManeuver"](BestNode).
  } else {
    local DvNeeded is TX_lib_calculations["VisViva"](ship:orbit:periapsis, (ship:orbit:periapsis + TargetVessel:orbit:periapsis)/2 + body:radius).
    local BestNode is list(time:seconds + eta:periapsis, 0, 0, DvNeeded).
    TX_lib_man_exe["ExecuteManeuver"](BestNode).
  }

}

Function RendezvousSetup {
  Parameter TargetVessel.

  local Per1 is time:seconds + eta:periapsis.
  local Per2 is time:seconds + TX_lib_true_anomaly["ETAToTrueAnomaly"](TargetVessel, 0).

  local vec1 is positionat(ship, per1)-ship:body:position.
  local vecd1 is vecdraw(ship:body:position, vec1 , red, "per1", 1.0, false, 0.2).
  set vecd1:startupdater to {return ship:body:position.}.

  local vec2 is positionat(target, per2)-ship:body:position.
  local vecd2 is vecdraw(ship:body:position, vec2, red, "per2", 1.0, false, 0.2).
  set vecd2:startupdater to {return body:position.}.

  local TrueAnomalyTargetPer is "x".

  if vdot(vcrs(vec1, vec2), v(0,1,0)) > 0 {
    set TrueAnomalyTargetPer to 360-vang(vec1,vec2).
    //HUDtext("POS", 30, 2, 30, white, true).
  } else {
    set TrueAnomalyTargetPer to vang(vec1,vec2).
    //HUDtext("NEG", 30, 2, 30, white, true).
  }

  local TimeTargetPeriapsis is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, TrueAnomalyTargetPer).

  //print "Time till target periapsis:   " + TimeTargetPeriapsis.

  local SMA is ship:orbit:semimajoraxis.
  local Ecc is ship:orbit:eccentricity.
  local CurRadiusAtTargetPeriapsis is (SMA * ( (1-ecc^2) / (1+ecc*cos(TrueAnomalyTargetPer))))-body:radius.
  local DvNeeded is TX_lib_calculations["VisViva"](CurRadiusAtTargetPeriapsis, (CurRadiusAtTargetPeriapsis + TargetVessel:orbit:apoapsis)/2 + body:radius).
  local BestNode is list(time:seconds + TimeTargetPeriapsis, 0, 0, DvNeeded).
  TX_lib_man_exe["ExecuteManeuver"](BestNode).

  // go to tar periapsis
  // burn till

}

Function FinalApproach {
  Parameter TargetVessel.
  Parameter StepsNeeded is 5.

  // when im at Ap how long will it take for target to be there
  local TargetAtAP is TX_lib_true_anomaly["ETAToTrueAnomaly"](TargetVessel, 180).
  //local TargetAtAP is TargetAtAP - eta:apoapsis.
  print round(TargetAtAP).
  local CurPeriod is ship:orbit:period.
  local TarPeriod is CurPeriod + (TargetAtAP/StepsNeeded).

  local TarSMA is (((TarPeriod^2)*ship:body:mu)/(4*constant:pi^2))^(1/3).
  local DvNeeded is TX_lib_calculations["VisViva"](ship:orbit:apoapsis, TarSMA).
  local ApproachNode is list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
  local RealNode is node(ApproachNode[0], ApproachNode[1], ApproachNode[2], ApproachNode[3]).
  add RealNode.
  wait 0.

  if nextnode:orbit:hasnextpatch {
    local NoMorePatch is false.
    until NoMorePatch = true {
      remove nextnode.
      wait 0.
      set StepsNeeded to StepsNeeded + 1.

      set CurPeriod to ship:orbit:period.
      set TarPeriod to CurPeriod + (TimeTillDesiredTrueAnomaly/StepsNeeded).

      set TarSMA to (((TarPeriod^2)*ship:body:mu)/(4*constant:pi^2))^(1/3).

      local DvNeeded is TX_lib_calculations["VisViva"](ship:orbit:apoapsis, TarSMA).
      set ApproachNode to list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
      local RealNode is node(ApproachNode[0], ApproachNode[1], ApproachNode[2], ApproachNode[3]).
      add RealNode.
      wait 0.

      if nextnode:orbit:hasnextpatch = false {
        set NoMorePatch to true.
      }
    }
  }

  remove nextnode.
  wait 0.

  TX_lib_man_exe["ExecuteManeuver"](ApproachNode).

  local InitialOrbits is time:seconds + (StepsNeeded - 1) * ship:orbit:period.
  warpto(InitialOrbits).
  wait until time:seconds > InitialOrbits.
  wait 1.

  local ApPeWarp is "x".
  if abs(ship:orbit:apoapsis - TargetVessel:orbit:apoapsis) < abs(ship:orbit:periapsis - TargetVessel:orbit:apoapsis) {
    set ApPeWarp to time:seconds + eta:apoapsis -30.
  } else {
    set ApPeWarp to time:seconds + eta:periapsis -30.
  }
  warpto(ApPeWarp).
  wait until time:seconds > ApPeWarp.
}

Function MainRelVelKill {
  Parameter TargetVessel.

  local VectorNeeded is (TargetVessel:velocity:orbit - ship:velocity:orbit).
  local BestNode is TX_lib_man_exe["NodeFromVector"](VectorNeeded).
  TX_lib_man_exe["ExecuteManeuver"](BestNode).
}

Function GoToTarget {
  Parameter TargetVessel.
  Parameter SpeedNeeded.

  local InitialVector is TargetVessel:position - ship:position.
  local VectorNeeded  is InitialVector:normalized * SpeedNeeded.
  local NodeList is TX_lib_man_exe["NodeFromVector"](VectorNeeded).
  TX_lib_man_exe["ExecuteManeuver"](NodeList).
}

Function VeryFinalApproach {
  parameter TargetVessel.

  local lock Distance to (TargetVessel:position - ship:position):mag.
  local OffTarget is true. // just killed relative velocity, needs to go to the target
  local FirstRun is true.

  local lock TargetVec to TargetVessel:position.
  local lock RelativeVelVec to (ship:velocity:orbit - TargetVessel:velocity:orbit).

  until Distance < 300 {
    if vdot(TargetVec, RelativeVelVec) < 0 {
      set warp to 0.
      wait until kuniverse:timewarp:rate = 1.
      set OffTarget to true.
    } else {
      if FirstRun = false {
        set OffTarget to false.
      }
    }

    if OffTarget = true {
      if FirstRun = false {
        set warp to 0.
        wait until kuniverse:timewarp:rate = 1.
        MainRelVelKill(TargetVessel).
      }

      if Distance > 15000 {
        TX_lib_steering["SteeringTarget"](TargetVessel).
        GoToTarget(TargetVessel, 50).
        TX_lib_steering["SteeringTargetRet"](TargetVessel).
        set warp to 2.
      } else if Distance > 3000 {
        TX_lib_steering["SteeringTarget"](TargetVessel).
        GoToTarget(TargetVessel, 30).
        TX_lib_steering["SteeringTargetRet"](TargetVessel).
        set warp to 2.
      } else if Distance > 1500 {
        TX_lib_steering["SteeringTarget"](TargetVessel).
        GoToTarget(TargetVessel, 20).
        TX_lib_steering["SteeringTargetRet"](TargetVessel).
        set warp to 1.
      }
    }

    if Distance < 1500 {
      if FirstRun = false {
        set warp to 0.
        wait until kuniverse:timewarp:rate = 1.
        MainRelVelKill(TargetVessel).
      }
      TX_lib_steering["SteeringTarget"](TargetVessel).
      GoToTarget(TargetVessel, 15).
      TX_lib_steering["SteeringTargetRet"](TargetVessel).
      wait until Distance < 299.
    }

    set FirstRun to false.
    wait 0.
  }
  set warp to 0.
  wait until kuniverse:timewarp:rate = 1.
  MainRelVelKill(TargetVessel).

}

Function FullRendezvous {
  Parameter TargetVessel.

  local Distance is (TargetVessel:position - ship:position):mag.
  if Distance > 30000 {
    MatchOrbit(TargetVessel).
    FinalApproach(TargetVessel).
  }
  MainRelVelKill(TargetVessel).
  VeryFinalApproach(TargetVessel).
}

print "read lib_rendezvous".
