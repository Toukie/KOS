

{

global TX_lib_rendezvous is lexicon(
  "CompleteRendezvous", CompleteRendezvous@
  ).
  local TXStopper is "[]".

local FinalMan is "x".

Function EnsureSmallerOrbit {
  Parameter TargetDestination.

  HUDtext("Smaller Orbit: start", 15, 2, 30, red, true).

  if ship:orbit:periapsis > TargetDestination:orbit:periapsis {
    local DvNeeded is TX_lib_other["VisViva"](ship:orbit:apoapsis, (ship:orbit:apoapsis + 0.9*TargetDestination:periapsis)/2 + ship:body:radius).
    local LowerList1 is list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](LowerList1).
  }

  if ship:orbit:apoapsis > TargetDestination:orbit:apoapsis {
    local DvNeeded is TX_lib_other["VisViva"](ship:orbit:periapsis, (ship:orbit:periapsis + 0.9*TargetDestination:apoapsis)/2 + ship:body:radius).
    local LowerList2 is list(time:seconds+eta:periapsis, 0, 0, DvNeeded).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](LowerList2).
  }

  HUDtext("Smaller Orbit: done" , 15, 2, 30, red, true).

}

Function RendezvousSetup {

  parameter TargetDestination.

	if true = false {
      local ArgOfPer1 is ship:orbit:argumentofperiapsis.
      local ArgOfPer2 is TargetDestination:orbit:argumentofperiapsis.
      local TrueAnomalyTargetPer is ArgOfPer2-ArgOfPer1.

	  HUDtext("TA of target Pe on current orbit: " + TrueAnomalyTargetPer, 15, 2, 30, red, true).

        if TrueAnomalyTargetPer < 0 {
        set TrueAnomalyTargetPer to 360 - abs(TrueAnomalyTargetPer).
		HUDtext("TA of target Pe on current orbit: " + TrueAnomalyTargetPer, 15, 2, 30, yellow, true).
      }
	 }

	  local Per1 is time:seconds + eta:periapsis.
	  local Per2 is time:seconds + TX_lib_true_anomaly["ETAToTrueAnomaly"](TargetDestination, 0).

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

    //HUDtext("Cur Per " + per1, 5, 2, 30, white, true).
    //HUDtext("Tar Ship Per " + per2, 5, 2, 30, white, true).
    //HUDtext("Cur Tar TA " + TrueAnomalyTargetPer, 30, 2, 30, white, true).

      local TimeTargetPeriapsis is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, TrueAnomalyTargetPer).

      //print "Time till target periapsis:   " + TimeTargetPeriapsis.

      local SMA is ship:orbit:semimajoraxis.
      local Ecc is ship:orbit:eccentricity.
      local CurRadiusAtTargetPeriapsis is (SMA * ( (1-ecc^2) / (1+ecc*cos(TrueAnomalyTargetPer))))-body:radius.
      local FinalMan is "x".

      if ship:orbit:semimajoraxis < TargetDestination:orbit:semimajoraxis {
        HUDtext("cur SMA < tar SMA", 30, 2, 30, white, true).
        local InputList is list(time:seconds + TimeTargetPeriapsis, 0, 0, 0).
        local NewScoreList is list(TargetDestination).
        local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal_radialout_radialin_timeplus_timemin").
        set FinalMan to TX_lib_hillclimb_universal["ResultFinder"](InputList, "ApoapsisMatch", NewScoreList, NewRestrictionList).
      } else {
        HUDtext("tar SMA < cur SMA", 30, 2, 30, white, true).
        local InputList is list(time:seconds + TimeTargetPeriapsis, 0, 0, 0).
        local NewScoreList is list(TargetDestination).
        local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal_radialout_radialin_timeplus_timemin").
        set FinalMan to TX_lib_hillclimb_universal["ResultFinder"](InputList, "PerApoMatch", NewScoreList, NewRestrictionList).
      }

      TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
}

