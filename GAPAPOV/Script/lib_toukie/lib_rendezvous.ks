Function EnsureSmallerOrbit {
  Parameter TargetDestination.

  if ship:orbit:periapsis > TargetDestination:orbit:periapsis {
    VisViva(ship:orbit:apoapsis, (ship:orbit:apoapsis + 0.9*TargetDestination:periapsis)/2 + ship:body:radius).
    set LowerList1 to list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
    DvCalc(LowerList1).
    TimeTillManeuverBurn(FinalManeuver:eta, DvNeeded).
    PerformBurn(EndDv, StartT).
  }

  if ship:orbit:apoapsis > TargetDestination:orbit:apoapsis {
    VisViva(ship:orbit:periapsis, (ship:orbit:periapsis + 0.9*TargetDestination:apoapsis)/2 + ship:body:radius).
    set LowerList2 to list(time:seconds+eta:periapsis, 0, 0, DvNeeded).
    DvCalc(LowerList2).
    TimeTillManeuverBurn(FinalManeuver:eta, DvNeeded).
    PerformBurn(EndDv, StartT).
  }
}

Function RendezvousSetup {

  parameter TargetDestination.

      set ArgOfPer1 to ship:orbit:argumentofperiapsis.
      set ArgOfPer2 to TargetDestination:orbit:argumentofperiapsis.
      set TrueAnomalyTargetPer to ArgOfPer2-ArgOfPer1.

      ETAToTrueAnomaly(ship, TrueAnomalyTargetPer).
      set TimeTargetPeriapsis to TimeTillDesiredTrueAnomaly.

      //print "Time till target periapsis:   " + TimeTargetPeriapsis.

      set SMA to ship:orbit:semimajoraxis.
      set Ecc to ship:orbit:eccentricity.
      set CurRadiusAtTargetPeriapsis to (SMA * ( (1-ecc^2) / (1+ecc*cos(TrueAnomalyTargetPer))))-body:radius.

      if ship:orbit:semimajoraxis < TargetDestination:orbit:semimajoraxis {
        local InputList is list(time:seconds + TimeTargetPeriapsis, 0, 0, 0).
        local NewScoreList is list(TargetDestination).
        local NewRestrictionList is IndexFiveFolderder("realnormal_antinormal_radialout_radialin_timeplus_timemin").
        set FinalMan to HillClimbLex["ResultFinder"](InputList, "ApoapsisMatch", NewScoreList, NewRestrictionList).
      } else {
        local InputList is list(time:seconds + TimeTargetPeriapsis, 0, 0, 0).
        local NewScoreList is list(TargetDestination).
        local NewRestrictionList is IndexFiveFolderder("realnormal_antinormal_radialout_radialin_timeplus_timemin").
        set FinalMan to HillClimbLex["ResultFinder"](InputList, "PerApoMatch", NewScoreList, NewRestrictionList).
      }

      DvCalc(FinalMan).
      TimeTillManeuverBurn(FinalManeuver:eta, DvNeeded).
      PerformBurn(EndDv, StartT).
}

Function MatchOrbit {
  Parameter TargetDestination.

  RelativeAngleCalculation(TargetDestination).

  print "Matching inclination".

  until thetachange < 0.04 {
   InclinationMatcher(TargetDestination).
  }

  EnsureSmallerOrbit(TargetDestination).

  print "Circularizing".

  if ship:orbit:eccentricity > 0.00001 {
    if ship:orbit:apoapsis > TargetDestination:orbit:periapsis {
      local InputList is list(time:seconds + eta:periapsis, 0, 0, 0).
      local NewScoreList is list(TargetDestination).
      local NewRestrictionList is IndexFiveFolderder("realnormal_antinormal").
      set FinalMan to HillClimbLex["ResultFinder"](InputList, "Circularize", NewScoreList, NewRestrictionList).
    } else {
      local InputList is list(time:seconds + eta:apoapsis, 0, 0, 0).
      local NewScoreList is list(TargetDestination).
      local NewRestrictionList is IndexFiveFolderder("realnormal_antinormal").
      set FinalMan to HillClimbLex["ResultFinder"](InputList, "Circularize", NewScoreList, NewRestrictionList).
    }
    DvCalc(FinalMan).
    TimeTillManeuverBurn(FinalManeuver:eta, DvNeeded).
    PerformBurn(EndDv, StartT).
  }



  print "Rendezvous approach".

  RendezvousSetup(TargetDestination).


  if ship:orbit:periapsis*1.05 > TargetDestination:orbit:apoapsis {
    print "lowering orbit".
    VisViva(ship:orbit:periapsis, (ship:orbit:periapsis+2*ship:body:radius+(0.8*TargetDestination:orbit:periapsis))/2).
    set LowerList to list(time:seconds+eta:periapsis, 0, 0, DvNeeded).
    DvCalc(LowerList).
    TimeTillManeuverBurn(FinalManeuver:eta, DvNeeded).
    PerformBurn(EndDv, StartT).
  }

    print "Matching up orbit".
    local InputList is list(time:seconds + eta:apoapsis, 0, 0, 0).
    local NewScoreList is list(TargetDestination).
    local NewRestrictionList is IndexFiveFolderder("realnormal_antinormal_radialout_radialin_timeplus_timemin").
    set FinalMan to HillClimbLex["ResultFinder"](InputList, "PerPerMatch", NewScoreList, NewRestrictionList).
    DvCalc(FinalMan).
    TimeTillManeuverBurn(FinalManeuver:eta, DvNeeded).
    PerformBurn(EndDv, StartT).
}

