Function GUISetup1 {
  set gui to gui(400).
  set gui1 to gui(300).
  set gui2 to gui(300).

  set RendWindows to false.
  /// GUI Input window

  local label1 is gui:addlabel("<b><size=30>ToukieDatak's GAPAPOV!</size></b>").
  set label1:style:align to "center".
  local label2 is gui:addlabel("<b><size=20>Go Ahead, Pick Any Planet Or Vessel!*</size></b>").
  set label2:style:align to "center".
  set gui:addlabel("<b><size=9>*no refunds if the script doesn't work</size></b>"):style:align to "center".
  gui:addlabel("<size=20>    </size>").
  gui:addlabel("<size=20> Important: set patched conics to >5 </size>").
  gui:addlabel("<size=15>Target destination: </size>").

  if hastarget = true {
    if target:mass > 10^15 {
      set textbox1 to gui:addtextfield(target:name).
    } else {
      set textbox1 to gui:addtextfield("Duna").
    }
  } else {
    set textbox1 to gui:addtextfield("Duna").
  }

  gui:addlabel("<size=15>    </size>").
  gui:addlabel("<size=15>Periapsis at the target destination:</size>").
  set textbox2 to gui:addtextfield("70000").
  gui:addlabel("<size=15>    </size>").
  gui:addlabel("<size=15>Inclination at the target destination:</size>").
  set textbox3 to gui:addtextfield("0").
  gui:addlabel("<size=15>    </size>").
  set RendButton  to gui:addbutton("rendezvous").
  set applybutton to gui:addbutton("apply").

  gui:show().

  set RendButton:onclick  to RendOptions@.
  set applybutton:onclick to CheckOptions@.
}

Function CheckOptions {

  clearscreen.
  gui2:dispose().
  set gui2 to gui(400).
  local label3 is gui2:addlabel("<size=15>Errors:</size>").
  gui2:addlabel("<size=15>    </size>").
  set label3:style:align to "center".

  local ProceedToPeriapsisCheck is BodyNameCheck().
  FalseErrorSetter().
  if ProceedToPeriapsisCheck = true {
    set ErrorMessage1 to PeriapsisCheck().
    set ErrorMessage2 to InclinationCheck().
  } else {
    set ErrorMessage001 to true.
  }

  ErrorMessageShower().

  gui2:show().

  if ErrorMessage1 = false and ErrorMessage2 = false and ErrorMessage001 = false {
    gui1:show().
    gui2:hide().
  }
}

Function RendOptions {
  local gui4 is gui(350).
  set gui4:addlabel("<b><size=15>pick a vessel to perform a rendezvous with:</size> </b>"):style:align to "center".
  if hastarget = true {
    set RendText to gui4:addtextfield(target:name).
  } else {
    set RendText to gui4:addtextfield("Eagle").
  }
  set RendConf to gui4:addbutton("confirm").
  gui4:show().
  set RendConf:onclick to RendOptionsConf@.
}

Function RendOptionsConf {
  set RendWindows to true.
  set FinishProcedure to true.
}

Function BodyNameCheck {
  local GivenName is textbox1:text.
  set GUIEmptyBodyList to list().
  list bodies in BodyList.
  For IndividualBody in BodyList {
    if IndividualBody:name = GivenName {
      GUIEmptyBodyList:add(IndividualBody).
    }
  }
  if GUIEmptyBodyList:length = 1 {
    return true.
  } else {
    return false.
  }
}

Function PeriapsisCheck {
 local DataString is (textbox2:text + ".0").
 local StringToNumber is DataString:tonumber(-27).

  if GUIEmptyBodyList[0]:atm:exists {
    if StringToNumber < GUIEmptyBodyList[0]:atm:height {
      set ErrorMessage101 to true.
      set ErrorBoolean to true.
    }
  }

  if StringToNumber <= 0 {
    set ErrorMessage102 to true.
    set ErrorMessage101 to false.
    set ErrorBoolean to true.
  }

  if StringToNumber = -27 {
    set ErrorMessage103 to true.
    set ErrorMessage102 to false.
    set ErrorMessage101 to false.
    set ErrorBoolean to true.
  }

  if StringToNumber > GUIEmptyBodyList[0]:soiradius {
    set ErrorMessage104 to true.
    set ErrorMessage103 to false.
    set ErrorBoolean to true.
  }

  return ErrorBoolean.
}

Function InclinationCheck {
  local DataString is textbox3:text.
  local StringToNumber is DataString:tonumber(-2727).

  if StringToNumber < 0 {
    set ErrorMessage201 to true.
    set ErrorBoolean1 to true.
  }

  if StringToNumber > 360 {
    set ErrorMessage202 to true.
    set ErrorBoolean1 to true.
  }

  if StringToNumber = -2727 {
    set ErrorMessage203 to true.
    set ErrorMessage201 to false.
    set ErrorBoolean1 to true.
  }

  return ErrorBoolean1.
}

