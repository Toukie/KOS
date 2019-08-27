global TX_lib_crew is lexicon(
  "WaitTillEVA", WaitTillEVA@
).

local TXStopper is "[]".

Function WaitTillEVA {
  local OldCrew is ship:crew().
  HUDtext("please EVA", 15, 2, 30, green, true).
  wait until ship:crew():length = OldCrew:length - 1.

  until ship:crew():length = OldCrew:length {
    wait 10.
    HUDtext("please board", 5, 2, 30, green, false).
  }

  HUDtext("welcome back", 5, 2, 30, green, false).
}

print "read lib_crew".
