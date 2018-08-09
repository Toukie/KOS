// Dont use this when matching inclination with planets out of current SOI

{

global T_Inclination is lexicon(
  "RelativeAngleCalculation", RelativeAngleCalculation@,
  "AscenDescenFinder", AscenDescenFinder@,
  "DeltaVTheta", DeltaVTheta@,
  "InclinationMatcher", InclinationMatcher@
  ).

Function RelativeAngleCalculation {

  Parameter TargetDestination.

  set Inclin1 to ship:orbit:inclination.
  set Inclin2 to TargetDestination:orbit:inclination.

  set Omega1  to ship:orbit:LAN.
  set Omega2  to TargetDestination:orbit:LAN.

  set a1 to (sin(Inclin1)*cos(Omega1)).
  set a2 to (sin(Inclin1)*sin(Omega1)).
  set a3 to cos(Inclin1).
  set a123 to v(a1, a2, a3).

  set b1 to (sin(Inclin2)*cos(Omega2)).
  set b2 to (sin(Inclin2)*sin(Omega2)).
  set b3 to cos(Inclin2).
  set b123 to v(b1, b2, b3).

  set thetachange to ARCcos(vdot(a123, b123)).
  //print "theta: " + thetachange.
}

Function AscenDescenFinder {

  parameter TarShip.

  set NormalVector1 to vcrs(ship:position - ship:body:position, ship:velocity:orbit).
  set NormalVector2 to vcrs(TarShip:position - TarShip:body:position, TarShip:velocity:orbit).

  // DNvector is the cross product of both normal vectors (both are on the same plane)
  set DNvector to vcrs(NormalVector2, NormalVector1).

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

}

Function DeltaVTheta {
  parameter TrueAnomaly.
  parameter ThetaNeeded.

  set SMA    to ship:orbit:semimajoraxis.
  set rad1   to SMA*(1- ecc*cos(TrueAnomaly)).
  set velo   to SQRT(body:mu*((2/rad1)-(1/SMA))).
  set dvincl to (2*velo*sin(ThetaNeeded/2)).
}

Function InclinationMatcher {

  Parameter TargetDestination.

  AscenDescenFinder(TargetDestination).

  T_TrueAnomaly["ETAToTrueAnomaly"](ship, TrueAnomAN).
  set TimeAN to TimeTillDesiredTrueAnomaly.
  T_TrueAnomaly["ETAToTrueAnomaly"](ship, TrueAnomDN).
  set TimeDN to TimeTillDesiredTrueAnomaly.

  RelativeAngleCalculation(TargetDestination).

  DeltaVTheta(TrueAnomAN, ThetaChange).
  set ANDv to dvincl.

  DeltaVTheta(TrueAnomDN, ThetaChange).
  set DNDv to dvincl.

  set DvNeeded to min(ANDv, DNDv).

  if ANDv < DNDv {
    set TimeNeeded to TimeAN.
    set DvNeeded to -1*DvNeeded.
  } else {
    set TimeNeeded to TimeDN.
  }

  //set InclinationManeuverList to list(time:seconds + TimeNeeded, 0, DvNeeded, 0).
  //ResultFinder(InclinationManeuverList, "inclination", "timeplus_timemin").
  //DvCalc(GlobalInput).

  local InputList is list(time:seconds + TimeNeeded, 0, DvNeeded, 0).
  local NewScoreList is list(TargetDestination).
  local NewRestrictionList is IndexFiveFolderder("realnormal_antinormal_radialout_radialin_timeplus_timemin").
  set FinalMan to T_HillUni["ResultFinder"](InputList, "Inclination", NewScoreList, NewRestrictionList).

  D_ManExe["DvCalc"](FinalMan).
  D_ManExe["TimeTillManeuverBurn"](FinalManeuver:eta, DvNeeded).
  D_ManExe["PerformBurn"](EndDv, StartT).

  RelativeAngleCalculation(TargetDestination).
}
}
print "read lib_inclination".
