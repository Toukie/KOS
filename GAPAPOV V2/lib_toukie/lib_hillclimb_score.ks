global TX_lib_hillclimb_score is lexicon(
  "CircScore", CircScore@,
  "ApoapsisScore", ApoapsisScore@,
  "PeriapsisScore", PeriapsisScore@,
  "InclinationScore", InclinationScore@,
  "MoonInsertionScore", MoonInsertionScore@,
  "FinalCorrectionScore", FinalCorrectionScore@,
  "DecircularizationScore", DecircularizationScore@,
  "MoonReturnScore", MoonReturnScore@,
  "InterplanetaryScore", InterplanetaryScore@,
  "PlanetFinalCorrectionScore", PlanetFinalCorrectionScore@
).
local TXStopper is "[]".

// maybe add a dv penalty?

Function AddManeuver {
  parameter NodeList.

  local NewNode is node(NodeList[0], NodeList[1], NodeList[2], NodeList[3]).
  add NewNode.
  wait until hasnode = true.
}

///

Function CircScore {
  parameter NodeList.
  parameter ParameterList. // not needed for this instance

  AddManeuver(NodeList).
  local ScoreManeuver is nextnode.
  local Score is ScoreManeuver:orbit:eccentricity.
  remove nextnode.
  return Score.
}

///

Function ApoapsisScore {
  parameter NodeList.
  parameter ParameterList.

  AddManeuver(NodeList).
  local ScoreManeuver is nextnode.
  local CurrentHeight is ScoreManeuver:orbit:apoapsis.
  local TargetHeight  is ParameterList[0].
  remove nextnode.

  print "cur height: " + CurrentHeight at(1,10).
  print "tar height: " + TargetHeight at(1,11).

  return round(abs(CurrentHeight - TargetHeight)/TargetHeight, 10).
}

///

Function PeriapsisScore {
  parameter NodeList.
  parameter ParameterList.

  print "ParameterList score " + ParameterList[0].

  AddManeuver(NodeList).
  local ScoreManeuver is nextnode.
  local CurrentHeight is ScoreManeuver:orbit:periapsis.
  local TargetHeight  is ParameterList[0].
  remove nextnode.

  print "cur height: " + CurrentHeight.
  print "tar height: " + TargetHeight.

  return round(abs(CurrentHeight - TargetHeight)/TargetHeight, 10).
}


///
Function InclinationScore {
  parameter NodeList.
  parameter ScoreList. // can be a target or can be a wanted inclination

  AddManeuver(NodeList).
  local ScoreManeuver is nextnode.

  // if ScoreList is a number
  if ScoreList[0]:istype("scalar") = true {
    local WantedInclin is ScoreList[0].
    local ThetaChange is abs(ScoreManeuver:orbit:inclination - WantedInclin).
    if  ThetaChange < 0.002 {
      set ThetaChange to 0.
    }
    if ScoreManeuver:orbit:hasnextpatch {
      print "has next patch while scoring inclination".
      set ThetaChange to abs(ScoreManeuver:orbit:inclination - WantedInclin) + 1000.
    }
    remove nextnode.
    return ThetaChange.
  }

  local TargetDestination is ScoreList[0].

  local Inclin1 is ScoreManeuver:orbit:inclination.
  local Inclin2 is TargetDestination:orbit:inclination.

  local Omega1  is ScoreManeuver:orbit:LAN.
  local Omega2  is TargetDestination:orbit:LAN.

  local a1 is (sin(Inclin1)*cos(Omega1)).
  local a2 is (sin(Inclin1)*sin(Omega1)).
  local a3 is cos(Inclin1).
  local a123 is v(a1, a2, a3).

  local b1 is (sin(Inclin2)*cos(Omega2)).
  local b2 is (sin(Inclin2)*sin(Omega2)).
  local b3 is cos(Inclin2).
  local b123 is v(b1, b2, b3).

  local ThetaChange is ARCcos(vdot(a123, b123)).
  //set Result to ThetaChange.

  if ThetaChange < 0.002 {
    set ThetaChange to 0.
  }

  remove nextnode.
  return ThetaChange.
}

///

