To run GAPAPOV you will first need to install KOS: https://ksp-kos.github.io/KOS/downloads_links.html#obtain

Then drag the /Script/ folder from the zip file into your KSP install's /Ships/ folder and merge the folders if needed.

If you already have an old version of GAPAPOV installed, delete:
	- lib_toukie (folder)
	- exe_toukie (folder)
	- bootup_toukie (file inside of the boot folder)

To open the KOS terminal right click the KOS processor and activate it. When IN ORBIT type the following to start the program, press the ENTER key to finish the sentence:

copypath("0:/boot/bootup_toukie", "").

runpath(bootup_toukie).

___________________________________________________________________________________________________

IMPORTANT TECHNICAL CONFIGURATIONS:

A high orbit is advised because you'll be able to use a higher timewarp.

Increase the amount of patches KSP will show to >4. If this doesn't happen some calculations can't be run.
To increase patches open KSP and go to:
  - Settings
  - Graphics
  - Conic Patch Limit

Accidental moon encounters have a big chance of messing stuff up.

___________________________________________________________________________________________________

I just got an error message telling me that the boot script or main script is out of date, what do I do?

First delete:
	- lib_toukie (folder)
	- exe_toukie (folder)
	- bootup_toukie (file inside of the boot folder)

And download the newest version from: https://github.com/Toukie/KOS/releases
Drag the /Script/ file from the zip file into the KSPfolder/Ships/ folder of your KSP install.
reboot the processor by typing:

reboot.

Still getting an error message? Then your boot script is out of date.
Eventhough you've replaced the boot file with the newest version the KOS processor still runs the old version.
The new versions of GAPAPOV update it automaticly if your script is out of date but the older versions dont
have the updater. So, to fix this manually type the following the KOS terminal:

deletepath("1:/boot/bootup_toukie").
copypath("0:/boot/bootup_toukie", "1:/boot/").
reboot.

If you still have problems make sure you've downloaded the newest version of GAPAPOV and make sure to delete the
old files as mentoined above.
___________________________________________________________________________________________________
