global TX_lib_man_exe is lexicon(
  "Circularization", Circularization@,
  "ChangeApoapsis", ChangeApoapsis@,
  "ChangePeriapsis", ChangePeriapsis@,
  "ExecuteManeuver", ExecuteManeuver@,
  "Decircularization", Decircularization@,
  "CircOrbitTarHeight", CircOrbitTarHeight@,
  "NodeFromVector", NodeFromVector@
  ).
  local TXStopper is "[]".

Function Circularization {
  parameter ApoPer is "apoapsis".

  local EtaTime is 0.
  local AtApoPer is 0.

  if ApoPer = "apoapsis" {
    set EtaTime to eta:apoapsis.
    set AtApoPer to ship:orbit:apoapsis.
  } else {
    set EtaTime to eta:periapsis.
    set AtApoPer to ship:orbit:periapsis.
  }

  local DvNeeded is TX_lib_calculations["VisViva"](AtApoPer, (AtApoPer+ship:body:radius)).
  local MyNodeList is list(time:seconds + EtaTime, 0, 0, DvNeeded).

  //local BestNode is TX_lib_hillclimb_main["Hillclimber"](MyNodeList, "none", TX_lib_hillclimb_score["CircScore"], "time_normal").
  TX_lib_man_exe["ExecuteManeuver"](MyNodeList).
}

Function ChangeApoapsis {
  parameter ParameterList.

  local TargetSMA is (ship:orbit:periapsis+ParameterList[0])/2 + ship:body:radius.
  local DvNeeded is TX_lib_calculations["VisViva"](ship:orbit:periapsis, TargetSMA).
  local MyNodeList is list(time:seconds + eta:periapsis, 0, 0, DvNeeded).

  local BestNode is TX_lib_hillclimb_main["Hillclimber"](MyNodeList, ParameterList, TX_lib_hillclimb_score["ApoapsisScore"], "normal").
  TX_lib_man_exe["ExecuteManeuver"](BestNode).
}

Function ChangePeriapsis {
  parameter ParameterList.

  local TargetSMA is (ship:orbit:apoapsis+ParameterList[0])/2 + ship:body:radius.
  local DvNeeded is TX_lib_calculations["VisViva"](ship:orbit:apoapsis, TargetSMA).
  local MyNodeList is list(time:seconds + eta:apoapsis, 0, 0, DvNeeded).

  local BestNode is TX_lib_hillclimb_main["Hillclimber"](MyNodeList, ParameterList, TX_lib_hillclimb_score["PeriapsisScore"], "normal").
  TX_lib_man_exe["ExecuteManeuver"](BestNode).
}

Function Decircularization {
  parameter TargetTA is 180.
  parameter NewPer is -10000.
  parameter DecircNow is false.

  local ETATA is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, TargetTA).
  local RadiusAtTA is ship:orbit:semimajoraxis * (1 - ship:orbit:eccentricity^2) / (1 + ship:orbit:eccentricity * cos(TargetTA)) - body:radius.

  if DecircNow = true {
    set ETATA to 0.
    set RadiusAtTA to altitude.
  }

  local DvNeeded is TX_lib_calculations["VisViva"](RadiusAtTA, (RadiusAtTA + NewPer)/2 + body:radius).
  local MyNodeList is list(time:seconds + ETATA, 0, 0, DvNeeded).

  TX_lib_man_exe["ExecuteManeuver"](MyNodeList).
}

Function CircOrbitTarHeight {
  parameter TarHeight.

  local i is 0.

  until i = 2 {
    if abs(TarHeight - ship:orbit:periapsis) < abs(TarHeight - ship:orbit:apoapsis) {
      ChangeApoapsis(list(TarHeight)).
    } else {
      ChangePeriapsis(list(TarHeight)).
    }
    set i to i + 1.
  }


}

/// Perform burn

Function TimeTillManeuverBurn {

  Parameter StartTime.
  Parameter TargetManeuver is nextnode.
  Parameter ThrustLimit is 100.

  local DvNeeded is TargetManeuver:deltav:mag.
  local LocalMaxThrust is max(0.001, maxthrust).

  local Accel0 is (LocalMaxThrust/mass).
  local eIsp is 0.
  local EngList is list().

  list engines in EngList.
  for eng in EngList{
    local EngMax is max(0.001, eng:maxthrust).
    set eIsp to eisP + ((EngMax/LocalMaxThrust)*eng:isp).
  }
  local Ve is eIsp*9.80665.

  if Ve = 0 {
    HUDtext("Error: no active engines, reboot with active engines", 15, 2, 30, red, true).
  }

  local FinalMass is (mass*constant():e^(-1*DvNeeded/Ve)).
  local Accel1 is (LocalMaxThrust/FinalMass).
  local BurnTime is (DvNeeded/((Accel0 + Accel1)/2)).
  local BurnTime is BurnTime * (100/ThrustLimit).

  local ETAStartT is (StartTime - BurnTime/2).
  local StartT is (ETAStartT+time:seconds).
  return StartT.
}

