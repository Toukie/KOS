{

global D_ManExe is lexicon(
  "DvCalc", DvCalc@,
  "TimeTillManeuverBurn", TimeTillManeuverBurn@,
  "PerformBurn", PerformBurn@,
  "ExecuteManeuver", ExecuteManeuver@
  ).

Function DvCalc {

  Parameter Input. // list of node-worthy items

  set FinalManeuver to node(Input[0], Input[1], Input[2], Input[3]).
  add FinalManeuver.
  wait 0.
  set DvNeeded to FinalManeuver:deltav:mag.

  SET eIsp TO 0.
  List engines IN my_engines.
  For eng In my_engines{
    SET eIsp TO eISP + ((eng:maxthrust/maxthrust)*eng:isp).
  }
  SET Ve TO eIsp*9.80665.

  set CurDv to Ve * ln(ship:mass / ship:drymass).
  set EndDv to CurDv - DvNeeded.
  //print "Current Dv: " + CurDv.
  //print "Final Dv:   " + EndDv.

}
///
///
///

Function TimeTillManeuverBurn {

  Parameter StartTime.
  Parameter DvNeeded.
  Parameter ThrustLimit is 100.

  SET A0 TO (Maxthrust/mass).
  SET eIsp TO 0.
  List engines IN my_engines.
  For eng In my_engines{
    SET eIsp TO eISP + ((eng:maxthrust/maxthrust)*eng:isp).
  }
  SET Ve TO eIsp*9.80665.
  SET FinalMass TO (mass*constant():e^(-1*DvNeeded/Ve)).
  SET A1 TO (Maxthrust/FinalMass).
  local BurnTime is (DvNeeded/((A0+A1)/2)).
  SET BurnTime TO BurnTime * (100/ThrustLimit).

  set ETAStartT to (StartTime - BurnTime/2).
  set StartT to (ETAStartT+time:seconds).
  //print "eta node: " + StartTime at(1,19).
  //print "eta Start Time: " + ETAStartT at(1,20).
  //print "burn time: " + BurnTime at(1,21).
  //print "eta man: " + (StartTime + time:seconds) at(1,22).
  //print "absolute start time: " + StartT at(1,23).

}

///
///
///

// TIME:SECONDS GETS ADDED HERE
FUNCTION PerformBurn {

  Parameter EndDv.
  Parameter StartT.
  Parameter ThrustLimit is 100.
  Parameter NoManeuver  is false.

  set StopBurn to false.

  if NoManeuver = false {
    T_Steering["SteeringManeuver"]().
    if nextnode:deltav:mag < 0.02 {
      set StopBurn to true.
    }
  }

  warpto(StartT-10).

  if NoManeuver = false {
    lock steering to nextnode:deltav.
  }

  wait until time:seconds > StartT.
  //print "ready to burn".

  until StopBurn = true {

    SET eIsp TO 0.
    List engines IN my_engines.
    For eng In my_engines{
      SET eIsp TO eISP + ((eng:maxthrust/maxthrust)*eng:isp).
      SET eng:ThrustLimit to ThrustLimit.
    }
    SET Ve TO eIsp*9.80665.

    set CurDv to Ve * ln(ship:mass / ship:drymass).

    set MaxAcc to ship:maxthrust/ship:mass.

    set DeltaVMag to (CurDv - EndDv).
    lock throttle to MIN(DeltaVMag/MaxAcc, 1).
    if DeltaVMag < 0 {
      lock throttle to 0.
    }

    if throttle < 0.00001 {
      set throttle to 0.
      set StopBurn to true.
    }

    if NoManeuver = false {
      if nextnode:deltav:mag < 0.02 {
	       set throttle to 0.
         wait 3.
	       set StopBurn to true.

	      }
    }
 }

  unlock steering.
  until hasnode = false {
    wait 1.
    remove nextnode.
    wait 1.
  }

  For eng In my_engines{
    SET eng:ThrustLimit to 100.
  }

  //print "--".
  ///print "current dv: " + CurDv.
  ///print "end dv:     " + EndDv.
  ///print "dv left:    " + DeltaVMag.
}

Function ExecuteManeuver {
  Parameter NodeWorthyList.

  if round((abs(NodeWorthyList[1]) + abs(NodeWorthyList[2]) + abs(NodeWorthyList[3])), 2) > 0 {
  DvCalc(NodeWorthyList).
  TimeTillManeuverBurn(FinalManeuver:eta, DvNeeded).
  wait 0.
  PerformBurn(EndDv, StartT).
  }
}

}
print "read lib_hillclimb_man_exe".
