{

global T_Other is lexicon(
  "ish", ish@,
  "VisViva", VisViva@,
  "CurrentDvCalc", CurrentDvCalc@,
  "DistanceAtTime", DistanceAtTime@,
  "ClosestApproachGetter", ClosestApproachGetter@,
  "ClosestApproachRefiner", ClosestApproachRefiner@,
  "RemoveAllNodes", RemoveAllNodes@
  ).

Function ish {
  Parameter a.
  Parameter b.
  Parameter ishyness.
  return a - ishyness < b and a + ishyness > b.
}

Function VisViva {
  Parameter StartAlt.
  // At which altitude do you want to start the burn
  Parameter TargetSMA.
  // What's the SMA at the end?
  Parameter ReturnWanted is false.

  set GM to body:mu.
  set StartAlt to StartAlt + body:radius.
  // StartAlt parameter does NOT include the body's radius (so it's added here)
  set VeloStart to SQRT(GM * ((2/StartAlt) - (1/ship:orbit:semimajoraxis)) ).
  set VeloEnd to SQRT(GM * ((2/StartAlt) - (1/TargetSMA)) ).
  set DvNeeded to VeloEnd-VeloStart.

  if ReturnWanted = true {
    return DvNeeded.
  }
}

Function CurrentDvCalc {
  Parameter ReturnWanted is false.

  SET eIsp TO 0.
  List engines IN my_engines.
  For eng In my_engines{
    SET eIsp TO eISP + ((eng:maxthrust/maxthrust)*eng:isp).
  }
  SET Ve TO eIsp*9.80665.

  set CurDv to Ve * ln(ship:mass / ship:drymass).

  if ReturnWanted = true {
    return CurDv.
  }
}

/////////////////////////////////
/////////////////////////////////
/////////////////////////////////

Function DistanceAtTime {
  Parameter T.
  Parameter TargetDestination.

  return ((positionat(ship, T) - positionat(TargetDestination, T)):mag).
}

Function ClosestApproachGetter {

  Parameter PeriodPrecision.
  Parameter T.
  Parameter SurpassThis.
  Parameter TargetDestination.

  set MostFavourableOption to T.
  print round(SurpassThis) at(1,13).

  set Candidates to list().
  if ScoringNode:orbit:hasnextpatch = true {
    set StandardStepSize to ScoringNode:orbit:nextpatch:period * PeriodPrecision.
    //print "StanStep  " +StandardStepSize at (1,7).
  } else {
    set StandardStepSize to ScoringNode:orbit:period * PeriodPrecision.
    //print "StanStep  " +StandardStepSize at (1,7).
  }

  Set StepSize to StandardStepSize.
  set EndFunction to 0.

  //                  10
  until EndFunction = 50 {
    Candidates:add(list(T + StepSize, TargetDestination)).
    set StepSize to StepSize + StandardStepSize.
    set EndFunction to EndFunction + 1.
    }

  Set StepSize to StandardStepSize.
  set EndFunction to 0.

  //                  10
  until EndFunction = 50 {
    Candidates:add(list(T - StepSize, TargetDestination)).
    set StepSize to StepSize + StandardStepSize.
    set EndFunction to EndFunction + 1.
    }

    for Candidate in Candidates {
      local CandidateScore is DistanceAtTime(Candidate[0], Candidate[1]).
      print round(CandidateScore) at (1,10).
      print round(SurpassThis) at (1,11).
      if CandidateScore < SurpassThis {
        set SurpassThis to CandidateScore.
        set MostFavourableOption to Candidate[0].
        set ClosestApproach to DistanceAtTime(Candidate[0], Candidate[1]).
      }
    }
}

Function ClosestApproachRefiner {
  Parameter TargetDestination.
  Parameter PrecisionNumber is 0.01. // 0.05

  set ScoringNode to nextnode.

  if ScoringNode:orbit:hasnextpatch = true {
    set T to time:seconds + 0.5 * ScoringNode:orbit:nextpatch:period.
  } else {
  set T to time:seconds + 0.5 * ScoringNode:orbit:period.
  }

  set SurpassThis to DistanceAtTime(T, TargetDestination).
  //print PrecisionNumber.
  //print t.
  //print SurpassThis.
  //print TargetDestination.
  ClosestApproachGetter(PrecisionNumber, T, SurpassThis, TargetDestination).
  //print ClosestApproach.

  set multiplier to 0.05.

  if ScoringNode:orbit:hasnextpatch = true {
  //  until multiplier*ScoringNode:orbit:nextpatch:period < 1 {
      //set multiplier to multiplier/10.
      ClosestApproachGetter(multiplier, MostFavourableOption, ClosestApproach, TargetDestination).
  //  }
  } else {
  //  until multiplier*ScoringNode:orbit:period < 1 {
    //  set multiplier to multiplier/10.
      ClosestApproachGetter(multiplier, MostFavourableOption, ClosestApproach, TargetDestination).
  //  }
  }


  //clearscreen.
  print "m:     " + round(ClosestApproach) + "                      " at(1,10).
  print "km:    " + round(ClosestApproach/1000) + "                 " at(1,11).
  print "Mm:    " + round(ClosestApproach/1000000) + "              " at(1,12).
  print "Gm:    " + round(ClosestApproach/1000000000) + "           " at(1,13).
  return ClosestApproach.
}


///////////////////
///////////////////
///////////////////

Function RemoveAllNodes {
  until hasnode = false {
    remove nextnode.
    wait 1.
  }
}
}
print "read lib_other".
