The ZBOT NAV Editor Command Menu Readme.txt
[Modified: March 16th, 2019]

-----
Mod/Author Information:
----------

Title : ZBOT NAV Editor Command Menu
Author : s0nought
Version : 1.2
Homepage : https://gamebanana.com/guis/34522

-----
Description:
----------

The ZBOT NAV Editor Command Menu is a GUI Mod for Counter-Strike 1.6 which features a number of useful commands to ease the work with the navigation mesh for the official Counter-Strike Bot V1.50 created by Michael S. Booth.

-----
Installing:
----------

Copy all the files from the ZIP archive to the mod directory (...\cstrike).

-----
Unstalling:
----------

Please follow the instructions below to remove the ZBOT NAV Editor Command Menu and restore the original command menu:

 1. Delete ...\cstrike\autoexec.cfg
 2. Delete ...\cstrike\commandmenu.txt
 3. Move ...\cstrike\zbotnavcm\commandmenu.txt.bak to ...\cstrike
 4. Rename "commandmenu.txt.bak" to "commandmenu.txt"
 5. [Previous installations] Delete ...\cstrike\zbotnavcm.cfg
 6. Close this document and delete ...\cstrike\zbotnavcm directory

-----
Usage:
----------

When in-game, press [H] to open the command menu. Use the mouse to navigate the menu. Click the left mouse button on the highlighted menu button to activate it.

Most of the available commands act like tools: select a command from the menu and click the left mouse button to apply it to the highlighted zone.

Function reference:

1. NAV EDITOR [ON/OFF] - [TOGGLE] Turn the NAV Editor on and off.

2. CURRENT ZONE

2.1. MARK / UNMARK - [TOGGLE] Mark/Unmark the current zone.

2.2. SPLIT - Split the current zone.

2.3. DELETE - Delete the current zone.

3. MARK ZONE AND ...

3.1. MERGE WITH ANOTHER - Place the cursor on the first zone and click the left mouse button to mark that zone. Place the cursor on the second zone and click the left mouse button to merge the marked zone with the current zone.

3.2. SPLICE TO ANOTHER - Place the cursor on the first zone and click the left mouse button to mark that zone. Place the cursor on the second zone and click the left mouse button to splice the marked zone with the current zone.

3.3. CONNECT WITH ANOTHER - Place the cursor on the first zone and click the left mouse button to mark that zone. Place the cursor on the second zone and click the left mouse button to connect the marked zone with the current zone.

3.4. DISCONNECT FROM ANOTHER - Place the cursor on the first zone and click the left mouse button to mark that zone. Place the cursor on the second zone and click the left mouse button to disconnect the marked zone from the current zone.

4. CREATE NEW ZONE - [TOGGLE] Begin/Stop drawing a new zone.

5. ADD OR REMOVE A FLAG

5.1. CROUCH - [TOGGLE] Add/Remove the crouch flag in the current zone.

5.2. JUMP - [TOGGLE] Add/Remove the jump flag in the current zone.

5.3. NO-JUMP - [TOGGLE] Add/Remove the no-jump flag in the current zone.

5.4. PRECISE - [TOGGLE] Add/Remove the precise flag in the current zone.

6. SAVE - Save navigation mesh to file (toggles console).

7. DEBUG

7.1. ADD / KICK BOT - [TOGGLE] Add/Kick random BOTs.

7.2. BOT ZOMBIE [ON/OFF] - [TOGGLE] Enable/Disable zombie mode (make BOTs passive or active).

7.3. SEND BOT TO CURRENT ZONE - Make BOT come to the current zone (if there is a marked zone already, unmark it first).

7.4. BOT TRACE VIEW [ON/OFF] - [TOGGLE] Enable/Disable trace view mode. Traces are only visible in the spectator mode and not in the Free Look mode (allow BOTs to join teams before the player first).

7.5. HOSTAGE DEBUG [ON/OFF] - [TOGGLE] Enable/Disable hostage debug mode.

8. ANALYZE

8.1. QUICK ANALYZE - Perform a quick analyze of the map (bot_quicksave 1).

8.2. FULL ANALYZE - Perform a full analyze of the map (bot_quicksave 0).

9. SHOW HELP - Display help.

-----
Requirements:
----------

The ZBOT NAV Editor Command Menu can NOT be used without zbotnavcm.cfg since it contains the scripts required for the command menu to function properly.
Make sure a new line is added to your userconfig.cfg or autoexec.cfg : exec "zbotnavcm/zbotnavcm.cfg"

On the other hand, zbotnavcm.cfg can be used without the command menu it comes with.
Make sure a new line is added to your userconfig.cfg or autoexec.cfg : exec "zbotnavcm/zbotnavcm.cfg"
If you do not want to modify your userconfig.cfg or autoexec.cfg, you will have to manually load zbotnavcm.cfg when in-game.

Bind the included aliases to the unbinded keys:

1. NAV EDITOR [ON/OFF]
bind "<key>" "botnav01"

2. MARK / UNMARK
bind "<key>" "botnav02"

