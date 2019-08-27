global TX_lib_gui_file_picker is lexicon(
  "MenuPicker", MenuPicker@
).
local TXStopper is "[]".

local TimeOut is false.

Function SetUp {
  clearguis().
  global gui1 is gui(400, 500).
  set gui1:y to 200.
  global gui2 is gui(400, 500).
  set gui2:y to 200.
  global DoneWaiting is false.
  global DoneWaiting2 is false.
  deletepath(missionrunner).
}

Function MenuPicker {
  parameter ChosenSeries is "none".

  SetUp().
  if ChosenSeries = "none" {
    AllFilesGetter().
  } else {
    SeriesFilesGetter(ChosenSeries).
  }

  until DoneWaiting = true {
    wait 0.3.
    if TimeOut = true {
      break.
    }
  }

  if TimeOut = true {
    set TimeOut to false.
    if exists(MenuRunner) {
      deletepath(MenuRunner).
    }
    log "MenuPicker()." to MenuRunner.
    run MenuRunner.
  } else {
    clearguis().
    run missionrunner.
  }
}

Function SeriesFilesGetter {
  parameter ChosenSeries.

  local AvailableFiles is open("0:/missions_toukie/" + ChosenSeries).

  local Label1 is gui1:addlabel("<b><size=20> Choose a file to run</size></b>").
  set Label1:style:align to "center".
  local SB is gui1:addscrollbox().
  set SB:valways to true.

  local FileLex is lexicon().
  local FileLexLoc is lexicon().
  local FileNumber is 0.

  for SomeFile in AvailableFiles {
    local IndivFile is SB:addbutton(SomeFile:name).
    set IndivFile:style:width to 350.
    set IndivFile:style:align to "center".
    set IndivFile:style:fontsize to 25.

    local IndividualFileNum is "File" + FileNumber.
    FileLex:add(IndividualFileNum, IndivFile).
    FileLexLoc:add(IndividualFileNum, SomeFile:name).
    set FileNumber to FileNumber + 1.
  }

  local LexIndex is 0.
  until LexIndex = FileLex:length {
    local CurLength is LexIndex.
    set FileLex["File" + LexIndex]:onclick to {
      set CopyPaste to FileLexLoc["File" + CurLength].
      log "TX_lib_copy_files["+ char(34) + "CopyAndRunFile" + char(34) + "](" + char(34) + CopyPaste + char(34) + ", " + char(34) + "0:/missions_toukie/" + ChosenSeries + "/" + char(34) + ")." to missionrunner.
      set DoneWaiting to true.
    }.
    set LexIndex to LexIndex + 1.
  }
  sb:addspacing(30).
  local BackButton is sb:addbutton("Back").
  set BackButton:style:fontsize to 25.
  set BackButton:style:width to 350.
  set BackButton:style:align to "center".
  set BackButton:onclick to {set TimeOut to true.}.
  gui1:show().
}

Function AllFilesGetter {
  local Folders is open("0:/missions_toukie/").
  local ChosenSeries is "".

  local FolderNumber is 0.
  local label1 is gui2:addlabel("<b><size=20> Choose a folder</size></b>").
  set label1:style:align to "center".
  local SB2 is gui2:addscrollbox().
  set SB2:valways to true.

  local FileLex is lexicon().
  local FileLexLoc is lexicon().

  For Folder in Folders {
    local FolderButton is SB2:addbutton(Folder:tostring).
    set FolderButton:style:fontsize to 25.
    set FolderButton:style:height to 35.
    set FolderButton:style:width to 350.
    set FolderButton:style:align to "center".
    local FolderButtonNum is "Folder" + FolderNumber.
    FileLex:add(FolderButtonNum, FolderButton).
    FileLexLoc:add(FolderButtonNum, Folder:name).
    set FolderNumber to FolderNumber + 1.
  }

  local LexReadingLength is 0.
  until LexReadingLength = FileLex:length {
    local CurLength is LexReadingLength.
    set FileLex["Folder" + CurLength]:onclick to {
      set ChosenSeries to FileLexLoc["Folder" + CurLength].
      gui2:hide().
      set DoneWaiting2 to true.
    }.
    set LexReadingLength to LexReadingLength + 1.
  }


  gui2:show().

  wait until DoneWaiting2 = true.

  SeriesFilesGetter(ChosenSeries).
}
