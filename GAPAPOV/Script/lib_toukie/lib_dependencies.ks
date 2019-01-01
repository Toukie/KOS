global TX_lib_dependencies is lexicon(
  "Dependencies", Dependencies@,
  "AllDepencies", AllDepencies@
).
  local TXStopper is "[]".

local UniqueSetList is uniqueset().
local UniqueSetList2 is uniqueset().
global UniqueSetFinal is uniqueset().
global NonUniqueSetFinal is list().
global CacheList is list().

Function Dependencies {
  Parameter FilePath.
  Parameter TargetList is UniqueSetList.

  set ScriptToString to open(FilePath):readall:string.

  local FirstFind is ScriptToString:find("TX_").
  local FirstEnd  is ScriptToString:findat("[", FirstFind + 2).

  local LowestNum is min(FirstFind, FirstEnd).
  local HighestNum is max(FirstFind, FirstEnd).
  // having 0 on the right side of if HighestNum and LowestNum <> -1 { always gives false

  if HighestNum and LowestNum <> -1 {
    local OnlyOneMatch is false.
    local PotentialString is ScriptToString:substring(FirstFind+3, (FirstEnd-FirstFind)-3).
    if PotentialString:contains(char(32)) or PotentialString:contains("@") or PotentialString:contains("boot") or PotentialString:contains("dependencies") {
      local FirstFind is ScriptToString:findat("TX_", FirstFind +2).
      local FirstEnd  is ScriptToString:findat("[", FirstFind + 2).
      if FirstFind = -1 {
        set OnlyOneMatch to true.
      } else {
        set PotentialString to ScriptToString:substring(FirstFind+3 , (FirstEnd-FirstFind)-3).
      }
    }

    if OnlyOneMatch = false {
      TargetList:add(PotentialString).
    }

    local OldFind is FirstFind.

    until false {
      local NewFind is ScriptToString:findat("TX_", OldFind + 2).
      if NewFind = -1 {
        break.
      }
      local NewEnd is ScriptToString:findat("[", NewFind + 2).
      local PotentialString is ScriptToString:substring(NewFind +3, (NewEnd-NewFind) -3).

      if PotentialString:contains(char(32)) or PotentialString:contains("@") or PotentialString:contains("boot") or PotentialString:contains("dependencies") {
        wait 0.
      } else {
        TargetList:add(ScriptToString:substring(NewFind+3, (NewEnd-NewFind)-3)).
      }
      set OldFind to NewFind.
    }
  }
}

Function AllDepencies {
  parameter FilePath.

  Dependencies(FilePath, UniqueSetList).

  local RanOnce is false.
  local FileCache is uniqueset().

  until UniqueSetList:length = 0 and RanOnce = true {
    for TXFileName in UniqueSetList {
      local LibTXPath is "x".
      if TXFileName:contains("lib_") {
        set LibTXPath to "0:/lib_toukie/" + TXFileName.
      } else if TXFileName:contains("exe_") {
        set LibTXPath to "0:/exe_toukie/" + TXFileName.
      }
      if exists(LibTXPath) {
        Dependencies(LibTXPath, UniqueSetList2).
      }
    }

    for FileName in UniqueSetList {
      FileCache:add(FileName).
    }

    for FileName in UniqueSetList2 {
      UniqueSetList:add(FileName).
    }

    for FileName in UniqueSetList {
      UniqueSetFinal:add(FileName).
    }

    for FileName in FileCache {
      UniqueSetList:remove(FileName).
    }

    set RanOnce to true.

  }
  FileCache:clear().
  local PathPrefix is "0:/".

  for FileName in UniqueSetFinal {

    if FileName:contains("lib_") {
      set PathPrefix to "0:/lib_toukie/".
    } else if FileName:contains("exe_") {
      set PathPrefix to "0:/exe_toukie/".
    }
    if exists(PathPrefix + FileName) = true {
      FileCache:add(FileName).
    }
  }
  UniqueSetFinal:clear().
  For FileName in FileCache {
    if FileName:contains("lib_") {
      set PathPrefix to "0:/lib_toukie/".
    } else if FileName:contains("exe_") {
      set PathPrefix to "0:/exe_toukie/".
    }
    local CompletePath is PathPrefix + FileName.
    if CompletePath:contains("lib_") and CompletePath:contains("exe_") {
      wait 0.
    } else {
      UniqueSetFinal:add(FileName).
    }
  }

// putting all items of unique set into a list (with order)

for FileName in UniqueSetFinal {
  NonUniqueSetFinal:add(FileName).
}

// putting exe file at the end
  FileCache:clear().
  wait 0.

  For FileName in NonUniqueSetFinal {
    if FileName:contains("exe_") {
      CacheList:add(FileName).
    }
  }

// exe files are now at the end
LOCAL NumberCycle IS NonUniqueSetFinal:LENGTH - 1.
UNTIL NumberCycle < 0 {
  IF CacheList:CONTAINS(NonUniqueSetFinal[NumberCycle]) {
    NonUniqueSetFinal:REMOVE(NumberCycle).
  }
  SET NumberCycle TO NumberCycle - 1 .
}

for FileName in CacheList {
  NonUniqueSetFinal:add(FileName).
}

  For FileName in NonUniqueSetFinal {

    if FileName:contains("lib_") {
      TX_boot["CopyAndRunFile"](FileName, "0:/lib_toukie/").
    } else if FileName:contains("exe_") {
      TX_boot["CopyFile"](FileName, "0:/exe_toukie/").
    }

  }
}
print "read lib_dependencies".
