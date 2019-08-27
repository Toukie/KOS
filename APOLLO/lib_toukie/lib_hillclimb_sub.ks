// this used to be my main hillclimber



{

local BestCandidate is list().
local Candidates    is list().

///
/// MAIN
///
// if input = output --> no progress, move on!

global TX_lib_hillclimb_sub is lex(
  "ResultFinder",        ResultFinder@,
  "ScoreImproveCompare", ScoreImproveCompare@,
  "Score",               Score@,
  "StepFunction",        StepFunction@,
  "EvenOrUnevenChecker", EvenOrUnevenChecker@,
  "Improve",             Improve@,
  "IndexFiveFolderder", IndexFiveFolderder@
  ).

local TXStopper is "[]".

Function ResultFinder {
  Parameter NodeList.
  Parameter ScoreType.
  Parameter ParameterList.
  Parameter RestrictionTypeList.


  local Best100dv is ScoreImproveCompare(NodeList,  ScoreType, ParameterList, RestrictionTypeList[0], 100).
  local Best10dv  is ScoreImproveCompare(Best100dv, ScoreType, ParameterList, RestrictionTypeList[1], 10).
  local Best1dv   is ScoreImproveCompare(Best10dv,  ScoreType, ParameterList, RestrictionTypeList[2], 1).
  local Best01dv  is ScoreImproveCompare(Best1dv,   ScoreType, ParameterList, RestrictionTypeList[3], 0.1).
  return             ScoreImproveCompare(Best01dv,  ScoreType, ParameterList, RestrictionTypeList[4], 0.01).
}

Function ScoreImproveCompare {
  Parameter InitialNodeList.
  Parameter ScoreType.
  Parameter ParameterList.
  Parameter RestrictionType.
  Parameter Increment.

  local NodeList is InitialNodeList:copy.

  until false {
    local OldNodeList is NodeList:copy.
    local OldScore is Score(OldNodeList, ScoreType, ParameterList).
    set NodeList to Improve(OldNodeList, ScoreType, ParameterList, RestrictionType, Increment).
    local NewScore is Score(NodeList, ScoreType, ParameterList).
    if round(OldScore, 6) <= round(NewScore, 6) {
      return OldNodeList.
    }
  }
}

///
/// SCORE
///

Function Score {
  Parameter NodeList.
  Parameter ScoreType.
  Parameter ParameterList.

  set result to TX_lib_hillclimb_score[ScoreType](NodeList, ParameterList).

  if Result < 0 {
    set Result to 2^64.
    print "result under 0            " at(1,26).
  }

  return Result.
}


///
/// IMPROVE
///

local StepOptions is lex(
  "timeplus",   0,
  "timemin",    1,
  "radialout",  2,
  "radialin",   3,
  "realnormal", 4,
  "antinormal", 5,
  "prograde",   6,
  "retrograde", 7
).

local StepSizeList is list(
  0, 0, 0, 0, 0, 0, 0, 0
).

Function StepFunction {
  Parameter StepType.
  Parameter StepSize.
  Parameter NodeList.
  Parameter RestrictionType.

  local EmptyStepList is StepSizeList:copy.

  if EvenOrUnevenChecker(StepOptions[StepType]) = "uneven" {
    set StepSize to -1 * StepSize.
  }

  if not RestrictionType:contains(StepType) {

    StepSizeList:remove(StepOptions[StepType]).
    StepSizeList:insert(StepOptions[StepType], StepSize).

    Candidates:add(list(
      NodeList[0]+StepSizeList[0]+StepSizeList[1],
      NodeList[1]+StepSizeList[2]+StepSizeList[3],
      NodeList[2]+StepSizeList[4]+StepSizeList[5],
      NodeList[3]+StepSizeList[6]+StepSizeList[7])).

    set StepSizeList to EmptyStepList.
  } else {
    print "Restriction found!" at(1,25).
    Candidates:add(list(NodeList[0], NodeList[1], NodeList[2], constant():pi)).
  }
}

Function EvenOrUnevenChecker {
  Parameter Number.

  if floor(Number/2) = ceiling(Number/2) {
    return "even".
  } else {
    return "uneven".
  }
}

Function Improve {
  Parameter NodeList.
  Parameter ScoreType.
  Parameter ParameterList.
  Parameter RestrictionType.
  Parameter Increment.

  local ScoreToBeat   is Score(NodeList, ScoreType, ParameterList).
  set BestCandidate to NodeList:copy.
  set Candidates    to list().
  local CandidateScore is 2^60.
  wait 0.

  StepFunction("timeplus",   Increment, NodeList, RestrictionType).
  StepFunction("timemin",    Increment, NodeList, RestrictionType).
  StepFunction("radialout",  Increment, NodeList, RestrictionType).
  StepFunction("radialin",   Increment, NodeList, RestrictionType).
  StepFunction("realnormal", Increment, NodeList, RestrictionType).
  StepFunction("antinormal", Increment, NodeList, RestrictionType).
  StepFunction("prograde",   Increment, NodeList, RestrictionType).
  StepFunction("retrograde", Increment, NodeList, RestrictionType).

  for Candidate in Candidates {
    if Candidate[3] = constant():pi {
      set CandidateScore to 2^64.
    } else {
    set CandidateScore to Score(Candidate, ScoreType, ParameterList).
    }
    //clearscreen.
    set CandidateScore to round(CandidateScore, 5).
    set ScoreToBeat to round(ScoreToBeat, 5).
    print "CandidateScore: " + CandidateScore + "                     "at (1,28).
    print "ScoreToBeat..:    " + ScoreToBeat + "                        " at (1,29).
    if CandidateScore < ScoreToBeat {
      set ScoreToBeat to CandidateScore.
      set BestCandidate to Candidate.
    }
  }
  return BestCandidate.
  }

Function IndexFiveFolderder {
  parameter WantedIndex.

  return list(WantedIndex, WantedIndex, WantedIndex, WantedIndex, WantedIndex).
}
///
/// END OF MAIN BRACKETS
///

}



print "read lib_hillclimb_sub".