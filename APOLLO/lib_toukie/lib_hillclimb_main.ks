global TX_lib_hillclimb_main is lexicon(
  "BoundaryGetter", BoundaryGetter@,
  "ScoreFunction", ScoreFunction@,
  "GoldenSearch", GoldenSearch@,
  "Hillclimber", Hillclimber@,
  "MinGoldSection", MinGoldSection@
).
local TXStopper is "[]".

Function BoundaryOverflowPrevention {
  parameter CurrentX.
  parameter IndexNeeded.

  if IndexNeeded <> 0 { // if anything else than the time is bigger than 50k set it to 50k
    if CurrentX > 50000 {
      set CurrentX to 50000.
      set StepSize to OriginalStepSize.
    }
  }
  return CurrentX.
}

Function BoundaryGetter {
  parameter Nodelist.   // (time:seconds + 30, 0, 0, 10)
  parameter IndexNeeded. // 3
  parameter ScoreSystem. // "inclinatotion", "circularization", etc
  parameter ParameterList.// parameters for score function ie. apoapsis height
  parameter StepDirection is (1).
  parameter StepSize is 0.1. // starting StepSize 0.1

  local CurrentX is Nodelist[IndexNeeded].  // 10
  set Currentx to BoundaryOverflowPrevention(currentx, IndexNeeded).
  local CurrentScore is ScoreSystem(Nodelist, ParameterList). // ie. 0.004
  local XandScore is list(CurrentX, CurrentScore). // (10, 0.004)

  local ScoreList is list(XandScore). // (10, 0.004)
  local CurrentData is 0.
  local TempStepSize is StepSize.
  global StepSize is StepSize.
  global OriginalStepSize is StepSize.

  // until scorelist has three entries keep adding them to the list
  until ScoreList:length = 3 {
    set CurrentData to ScoreList[ScoreList:length -1]. // (10, 0.004)
    set CurrentX to CurrentData[0]. // 10
    set Currentx to BoundaryOverflowPrevention(currentx, IndexNeeded).

    local NewNodeList is NodeList:copy.
    NewNodeList:remove(IndexNeeded).

    local NewNodeListOrg is NewNodeList:copy.
    local OrgX is CurrentX. // pre updated x
    NewNodeListOrg:insert(IndexNeeded, CurrentX). // original value: 10
    set OrgScore to ScoreSystem(NewNodeListOrg, ParameterList).

    set CurrentX to CurrentX + StepDirection * StepSize. // 9.9
    set Currentx to BoundaryOverflowPrevention(currentx, IndexNeeded).
    local NewNodeListPlus is NewNodeList:copy.
    NewNodeListPlus:insert(IndexNeeded, CurrentX). // + step value: 9.9
    set PlusScore to ScoreSystem(NewNodeListPlus, ParameterList).

    local NewNodeListMin is NewNodeList:copy.
    local MinX is CurrentX -2*StepDirection*StepSize.
    set MinX to BoundaryOverflowPrevention(currentx, IndexNeeded).
    NewNodeListMin:insert(IndexNeeded, MinX). // two steps in the opposite direction: 10.1
    set MinScore to ScoreSystem(NewNodeListMin, ParameterList).

    local BestScore is min(OrgScore, PlusScore).
    local BestScore is min(BestScore, MinScore).

    if BestScore = OrgScore {
      set CurrentX to OrgX.
    } else if BestScore = MinScore {
      set CurrentX to MinX.
    } // other wise it's the current CurrentX


    local DataList is list().
    DataList:add(CurrentX).
    DataList:add(BestScore).
    set StepSize to StepSize * 2. // -0.2

    local MaxStepSize is 1000.
    if StepSize > MaxStepSize {
      set StepSize to MaxStepSize.
    }
    ScoreList:add(DataList).
  }

  local BreakAttempt is 0.
  until ScoreList[1][1] <= ScoreList[0][1] and ScoreList[1][1] <= ScoreList[2][1] {
    local TempList is list().
    for ListData in ScoreList {
      TempList:add(ListData).
    }
    TempList:remove(0). // removed oldest entry

    local OldScoreList is list(). // makes a list of the old scorelist to compare with the new scorelist
    for ListData in ScoreList {
      OldScoreList:add(ListData).
    }

    set CurrentData to TempList[1]. // newest entry (only two entries because the oldest got deleted)
    set CurrentX to CurrentData[0]. // x value of newest entry
    set Currentx to BoundaryOverflowPrevention(currentx, IndexNeeded).

    ////////////////

    local NewNodeList is NodeList:copy.
    NewNodeList:remove(IndexNeeded).

    local NewNodeListOrg is NewNodeList:copy.
    local OrgX is CurrentX. // pre updated x
    NewNodeListOrg:insert(IndexNeeded, CurrentX). // original value: 10
    set OrgScore to ScoreSystem(NewNodeListOrg, ParameterList).

    set CurrentX to CurrentX + StepDirection * StepSize. // 9.9
    set Currentx to BoundaryOverflowPrevention(currentx, IndexNeeded).
    local NewNodeListPlus is NewNodeList:copy.
    NewNodeListPlus:insert(IndexNeeded, CurrentX). // + step value: 9.9
    set PlusScore to ScoreSystem(NewNodeListPlus, ParameterList).

    local NewNodeListMin is NewNodeList:copy.
    local MinX is CurrentX -2*StepDirection*StepSize.
    set MinX to BoundaryOverflowPrevention(currentx, IndexNeeded).
    NewNodeListMin:insert(IndexNeeded, MinX). // two steps in the opposite direction: 10.1
    set MinScore to ScoreSystem(NewNodeListMin, ParameterList).

    local BestScore is min(OrgScore, PlusScore).
    local BestScore is min(BestScore, MinScore).

    if BestScore = OrgScore {
      set CurrentX to OrgX.
    } else if BestScore = MinScore {
      set CurrentX to MinX.
    } // other wise it's the current CurrentX


    local DataList is list().
    DataList:add(CurrentX).
    DataList:add(BestScore).
    set StepSize to StepSize * 2.

    local MaxStepSize is 1000.
    if StepSize > MaxStepSize {
      set StepSize to MaxStepSize.
    }
    TempList:add(DataList).
    set ScoreList to TempList.

    // if new score is worse than old score or all the new scores are the same
    if (round(ScoreList[0][1], 3) > round(OldScoreList[0][1],3)
    and round(ScoreList[1][1],3) > round(OldScoreList[1][1],3)
    and round(ScoreList[2][1],3) > round(OldScoreList[2][1],3))
    or (ScoreList[0][1]=ScoreList[1][1]=ScoreList[2][1]) {
      if BreakAttempt = 1 {
        HUDTEXT("no improvement in either way breaking", 5, 2, 30, red, false).
        break.
      }
      set BreakAttempt to 1.
      HUDTEXT("no improvement made! switching sign and resetting StepSize.", 5, 2, 30, red, false).
      //print "no improvement made! switching sign and resetting StepSize.".
      //set StepDirection to StepDirection*-1.
      set StepSize to TempStepSize/10.
      local MinStepSize is 10^(-6).
      if StepSize < MinStepSize {
        set StepSize to MinStepSize.
      }
      set TempStepSize to StepSize.
    }

  }
  //print "final ScoreList: " + ScoreList.
  return ScoreList.
}

