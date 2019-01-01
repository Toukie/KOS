

{

global TX_lib_transfer is lex(
  "InterplanetaryTransfer", InterplanetaryTransfer@,
  "MoonTransfer", MoonTransfer@,
  "MoonToReferencePlanet", MoonToReferencePlanet@,
  "MoonToMoon", MoonToMoon@,
  "ChangeOrbit", ChangeOrbit@
  ).
  local TXStopper is "[]".

Function InterplanetaryTransfer {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.
  Parameter PreciseCirc is true.

  TX_lib_transfer_burn["InsertionBurn"](TargetDestination, TargetPeriapsis).
  local CorrectionBurnNeeded is TX_lib_transfer_burn["ExitSOI"](TargetDestination).

  until CorrectionBurnNeeded = false {
    TX_lib_transfer_burn["CorrectionBurn"](TargetDestination, TargetPeriapsis).
    if ship:orbit:hasnextpatch = true {
      if ship:orbit:nextpatch:body = TargetDestination {
        set CorrectionBurnNeeded to false.
        clearscreen.
        wait 2.
        print "All go!".
      }
    }
  }

  local TimeTillIntercept is time:seconds + eta:transition - 5.
  warpto(TimeTillIntercept).
  wait until time:seconds > TimeTillIntercept + 10.

  TX_lib_transfer_burn["FinalCorrectionBurn"](TargetDestination, TargetPeriapsis, TargetInclination).
  local NoAccidentalIntercept is true.

  if ship:orbit:hasnextpatch = true {
    if ship:orbit:nextpatch:hasnextpatch = true {
      if ship:orbit:nextpatch:nextpatch:body = TargetDestination {
        if eta:transition < eta:periapsis {
          print "we've got an accidental moon encounter!".
          set NoAccidentalIntercept to false.
          local TimeTillMoonEncounter is time:seconds + eta:transition - 2.
          warpto(TimeTillMoonEncounter).
          wait until time:seconds > TimeTillMoonEncounter + 4.
          // make sure we dont crash into the surface
          if ship:orbit:periapsis < 30000 {
            local NewList is list(time:seconds + 30, 0, 0, 0).
            local NewScoreList is list(30000).
            local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal_timeplus_timemin").
            local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Periapsis", NewScoreList, NewRestrictionList).
            TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
          }

          // I dont even know what this variable is
          if NoAccidentalIntercept = true {

            local TimeTillMoonExit is time:seconds + eta:transition - 2.
            warpto(TimeTillMoonExit).
            wait until time:seconds > TimeTillMoonExit + 4.

            local MinHeight is 30000.
            if ship:orbit:body:atm:exists {
              set MinHeight to ship:orbit:body:atm:height*1.5.
            }

            if ship:orbit:periapsis < MinHeight {
              local NewList is list(time:seconds + 30, 0, 0, 0).
              local NewScoreList is list(MinHeight).
              local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal_timeplus_timemin").
              local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Periapsis", NewScoreList, NewRestrictionList).
              TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
            }
          } else {
            TX_lib_transfer_burn["MoonTransfer"](TargetDestination, TargetPeriapsis, TargetInclination, true).
          }
        }
      }
    }
  }

  local NewList is list(time:seconds + eta:periapsis, 0, 0, -100).
  local NewScoreList is list(TargetDestination).
  local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("none").
  local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Circularize", NewScoreList, NewRestrictionList).
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).

  TX_lib_transfer_burn["InclinationMatcher2"](TargetInclination).

  if PreciseCirc = true {

    print "precision mode on".
    // we have circularized by now so nows the time to match periapsis and apoapsis to the target

    local DvNeededForTar is TX_lib_other["VisViva"](ship:orbit:apoapsis, (ship:orbit:apoapsis + TargetPeriapsis)/2 + ship:body:radius).
    local TarList is list(time:seconds + eta:apoapsis, 0, 0, DvNeededForTar).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](TarList).

    // check if we need to go to apo or per to circularize

    local ManVal1 is abs(TargetPeriapsis-ship:orbit:periapsis).
    local ManVal2 is abs(TargetPeriapsis-ship:orbit:apoapsis).
    local ApoOrPerHeight is "x".
    local ApoOrPerETA is "x".

    if ManVal1 < ManVal2 {
      set ApoOrPerHeight to ship:orbit:periapsis.
      set ApoOrPerETA to eta:periapsis.
    } else {
      set ApoOrPerHeight to ship:orbit:apoapsis.
      set ApoOrPerETA to eta:apoapsis.
    }

    local DvNeededForCirc is TX_lib_other["VisViva"](ApoOrPerHeight, ApoOrPerHeight+ship:body:radius).
    local CircList is list(time:seconds + ApoOrPerETA, 0, 0, DvNeededForCirc).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](CircList).
  }
}