Function FinalApproach {
  Parameter TargetDestination.
  Parameter StepsNeeded is 1.

  ETAToTrueAnomaly(TargetDestination, 180, eta:apoapsis).

  set CurPeriod to ship:orbit:period.
  set TarPeriod to CurPeriod + (TimeTillDesiredTrueAnomaly/StepsNeeded).

  set TarSMA to (((TarPeriod^2)*ship:body:mu)/(4*constant:pi^2))^(1/3).

  VisViva(ship:orbit:apoapsis, TarSMA).
  set AproachList to list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
  DvCalc(AproachList).

  if nextnode:orbit:hasnextpatch {
    if nextnode:orbit:nextpatch:body <> ship:orbit:body{
      until nextnode:orbit:nextpatch:body = ship:orbit:body{
        remove nextnode.
        set StepsNeeded to StepsNeeded + 1.

        set CurPeriod to ship:orbit:period.
        set TarPeriod to CurPeriod + (TimeTillDesiredTrueAnomaly/StepsNeeded).

        set TarSMA to (((TarPeriod^2)*ship:body:mu)/(4*constant:pi^2))^(1/3).

        VisViva(ship:orbit:apoapsis, TarSMA).
        set AproachList to list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
        DvCalc(AproachList).
      }
    }
  }

  TimeTillManeuverBurn(FinalManeuver:eta, DvNeeded).
  PerformBurn(EndDv, StartT).

  wait 5.
  if StepsNeeded > 1 {
    set TargetTime to time:seconds + (StepsNeeded-1)*ship:orbit:period.
    warpto(TargetTime).
  } else {
    set TargetTime to time:seconds + 0.75*ship:orbit:period.
    warpto(TargetTime).
  }
  //print "warping some more".
  wait until time:seconds > TargetTime.
  wait 5.
  ETAToTrueAnomaly(TargetDestination, 180).
  set TargetTime to time:seconds+TimeTillDesiredTrueAnomaly.
  warpto(TargetTime).
  //print "warped some more".
  wait until time:seconds > TargetTime.
  wait 7.

  set Distance to (TargetDestination:position - ship:position):mag.
  if  Distance > 50000 {
    //print "too far away, warping again".
    ETAToTrueAnomaly(TargetDestination, 180).
    set TargetTime to time:seconds+TimeTillDesiredTrueAnomaly.
    warpto(TargetTime).
    wait until time:seconds > TargetTime.
  }
}

Function MainRelVelKill {
  Parameter TargetDestination.

  SteeringTargetRet(TargetDestination).
  set DvNeeded to (ship:velocity:orbit-TargetDestination:velocity:orbit):mag.
  CurrentDvCalc().
  set EndDv to CurDv - DvNeeded.
  PerformBurn(EndDv, 10, 100, true).
}

Function VeryFinalApproach {

  Parameter TargetDestination.

  lock Distance to (TargetDestination:position - ship:position):mag.
  set warpmode to "rails".

  if Distance > 15000 {
    //print "extra boost needed".
    MainRelVelKill(TargetDestination).
    SteeringTarget(TargetDestination).
    set DvNeeded to 100.
    CurrentDvCalc().
    set EndDv to CurDv - DvNeeded.
    PerformBurn(EndDv, 10, 100, true).
    SteeringTargetRet(TargetDestination).
    set warp to 2.
    wait until Distance < 10000.
    set warp to 0.
    MainRelVelKill(TargetDestination).
  }

  if Distance > 3000 {
    //print "3000 meters".
    MainRelVelKill(TargetDestination).
    SteeringTarget(TargetDestination).
    set DvNeeded to 40.
    CurrentDvCalc().
    set EndDv to CurDv - DvNeeded.
    PerformBurn(EndDv, 10, 100, true).
    SteeringTargetRet(TargetDestination).
    set warp to 1.
    wait until Distance < 1000.
    set warp to 0.
    MainRelVelKill(TargetDestination).
  }

  MainRelVelKill(TargetDestination).
  SteeringTarget(TargetDestination).
  set DvNeeded to 10.
  CurrentDvCalc().
  set EndDv to CurDv - DvNeeded.
  PerformBurn(EndDv, 10, 100, true).
  SteeringTargetRet(TargetDestination).
  wait until Distance < 275.
  MainRelVelKill(TargetDestination).
}

Function CompleteRendezvous {
  Parameter TargetDestination.

  set Distance to (TargetDestination:position - ship:position):mag.
  if Distance > 7500 {
    MatchOrbit(TargetDestination).
    FinalApproach(TargetDestination, 5).
  }
  MainRelVelKill(TargetDestination).
  VeryFinalApproach(TargetDestination).
}

print "read lib_rendezvous".
