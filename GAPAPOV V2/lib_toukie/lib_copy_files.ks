global TX_lib_copy_files is lexicon(
  "CopyAndRunFile", CopyAndRunFile@,
  "CopyFile", CopyFile@,
  "DependenciesContinued", DependenciesContinued@
).

local TXStopper is "[]".

Function CopyFile {
  parameter TargetFile.
  parameter FileLocation is "0:/".
  parameter FileDestination is "".

  set string1 to FileLocation + TargetFile.
  deletepath(TargetFile).
  if exists(string1) = true {
    if open(string1):size > path(FileDestination):volume:freespace {
      HUDtext( "Not enough storage! Need more storage", 15, 2, 45, red, true).
      wait 999.
      HUDtext( "Skipping copying " +string1 + "reboot later and delete old files", 15, 2, 45, red, true).
    } else {
      copypath(string1, FileDestination).
    }
  } else {
      HUDtext( string1 + " doesn't exist", 15, 2, 45, red, true).
  }
}

Function CopyAndRunFile {
  parameter TargetFile.
  parameter FileLocation is "0:/".
  parameter FileDestination is "".

  set string1 to FileLocation + TargetFile.
  deletepath(TargetFile).

  if exists(string1) = true {
    if open(string1):size > path(FileDestination):volume:freespace {
      HUDtext( "Not enough storage! Need more storage", 15, 2, 45, red, true).
      wait 999.
      HUDtext( "Skipping copying " + TargetFile + " reboot later and delete old files", 15, 2, 45, red, true).
    } else {
      //print "ssssssssssssssssssssssssss".
      //print "string1: " + string1.
    //  print "FileDestination: " + FileDestination.
    //  print "TargetFile: " + TargetFile.
    //  print "ssssssssssssssssssssssssss".
      copypath(string1, FileDestination).
      // files has been copied to directory f but still needs to be run
      local CurrentDirec is path().
      cd(FileDestination).
      runpath(TargetFile).
      cd(CurrentDirec).
    }
  } else {
      HUDtext( string1 + " doesn't exist", 15, 2, 45, red, true).
  }
}

Function DependenciesContinued {

  list processors in ProList.
  local DirectoryList is list().
  local PreferredDirectory is "unknown".
  local FirstDirectory is ProList[0].
  local NoTag is true.

  if ProList:length > 1 {
    set NoTag to false.
    HUDtext( "Give your KOS processors tags in the VAB!", 15, 2, 45, red, true).
    for SomeProcessor in ProList {
      DirectoryList:add(SomeProcessor:tag).
    }
    set PreferredDirectory to DirectoryList[ProList:length-1]. // last one gets preference
  } else {
    //HUDtext( "DONT TAG YOUR PROCESSOR WHEN YOU ONLY HAVE ONE", 15, 2, 45, red, true).
    HUDtext( "REVERT TO VAB AND REMOVE TAG IF PROBLEMS OCCUR", 15, 2, 45, red, true).
    set PreferredDirectory to "1".
    set FirstDirectory to "1".
    if ProList[0]:tag <> "" {
      set NoTag to false.
      HUDtext( "Tag found!", 15, 2, 45, green, true).
      set PreferredDirectory to ProList[0]:tag.
      set PreferredDirectory to ProList[0]:tag.
    }
  }

  for directory in DirectoryList {
    cd(directory + ":/").
    list files in SomeFileList.
    for SomeFile in SomeFileList {
      if SomeFile:name:contains("lib") {
        deletepath(SomeFile).
      }
    }
  }

  if NoTag = false {
    cd(FirstDirectory:tag + ":/").
  } else {
    cd("1:/").
  }

  HUDtext( "Preferred Directory: " + PreferredDirectory, 15, 5, 45, green, true).
  local NUSFcopy is uniqueset().
  for file in NonUniqueSetFinal {
    NUSFcopy:add(file).
  }

  local filestring is "".
  local counter is 2.


  //print "NonUniqueSetFinal: " + NonUniqueSetFinal.

  //print "DirectoryList " + DirectoryList.
  //print "NUSFcopy: " + NUSFcopy.
  //cd(DirectoryList[0] +":/").

  until NonUniqueSetFinal:length = 0 {
    For FileName in NonUniqueSetFinal {
      if FileName:contains("lib_") {
        //print "copying: " + FileName + " from 0:/lib_toukie/ " + "to " + PreferredDirectory + ":/".
        TX_lib_copy_files["CopyAndRunFile"](FileName, "0:/lib_toukie/", PreferredDirectory + ":/").
      } else if FileName:contains("exe_") {
        TX_lib_copy_files["CopyFile"](FileName, "0:/exe_toukie/", PreferredDirectory + ":/").
      }
      set filestring to filestring + FileName.
    }

    //print "filestring " + FileString.

    // put all files of NUSFcopy in a string and check if the files on archive match

    cd(PreferredDirectory + ":/").
    local TempList is list().
    list files in TempList.
    if NoTag = false {
      cd(FirstDirectory:tag + ":/").
    }

    //print "TempList: " + TempList.
    //print "NUSFcopy: " + NUSFcopy.
    //print "====+++====".

    for SomeFile in TempList {
      local FileToString is SomeFile:name.
      local EndKS is FileToString:find(".ks").
      if EndKS > 0 {
        local RemoveKS is FileToString:substring(0, EndKS).
        if FileString:contains(RemoveKS) {
          NUSFcopy:remove(RemoveKS).
        }
      }
    }

    //maybe not needed?
    set filestring to "".
    //print "NUSFcopy: " + NUSFcopy.
    //print "=========".
    // delete files that are on the PreferredDirectory from the NUSFcopy

    //print "DirectoryList: " + DirectoryList.
    //print "prolist length: " + ProList:length.

    set NonUniqueSetFinal to NUSFcopy.
    if NUSFcopy:length > 0 {
      if ProList:length >= counter {
        set PreferredDirectory to DirectoryList[ProList:length-counter].
        set counter to counter + 1.
        //print "PreferredDirectory: " + PreferredDirectory.
      }
    }
  }
}

print "read lib_copy_files".
