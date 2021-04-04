# Mappin System Example

### Features

- Place a map pin at the player's current position
- Place a map pin on an object under the crosshair (NPC, Car, Terminal, etc.)

### Notes

A map pin can be tracked (drawing path in the map and minimap) if the variant allowing it. 
A map pin placed on an object follows the object if it moves.

Custom map pins remain after fast traveling. 
Although the "pinned" object can be disposed / teleported, 
in which case the pin will move to an unpredictable coordinate.

### References

- [Mappin System](https://redscript.redmodding.org/#24572)
- [Mappin Variants](https://github.com/WolvenKit/CyberCAT/blob/main/CyberCAT.Core/Enums/Dumped%20Enums/gamedataMappinVariant.cs)
- [Targeting System](https://redscript.redmodding.org/#21605)
