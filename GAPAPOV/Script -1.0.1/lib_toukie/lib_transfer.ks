// NOTE Line 40 accidental moon intercept stuff
// NOTE Final correction has edited Inclination check, needs to be relative 15 degrees ish
{

global T_Transfer is lex(
  "InterplanetaryTransfer", InterplanetaryTransfer@,
  "MoonTransfer", MoonTransfer@,
  "MoonToReferencePlanet", MoonToReferencePlanet@
  ).

Function InterplanetaryTransfer {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.
  Parameter PreciseCirc is true.

  T_TransferBurn["InsertionBurn"](TargetDestination, TargetPeriapsis).
  local CorrectionBurnNeeded is T_TransferBurn["ExitSOI"](TargetDestination).

  until CorrectionBurnNeeded = false {
    T_TransferBurn["CorrectionBurn"](TargetDestination, TargetPeriapsis).
    if ship:orbit:hasnextpatch = true {
      if ship:orbit:nextpatch:body = TargetDestination {
        set CorrectionBurnNeeded to false.
        clearscreen.
        wait 2.
        print "All go!".
      }
    }
  }

  //local DayBeforeIntercept is time:seconds + eta:transition - (6 * 3600).
  //warpto (DayBeforeIntercept).
  //until time:seconds > DayBeforeIntercept {
  //  print DayBeforeIntercept - time:seconds at(1, 10).
  //  wait 1.
  //}

  local TimeTillIntercept is time:seconds + eta:transition - 5.
  warpto(TimeTillIntercept).
  wait until time:seconds > TimeTillIntercept + 10.

  T_TransferBurn["FinalCorrectionBurn"](TargetDestination, TargetPeriapsis, TargetInclination).

  if ship:orbit:hasnextpatch = true {
    if ship:orbit:nextpatch:hasnextpatch = true {
      if ship:orbit:nextpatch:nextpatch:body = TargetDestination {
        print "we've got an accidental moon encounter!".
        local TimeTillMoonEncounter is time:seconds + eta:transition - 2.
        warpto(TimeTillMoonEncounter).
        wait until time:seconds > TimeTillMoonEncounter + 4.
        // make sure we dont crash into the surface
        if ship:orbit:periapsis < 30000 {
          local NewList is list(time:seconds + 30, 0, 0, 0).
          local NewScoreList is list(30000).
          local NewRestrictionList is list(
            "realnormal_antinormal_timeplus_timemin",
            "realnormal_antinormal_timeplus_timemin",
            "realnormal_antinormal_timeplus_timemin",
            "realnormal_antinormal_timeplus_timemin",
            "realnormal_antinormal_timeplus_timemin"
            ).
          local FinalMan is T_HillUni["ResultFinder"](NewList, "Periapsis", NewScoreList, NewRestrictionList).
          D_ManExe["ExecuteManeuver"](FinalMan).
        }

        if NoAccidentalIntercept = true {

          local TimeTillMoonExit is time:seconds + eta:transition - 2.
          warpto(TimeTillMoonExit).
          wait until time:seconds > TimeTillMoonExit + 4.

          set MinHeight to 30000.
          if ship:orbit:body:atm:exists {
            set MinHeight to ship:orbit:body:atm:height*1.5.
          }

          if ship:orbit:periapsis < MinHeight {
            local NewList is list(time:seconds + 30, 0, 0, 0).
            local NewScoreList is list(MinHeight).
            local NewRestrictionList is list(
              "realnormal_antinormal_timeplus_timemin",
              "realnormal_antinormal_timeplus_timemin",
              "realnormal_antinormal_timeplus_timemin",
              "realnormal_antinormal_timeplus_timemin",
              "realnormal_antinormal_timeplus_timemin"
              ).
            local FinalMan is T_HillUni["ResultFinder"](NewList, "Periapsis", NewScoreList, NewRestrictionList).
            D_ManExe["ExecuteManeuver"](FinalMan).
          }
        }

        if NoAccidentalIntercept = false {
          T_TransferBurn["MoonTransfer"](TargetDestination, TargetPeriapsis, TargetInclination, true).
        }
      }
    }
  }

  local NewList is list(time:seconds + eta:periapsis, 0, 0, -100).
  local NewScoreList is list(TargetDestination).

  local NewRestrictionList is list(
    "none",
    "none",
    "none",
    "none",
    "none"
    ).

  local FinalMan is T_HillUni["ResultFinder"](NewList, "Circularize", NewScoreList, NewRestrictionList).
  D_ManExe["DvCalc"](FinalMan).
  D_ManExe["TimeTillManeuverBurn"](FinalManeuver:eta, DvNeeded).
  D_ManExe["PerformBurn"](EndDv, StartT).

  if PreciseCirc = true {

    print "precision mode on".
    // we have circularized by now so nows the time to match periapsis and apoapsis to the target

    local DvNeededForTar is T_Other["VisViva"](ship:orbit:apoapsis, (ship:orbit:apoapsis + TargetPeriapsis)/2 + ship:body:radius , true).
    local TarList is list(time:seconds + eta:apoapsis, 0, 0, DvNeededForTar).
    D_ManExe["ExecuteManeuver"](TarList).

    // check if we need to go to apo or per to circularize

    local ManVal1 is abs(TargetPeriapsis-ship:orbit:periapsis).
    local ManVal2 is abs(TargetPeriapsis-ship:orbit:apoapsis).

    if ManVal1 < ManVal2 {
      set ApoOrPerHeight to ship:orbit:periapsis.
      set ApoOrPerETA to eta:periapsis.
    } else {
      set ApoOrPerHeight to ship:orbit:apoapsis.
      set ApoOrPerETA to eta:apoapsis.
    }

    local DvNeededForCirc is T_Other["VisViva"](ApoOrPerHeight, ApoOrPerHeight+ship:body:radius, true).
    local CircList is list(time:seconds + ApoOrPerETA, 0, 0, DvNeededForCirc).
    D_ManExe["ExecuteManeuver"](CircList).
  }
}

Function MoonTransfer {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.
  Parameter AccidentalInterceptFromPlanet is false.

  if AccidentalInterceptFromPlanet = false {
    T_Inclination["RelativeAngleCalculation"](TargetDestination).
    if ThetaChange > 0.01 {
    T_Inclination["InclinationMatcher"](TargetDestination).
    }

    if TargetDestination:orbit:eccentricity > 0.1 {
      if not (TargetDestination:orbit:trueanomaly > 220 and TargetDestination:orbit:trueanomaly < 270) {
        set kuniverse:timewarp:warp to T_Warp["GetAllowedTimeWarp"]().
        wait until TargetDestination:orbit:trueanomaly > 220 and TargetDestination:orbit:trueanomaly < 270.
      }
      set kuniverse:timewarp:warp to 0.
    }

    T_Warp["WarpToPhaseAngle"](TargetDestination, 1, ship, ship:body, true).
    T_TransferBurn["MoonInsertionBurn"](TargetDestination, TargetPeriapsis, TargetInclination).

    set MoonCorrectionBurnNeeded to true.
    if ship:orbit:hasnextpatch {
      if ship:orbit:nextpatch:body = TargetDestination {
        set MoonCorrectionBurnNeeded to false.
      }
    }

    until MoonCorrectionBurnNeeded = false {
      T_TransferBurn["MoonCorrectionBurn"](TargetDestination, TargetPeriapsis, TargetInclination).

      if ship:orbit:hasnextpatch {
        if ship:orbit:nextpatch:body = TargetDestination {
          set MoonCorrectionBurnNeeded to false.
        }
      }
    }

    until ship:body = TargetDestination {
      if eta:transition > 120 {
        local TimeTillIntercept is time:seconds + eta:transition - 5.
        warpto(TimeTillIntercept).
        wait until time:seconds > TimeTillIntercept.
        wait 10.
      }

      if eta:transition < 120 {
        local TimeTillIntercept is time:seconds + eta:transition + 10.
        warpto(TimeTillIntercept).
        wait until time:seconds > TimeTillIntercept.
        wait 1.
      }
    }
  }

  if ship:orbit:eccentricity > 100 {
    set EccentricityGoDown to ship:orbit:eccentricity.
    T_Steering["SteeringOrbitRet"]().
    until EccentricityGoDown < 100 {
      lock throttle to min(1, (abs(EccentricityGoDown-100))/100).
      set EccentricityGoDown to ship:orbit:eccentricity.
      if round(throttle, 2) = 0 {
        set EccentricityGoDown to 0.
      }
    }
    lock throttle to 0.
  }

  T_TransferBurn["MoonPostEncounterBurn"](TargetPeriapsis, TargetInclination).

  if eta:periapsis > 30 {
    set NewList to list(time:seconds + eta:periapsis, 0, 0, 0).
    set NewScoreList to list(TargetDestination).

    local NewRestrictionList is list(
      "realnormal_antinormal",
      "realnormal_antinormal",
      "realnormal_antinormal",
      "realnormal_antinormal",
      "realnormal_antinormal"
      ).

    local FinalMan is T_HillUni["ResultFinder"](NewList, "Circularize", NewScoreList, NewRestrictionList).
    D_ManExe["ExecuteManeuver"](FinalMan).

    until ship:orbit:eccentricity <= 1 {
      local DvNeededForCirc is T_Other["VisViva"](ship:altitude, ship:altitude+ship:body:radius, true).
      local CircList is list(time:seconds, 0, 0, DvNeededForCirc).
      D_ManExe["ExecuteManeuver"](CircList).
    }

  } else {
    until ship:orbit:eccentricity <= 1 {
      local DvNeededForCirc is T_Other["VisViva"](ship:altitude, ship:altitude+ship:body:radius, true).
      local CircList is list(time:seconds, 0, 0, DvNeededForCirc).
      D_ManExe["ExecuteManeuver"](CircList).
    }
  }

  // we have circularized by now so nows the time to match periapsis and apoapsis to the target

  local DvNeededForTar is T_Other["VisViva"](ship:orbit:apoapsis, (ship:orbit:apoapsis + TargetPeriapsis)/2 + ship:body:radius , true).
  local TarList is list(time:seconds + eta:apoapsis, 0, 0, DvNeededForTar).
  D_ManExe["ExecuteManeuver"](TarList).

  // check if we need to go to apo or per to circularize

  local ManVal1 is abs(TargetPeriapsis-ship:orbit:periapsis).
  local ManVal2 is abs(TargetPeriapsis-ship:orbit:apoapsis).

  if ManVal1 < ManVal2 {
    set ApoOrPerHeight to ship:orbit:periapsis.
    set ApoOrPerETA to eta:periapsis.
  } else {
    set ApoOrPerHeight to ship:orbit:apoapsis.
    set ApoOrPerETA to eta:apoapsis.
  }

  local DvNeededForCirc is T_Other["VisViva"](ApoOrPerHeight, ApoOrPerHeight+ship:body:radius, true).
  local CircList is list(time:seconds + ApoOrPerETA, 0, 0, DvNeededForCirc).
  D_ManExe["ExecuteManeuver"](CircList).
}

Function MoonToReferencePlanet {
  Parameter StartingBody.
  Parameter TargetPlanet.
  Parameter TargetPeriapsis is 0.5*StartingBody:orbit:semimajoraxis.
  Parameter TargetInclination is 3.1416.

  if StartingBody:body = sun {
    local JunkTime is time:seconds + 2.
    until time:seconds > JunkTime {
      print "ERROR, not orbiting a moon".
    }
  }

  lock PosToNegAngle to vcrs(vcrs(ship:velocity:orbit, body:position),ship:body:orbit:velocity:orbit).
  lock NegToPosAngle to vcrs(ship:body:orbit:velocity:orbit, vcrs(ship:velocity:orbit, body:position)).

  set kuniverse:timewarp:warp to (T_Warp["GetAllowedTimeWarp"]()).
  set CurrentEjectionAngle to 100.

  until CurrentEjectionAngle > 355 or CurrentEjectionAngle < 5 {
    if TargetPlanet:orbit:semimajoraxis > StartingBody:orbit:semimajoraxis {
      if vang(-body:position, PosToNegAngle) < vang(-body:position, NegToPosAngle) {
        set CurrentEjectionAngle to 360 - vang(-body:position , body:orbit:velocity:orbit).
      } else {
        set CurrentEjectionAngle to vang(-body:position , body:orbit:velocity:orbit).
      }
      print "Angle from retrograde:   " + CurrentEjectionAngle at (1,4).
    }

    if TargetPlanet:orbit:semimajoraxis < StartingBody:orbit:semimajoraxis {
      if vang(-body:position, NegToPosAngle) < vang(-body:position, PosToNegAngle) {
        set CurrentEjectionAngle to 360 - vang(-body:position , -body:orbit:velocity:orbit).
      } else {
        set CurrentEjectionAngle to vang(-body:position , -body:orbit:velocity:orbit).
      }
      set InbetweenEjectionAngle to (CurrentEjectionAngle + 180).
      if InbetweenEjectionAngle > 360 {
        set InbetweenEjectionAngle to InbetweenEjectionAngle - 360.
      }
      set CurrentEjectionAngle to InbetweenEjectionAngle.
      print "Angle from retrograde: " + CurrentEjectionAngle at (1,4).
    }
  }

  set warpnumber to 1.
  until warpnumber = 8 {
    set kuniverse:timewarp:warp to (T_Warp["GetAllowedTimeWarp"]() - warpnumber).
    wait 5.
    set WarpNumber to WarpNumber + 1.
  }
  wait 3.
  set kuniverse:timewarp:warp to 0.

  local TargetSMA is ship:altitude + 1.05 * ship:body:soiradius + ship:body:radius.
  local DvNeededForExit is T_Other["VisViva"](ship:altitude, TargetSMA, true).
  local ExitList is list(time:seconds, 0, 0, DvNeededForExit).
  D_ManExe["ExecuteManeuver"](ExitList).

  local CriticalHeight is 100000.
  if ship:body:body:atm:exists {
    set CriticalHeight to 2*ship:body:body:atm:height.
  }

  local Warptime is time:seconds + eta:transition.
  warpto(Warptime).
  wait until time:seconds > Warptime + 5.

  if ship:orbit:periapsis < CriticalHeight {
    print "Correction needed!".
    local NewList is list(time:seconds + 30, 0, 0, 0).
    local NewScoreList is list(CriticalHeight).
    local NewRestrictionList is list(
      "realnormal_antinormal_timeplus_timemin_prograde_retrograde_radialin_radialout",
      "realnormal_antinormal_timeplus_timemin_prograde_retrograde",
      "realnormal_antinormal_timeplus_timemin_prograde_retrograde",
      "realnormal_antinormal_timeplus_timemin_prograde_retrograde",
      "realnormal_antinormal_timeplus_timemin_prograde_retrograde"
      ).
    local FinalMan is T_HillUni["ResultFinder"](NewList, "Periapsis", NewScoreList, NewRestrictionList).
    D_ManExe["ExecuteManeuver"](FinalMan).
  }

  local TargetSMA is (TargetPeriapsis + ship:orbit:periapsis)/2 + ship:body:radius.
  local DvNeededForTarPer is T_Other["VisViva"](ship:periapsis, TargetSMA, true).
  local TarPerList is list(time:seconds + eta:periapsis, 0, 0, DvNeededForTarPer).
  D_ManExe["ExecuteManeuver"](TarPerList).

  local ManVal1 is abs(TargetPeriapsis-ship:orbit:periapsis).
  local ManVal2 is abs(TargetPeriapsis-ship:orbit:apoapsis).

  if ManVal1 < ManVal2 {
    set ApoOrPerETA to eta:periapsis.
  } else {
    set ApoOrPerETA to eta:apoapsis.
  }

  local InclinWarp is time:seconds + ApoOrPerETA.
  warpto(InclinWarp).
  wait until time:seconds > InclinWarp.

  if TargetInclination = 3.1416 {
    wait 0.
  } else {
    T_TransferBurn["InclinationMatcher2"](TargetInclination).
  }

  if ManVal1 < ManVal2 {
    set ApoOrPerETA to eta:periapsis.
  } else {
    set ApoOrPerETA to eta:apoapsis.
  }

  local NewList is list(time:seconds + ApoOrPerETA, 0, 0, 0).
  local NewScoreList is list(1).

  local NewRestrictionList is list(
    "realnormal_antinormal_timeplus",
    "realnormal_antinormal_timeplus",
    "realnormal_antinormal_timeplus",
    "realnormal_antinormal_timeplus",
    "realnormal_antinormal_timeplus"
    ).

  local FinalMan is T_HillUni["ResultFinder"](NewList, "Circularize", NewScoreList, NewRestrictionList).
  D_ManExe["DvCalc"](FinalMan).
  D_ManExe["TimeTillManeuverBurn"](FinalManeuver:eta, DvNeeded).
  D_ManExe["PerformBurn"](EndDv, StartT).

 }

}

print "read lib_transfer".
