# Indy’s Trains

A server script to add customizable cyber metro trains (from BN3/EXE3) to Open Net Battle servers. 

![train-preview](https://github.com/user-attachments/assets/1282c0e3-485a-409b-83c3-67c8e699e623)

<h3>How does it work?</h3>

> This script is plug-n-play. Once you copy the required scripts and assets to your server (see below) everything else is configured within the Tiled map editor for your server area. Additionally, you can install the Tiled extension which will make adding them to your map even easier. 




### Want to try it out? 

> This repository is a complete test server you can spin up, which includes configured examples for both types of trains and the conductor, which will show you how they should be configured and how they function in-game without having to do the setup yourself. 

### How do I install this on my ONB server? 

> 1. Download the repository. 
> 2. Copy `/assets/indy-trains/` to your server’s asset folder. 
> 3. Copy `/scripts/indy-trains/` to your server’s script folder. 
> 4. Copy `indys-trains-tiled.js` to your Tiled extension folder.
> <br> (in Tiled go to Settings, select Plugins, then click "Open..." below Extensions). 

### How do I add trains to my maps? 

This script provides three object types: Cargo Trains, Passenger Trains, and Conductors. Cargo Trains run along a straight path on a loop and do not have any interactions (they are purely aesthetics). Passenger Trains function exactly like the cyber metro from BN3/EXE3 where you talk to a Mr. Prog (Conductor) who summons a train and the player is transported to another area. Conductors spawn the Mr. Prog and should be placed wherever you want players to request a Passenger Train. 

### Setup for Cargo Trains

   1. Open your map in Tiled.
   2. Select an Object Layer on your map. 
   3. Open the `File` menu, click `New` and select `Add Cargo Train...`
   4. Fill in the dialog box based on the information below:
 > `Train Name` must be unique for the area.<br>
> `Color` changes the train's appearance.<br>
> `Speed` can be increased to make the train move faster (1 = default, 1.5 is 50% faster, 2 is 100% faster, etc.) <br>
> `Direction` select which direction the train is traveling.<br>
> `Start Point` provide a x,y,z tile position (hover over a tile and look in the bottom left of Tiled to see X and Y).<br>
>  &nbsp; &nbsp; For the bottom most layer, Z equals 0 and goes up by 1 as you move upward.<br>
> `End Point` provide a x,y,z tile position (hover over a tile and look in the bottom left of Tiled to see X and Y).<br>
> `Driver Texture` path to image file for your Driver NPC (optionaL). <br>
> `Driver Animation` path to .animation file for your Driver NPC (optionaL). <br>
> `Cargo Texture` path to image file for your cargo/passenger NPC (optionaL). <br>
> `Cargo Animation` path to .animation file for your cargo/passenger NPC (optionaL).

  5. Click "Add Train" (a new Point will be added to your map, you can place it anywhere). 

The dialog box is smart so if you type something that's invalid it will let you know. However, it doesn't check if your X,Y,Z positions are correct. If you need to edit them after you make your Cargo Train simply press `S` on your keyboard (selects the `Select Object` tool) and click on the Point for your Cargo Train, you can then change the X,Y,Z values on the left under Custom Properties. 

### Setup for Passenger Trains

Passenger Trains can transport players between areas within a server or to a completely different servers. The receiving server does not have to have a train configured for this to work (but in that case the user will simply be dropped off at the Home Warp of the destination server). 

   1. Open your map in Tiled.
   2. Select an Object Layer on your map. 
   3. Open the `File` menu, click `New` and select `Add Passenger Train...`
   4. Fill in the dialog box based on the information below:

### Setup for Conductors

   1. Open your map in Tiled.
   2. Select an Object Layer on your map. 
   3. Open the `File` menu, click `New` and select `Add Conductor...`
   4. Fill in the dialog box based on the information below:

### Credits

Coding - Indiana<br>
Cyber Metro Sprite - Indiana<br>
Conductor Prog Sprite - CyanMan.EXE<br>
Sound Effects - DJRezzed/Enzan<br>