Function ScoreFunction {
  parameter NodeList.
  parameter IndexNeeded.
  parameter ParameterList.
  parameter ScoreSystem.
  parameter Value.

  local NewNodeList is list().
  for item in NodeList {
    NewNodeList:add(item).
  }
  NewNodeList:remove(IndexNeeded). // (time:seconds + 30, 0, 0)
  NewNodeList:insert(IndexNeeded, Value).
  set NewScore to ScoreSystem(NewNodeList, ParameterList).
  return NewScore.
}

Function GoldenSearch {
  parameter Nodelist.   // (time:seconds + 30, 0, 0, 10)
  parameter IndexNeeded. // 3 = prograde
  parameter ParameterList.// parameters for score function ie. apoapsis height
  parameter ScoreSystem. //@Squared or similar
  // if list [0] = start [1] = end [2] = scoresystem
  parameter StepDirection is (1).
  parameter StepSize is 1e-5. // 0.001
  parameter xtol is 1e-5.
  parameter ftol is 1e-5.

  //log "IndexNeeded: " + IndexNeeded to ("0:/aplog").

  if time:seconds > NodeList[0] {
    set NodeList[0] to time:seconds + 15.
    HUDtext("passed node eta", 15, 2, 30, green, true).
  }

  local DecentScoreList is "x".
  local GoodValue is "x".
  local OwnBoundariesUsed is false.

  if defined OwnBoundaries {

    //HUDtext("Own boundaries: " + OwnBoundaries, 15, 2, 30, red, true).
    //local OwnBoundaries is list("time_prograde", list(time1, time2), list(pro1, pro2)).
    local BoundaryLex is lexicon().
    local BoundaryStep is 1.

    if OwnBoundaries[0]:contains("time") {
      BoundaryLex:add(0, OwnBoundaries[BoundaryStep]).
      set BoundaryStep to BoundaryStep + 1.
    }

    if OwnBoundaries[0]:contains("radial") {
      BoundaryLex:add(1, OwnBoundaries[BoundaryStep]).
      set BoundaryStep to BoundaryStep + 1.
    }

    if OwnBoundaries[0]:contains("normal") {
      BoundaryLex:add(2, OwnBoundaries[BoundaryStep]).
      set BoundaryStep to BoundaryStep + 1.
    }

    if OwnBoundaries[0]:contains("prograde") {
      BoundaryLex:add(3, OwnBoundaries[BoundaryStep]).
      set BoundaryStep to BoundaryStep + 1.
    }

    if BoundaryLex:haskey(IndexNeeded) {
      set OwnBoundariesUsed to true.
      //log OwnBoundaries to ("0:/aplog").
      //log "---" to ("0:/aplog").
      local OwnBoundaries is BoundaryLex[IndexNeeded].
      // IMPORTANT OWNBOUNDRIES is like a start and end point per node item: [0] = time [1] = radial etc
      set GoodValue to MinGoldSection(ScoreFunction@:bind(NodeList, IndexNeeded, ParameterList, ScoreSystem),
      OwnBoundaries[0],
      OwnBoundaries[1],
      xtol,
      ftol).

    }


  }

  if OwnBoundariesUsed = false {
    set DecentScoreList to BoundaryGetter(NodeList, IndexNeeded, ScoreSystem, ParameterList, StepDirection, StepSize).
    set GoodValue to MinGoldSection(ScoreFunction@:bind(NodeList, IndexNeeded, ParameterList, ScoreSystem),
    DecentScoreList[0][0],
    DecentScoreList[2][0],
    xtol,
    ftol).
  }

  //print "decent score list: " + DecentScoreList.

  NodeList:remove(IndexNeeded).
  NodeList:insert(IndexNeeded, GoodValue).
  return NodeList.
}