Function MatchOrbit {
  Parameter TargetDestination.

  local ThetaChange is TX_lib_inclination["RelativeAngleCalculation"](TargetDestination).

  print "Matching inclination".

  until ThetaChange < 0.04 {
   TX_lib_inclination["InclinationMatcher"](TargetDestination).
   set ThetaChange to TX_lib_inclination["RelativeAngleCalculation"](TargetDestination).
  }

  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  //EnsureSmallerOrbit(TargetDestination).
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  print "Circularizing".

  if ship:orbit:eccentricity > 0.00001 {
    local InputList is list().
    if ship:orbit:apoapsis > TargetDestination:orbit:periapsis {
      set InputList to list(time:seconds + eta:periapsis, 0, 0, 0).
    } else {
      set InputList to list(time:seconds + eta:apoapsis, 0, 0, 0).
    }
    local NewScoreList is list(TargetDestination).
    local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal").
    set FinalMan to TX_lib_hillclimb_universal["ResultFinder"](InputList, "Circularize", NewScoreList, NewRestrictionList).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
  }



  print "Rendezvous approach".

  RendezvousSetup(TargetDestination).


  if ship:orbit:semimajoraxis > TargetDestination:orbit:semimajoraxis {
    HUDtext("Lowering Orbit", 5, 2, 30, white, true).
    print "lowering orbit".
    local DvNeeded is TX_lib_other["VisViva"](ship:orbit:periapsis, TargetDestination:orbit:semimajoraxis).
    local LowerList is list(time:seconds+eta:periapsis, 0, 0, DvNeeded).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](LowerList).
  } else {
    HUDtext("Increasing Orbit", 5, 2, 30, white, true).
    print "Increasing orbit".
    local DvNeeded is TX_lib_other["VisViva"](ship:orbit:apoapsis, TargetDestination:orbit:semimajoraxis).
    local LowerList is list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](LowerList).
  }

  if true = false {
    HUDtext("Matching Orbit", 5, 2, 30, white, true).
    print "Matching up orbit".
    local InputList is list(time:seconds + eta:apoapsis, 0, 0, 0).
    local NewScoreList is list(TargetDestination).
    local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal_radialout_radialin_timeplus_timemin").
    set FinalMan to TX_lib_hillclimb_universal["ResultFinder"](InputList, "PerPerMatch", NewScoreList, NewRestrictionList).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
  }

}

Function FinalApproach {
  Parameter TargetDestination.
  Parameter StepsNeeded is 1.

  local TimeTillDesiredTrueAnomaly is TX_lib_true_anomaly["ETAToTrueAnomaly"](TargetDestination, 180, eta:apoapsis).

  local CurPeriod is ship:orbit:period.
  local TarPeriod is CurPeriod + (TimeTillDesiredTrueAnomaly/StepsNeeded).

  local TarSMA is (((TarPeriod^2)*ship:body:mu)/(4*constant:pi^2))^(1/3).

  local DvNeeded is TX_lib_other["VisViva"](ship:orbit:apoapsis, TarSMA).
  local ApproachList is list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
  local ApproachNode is node(ApproachList[0], ApproachList[1], ApproachList[2], ApproachList[3]).
  add ApproachNode.
  wait 0.

  if nextnode:orbit:hasnextpatch {
    if nextnode:orbit:nextpatch:body <> ship:orbit:body{
      until nextnode:orbit:nextpatch:body = ship:orbit:body{
        set StepsNeeded to StepsNeeded + 1.

        set CurPeriod to ship:orbit:period.
        set TarPeriod to CurPeriod + (TimeTillDesiredTrueAnomaly/StepsNeeded).

        set TarSMA to (((TarPeriod^2)*ship:body:mu)/(4*constant:pi^2))^(1/3).

        local DvNeeded is TX_lib_other["VisViva"](ship:orbit:apoapsis, TarSMA).
        set ApproachList to list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
      }
    }
  }

  remove ApproachNode.
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](ApproachList).

  HUDtext("correction done", 5, 2, 30, white, true).

  wait 5.
  local TargetTime is "x".
  if StepsNeeded > 1 {
    set TargetTime to time:seconds - 10 + (StepsNeeded-1)*ship:orbit:period.
    warpto(TargetTime).
  } else {
    set TargetTime to time:seconds - 10 + 0.75*ship:orbit:period.
    warpto(TargetTime).
  }
  HUDtext("Warping some more", 5, 2, 30, white, true).
  //print "warping some more".
  wait until time:seconds > TargetTime.
  wait 5.
  local TimeTillDesiredTrueAnomaly is TX_lib_true_anomaly["ETAToTrueAnomaly"](TargetDestination, 180).
  set TargetTime to time:seconds + TimeTillDesiredTrueAnomaly - 10.
  warpto(TargetTime).
  HUDtext("Warped more", 5, 2, 30, white, true).
  //print "warped some more".
  wait until time:seconds > TargetTime.
  wait 7.

  local Distance1 is (TargetDestination:position - ship:position):mag.
  if  Distance1 > 15000 {
    set warp to 0.
    until kuniverse:timewarp:issettled = true {
      wait 1.
    }
    HUDtext("Warping again 1x", 5, 2, 30, white, true).
    //print "too far away, warping again".
    local AbsCurTarApo is abs(ship:orbit:apoapsis - TargetDestination:orbit:apoapsis).
    local AbsCurTarPer is abs(ship:orbit:periapsis - TargetDestination:orbit:periapsis).

    local TimeTillDesiredTrueAnomaly is eta:periapsis.
    if AbsCurTarApo < AbsCurTarPer {
      set TimeTillDesiredTrueAnomaly to eta:apoapsis.
    }

    set TargetTime to time:seconds + TimeTillDesiredTrueAnomaly - 10.
    warpto(TargetTime).
    wait until time:seconds > TargetTime.
  }

  local Distance2 is (TargetDestination:position - ship:position):mag.
  if  Distance2 > 15000 {
    set warp to 0.
    until kuniverse:timewarp:issettled = true {
      wait 1.
    }
    HUDtext("Warping again 2x", 5, 2, 30, white, true).
    //print "too far away, warping again".
    local AbsCurTarApo is abs(ship:orbit:apoapsis - TargetDestination:orbit:apoapsis).
    local AbsCurTarPer is abs(ship:orbit:periapsis - TargetDestination:orbit:periapsis).

    local TimeTillDesiredTrueAnomaly is eta:periapsis.
    if AbsCurTarApo < AbsCurTarPer {
      set TimeTillDesiredTrueAnomaly to eta:apoapsis.
    }
    set TargetTime to time:seconds + TimeTillDesiredTrueAnomaly - 10.
    warpto(TargetTime).
    wait until time:seconds > TargetTime.
  }
}

