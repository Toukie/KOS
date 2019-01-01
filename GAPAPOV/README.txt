To run GAPAPOV you will first need to install KOS: https://ksp-kos.github.io/KOS/downloads_links.html#obtain

Then drag the Script folder from the zip file into your KSP install's Ships/ folder and merge the folders if needed.

If youre using steam you can right click KSP in the library and click on properties.
Click on the local files tab and click on browse local files.

If you already have an old version of GAPAPOV installed, delete:
	- lib_toukie (folder)
	- exe_toukie (folder)
	- missions_toukie (folder)
	- bootup_toukie (file inside of the boot folder)
	- bootup_updater (file inside of the boot folder)

Reinstall GAPAPOV by dragging the Script folder from GAPAPOV into the Ships folder from KSP.

In the VAB in game go to the same tab where you can find SAS and RCS thrusters and place a kOS processor on your craft.
Right click the kOS part and increase the storage capasity and make sure bootup_toukie is the bootfile.

=======
Add a KOS terminal part to your vessel and go to the launchpad.
To open the KOS terminal right click the KOS processor and activate it.
In the terminal, type and press ENTER once you're done:

edit startup.

Don't forget to use a period at the end, a new window should appear.
Copy the following piece of code using Ctrl + C and paste it in the new window by using Ctrl + V.

deletepath("1:/boot/bootup_toukie").
copypath("0:/boot/bootup_toukie", "1:/boot/").
reboot.

Click on the save button and in the first terminal type:

run startup.
_________________________________________________________________

IMPORTANT TECHNICAL CONFIGURATIONS:

Increase the amount of patches KSP will show to >4. If this doesn't happen some calculations can't be run.
To increase patches open KSP and go to:
  - Settings
  - Graphics
  - Conic Patch Limit

Accidental moon encounters have a big chance of messing stuff up.

_________________________________________________________________

I just got an error message telling me that the boot script or main script is out of date, what do I do?

First delete:
	- lib_toukie (folder)
	- exe_toukie (folder)
	- bootup_toukie (file inside of the boot folder)

And download the newest version from: https://github.com/Toukie/KOS/releases
Drag the /Script/ file from the zip file into the KSP folder Ships of your KSP install.
reboot the processor by typing:

reboot.

Still getting an error message? Then your boot script is out of date. Eventhough you've replaced the boot file with the newest version the KOS processor still runs the old version. The new versions of GAPAPOV update it automaticly if your script is out of date but the older versions dont have the updater. So, to fix this manually type the following the KOS terminal:

deletepath("1:/boot/bootup_toukie").
copypath("0:/boot/bootup_toukie", "1:/boot/").
reboot.

If you still have problems make sure you've downloaded the newest version of GAPAPOV and make sure to delete the old files as mentioned above.
_________________________________________________________________