Function Hillclimber {
  parameter NodeList.
  parameter ParameterList.
  parameter ScoreSystem.
  parameter Restrictions.
  parameter StepDirection is (1).
  parameter StepSize is 1e-5. // 0.001
  parameter xtol is 1e-5.
  parameter ftol is 1e-5.

  TX_lib_gui["CancelHillclimb"]().

  local RestrictionTypes is list("time", "radial", "normal", "prograde").
  local ResLex is lexicon("time", 0, "radial", 1, "normal", 2, "prograde", 3).
  local AvailableTypes is list().
  local ResIndex is 0.

  for item in RestrictionTypes {
    if not Restrictions:contains(RestrictionTypes[ResIndex]) {
      AvailableTypes:add(item).
    }
    set ResIndex to ResIndex + 1.
  }


  local OldScore is ScoreSystem(NodeList, ParameterList).
  local NewScore is 0.
  local OldStep is 0.
  local NewStep is 0.

  until 1=0 {
    local OldScore is ScoreSystem(NodeList, ParameterList).

    if time:seconds > NodeList[0] {
      set NodeList[0] to time:seconds + 30.
      HUDtext("passed node eta", 15, 2, 30, green, true).
    }

    for item in AvailableTypes {
      local IndexNeeded is ResLex[item].
      set OldStep to NodeList[IndexNeeded].
      set NodeList to GoldenSearch(Nodelist, IndexNeeded, ParameterList, ScoreSystem, StepDirection, StepSize, xtol, ftol).
      set NewStep to NodeList[IndexNeeded].
    }



    local NewScore is ScoreSystem(NodeList, ParameterList).

    print "Oldscore: " + round(OldScore, 10).
    print "NewScore: " + round(NewScore, 10).
    print "difference: " + abs(round(OldScore, 5)-round(NewScore, 5)).
    print "OldStep: " + round(OldStep, 10).
    print "NewStep: " + round(NewStep, 10).
    print "difference: " + abs(round(OldStep, 5)-round(NewStep, 5)).
    print "=====================================".



    if (OldScore - NewScore) < 10^(-5){
      break.
    }

    // cancel Hillclimber GUI
    if exists(CancelHillclimber) {
      break.
    }
  }

  hcgui:hide().

  if defined OwnBoundaries {
    unset OwnBoundaries. // overrides the boudnary getter
  }

  return NodeList.
}