Function MainRelVelKill {
  Parameter TargetDestination.

  local VectorNeeded is (TargetDestination:velocity:orbit - ship:velocity:orbit).
  local NodeList is TX_lib_other["NodeFromVector"](VectorNeeded).
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](NodeList).
}

Function GoToTarget {
  Parameter TargetDestination.
  Parameter SpeedNeeded.

  local InitialVector is TargetDestination:position - ship:position.
  local VectorNeeded  is InitialVector:normalized * SpeedNeeded.
  local NodeList is TX_lib_other["NodeFromVector"](VectorNeeded).
  TX_lib_hillclimb_man_exe["ExecuteManeuver"](NodeList).
}

Function VeryFinalApproach {

  Parameter TargetDestination.

  local lock Distance to (TargetDestination:position - ship:position):mag.
  set warpmode to "rails".

  if Distance > 15000 {
    MainRelVelKill(TargetDestination).
    TX_lib_steering["SteeringTarget"](TargetDestination).
    GoToTarget(TargetDestination, 50).
    TX_lib_steering["SteeringTargetRet"](TargetDestination).
    set warp to 2.
    wait until Distance < 10000.
    set warp to 0.
    MainRelVelKill(TargetDestination).
  }

  if Distance > 3000 {
    //print "3000 meters".
    MainRelVelKill(TargetDestination).
    TX_lib_steering["SteeringTarget"](TargetDestination).
    GoToTarget(TargetDestination, 30).
    TX_lib_steering["SteeringTargetRet"](TargetDestination).
    set warp to 1.
    wait until Distance < 1000.
    set warp to 0.
    MainRelVelKill(TargetDestination).
  }

  MainRelVelKill(TargetDestination).
  TX_lib_steering["SteeringTarget"](TargetDestination).
  GoToTarget(TargetDestination, 10).
  TX_lib_steering["SteeringTargetRet"](TargetDestination).
  set warp to 1.
  wait until Distance < 275.
  set warp to 0.
  MainRelVelKill(TargetDestination).
}

Function CompleteRendezvous {
  Parameter TargetDestination.

  local Distance is (TargetDestination:position - ship:position):mag.
  if Distance > 7500 {
    MatchOrbit(TargetDestination).
    FinalApproach(TargetDestination, 5).
  }
  MainRelVelKill(TargetDestination).
  VeryFinalApproach(TargetDestination).
}

}

print "read lib_rendezvous".
