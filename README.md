# Enhanced Raid Frames

Enhanced Raid Frames is a raid frame utility addon for WoW 8.3+ that brings configurable indicators for enhancing the built in raid frames, allowing them to function much closer to add-ons such as Grid or Vuhdo.

There are 9 indicators for each raid member, forming a 3x3 grid overlaying each unit frame, that allow for showing the presence of and countdown times of buffs and debuffs in any configuration that suits your needs.

Indicators can be configured to show any buffs/debuffs of your choice and you can configure several buffs/debuffs in the same indicator. Some simple options lets you select to show only if the buff is missing, only cast by you, stack sizes and more.

As an added bonus there's also an option to turn off the standard buff/debuff icons.

--------------

## Examples:

![Example 1](https://media.forgecdn.net/attachments/233/53/1.jpg "Example 1")

Example of indicators on a unit. Left lower corner shows remaining time of my Rejuvenation, center botton shows stack size and time remaining of my Lifebloom, bottom right shows time left of my Regrowth.

![Example 2](https://media.forgecdn.net/attachments/233/54/2.jpg "Example 2")

Example of indicators in a raid. The big red dot on Stormfront is an indicator showing he's missing Mark of the Wild or Blessing of Kings.

Also show in this picture is: [Enhanced Raid Frame: Raid Icons](https://www.curseforge.com/wow/addons/enhanced-raid-frame-icons "Enhanced Raid Frames: Raid Icons")

![Example 3](https://media.forgecdn.net/attachments/233/55/3.jpg "Example 3")

Another example, using icons as well as stack size coloring of the Earth Shield buff.

---------------

### Indicator options
* The following can be used as buffs/debuffs:
   * **Name of buff/debuff** - Make sure this corresponds exactly to the name of the buff/debuff as it is called when it's on the unit (you can see the name if you cast the spell on yourself and it's not necessarily the same as the spell name)
   * **"Magic/Poison/Disease/Curse"** - To show any debuffs of that kind in that indicator
   * **Spell ID** - ID of the spell to track (useful when the spell name is ambiguous, i.e. Germination)
   * **"PvP"** - To show if a unit is PvP flagged
   * **"ToT"** - To show if a unit is the target of your target

### Other options:

* **Mine only** - Only look for buffs cast by yourself. Can be used for example to track only hots cast by yourself
* **Show only if missing** - Only show the indicator if all the buff/debuff specified are missing. Will be shown with a "blob" instead of numbers
* **Show on me only** - Only show the indicator on yourself. Can be used to track missing self buffs or procs on yourself
* **Show text counter** - Will show a number counting remaining time
* **Show decimals** - Will show remaining time with a decimal for times &lt; 10s
* **Use stack size coloring** - Will color the counter based on the stack size (&gt;=3 green, 2 yellow, 1 red)
* **Color by remaining time** - Will use the selected coloring for time &gt; 5s, yellow for 3-5s, red for &lt; 3s remaining time
* **Show stack size** - Will show the stack size if the buff/debuff can stack
* **Show icon** - Will show the spell icon

------------------

## Credits:
Original Author: Szandos

Enhanced Raid Frames is an extension of the amazing Blizzard Raid Frame: Indicators addon started by Szandos, for World of Warcraft prior to Battle for Azeroth. All credit for the bulk of this addon should go to him accordingly. I, Soyier, take no credit for the idea or implementation of this addon prior to my adoption of the code in the Summer of 2018.