Function MoonInsertionScore {
  parameter NodeList.
  parameter ParameterList.

  local TargetBody is ParameterList[0].
  local TargetPeriapsis is ParameterList[1].
  local TargetInclination is ParameterList[2].
  local TargetLAN is "none".

  if ParameterList:length = 4 {
    set TargetLAN to ParameterList[3].
  }

  local InterceptCheck  is false.

  AddManeuver(NodeList).
  local ScoreManeuver is nextnode.
  local TransferPenalty    is "x".
  local PeriapsisPenalty   is "x".
  local InclinationPenalty is "x".
  local LANPenalty is "x".
  local TotalPenalty is "x".
  local TimePenalty is 0.

  if nextnode:eta > 2*nextnode:orbit:period {
    set TimePenalty to 10*nextnode:eta.
  }

  if nextnode:eta < 0 {
    set TimePenalty to 2^64.
  }



  if TargetInclination < 0.01 {
    set TargetInclination to 0.01.
  }

  if ScoreManeuver:orbit:hasnextpatch = true {
    if ScoreManeuver:orbit:nextpatch:body = TargetBody {
      set InterceptCheck to true.
      set TransferPenalty to 0.
      set InclinationPenalty to (abs(ScoreManeuver:orbit:nextpatch:inclination - TargetInclination)/TargetInclination).
      if TargetLAN <> "none" {
        if TargetLAN < 0.01 {
          set TargetLAN to 0.01.
        }
        set LANPenalty to (abs(ScoreManeuver:orbit:nextpatch:LAN - TargetLAN)/TargetLAN).
      } else {
        set LANPenalty to 0.
      }

      //log "===== moon transfer =====" to ("0:/logme").
      //log "Tar Incl: " + TargetInclination to ("0:/logme").
      //log "Act Incl: " + ScoreManeuver:orbit:nextpatch:inclination to ("0:/logme").
      //log "dIncl:    " + abs(ScoreManeuver:orbit:nextpatch:inclination - TargetInclination) to ("0:/logme").
      //log "penalty:  " + abs(ScoreManeuver:orbit:nextpatch:inclination - TargetInclination)/TargetInclination to ("0:/logme").

      set PeriapsisPenalty to abs(ScoreManeuver:orbit:nextpatch:periapsis - TargetPeriapsis)/TargetPeriapsis.
    }
  }

  if InterceptCheck = false {
    if ScoreManeuver:orbit:hasnextpatch = true {
      set TransferPenalty    to 2^64.
      set PeriapsisPenalty   to 2^64.
      set InclinationPenalty to 10^5.
      set LANPenalty         to 10^5.
    } else {
      set TransferPenalty    to TX_lib_closest_approach["ClosestApproachFinder"](TargetBody).
      set TransferPenalty    to TransferPenalty/(10^3).
      set PeriapsisPenalty   to 10000.
      set InclinationPenalty to 10^5.
      set LANPenalty         to 10^5.
    }
  }

  local DeltaVPenalty is 0.
  set TotalPenalty to TransferPenalty + PeriapsisPenalty + InclinationPenalty + LANPenalty + TimePenalty + DeltaVPenalty.

  clearscreen.
  print "TransferPenalty:    " + TransferPenalty + "                   " at(1,20).
  print "PeriapsisPenalty:   " + PeriapsisPenalty + "                  " at(1,21).
  print "InclinationPenalty: " + InclinationPenalty + "                " at(1,22).
  print "LANPenalty:         " + LANPenalty + "                        " at(1,23).
  print "DeltaVPenalty:      " + DeltaVPenalty + "                     " at(1,24).
  print "TimePenalty:        " + TimePenalty + "                       " at(1,25).
  print "TotalPenalty:       " + TotalPenalty + "                      " at(1,26).
  remove nextnode.
  return round(TotalPenalty, 3).

}

///