Function MoonTransfer {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.
  Parameter AccidentalInterceptFromPlanet is false.

  if AccidentalInterceptFromPlanet = false {
    local ThetaChange is TX_lib_inclination["RelativeAngleCalculation"](TargetDestination).
    if ThetaChange > 0.01 {
      TX_lib_inclination["InclinationMatcher"](TargetDestination).
    }

    // only ever true for Gilly
    if TargetDestination:orbit:eccentricity > 0.1 {
      if not (TargetDestination:orbit:trueanomaly > 220 and TargetDestination:orbit:trueanomaly < 270) {
        TX_lib_other["WarpSetter"](75, 100000).
        wait until TargetDestination:orbit:trueanomaly > 220 and TargetDestination:orbit:trueanomaly < 270.
      }
      TX_lib_other["WarpDecreaser"]().
    }

    TX_lib_warp["WarpToPhaseAngle"](TargetDestination, 10, ship, ship:body, 10000).
    // stop when in 10 degrees range and then make a maneuver at the time it takes for 5 degrees
    TX_lib_transfer_burn["MoonInsertionBurn"](TargetDestination, TargetPeriapsis, TargetInclination).

    local MoonCorrectionBurnNeeded is true.
    if ship:orbit:hasnextpatch {
      if ship:orbit:nextpatch:body = TargetDestination {
        set MoonCorrectionBurnNeeded to false.
      }
    }

    until MoonCorrectionBurnNeeded = false {
      TX_lib_transfer_burn["MoonCorrectionBurn"](TargetDestination, TargetPeriapsis, TargetInclination).

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
    local EccentricityGoDown is ship:orbit:eccentricity.
    TX_lib_steering["SteeringOrbitRet"]().
    until EccentricityGoDown < 100 {
      lock throttle to min(1, (abs(EccentricityGoDown-100))/100).
      set EccentricityGoDown to ship:orbit:eccentricity.
      if round(throttle, 2) = 0 {
        set EccentricityGoDown to 0.
      }
    }
    lock throttle to 0.
  }

  print "PRE INCL CORRECTION".
  local NewList is list(time:seconds + 30, 0, 0, 0).
  local NewScoreList is list(TargetDestination, TargetPeriapsis, TargetInclination).
  local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("prograde_retrograde").
  if abs(ship:orbit:inclination - TargetInclination) > 15 {
    set NewScoreList to list(TargetDestination, TargetPeriapsis, TargetInclination, 10).
    set NewRestrictionList to TX_lib_hillclimb_universal["IndexFiveFolderder"]("nothing").
    print "no restrictions!".
  }

  TX_lib_hillclimb_canceler["HillClimbCancel"]().
  local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "FinalCorrection", NewScoreList, NewRestrictionList).
  TX_lib_hillclimb_canceler["HillCancelOptionHider"]().

  TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).

  //TX_lib_transfer_burn["MoonPostEncounterBurn"](TargetPeriapsis, TargetInclination).
  print "POST INCL CORRECTION".

  if eta:periapsis > 30 {
    local NewList is list(time:seconds + eta:periapsis, 0, 0, 0).
    local NewScoreList is list(TargetDestination).
    local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal").
    local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Circularize", NewScoreList, NewRestrictionList).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).

    print "checking eccentricity".
    until ship:orbit:eccentricity <= 1 {
      local DvNeededForCirc is TX_lib_other["VisViva"](ship:altitude, ship:altitude+ship:body:radius).
      local CircList is list(time:seconds, 0, 0, DvNeededForCirc).
      TX_lib_hillclimb_man_exe["ExecuteManeuver"](CircList).
    }

  } else {
    print "periapsis too close emergency burn".
    until ship:orbit:eccentricity <= 1 {
      local DvNeededForCirc is TX_lib_other["VisViva"](ship:altitude, ship:altitude+ship:body:radius).
      local CircList is list(time:seconds, 0, 0, DvNeededForCirc).
      TX_lib_hillclimb_man_exe["ExecuteManeuver"](CircList).
    }
  }

  // we have circularized by now so nows the time to match periapsis and apoapsis to the target
  // but first match inclination

  TX_lib_transfer_burn["InclinationMatcher2"](TargetInclination).

  print "matching per and apo".
  local DvNeededForTar is TX_lib_other["VisViva"](ship:orbit:apoapsis, (ship:orbit:apoapsis + TargetPeriapsis)/2 + ship:body:radius).
  local TarList is list(time:seconds + eta:apoapsis, 0, 0, DvNeededForTar).
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](TarList).

  // check if we need to go to apo or per to circularize

  local ManVal1 is abs(TargetPeriapsis-ship:orbit:periapsis).
  local ManVal2 is abs(TargetPeriapsis-ship:orbit:apoapsis).
  local ApoOrPerHeight is "x".
  local ApoOrPerETA is "x".

  if ManVal1 < ManVal2 {
    set ApoOrPerHeight to ship:orbit:periapsis.
    set ApoOrPerETA to eta:periapsis.
  } else {
    set ApoOrPerHeight to ship:orbit:apoapsis.
    set ApoOrPerETA to eta:apoapsis.
  }

  local DvNeededForCirc is TX_lib_other["VisViva"](ApoOrPerHeight, ApoOrPerHeight+ship:body:radius).
  local CircList is list(time:seconds + ApoOrPerETA, 0, 0, DvNeededForCirc).
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](CircList).
}

