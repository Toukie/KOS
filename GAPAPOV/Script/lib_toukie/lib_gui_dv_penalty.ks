
global TX_lib_gui_dv_penalty is lexicon (
  "DvButtonShow", DvButtonShow@,
  "GetRidOfDvGUI", GetRidOfDvGUI@,
  "CheckDvFileNames", CheckDvFileNames@
).
local TXStopper is "[]".

local DvGUI is gui(400).
local Incr10 is "x".
local Incr01 is "x".
local Decr01 is "x".
local Decr10 is "x".

Function DvButtonShow {

  DvGUI:dispose().
  set DvGUI to gui(400).
  DvGUI:addlabel("<size=15> Change how heavy the delta v penalty is</size>").
  DvGUI:addlabel("<size=10> Current penalty weight :</size>").
  DvGUI:addlabel(DvPenaltyModifier:tostring).
  // from hillclimb scoring
  set Incr10 to dvgui:addbutton("increase penalty weight by 1").
  set Incr01 to dvgui:addbutton("increase penalty weight by 0.1").
  set Decr01 to dvgui:addbutton("decrease penalty weight by 0.1").
  set Decr10 to dvgui:addbutton("decrease penalty weight by 1").

  set Incr10:onclick to Incr10Func@.
  set Incr01:onclick to Incr01Func@.
  set Decr01:onclick to Decr01Func@.
  set Decr10:onclick to Decr10Func@.

  set DvGUI:x to -200.
  set DvGUI:y to 0.

  DvGUI:show().
}

Function Incr10Func {
  log "" to DeltaVPenaltyIncr10.ks.
}

Function Incr01Func {
  log "" to DeltaVPenaltyIncr01.ks.
}

Function Decr01Func {
  log "" to DeltaVPenaltyDecr01.ks.
}

Function Decr10Func {
  log "" to DeltaVPenaltyDecr10.ks.
}

Function GetRidOfDvGUI {
  DvGUI:hide().
  deletepath(DeltaVPenaltyIncr10).
  deletepath(DeltaVPenaltyIncr01).
  deletepath(DeltaVPenaltyDecr01).
  deletepath(DeltaVPenaltyDecr10).
}

Function CheckDvFileNames {

  local GotIncOrDec is 0.

  if exists(DeltaVPenaltyIncr10) {
    set DvPenaltyModifier to DvPenaltyModifier + 1.
    deletepath(DeltaVPenaltyIncr10).
    set GotIncOrDec to 1.
  }

  if exists(DeltaVPenaltyIncr01) {
    set DvPenaltyModifier to DvPenaltyModifier + 0.1.
    deletepath(DeltaVPenaltyIncr01).
    set GotIncOrDec to 1.
  }

  if exists(DeltaVPenaltyDecr01) {
    set DvPenaltyModifier to DvPenaltyModifier - 0.1.
    deletepath(DeltaVPenaltyDecr01).
    set GotIncOrDec to 1.
  }

  if exists(DeltaVPenaltyDecr10) {
    set DvPenaltyModifier to DvPenaltyModifier - 1.
    deletepath(DeltaVPenaltyDecr10).
    set GotIncOrDec to 1.
  }

  if GotIncOrDec = 1 {
    DvButtonShow().
  }
}