Function FinalCorrectionScore {
  parameter NodeList.
  parameter ParameterList.

  AddManeuver(NodeList).
  local ScoreManeuver is nextnode.

  local ScoreManeuver is nextnode.
  local TargetBody        is ParameterList[0].
  local TargetPeriapsis   is ParameterList[1].
  local TargetInclination is ParameterList[2].
  local TargetLAN         is ParameterList[3].
  local InclinationPenaltyWeight is 1.
  local LANPenalty is 0.

  if ParameterList:length = 5 {
    set InclinationPenaltyWeight to ParameterList[4].
  }

  local DeltaVPenalty is ScoreManeuver:deltav:mag.

  if TargetLAN <> "none" {
    if TargetLAN < 0.01 {
      set TargetLAN to 0.01.
    }
    set LANPenalty to abs((ScoreManeuver:orbit:LAN - TargetLAN)/TargetLAN).
  }

  if TargetInclination < 1 {
    set TargetInclination to 1.
  }

  local InclinationPenalty is 10^9.
  local PeriapsisPenalty is abs(ScoreManeuver:orbit:periapsis - TargetPeriapsis)/TargetPeriapsis.

  if ScoreManeuver:orbit:periapsis < 0 {
    set PeriapsisPenalty to abs(ScoreManeuver:orbit:periapsis).
  }

  if abs(ScoreManeuver:orbit:inclination - TargetInclination) < 15 {
    set InclinationPenalty to 0.
  } else {
    set InclinationPenalty to InclinationPenaltyWeight * abs(ScoreManeuver:orbit:inclination - TargetInclination)/TargetInclination.
  }

  local DeltaVPenalty is 0.
  local TotalPenalty is (InclinationPenalty + PeriapsisPenalty + LANPenalty + DeltaVPenalty).
  clearscreen.
  print "InclinationPenalty  " + InclinationPenalty + "             " at(1,11).
  print "PeriapsisPenalty    " + PeriapsisPenalty + "               " at(1,12).
  print "LANPenalty:         " + LANPenalty + "                     " at(1,13).
  print "DeltaVPenalty       " + DeltaVPenalty + "                  " at(1,14).
  print "Total Penalty       " + TotalPenalty + "                   " at(1,15).
  remove nextnode.
  return round(TotalPenalty, 8).
}

///

Function DecircularizationScore {
  parameter NodeList.
  parameter ParameterList. // 0.9 would be good

  AddManeuver(NodeList).
  local ScoreManeuver is nextnode.
  local CurEcc is ScoreManeuver:orbit:eccentricity.
  local TargetEcc is ParameterList[0].
  local Score is 100*abs(TargetEcc - CurEcc).
  if nextnode:orbit:periapsis > 0 {
    set score to score*2^64.
  }

  remove nextnode.
  return Score.
}

///

Function MoonReturnScore {
  parameter NodeList.
  parameter ParameterList.

  for item in NodeList {
    if item <> NodeList[0] { // for each item in the nodelist except for time
      if item > 100000 {
        set item to 100000.
      }
    }
  }



  AddManeuver(NodeList).

  local TargetHeight is ParameterList[0].
  if TargetHeight = 0 {
    set TargetHeight to 0.01.
  }
  // advised: atm height + 10km or 100km
  local SOIPenalty is 0.
  local PePenalty is 0.

  local DvPenalty is round(nextnode:deltav:mag,4).
  if DvPenalty > 10000 {
    set DvPenalty to 10000.
  }

  // RUN ONLY WHEN IN STABLE ORBIT
  if nextnode:orbit:periapsis < 5000 {
    set SOIPenalty to 500*abs(nextnode:orbit:periapsis).
  }

  if nextnode:orbit:hasnextpatch = false {
    set SOIPenalty to round(ship:body:soiradius - nextnode:orbit:apoapsis).
    set PePenalty to 2^32.
  } else {
    if nextnode:orbit:nextpatch:hasnextpatch = true {
      set PePenalty to 2^64.
    } else {
      set PePenalty to round((abs(nextnode:orbit:nextpatch:periapsis - TargetHeight)/TargetHeight),3).
    }

  }

  local TotalPenalty is (SOIPenalty+PePenalty+DvPenalty).
  clearscreen.
  print "SOIPenalty      " + SOIPenalty + "              " at(1,11).
  print "PePenalty       " + PePenalty + "               " at(1,12).
  print "DvPenalty       " + DvPenalty + "               " at(1,13).
  print "Total Penalty   " + TotalPenalty + "            " at(1,14).
  remove nextnode.
  return TotalPenalty.
}

///