Function MoonToReferencePlanet {
  Parameter StartingBody.
  Parameter TargetPlanet.
  Parameter TargetPeriapsis is 0.5*StartingBody:orbit:semimajoraxis.
  Parameter TargetInclination is 3.1416.

  HUDtext("returning from a moon", 5, 2, 30, red, true).

  if StartingBody:body = sun {
    local JunkTime is time:seconds + 2.
    until time:seconds > JunkTime {
      print "ERROR, not orbiting a moon".
    }
  }

  TX_lib_other["WarpSetter"](75).
  local AngleFromPeriapsis is 100.

  until AngleFromPeriapsis < 10 {
    set AngleFromPeriapsis to vang(body:orbit:velocity:orbit, ship:position - body:position).
    wait 0.
    TX_lib_readout["RetrogradeAngleGUI"](AngleFromPeriapsis, 0).
  }

  TX_lib_other["WarpDecreaser"]().

  local TargetSMA is ship:altitude + 1.05 * ship:body:soiradius + ship:body:radius.
  local DvNeededForExit is TX_lib_other["VisViva"](ship:altitude, TargetSMA).
  local ExitList is list(time:seconds, 0, 0, DvNeededForExit).
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](ExitList).

  local CriticalHeight is 100000.
  if ship:body:body:atm:exists {
    set CriticalHeight to 2*ship:body:body:atm:height.
  }

  local Warptime is time:seconds + eta:transition.
  warpto(Warptime).
  wait until time:seconds > Warptime + 5.
  print "out of moon SOI".

  if ship:orbit:periapsis < CriticalHeight {
    print "Correction needed!".
    local NewList is list(time:seconds + 30, 0, 0, 0).
    local NewScoreList is list(CriticalHeight).
    local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal_timeplus_timemin_prograde_retrograde_radialin_radialout").
    local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Periapsis", NewScoreList, NewRestrictionList).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
  }

  // circularize at the rough periapsis
  local NewList is list(time:seconds + eta:periapsis, 0, 0, 0).
  local NewScoreList is list().
  local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("nothing").
  local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Circularize", NewScoreList, NewRestrictionList).
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).

 // match inclination
  if TargetInclination = 3.1416 {
    wait 0.
  } else {
    TX_lib_transfer_burn["InclinationMatcher2"](TargetInclination).
  }

  local TargetSMA is (TargetPeriapsis + ship:orbit:periapsis)/2 + ship:body:radius.
  local DvNeededForTarPer is TX_lib_other["VisViva"](ship:periapsis, TargetSMA).
  local TarPerList is list(time:seconds + eta:periapsis, 0, 0, DvNeededForTarPer).
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](TarPerList).

  local ManVal1 is abs(TargetPeriapsis-ship:orbit:periapsis).
  local ManVal2 is abs(TargetPeriapsis-ship:orbit:apoapsis).
  local ApoOrPerETA is "x".

  if ManVal1 < ManVal2 {
    set ApoOrPerETA to eta:periapsis.
  } else {
    set ApoOrPerETA to eta:apoapsis.
  }

  local NewList is list(time:seconds + ApoOrPerETA, 0, 0, 0).
  local NewScoreList is list().
  local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal_timeplus").
  local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Circularize", NewScoreList, NewRestrictionList).
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
}

Function MoonToMoon {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.
  print "work in progress a niffo".
}

Function ChangeOrbit {
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  if abs(TargetInclination - ship:orbit:inclination) > 0.04 {
    TX_lib_transfer_burn["InclinationMatcher2"](TargetInclination).
  }

  local TargetSMA is (TargetPeriapsis + ship:orbit:periapsis)/2 + ship:body:radius.
  local DvNeededForTarPer is TX_lib_other["VisViva"](ship:periapsis, TargetSMA).
  local TarPerList is list(time:seconds + eta:periapsis, 0, 0, DvNeededForTarPer).
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](TarPerList).

  local ManVal1 is abs(TargetPeriapsis-ship:orbit:periapsis).
  local ManVal2 is abs(TargetPeriapsis-ship:orbit:apoapsis).
  local ApoOrPerETA is "x".

  if ManVal1 < ManVal2 {
    set ApoOrPerETA to eta:periapsis.
  } else {
    set ApoOrPerETA to eta:apoapsis.
  }

  local NewList is list(time:seconds + ApoOrPerETA, 0, 0, 0).
  local NewScoreList is list().
  local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal_timeplus").
  local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Circularize", NewScoreList, NewRestrictionList).
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
}

}

print "read lib_transfer".