Function FalseErrorSetter {
  set ErrorBoolean to false.
  set ErrorBoolean1 to false.
  set ErrorMessage1 to false.
  set ErrorMessage2 to false.
  set ErrorMessage001 to false.
  set ErrorMessage101 to false.
  set ErrorMessage102 to false.
  set ErrorMessage103 to false.
  set ErrorMessage104 to false.
  set ErrorMessage201 to false.
  set ErrorMessage202 to false.
  set ErrorMessage203 to false.
}

/// GUI 1 cancel / confirm buttons
Function GUISetup2 {
  local ConfirmButton is gui1:addbutton("confirm").
  local CancelButton  is gui1:addbutton("cancel").

  set ConfirmButton:onclick to ConfirmOptions@.
  set CancelButton:onclick to CancelOptions@.
}

Function ConfirmOptions {
  gui:hide().
  gui1:hide().
  gui2:hide().
  set FinishProcedure to true.
  wait 1.
}

Function CancelOptions {
  gui1:hide().
  gui2:hide().
  gui2:dispose().
}

// GUI 2 error messages

Function ErrorMessageShower {

  if ErrorMessage001 = true {
    set gui2:addlabel("<size=15>incorrect body name</size>"):style:align to "center".
    gui2:addlabel("<size=15>    </size>").
  }

    if ErrorMessage101 = true {
      set gui2:addlabel("<size=15>periapsis under atmosphere</size>"):style:align to "center".
      gui2:addlabel("<size=15>    </size>").
    }
    if ErrorMessage102 = true {
      set gui2:addlabel("<size=15>periapsis under surface</size>"):style:align to "center".
      gui2:addlabel("<size=15>    </size>").
    }
    if ErrorMessage103 = true {
      set gui2:addlabel("<size=15>periapsis input contains letters, use numbers only</size>"):style:align to "center".
      gui2:addlabel("<size=15>    </size>").
    }
    if ErrorMessage104 = true {
      set gui2:addlabel("<size=15>periapsis too high, outside of SOI</size>"):style:align to "center".
      gui2:addlabel("<size=15>    </size>").
    }

    if ErrorMessage201 = true {
      set gui2:addlabel("<size=15>inclination under 0 degrees, [0, 360]</size>"):style:align to "center".
      gui2:addlabel("<size=15>    </size>").
    }
    if ErrorMessage202 = true {
      set gui2:addlabel("<size=15>inclination above 360 degrees, [0, 360]</size>"):style:align to "center".
      gui2:addlabel("<size=15>    </size>").
    }
    if ErrorMessage203 = true {
      set gui2:addlabel("<size=15>inclination input contains letters, use numbers only</size>"):style:align to "center".
      gui2:addlabel("<size=15>    </size>").
    }
}

//

Function CompleteParameterGUI {
  GUISetup1().
  GUISetup2().
  set FinishProcedure to false.
  until FinishProcedure = true {
    wait 2.
  }
  clearguis().
  if RendWindows = false {
    set TargetBody to GUIEmptyBodyList[0].
    set TargetPeriapsis to textbox2:text:tonumber().
    set TargetInclination to textbox3:text:tonumber().
    set ParameterList to list(TargetBody, TargetPeriapsis, TargetInclination).
  } else {
    set TargetVessel to RendText:text.
    set ParameterList to list(TargetVessel).
  }

  return ParameterList.
}


  ////////////////
 /// NOT USED ///
////////////////

Function ArrivedAtPlanetGUI {
  set gui3 to gui(300).
  set FinishProcedurex to false.
  set gui3:addlabel("Although the ship isn't at its destination, it might not have enough Dv to make it."):style:align to "center".
  set gui3:addlabel("Current Dv left:"):style:align to "center".
  local CurrentDv is CurrentDvCalc(true).
  print CurrentDv.
  set gui3:addlabel(char(34) + round(CurrentDv) + char(34)):style:align to "center".
  set gui3:addlabel("To continue without refueling press continue."):style:align to "center".
  set gui3:addlabel("To stop here for now press exit, after refueling type 'reboot.' in the terminal."):style:align to "center".
  local continuebutton is gui3:addbutton("continue").
  local exitbutton is gui3:addbutton("exit").

  gui3:show().

  set ContinueButton:onclick to ContinueGUI@.
  set ExitButton:onclick to ExitGUI@.

  wait until FinishProcedurex = true.
}

Function ContinueGUI {
  gui3:hide().
  gui3:dispose().
  set FinishProcedurex to true.
  set ContinueJourney to true.
  wait 1.
}

Function ExitGUI {
  gui3:hide().
  gui3:dispose().
  set FinishProcedurex to true.
  set ContinueJourney to false.
}

print "read lib_gui".
