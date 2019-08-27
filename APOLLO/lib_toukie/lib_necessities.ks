global TX_lib_necessities is lexicon(
  "DoNecessities", DoNecessities@
).

local TXStopper is "[]".


Function DoNecessities {
  TX_lib_stage["StageCheck"]().

  when ship:status = "SUB_ORBITAL" then {

    for m in ship:modulesnamed("ModuleProceduralFairing") {
      m:doevent("deploy").
    }

    wait 1.
    panels on.
  }
}

print "read lib_necessities".
