# Indy’s Trains

A server script to add customizable cyber metro trains (from BN3/EXE3) to Open Net Battle servers. 

[collogue of four screenshots]

### How does it work?

This script is plug-n-play. Once you copy the required scripts and assets to your server (see below) everything else is configured within the Tiled map editor for your server area. Additionally, you can install the Tiled extension which will make adding them to your map even easier. 

### Want to try it out? 

This repository is a complete test server you can spin up, which includes configured examples for both types of trains and the conductor, which will show you how they should be configured and how they function in-game without having to do the setup yourself. 

### How do I install this on my ONB server? 

1. Download the repository. 
2. Copy `/assets/indy-trains/` to your server’s asset folder. 
3. Copy `/scripts/indy-trains/` to your server’s script folder. 
4. Copy `indys-trains-tiled.js` to your Tiled extension folder  

### How do I add trains to my maps? 

Within the script there are two types of trains: Cargo Trains and Passenger Trains. Cargo Trains run along a path on a loop and do not have any interactions, they are purely aesthetics. Passenger Trains, on the other hand, function exactly like the cyber metro from BN3/EXE3 where you talk to a Mr. Prog who summons a train and the player is transported to another area. 

Setup for Cargo Trains

Required Custom Properties


Setup for Passenger Trains (Area-to-Area)



Setup for Passenger Trains (Server-to-Server)

Passenger Trains can also transport players between servers. The receiving server does not have to have a train configured for this to work, but means the user will simply be dropped off at the Home Warp of the destination server. 

### Credits

Coding - Indiana
Cyber Metro Sprite - Indiana
Conductor Prog Sprite - CyanMan.EXE
Sound Effect - DJRezzed/Enzan
