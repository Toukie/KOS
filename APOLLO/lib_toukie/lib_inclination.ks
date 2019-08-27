

// Dont use this when matching inclination with planets out of current SOI

global TX_lib_inclination is lexicon(
  "RelativeAngleCalculation", RelativeAngleCalculation@,
  "AscenDescenFinder", AscenDescenFinder@,
  "DeltaVTheta", DeltaVTheta@,
  "InclinationMatcher", InclinationMatcher@,
  "InclinationSetter", InclinationSetter@,
  "InclinationCorrection", InclinationCorrection@
  ).
  local TXStopper is "[]".

Function RelativeAngleCalculation {

  parameter TargetDestination.

  local Inclin1 is ship:orbit:inclination.
  local Inclin2 is TargetDestination:orbit:inclination.

  local Omega1  is ship:orbit:LAN.
  local Omega2  is TargetDestination:orbit:LAN.

  local a1 is (sin(Inclin1)*cos(Omega1)).
  local a2 is (sin(Inclin1)*sin(Omega1)).
  local a3 is cos(Inclin1).
  local a123 is v(a1, a2, a3).

  local b1 is (sin(Inclin2)*cos(Omega2)).
  local b2 is (sin(Inclin2)*sin(Omega2)).
  local b3 is cos(Inclin2).
  local b123 is v(b1, b2, b3).

  local  ThetaChange is ARCcos(vdot(a123, b123)).
  return ThetaChange.
}

Function AscenDescenFinder {

  parameter TarShip.

  local NormalVector1 is vcrs(ship:position - ship:body:position, ship:velocity:orbit).
  local NormalVector2 is vcrs(TarShip:position - TarShip:body:position, TarShip:velocity:orbit).

  // DNvector is the cross product of both normal vectors (both are on the same plane)
  local DNvector is vcrs(NormalVector2, NormalVector1).
  local TrueAnomDN is "x".
  local TrueAnomAN is "x".

  // TA of DN
  if vdot(DNvector + body:position, ship:velocity:orbit) > 0 {
    set TrueAnomDN to ship:orbit:trueanomaly + vang(DNvector, ship:position - ship:body:position).
  } else {
    set TrueAnomDN to ship:orbit:trueanomaly - vang(DNvector, ship:position - ship:body:position).
  }

  until TrueAnomDN > 0 {
    set TrueAnomDN to TrueAnomDN + 360.
    wait 0.
  }

  if TrueAnomDN > 360 {
    set TrueAnomDN to TrueAnomDN -360.
  }

  // TA of AN
  set TrueAnomAN to TrueAnomDN + 180.
  until TrueAnomAN < 360 {
    set TrueAnomAN to TrueAnomAN -360.
  }

  local ANDNList is list(TrueAnomAN, TrueAnomDN).
  return ANDNList.

}

Function DeltaVTheta {
  parameter TrueAnomaly.
  parameter ThetaNeeded.

  local ecc    is ship:orbit:eccentricity.
  local SMA    is ship:orbit:semimajoraxis.
  local rad1   is SMA*(1- ecc*cos(TrueAnomaly)).
  local velo   is SQRT(body:mu*((2/rad1)-(1/SMA))).
  local DvIncl is (2*velo*sin(ThetaNeeded/2)).
  return DvIncl.
}

// for matching incl with a target
Function InclinationMatcher {

  Parameter TargetDestination.
  // Mun has 0 degrees inclination so an AN DN pos can be found

  local ANDNList is AscenDescenFinder(TargetDestination).
  local TrueAnomAN is ANDNList[0].
  local TrueAnomDN is ANDNList[1].
  local TimeNeeded is "x".

  local TimeAN is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, TrueAnomAN).
  local TimeDN is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, TrueAnomDN).
  local ThetaChange is RelativeAngleCalculation(TargetDestination).

  local ANDv is DeltaVTheta(TrueAnomAN, ThetaChange).
  local DNDv is DeltaVTheta(TrueAnomDN, ThetaChange).

  local DvNeeded is min(ANDv, DNDv).

  if ANDv < DNDv {
    set TimeNeeded to TimeAN.
    set DvNeeded to -1*DvNeeded.
  } else {
    set TimeNeeded to TimeDN.
  }



  local InputList is list(time:seconds + TimeNeeded, 0, DvNeeded, 0).
  local NewScoreList is list(TargetDestination).
  local BestNode is TX_lib_hillclimb_main["Hillclimber"](InputList, NewScoreList, TX_lib_hillclimb_score["InclinationScore"], "radial_time").
  TX_lib_man_exe["ExecuteManeuver"](BestNode).
}

// for setting an incl without target
Function InclinationSetter {
  Parameter TargetInclination.

  local TrueAnomAN is 360 - ship:orbit:argumentofperiapsis.
  local TrueAnomDN is TrueAnomAN + 180.

  if TrueAnomAN < 0 {
    set TrueAnomAN to TrueAnomAN + 360.
  }

  if TrueAnomDN > 360 {
    set TrueAnomDN to TrueAnomDN - 360.
  }

  local TimeNeeded is "x".
  local TimeAN is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, TrueAnomAN).
  local TimeDN is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, TrueAnomDN).
  local ThetaChange is abs(ship:orbit:inclination - TargetInclination).

  local ANDv is DeltaVTheta(TrueAnomAN, ThetaChange).
  local DNDv is DeltaVTheta(TrueAnomDN, ThetaChange).

  local DvNeeded is min(ANDv, DNDv).

  if ANDv < DNDv {
    set TimeNeeded to TimeAN.
    set DvNeeded to -1*DvNeeded.
  } else {
    set TimeNeeded to TimeDN.
  }

  if abs(ship:orbit:inclination - TargetInclination) > 0.1 {
    local InputList is list(time:seconds + TimeNeeded, 0, DvNeeded, 0).

    local NewRestrictionList is "x".
    if abs(ship:orbit:inclination - TargetInclination) > 90 {
      print "over 90 deg diff".
      set NewRestrictionList to "time_prograde".
    } else {
      print "under 90 deg diff".
      set NewRestrictionList to "time_prograde_radial".
    }

    local NewScoreList is list(TargetInclination).
    local BestNode is TX_lib_hillclimb_main["Hillclimber"](InputList, NewScoreList, TX_lib_hillclimb_score["InclinationScore"], NewRestrictionList).
    TX_lib_man_exe["ExecuteManeuver"](BestNode).
  }
}

Function InclinationCorrection {
  parameter TargetInclination.
  parameter TargetTime is 0.

  local TargetTime is TargetTime + time:seconds.

  local dIncl is abs(TargetInclination - ship:orbit:inclination).
  local RotateAngle is angleaxis(dIncl, positionat(ship, TargetTime)-ship:body:position).
  local TarVec is velocityat(ship, TargetTime):orbit * RotateAngle.
  local ManVec is TarVec - velocityat(ship, TargetTime):orbit.

  local NodeList is TX_lib_man_exe["NodeFromVector"](ManVec, TargetTime).

  return NodeList.
}



print "read lib_inclination".
