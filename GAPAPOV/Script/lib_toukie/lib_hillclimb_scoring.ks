{

global T_ScoreOptions is lex (
  "Circularize",     ScoreCircularize@,
  "Inclination",     ScoreInclination@,
  "Apoapsis",        ScoreApoapsis@,
  "Periapsis",       ScorePeriapsis@,
  "ApoapsisMatch",   ScoreApoMatch@,
  "PerApoMatch",     ScorePerApoMatch@,
  "PerPerMatch",     ScorePerPerMatch@,
  "MoonTransfer",    ScoreMoonTransfer@,
  "Interplanetary",  ScoreInterplanetary@,
  "FinalCorrection", ScoreFinalCorrection@
  ).

Function ScoreCircularize {
  Parameter ScoreList.

  set ScoreManeuver to nextnode.

  if ScoreList:length = 2 {
    if ScoreManeuver:orbit:body = ScoreList[1] {
      return ScoreManeuver:orbit:eccentricity.
    } else {
      return 2^64.
    }
  }

  return ScoreManeuver:orbit:eccentricity.
}

Function ScoreInclination {
  Parameter ScoreList.

  set ScoreManeuver to nextnode.

  if ScoreList[0]:istype("scalar") = true {
    local WantedInclin is ScoreList[0].
    set ThetaChange to abs(ScoreManeuver:orbit:inclination - WantedInclin).
    if  ThetaChange < 0.002 {
      set ThetaChange to 0.
    }
    return ThetaChange.
  }

  local TargetDestination is ScoreList[0].

  local Inclin1 is ScoreManeuver:orbit:inclination.
  local Inclin2 is TargetDestination:orbit:inclination.

  local Omega1  is ScoreManeuver:orbit:LAN.
  local Omega2  is TargetDestination:orbit:LAN.

  set a1 to (sin(Inclin1)*cos(Omega1)).
  set a2 to (sin(Inclin1)*sin(Omega1)).
  set a3 to cos(Inclin1).
  set a123 to v(a1, a2, a3).

  set b1 to (sin(Inclin2)*cos(Omega2)).
  set b2 to (sin(Inclin2)*sin(Omega2)).
  set b3 to cos(Inclin2).
  set b123 to v(b1, b2, b3).

  set ThetaChange to ARCcos(vdot(a123, b123)).
  set Result to ThetaChange.

  if ThetaChange < 0.002 {
    set ThetaChange to 0.
  }

  return ThetaChange.
}

Function ScoreApoapsis {
  Parameter ScoreList.

  set ScoreManeuver to nextnode.
  local CurrentHeight is ScoreManeuver:orbit:apoapsis.
  local TargetHeight  is ScoreList[0].

  return round(abs(CurrentHeight - TargetHeight)/TargetHeight, 10).
}

Function ScorePeriapsis {
  Parameter ScoreList.

  set ScoreManeuver to nextnode.
  local CurrentHeight is ScoreManeuver:orbit:periapsis.
  local TargetHeight  is ScoreList[0].

  return round(abs(CurrentHeight - TargetHeight)/TargetHeight, 10).
}

Function OrbitParamGetter {
  Parameter ObjectName.
  Parameter OrbitalParameter.

  if OrbitalParameter = "apoapsis" {
    return ObjectName:orbit:apoapsis.
  }

  if OrbitalParameter = "periapsis" {
    return ObjectName:orbit:periapsis.
  }
}

Function ScoreVarMatch {
  Parameter ScoreList.
  Parameter ApoPerList.

  set ScoreManeuver to nextnode.
  local TargetDestination is ScoreList[0].
  local Value1 is OrbitParamGetter(ScoreManeuver, ApoPerList[0]).
  local Value2 is OrbitParamGetter(TargetDestination, ApoPerList[1]).
  local Value3 is OrbitParamGetter(TargetDestination, ApoPerList[2]).

  return round(abs(Value1 - Value2)/Value3, 10).
}

Function ScoreApoMatch {
  Parameter ScoreList.

  local ApoPerList is list("apoapsis", "apoapsis", "apoapsis").
  return ScoreVarMatch(ScoreList, ApoPerList).
}

Function ScorePerApoMatch {
  Parameter ScoreList.

  local ApoPerList is list("periapsis", "apoapsis", "apoapsis").
  return ScoreVarMatch(ScoreList, ApoPerList).
}

Function ScorePerPerMatch {
  Parameter ScoreList.

  local ApoPerList is list("periapsis", "periapsis", "periapsis").
  return ScoreVarMatch(ScoreList, ApoPerList).
}

Function ScoreMoonTransfer {
  Parameter ScoreList.

  set ScoreManeuver to nextnode.
  local TargetBody        is ScoreList[0].
  local TargetPeriapsis   is ScoreList[1].
  local TargetInclination is ScoreList[2].
  local InterceptCheck  is false.

  if TargetInclination = 0 {
    set TargetInclination to 0.01.
  }

  if ScoreManeuver:orbit:hasnextpatch = true {
    if ScoreManeuver:orbit:nextpatch:body = TargetBody {
      set InterceptCheck     to true.
      set TransferPenalty    to 0.
      set InclinationPenalty to round((abs(ScoreManeuver:orbit:nextpatch:inclination - TargetInclination)/TargetInclination), 2).
      set PeriapsisPenalty   to round((abs(ScoreManeuver:orbit:nextpatch:periapsis - TargetPeriapsis)/TargetPeriapsis), 1).
    }
  }

  if InterceptCheck = false {
    if ScoreManeuver:orbit:hasnextpatch = true {
      set TransferPenalty    to (20^64)/2.
      set PeriapsisPenalty   to (20^64)/2.
      set InclinationPenalty to 10^5.
    } else {
      set TransferPenalty    to T_Other["ClosestApproachRefiner"](TargetBody).
      set TransferPenalty    to round(TransferPenalty/(10^3)).
      set PeriapsisPenalty   to 10000.
      set InclinationPenalty to 10^5.
    }
  }
  //clearscreen.
  set TotalPenalty to TransferPenalty + PeriapsisPenalty + InclinationPenalty.
  print "TransferPenalty:   " + TransferPenalty + "                   " at(1,20).
  print "PeriapsisPenalty:  " + PeriapsisPenalty + "                  " at(1,21).
  print "InclinationPenalty " + InclinationPenalty + "                " at(1,22).
  print "TotalPenalty:      " + TotalPenalty + "                      " at(1,23).
  return TotalPenalty.
}

Function ScoreInterplanetary {
  Parameter ScoreList.

  set ScoreManeuver to nextnode.
  local TargetBody      is ScoreList[0].
  local TargetPeriapsis is ScoreList[1].

  set TransferPenalty to 10000.
  set SOIexitPenalty  to 10^6.
  set PeriapsisPenalty to 10000.

  if ScoreManeuver:orbit:hasnextpatch = true {
    if ScoreManeuver:orbit:nextpatch:body = TargetBody {
      print "A - okay" at(1,35).
      set PeriapsisPenalty to round((abs(ScoreManeuver:orbit:nextpatch:periapsis - TargetPeriapsis)/TargetPeriapsis), 1).
      set TransferPenalty to 0.
      set SOIexitPenalty to 0.
    } if ScoreManeuver:orbit:nextpatch:hasnextpatch = true {
        if ScoreManeuver:orbit:nextpatch:nextpatch:body = TargetBody {
          print "B - okay" at(1,35).
          set PeriapsisPenalty to round((abs(ScoreManeuver:orbit:nextpatch:nextpatch:periapsis - TargetPeriapsis)/TargetPeriapsis), 1).
          set TransferPenalty to 0.
          set SOIexitPenalty to 0.
        }
    }
  }

  if TransferPenalty <> 0 {
    print "C - okay" at(1,35).
    if ScoreManeuver:orbit:hasnextpatch = false and ScoreManeuver:orbit:body <> TargetBody:body {
      set SOIexitPenalty to round(ship:body:soiradius/ScoreManeuver:orbit:apoapsis).
    } else {
      set SOIexitPenalty to 0.

      print T_ClosestApp["ClosestApproachFinder"](TargetBody) at(1,36).
      set TransferPenalty to T_ClosestApp["ClosestApproachFinder"](TargetBody).
      set TransferPenalty to round(TransferPenalty/(10^6)).
      set PeriapsisPenalty to 10000.
    }
  }

  wait 0.
  //clearscreen.
  print "TransferPenalty   " + TransferPenalty + "            " at(1,20).
  print "SOIexitPenalty    " + SOIexitPenalty + "             " at(1,21).
  print "PeriapsisPenalty  " + PeriapsisPenalty + "           " at(1,22).
  print "Total Penalty     " + (TransferPenalty+SOIexitPenalty+PeriapsisPenalty) + "          " at(1,23).
  return (TransferPenalty+SOIexitPenalty+PeriapsisPenalty).
}

Function ScoreFinalCorrection {
  Parameter ScoreList.

  set ScoreManeuver to nextnode.
  local TargetBody        is ScoreList[0].
  local TargetPeriapsis   is ScoreList[1].
  local TargetInclination is ScoreList[2].

  if TargetInclination = 0 {
    set TargetInclination to 0.01.
  }

  set PeriapsisPenalty to 10^9.
  set InclinationPenalty to 10^9.

  set PeriapsisPenalty to round((abs(ScoreManeuver:orbit:periapsis - TargetPeriapsis)/TargetPeriapsis), 2).

  if abs(ScoreManeuver:orbit:inclination - TargetInclination) < 15 {
    set InclinationPenalty to 0.
  } else {
    set InclinationPenalty to round((abs(ScoreManeuver:orbit:inclination - TargetInclination)/TargetInclination), 2).
  }

  print "                                       " at(1,10).
  print "InclinationPenalty  " + InclinationPenalty + "             " at(1,11).
  print "PeriapsisPenalty    " + PeriapsisPenalty + "           " at(1,12).
  print "Total Penalty       " + (InclinationPenalty+PeriapsisPenalty) + "          " at(1,13).
  //return PeriapsisPenalty.
  print "Total Penalty       " + (InclinationPenalty+PeriapsisPenalty) + "          " at(1,13).
  return (InclinationPenalty+PeriapsisPenalty).
}


}

print "read lib_hillclimb_scoring".
