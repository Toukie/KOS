@lazyglobal off.

// SECOND CORE SHIZZLE
// (first core:) if CancelInclinationHillclimb exists set incl penalty to ZERO

global TX_lib_hillclimb_canceler is lexicon(
  "HillClimbCancel", HillClimbCancel@,
  "HillCancelOptionHider", HillCancelOptionHider@
).
local TXStopper is "[]".

local HillGUI is gui(400).
local CanInclButton is "x".
local CanPerButton is "x".
local CanDvButton is "x".
local CancelStatus is "x".

Function HillClimbCancel {

  set CancelStatus to 0.
  HillGUI:dispose().
  set HillGUI to gui(400).
  HillGUI:addlabel("<size=15>If the maneuver making takes too long you can cancel the parameter which is holding back the hillclimber (a lower score is good)</size>").
  set CanInclButton to HillGUI:addbutton("cancel inclination penalty").
  set CanPerButton to HillGUI:addbutton("cancel periapsis penaly").
  set CanDvButton to HillGUI:addbutton("cancel delta v penalty").
  set CanInclButton:onclick to CancelInclination@.
  set CanPerButton:onclick  to CancelPeriapsis@.
  set CanDvButton:onclick to CancelDv@.

  set HillGUI:x to -200.
  set HillGUI:y to 300.

  HillGUI:show().
  TX_lib_gui_dv_penalty["DvButtonShow"]().
}

Function CancelInclination {
  set CancelStatus to CancelStatus + 1.
  log "" to CancelInclinationHillclimb.ks.
  CanInclButton:hide().

  if CancelStatus = 3 {
    HillGUI:hide().
  }
}

Function CancelPeriapsis {
  set CancelStatus to CancelStatus + 1.
  log "" to CancelPeriapsisHillclimb.ks.
  CanPerButton:hide().

  if CancelStatus = 3 {
    HillGUI:hide().
  }
}

Function CancelDv {
  set CancelStatus to CancelStatus + 1.
  log "" to CancelDvHillclimb.ks.
  CanDvButton:hide().

  if CancelStatus = 3 {
    HillGUI:hide().
  }
}

Function HillCancelOptionHider {
  HillGUI:hide().
  deletepath(CancelInclinationHillclimb).
  deletepath(CancelPeriapsisHillclimb).
  TX_lib_gui_dv_penalty["GetRidOfDvGUI"]().
}

print "read lib_hillclimb_canceler".
