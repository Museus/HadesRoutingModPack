# HadesRoutingModPack
This is a collection of mods developed by the Hades community over time. They are each somewhat useful on their own, but combined make it significantly easier to route runs.

# Installation
To install these mods, go the the [Releases](https://github.com/Museus/HadesRoutingModPack/releases) tab and download the latest .zip file. This will include the following files:
 - Mods/
   - ShowChamberNumber/
   - RngDisplayMod/
   - PrintUtil/
   - DebugBoxMod/
   - ModUtil/
 - modimporter.py

[A video tutorial on how to install mods is available from PonyWarrior here](https://www.youtube.com/watch?v=YF0ij7MgOrI)

If you prefer text instructions, follow these steps:

If you don't already have Python installed, download it from [python.org](https://www.python.org/downloads/) and install it.

Once you have downloaded the `HadesRoutingModPack.zip` file, open up your Hades game directory. You can find this by launching Hades, then opening Task Manager, finding the Hades process, right-clicking on it, and selecting Open File Location.

Unzip the files into the `.../Hades/Content` folder. You should now have the standard folders such as `Scripts` and `Game` as well as a new folder called `Mods` and the `modimporter.py` script.

Run the `modimporter.py` script to install the mods, then load into your game. Whenever you want to uninstall the mods, simply delete the contents of the `Mods` folder, and run the `modimporter.py` script again.

# Info and Configuration
Each of these mods can be toggled on and off, and in some cases have more customization. To change these options, open the `Mods` folder, then open the folder for the mod you want to configure, then open the `<modname>.lua` file in Notepad. There will be a block at the top with `local config = {` followed by options that can be changed.

## DebugBoxMod
This mod adds a text overlay to the game, which can be used by other mods to display information that might be useful to the player. This is different from the official Debug Overlay that SGG has made available in that it must be printed to directly by a mod and is not part of the base game.

This mod is potentially useful for creating a route, but not as useful for just running the route. Therefore, it is disabled by default.

The options for this include:
 - ShowDebug (if false, no output will be shown)
 - ShowDetailedDebug (if false, stack prints will not be shown)
 - LinesToShow (max number of lines to display)
 - FontSize (default font size to use)
 - LineSpacing (space between lines -- 0 means the lines are touching)
 - BoxXPosition (X Position, default is below the Chamber Number)
 - BoxYPosition (Y Position, default is below the Chamber Number)

## PrintUtil
This is a small library of functions that help print information to the screen. These will not do anything unless called by another mod, so there isn't really any configuration that needs to happen.

## ShowChamberNumber
This mod just makes it so that your current depth shows up at all times, rather than only when you open the Boon Summary menu. This mod has one option - `ShowDepth` - which can be toggled to turn this mod on and off.

## RngInterface
This mod hooks into RNG and tracks the seed and increment. By itself, it does not do anything, but it allows other mods to provide functions that will be run whenever RNG is incremented or the Seed changes.

## RngDisplay
This mod adds an RNG Overlay to Hades, to display Seed and RNG uses. It depends on RngInterface. It can also display most of the rolls that happen to the DebugBoxMod, assuming that is installed and turned on. The options available are:
 - ShowSeed (if false, does not display the seed)
 - ShowUses (if false, does not display RNG uses)
 - OutputToDebug (if false, does not print information to DebugBoxMod)

## RouteVerifier
This mod adds an indicator for whether you are on route. It is pre-populated with [the Nemesis route by ParadigmSort](https://docs.google.com/spreadsheets/d/1-wTLltI0pffB6FCsooAphUBbq6NFeTednH--71AC0rY) but can track any route.

# Other Tools/Mods
Not included in this list, but incredibly useful, is [ParasDoorPredictions](https://github.com/parasHadesMods/ParasDoorPredictions). It  is strongly recommended to install this mod when creating a route, but is not necessary for running a route that was already made.

[Ello's Boon Selector](https://github.com/ellomenop/EllosStartingBoonSelectorMod) makes it incredibly easy to get the starting seed you want, and is necessary for running any route that does not have a SaveManager pack associated with it.

[HadesSaveManager](https://github.com/museus/HadesSaveManager) is an external save manager that allows you to create snapshots throughout a run. It is specifically targeted at assisting with routed runs.