Function InterplanetaryScore {
  parameter NodeList.
  parameter ParameterList.

  AddManeuver(NodeList).
  local ScoreManeuver is nextnode.
  local TargetBody is ParameterList[0].
  local TargetPeriapsis is ParameterList[1].

  local TransferPenalty is 10000.
  local SOIexitPenalty is 10^6.
  local PeriapsisPenalty is 10000.

  if defined DvModifier = false {
    global DvModifier is 1.
  }

  local DvPenalty is nextnode:deltav:mag * DvModifier.

  if ScoreManeuver:orbit:hasnextpatch = true {
    if ScoreManeuver:orbit:nextpatch:body = TargetBody {
      print "A - okay" at(1,35).
      set PeriapsisPenalty to (abs(ScoreManeuver:orbit:nextpatch:periapsis - TargetPeriapsis)/TargetPeriapsis).
      set TransferPenalty to 0.
      set SOIexitPenalty to 0.
    } else if ScoreManeuver:orbit:nextpatch:hasnextpatch = true {
      if ScoreManeuver:orbit:nextpatch:nextpatch:body = TargetBody {
        print "B - okay" at(1,35).
        set PeriapsisPenalty to (abs(ScoreManeuver:orbit:nextpatch:nextpatch:periapsis - TargetPeriapsis)/TargetPeriapsis).
        set TransferPenalty to 0.
        set SOIexitPenalty to 0.
      }
    }
  }

  if TransferPenalty <> 0 {
    print "C - okay" at(1,35).
    if ScoreManeuver:orbit:hasnextpatch = false and ScoreManeuver:orbit:body <> TargetBody:body {
      set SOIexitPenalty to ship:body:soiradius/ScoreManeuver:orbit:apoapsis.
    } else {
      set SOIexitPenalty to 0.
      set TransferPenalty to round(TX_lib_closest_approach["ClosestApproachFinder"](TargetBody)/(10^6), 3).
      print TransferPenalty at(1,36).
      set TransferPenalty to TransferPenalty.
      set PeriapsisPenalty to 10000.
    }
  }

  local TotalPenalty is (TransferPenalty+SOIexitPenalty+PeriapsisPenalty+DvPenalty).
  clearscreen.
  print "TransferPenalty   " + TransferPenalty + "            " at(1,20).
  print "SOIexitPenalty    " + SOIexitPenalty + "             " at(1,21).
  print "PeriapsisPenalty  " + PeriapsisPenalty + "           " at(1,22).
  print "DeltaVPenalty     " + DvPenalty + "                  " at(1,23).
  print "Total Penalty     " + TotalPenalty + "               " at(1,24).
  remove nextnode.
  return round(TotalPenalty, 5).
}

// not just for planets though
Function PlanetFinalCorrectionScore {
  parameter NodeList.
  parameter ParameterList.

  AddManeuver(NodeList).
  local ScoreManeuver is nextnode.
  local TargetBody is ParameterList[0].
  local TargetPeriapsis is ParameterList[1].
  local TargetInclination is ParameterList[2].
  local InclinationPenaltyWeight is 1.

  if ParameterList:length = 4 {
    set InclinationPenaltyWeight to ParameterList[3].
  }

  if TargetInclination < 1 {
    set TargetInclination to 1.
  }

  local PeriapsisPenalty is 10^9.
  local InclinationPenalty is 10^9.
  local PeriapsisPenalty is (abs(ScoreManeuver:orbit:periapsis - TargetPeriapsis)/TargetPeriapsis).

  local DeltaVPenalty is ScoreManeuver:deltav:mag.

  if abs(ScoreManeuver:orbit:inclination - TargetInclination) < 15 {
    set InclinationPenalty to 0.
  } else {
    set InclinationPenalty to InclinationPenaltyWeight * abs(ScoreManeuver:orbit:inclination - TargetInclination)/TargetInclination.
  }

  local TotalPenalty is (InclinationPenalty + PeriapsisPenalty + DeltaVPenalty).
  clearscreen.
  print "                                       " at(1,10).
  print "InclinationPenalty  " + InclinationPenalty + "             " at(1,11).
  print "PeriapsisPenalty    " + PeriapsisPenalty + "           " at(1,12).
  print "DeltaVPenalty       " + DeltaVPenalty + "              " at(1,13).
  print "Total Penalty       " + TotalPenalty + "          " at(1,14).
  remove nextnode.
  return round(TotalPenalty, 8).
}


print "read lib_hillclimb_score".
