# Indy’s Trains

A script to add customizable cyber metro trains (from BN3/EXE3) to Open Net Battle servers. 

![train-preview](https://github.com/user-attachments/assets/1282c0e3-485a-409b-83c3-67c8e699e623)

<h3>How does it work?</h3>

> This script is plug-n-play. Once you copy the required scripts and assets to your server (see below) everything else is configured within the Tiled map editor for your server area. Additionally, you can install the Tiled extension which will make adding them to your map even easier. 

### Want to try it out? 

> This repository is a complete test server you can spin up that includes configured examples for both types of trains and the conductor. It will show you how they should be configured and how they function in-game without having to do the setup yourself. 

### How do I install this on my ONB server? 

> 1. Download the repository. 
> 2. Copy `/assets/indy-trains/` to your server’s asset folder. 
> 3. Copy `/scripts/indy-trains/` to your server’s script folder. 
> 4. Copy `indys-trains-tiled.js` to your Tiled extension folder.
> <br> (in Tiled go to Settings, select Plugins, then click "Open..." below Extensions). 

### What's included in this script? 

This script adds three new object types: Cargo Trains, Passenger Trains, and Conductors. Cargo Trains run along a straight path on a loop and do not have any interactions (they are purely aesthetics). Passenger Trains function exactly like the cyber metro from BN3/EXE3 where you talk to a Mr. Prog (Conductor) who summons a train and the player is transported to another area. Conductors spawn the Mr. Prog and should be placed wherever you want players to request a Passenger Train. <br><br>All of the necessary assets (sprites, animations, and sound effects) are included with the script. 

### How do I add a Cargo Train?

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

The dialog box is smart so if you type something that's malformed it will let you know. However, it doesn't check if your X,Y,Z positions are correct. If you need to edit them after you make your Cargo Train simply press `S` on your keyboard (selects the `Select Object` tool) and click on the Point on your map for your Cargo Train, you can then change the X,Y,Z values on the left under _Custom Properties_. 

### How do I add a Passenger Train?

Passenger Trains can transport players between areas within a server or to completely different servers. The receiving server does not need a train configured for the transfer to work, however, if no train on the receiving server is configured then the player will simply be dropped off at the Home Warp of the destination server. 

> **Important:** Because of how tiles/objects stack in ONB, your train object and track should be three layers below your platform. For example, if your main platform is currently at Layer 0 (Vertical Offset 0) you need to move it to Layer 3 (Vertical Offset -32) and put the track on Layer 0 (Vertical Offset 0). If this doesn't make sense take a look at the layers in default.tmx from the demo server. If you put them any closer there will be visual glitches where the train appears above your platform (instead of below). 

   1. Open your map in Tiled.
   2. Select an Object Layer on your map. 
   3. Open the `File` menu, click `New` and select `Add Passenger Train...`
   4. Fill in the dialog box based on the information below:

While you've added a Passenger Train, you also have to add a Conductor (so the player can choose a destination and summon the Passenger Train). 

Remember, the dialog box is smart so if you type something that's malformed it will let you know. However, it doesn't check if your X,Y,Z positions are correct. If you need to edit them after you make your Passenger Train simply press `S` on your keyboard (selects the `Select Object` tool) and click on the Point on your map for your Passenger Train, you can then change the X,Y,Z values on the left under _Custom Properties_. 


### How do I add a Conductor?

The conductor object will spawn an Conductor Prog when your server boots. When players interact with this NPC a menu will appear allowing players to select a destination. You will configure the destination options within Conductor object as explained below.

> Important: Where you place your conductor will dictate where the NPC spawns, so once you add it position it accordingly. It should always be next to the _Stop Position_ for your train. 

   1. Open your map in Tiled.
   2. Select an Object Layer on your map. 
   3. Open the `File` menu, click `New` and select `Add Conductor...`
   4. Fill in the dialog box based on the information below:

## Can I make a one way Passenger Train?

Yes, simple do not add a Conductor on the other end. Once they arrive at the destination there won't be an NPC to use to go back to where they started. 

## Can different Conductors have different destinations?

No, each conductor is completely indepedent and can have a unique list of destinations. For example, let's say you have a Conductor in ACDC 1, SciLab 1, and Yoka Square. You can make the Conductor in ACDC have SciLab 1 and Yoka Square as destinations, but the Yoka Square conductor can have just SciLab 1 as a destination. 

## Credits

Coding - Indiana<br>
Cyber Metro Sprite - Indiana<br>
Conductor Prog Sprite - CyanMan.EXE<br>
Sound Effects - DJRezzed/Enzan<br>