3. SPLIT
bind "<key>" "botnav03"

4. DELETE
bind "<key>" "botnav04"

5. MARK ZONE AND MERGE WITH ANOTHER
bind "<key>" "botnav05"

6. MARK ZONE AND SPLICE TO ANOTHER
bind "<key>" "botnav06"

7. MARK ZONE AND CONNECT WITH ANOTHER
bind "<key>" "botnav07"

8. MARK ZONE AND DISCONNECT FROM ANOTHER
bind "<key>" "botnav08"

9. CREATE NEW ZONE
bind "<key>" "botnav09"

10. ADD OR REMOVE A FLAG (CROUCH)
bind "<key>" "botnav10"

11. ADD OR REMOVE A FLAG (JUMP)
bind "<key>" "botnav11"

12. ADD OR REMOVE A FLAG (NO-JUMP)
bind "<key>" "botnav12"

13. ADD OR REMOVE A FLAG (PRECISE)
bind "<key>" "botnav13"

14. SAVE
bind "<key>" "botnav14"

15. ADD / KICK BOT
bind "<key>" "botnav15"

16. BOT ZOMBIE [ON/OFF]
bind "<key>" "botnav16"

17. SEND BOT TO ZONE
bind "<key>" "botnav17"

18. BOT TRACE VIEW [ON/OFF]
bind "<key>" "botnav18"

19. HOSTAGE DEBUG [ON/OFF]
bind "<key>" "botnav19"

20. QUICK ANALYZE
bind "<key>" "botnav20"

21. FULL ANALYZE
bind "<key>" "botnav21"

22. SHOW HELP
bind "<key>" "botnav22"

-----
FAQ:
----------

 Q.
  When I press [H], the command menu does not show up.

 A.
  Make sure [H] is binded to open the command menu:

  1. Open the console by pressing the tilde key (~).
  2. Type in "bind h +commandmenu" (without quotation marks).
  3. Hit ENTER.

-----
License:
----------

You are allowed to:

. Download, copy and distribute this material
. Use the source code to build upon this material and distribute the modified material

Under the following terms:

. You must give appropriate credit and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
. You may not use the material for commercial purposes.

-----
Changelog:
----------

 v1.2 : March 16th, 2019
 - Changes to autoexec.cfg
 -- Removed echo command

 - Changes to commandmenu.txt
 -- Renamed some of the buttons
 -- Menu structure overhaul
 --- Removed GENERAL sub-menu
 --- Moved SAVE button to the root of the menu
 --- Moved SHOW HELP button to the root of the menu
 --- Removed LOAD SCRIPTS, BOT JOIN AFTER PLAYER OFF / ON buttons

 - Updated zbotnavcm\Readme.txt

 - Changes to in-game help
 -- Removed zbotnavh1.cfg, zbotnavh2.cfg, zbotnavh3.cfg, zbotnavh4.cfg, zbotnavh5.cfg, zbotnavh6.cfg

 - Changes to zbotnavcm\zbotnavcm.cfg
 -- Renamed all the scripts
 -- Decreased file size from 5 KB to 3 KB
 -- Removed scripts that are no longer necessary
 -- Changed the way MARK / UNMARK, SPLIT, DELETE, MERGE WITH ANOTHER, SPLICE TO ANOTHER, CONNECT WITH ANOTHER, DISCONNECT FROM ANOTHER, CROUCH, JUMP, NO-JUMP, PRECISE scripts work

 v1.1 : February 17th, 2019
 - Added Readme.txt and commandmenu.txt.bak
 -- zbotnavcm\Readme.txt
 -- zbotnavcm\commandmenu.txt.bak (the original command menu)

 - Added in-game help
 -- zbotnavcm\zbotnavah.cfg
 -- zbotnavcm\zbotnavh1.cfg
 -- zbotnavcm\zbotnavh2.cfg
 -- zbotnavcm\zbotnavh3.cfg
 -- zbotnavcm\zbotnavh4.cfg
 -- zbotnavcm\zbotnavh5.cfg
 -- zbotnavcm\zbotnavh6.cfg

 - Moved configs to a separate directory (...\cstrike\zbotnavcm)

 - Changes to autoexec.cfg
 -- Changed path to zbotnavcm.cfg

 - Changes to commandmenu.txt
 -- Renamed some of the buttons
 -- Added SHOW HELP button to the GENERAL sub-menu
 -- Added BOT JOIN AFTER PLAYER OFF / ON button to the DEBUG sub-menu

 - Changes to zbotnavcm\zbotnavcm.cfg
 -- Added scripts for in-game help
 -- Added BOT JOIN AFTER PLAYER OFF / ON script
 -- Fixed BOT TRACE VIEW ON / OFF script bug (trace view mode can not be enabled if bot_debug is set to 0)
 -- Changed the way MARK AND MERGE, MARK AND SPLICE, MARK AND CONNECT, MARK AND DISCONNECT, CREATE NEW ZONE, SEND BOT TO CURRENT ZONE scripts work

 v1.0 : February 10th, 2019
 - Release