Function PerformBurn {

  Parameter StartT.
  Parameter ThrustLimit is 100.

  //log nextnode:deltav:mag + ", " to burnstats.ks.

  local StopBurn is false.
  sas off.

  TX_lib_steering["SteeringManeuver"]().

  if nextnode:deltav:mag < 0.02 {
    set StopBurn to true.
  }

  warpto(StartT-10).

  lock steering to nextnode:deltav.
  wait until vang(ship:facing:vector, nextnode:deltav) < 0.1.
  local ShipFacingVec is ship:facing:vector.
  local lock ManVec to nextnode:deltav:normalized.

  wait until time:seconds > StartT.

  local OldDeltaVList is list().
  local OldDeltaVCount is 0.
  local OldDeltaVAverage is 10^(-9).
  local NewDeltaVList is list().
  local NewDeltaVCount is 0.
  local NewDeltaVAverage is 0.

  until StopBurn = true {

    if OldDeltaVCount < 25 {
      set OldDeltaVCount to OldDeltaVCount + 1.
      set OldDeltaVAverage to 10^(-9).
      OldDeltaVList:add(nextnode:deltav:mag).
    } else {
      for DeltaVMag in OldDeltaVList {
        set OldDeltaVAverage to OldDeltaVAverage + DeltaVMag.
      }
      set OldDeltaVAverage to round((OldDeltaVAverage / OldDeltaVCount), 5).
      set OldDeltaVCount to 0.
    }
    wait 0.

    if NewDeltaVCount < 25 {
      set NewDeltaVCount to NewDeltaVCount + 1.
      set NewDeltaVAverage to 0.
      NewDeltaVList:add(nextnode:deltav:mag).
    } else {
      for DeltaVMag in NewDeltaVList {
        set NewDeltaVAverage to NewDeltaVAverage + DeltaVMag.
      }
      set NewDeltaVAverage to round((NewDeltaVAverage / NewDeltaVCount), 5).
      set NewDeltaVCount to 0.
    }
    wait 0.

    local LocalMaxThrust is max(0.001, maxthrust).
    local eIsp is 0.
    local EngList is list().

    list engines in EngList.
    for eng in EngList{
      local EngMax is max(10^(-9), eng:maxthrust).
      set eIsp to eisP + ((EngMax/LocalMaxThrust)*eng:isp).
    }
    local Ve is eIsp*9.80665.
    local CurDv   to Ve * ln(ship:mass / ship:drymass).
    local MaxAcc  to MaxThrust/ship:mass.
    local MaxAcc  to max(0.001, MaxAcc).

    lock throttle to min(nextnode:deltav:mag/MaxAcc, 1).

    if MaxThrust > 0 {
      local CurThrust is throttle * MaxThrust.
      if CurThrust < 0.1 {
        lock throttle to 0.
        HUDtext("Throttle near 0, ending burn.", 5, 2, 30, green, false).
        set StopBurn to true.
      }
    }

    if nextnode:deltav:mag < 0.01 {
        lock throttle to 0.
        HUDtext("Dv left very small, ending burn.", 5, 2, 30, green, false).
        wait 3.
        set StopBurn to true.
      }

    if vdot(ShipFacingVec, ManVec) < 0 {
      lock throttle to 0.
      HUDtext("Dv marker to far from starting position.", 5, 2, 30, green, false).
      wait 3.
      set StopBurn to true.    }

    if OldDeltaVAverage < NewDeltaVAverage {
      lock throttle to 0.
      HUDtext("OldDv: " + OldDeltaVAverage, 5, 2, 30, green, true).
      HUDtext("NewDv: " + NewDeltaVAverage, 5, 2, 30, green, true).
      wait 1.
      set StopBurn to true.
    }
  }
}

Function ExecuteManeuver {
  Parameter NodeWorthyList.

  local FinalManeuver is node(NodeWorthyList[0], NodeWorthyList[1], NodeWorthyList[2], NodeWorthyList[3]).
  add FinalManeuver.
  wait 1.

  if nextnode:deltav:mag > 0.1 {
    local TimeTill is TimeTillManeuverBurn(FinalManeuver:eta, FinalManeuver).
    PerformBurn(TimeTill).
    unlock steering.
  }
  remove nextnode.
}

Function NodeFromVector {
  Parameter VecTarget.
  Parameter NodeTime is time:seconds.
  Parameter LocalBody is ship:body.

  local vecNodePrograde is velocityat(ship,nodeTime):orbit.
  local vecNodeNormal is vcrs(vecNodePrograde,positionat(ship,nodeTime) - localBody:position).
  local vecNodeRadial is vcrs(vecNodeNormal,vecNodePrograde).

  local nodePrograde is vdot(vecTarget,vecNodePrograde:normalized).
  local nodeNormal is vdot(vecTarget,vecNodeNormal:normalized).
  local nodeRadial is vdot(vecTarget,vecNodeRadial:normalized).

  return list(nodeTime,nodeRadial,nodeNormal,nodePrograde).
}


print "read lib_man_exe".