function MinGoldSection {
  parameter fn, a, b, xtol is 1e-5, ftol is 1e-5.

  //log "starting A " + a to ("0:/aplog").
  //log "starting B " + b to ("0:/aplog").

  local golden is 2 / (1 + sqrt(5)).
  local cgolden is 1 - golden.
  local c is golden * a + cgolden * b.
  local d is cgolden * a + golden * b.

  // a---c--d---b
  local fa is fn(a).
  local fb is fn(b).
  local fc is fn(c).
  local fd is fn(d).
  local dx is 0.
  local df is 0.
  local next is 0. // 1 if next update is C, 2 if D

  if fc < fa and fc < fd {
    set dx to d - a.
    set df to min(abs(fd - fc), abs(fa - fc)).
    // relabel D as B, C as D
    set b to d.
    set fb to fd.
    set d to c.
    set fd to fc.
    set next to 1.
  }

  else if fd < fc and fd < fb {
    set dx to b - c.
    set df to min(abs(fc - fd), abs(fb - fd)).
    // relabel C as A, D as C
    set a to c.
    set fa to fc.
    set c to d.
    set fc to fd.
    set next to 2.
  }

  else if fc < fd {
    set dx to d - a.
    set df to min(abs(fd - fc), abs(fa - fc)).
    // relabel D as B, C as D
    set b to d.
    set fb to fd.
    set d to c.
    set fd to fc.
    set next to 1.
  }

  else {
    set dx to b - c.
    set df to min(abs(fc - fd), abs(fb - fd)).
    // relabel C as A, D as C
    set a to c.
    set fa to fc.
    set c to d.
    set fc to fd.
    set next to 2.
  }

  until abs(dx) < xtol or abs(df) < ftol {
    if next = 1 {
      set c to golden * a + cgolden * b.
      set fc to fn(c).
    }
    else {
      set d to cgolden * a + golden * b.
      set fd to fn(d).
    }

    if fc < fa and fc < fd {
      set dx to d - a.
      set df to min(abs(fd - fc), abs(fa - fc)).
      // relabel D as B, C as D
      set b to d.
      set fb to fd.
      set d to c.
      set fd to fc.
      set next to 1.
    }

    else if fd < fc and fd < fb {
      set dx to b - c.
      set df to min(abs(fc - fd), abs(fb - fd)).
      // relabel C as A, D as C
      set a to c.
      set fa to fc.
      set c to d.
      set fc to fd.
      set next to 2.
    }

    else if fc < fd {
      set dx to d - a.
      set df to min(abs(fd - fc), abs(fa - fc)).
      // relabel D as B, C as D
      set b to d.
      set fb to fd.
      set d to c.
      set fd to fc.
      set next to 1.
    }

    else {
      set dx to b - c.
      set df to min(abs(fc - fd), abs(fb - fd)).
      // relabel C as A, D as C
      set a to c.
      set fa to fc.
      set c to d.
      set fc to fd.
      set next to 2.
    }
  }
  // return the argument of the minimal value found so far
  //log "A " + a to ("0:/aplog").
  //log "B " + b to ("0:/aplog").
  //log "C " + c to ("0:/aplog").
  //log "D " + d to ("0:/aplog").
  if next = 1 { return d. }
  else { return c. }
}


print "read lib_hillclimb_main".
