/******************************************************************************
 *    Reign of the Undead, v2.x
 *
 *    Copyright (c) 2010-2013 Reign of the Undead Team.
 *    See AUTHORS.txt for a listing.
 *
 *    Permission is hereby granted, free of charge, to any person obtaining a copy
 *    of this software and associated documentation files (the "Software"), to
 *    deal in the Software without restriction, including without limitation the
 *    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 *    sell copies of the Software, and to permit persons to whom the Software is
 *    furnished to do so, subject to the following conditions:
 *
 *    The above copyright notice and this permission notice shall be included in
 *    all copies or substantial portions of the Software.
 *
 *    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *    SOFTWARE.
 *
 *    The contents of the end-game credits must be kept, and no modification of its
 *    appearance may have the effect of failing to give credit to the Reign of the
 *    Undead creators.
 *
 *    Some assets in this mod are owned by Activision/Infinity Ward, so any use of
 *    Reign of the Undead must also comply with Activision/Infinity Ward's modtools
 *    EULA.
 ******************************************************************************/
/** @file _umi.gsc The RotU implementation of the unified mapping interface as
 * specified in @code maps\mp\_unified_mapping_interface.gsc @endcode
 *
 * Attention Mappers: Include this file in your main map file--
 *                    not @code maps\mp\_unified_mapping_interface.gsc @endcode
 */

#include scripts\include\data;
#include scripts\include\entities;
#include scripts\include\hud;
#include scripts\include\matrix;
#include scripts\include\utility;

//
// Unified Mapping Interface (UMI) Public Functions
//
// Map makers can count on these functions being defined in every mod that uses
// the UMI.  However, any given function may not actually have a use in the mod,
// e.g. a call to buildParachutePickup() won't cause any compile or runtime errors
// when the map is run in RotU, but that call will have no effect as parachute drops
// aren't part of RotU.
//

/**
 * @brief Returns the lower-cased name of the mod that is trying to load the map
 *
 * @returns string The name of the mod, e.g. "rotu", "rozo", etc
 * @since RotU 2.2.1
 */
modName()
{
    if (isDefined(level.modName)) {return level.modName;}
    else {
        level.modName = "rotu";
        return level.modName;
    }
}

/**
 * @brief Returns the native type of the map being loaded
 *
 * @returns string The native type of the map, e.g. "rotu", "rozo", etc.
 * @since RotU 2.2.1
 */
nativeMapType()
{
    if (isDefined(level.nativeMapType)) {return level.nativeMapType;}
    else {return "";}
}

/**
 * @brief Sets the native type of the map being loaded
 *
 * @param nativeMapType string The native type of the map, e.g. "rotu", "rozo", etc.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
setNativeMapType(nativeMapType)
{
    level.nativeMapType = nativeMapType;
}

/**
 * @brief UMI Converts CSV waypoints to BTD waypoints, and prints them to the server log
 * It prints the BTD function, but will require the timecodes to be removed from the
 * front the the line, as well as any extraneous info printed to the log at the
 * same time by other functions.
 *
 * @returns nothing
 */
devDumpCsvWaypointsToBtd()
{
    debugPrint("in _umi::devDumpCsvWaypointsToBtd()", "fn", level.nonVerbose);

    wp = [];
    wpCount = 0;

    fileName =  "waypoints/"+ tolower(getdvar("mapname")) + "_wp.csv";
    wpCount = int(TableLookup(fileName, 0, 0, 1));

    if ((!isDefined(wpCount)) || (wpCount == 0)) {
        noticePrint("No csv waypoints in fastfile, nothing to dump.");
        return;
    }

    wpFilename = tolower(getdvar("mapname"))+"_waypoints.gsc";
    logPrint("// BTD-style load_waypoints() function for file " + wpFilename + " generated by RotU\n");
    logPrint("// based on waypoints compiled into the map's fast file.\n");
    logPrint("//\n");
    logPrint("// These waypoints can be edited and then used to override the waypoints in the fast file\n");
    logPrint("// using _umi::setPreferBtdWaypoints(true)\n");
    logPrint("// Alternatively, you may use these waypoints, and recompile the fast file without the waypoints.\n");
    logPrint("//\n");
    logPrint("// N.B. You will need to delete the timecodes at the beginning of these lines!\n");
    logPrint("//\n");

    logPrint("load_waypoints()\n");
    logPrint("{\n");
    logPrint("    level.waypoints = [];\n");
    logPrint("    \n");

    for (i=0; i<level.WpCount; i++) {
        wpIndex = i;
        csvIndex = i + 1;
        strOrigin = TableLookup(fileName, 0, csvIndex, 1);
        originTokens = strtok(strOrigin, " ");
        x = atof(originTokens[0]);
        y = atof(originTokens[1]);
        z = atof(originTokens[2]);

        logPrint("    level.waypoints["+wpIndex+"] = spawnstruct();\n");
        logPrint("    level.waypoints["+wpIndex+"].origin = ("+x+","+y+","+z+");\n");

        strLinked = TableLookup(fileName, 0, csvIndex, 2);
        linkedTokens = strtok(strLinked, " ");
        childCount = linkedTokens.size;
        logPrint("    level.waypoints["+wpIndex+"].childCount = "+childCount+";\n");

        for (j=0; j<childCount; j++) {
            logPrint("    level.waypoints["+wpIndex+"].children["+j+"] = "+linkedTokens[j]+";\n");
        }
    }

    logPrint("    \n");
    logPrint("    level.waypointCount = level.waypoints.size;\n");
    logPrint("}\n");
}

/**
 * @brief UMI Converts BTD waypoints to CSV waypoints, and prints them to the server log
 * It prints the contents of the *.csv file, but will require the timecodes to be removed from the
 * front the the line, as well as any extraneous info printed to the log at the
 * same time by other functions.
 *
 * This function must be called immediately after load_waypoints(), e.g.
 * @code
 * maps\mp\mp_burgundy_bulls_waypints::load_waypoints();
 * devDumpBtdWaypointsToCsv();
 * @endcode
 *
 * @returns nothing
 */
devDumpBtdWaypointsToCsv()
{
    debugPrint("in _umi::devDumpBtdWaypointsToCsv()", "fn", level.nonVerbose);

    if ((!isDefined(level.waypoints)) || (level.waypoints.size == 0)) {
        noticePrint("No BTD waypoints in memory, nothing to dump.");
        return;
    }

    fileName =  "waypoints/"+ tolower(getdvar("mapname")) + "_wp.csv";
    logPrint("// CSV-style waypoints generated by RotU from BTD-style waypoints.\n");
    logPrint("// Save these lines in a file named " + fileName + "\n");
    logPrint("//\n");
    logPrint("// These waypoints can then be compiled into the map's fast file.\n");
    logPrint("//\n");
    logPrint("// N.B. You will need to delete the timecodes at the beginning of these lines!\n");
    logPrint("//\n");

    logPrint("0,"+level.waypoints.size+",0\n");
    for (i=0; i<level.waypoints.size; i++) {
        csvIndex = i+1;
        x = level.waypoints[i].origin[0];
        y = level.waypoints[i].origin[1];
        z = level.waypoints[i].origin[2];
        linkedWaypoints = level.waypoints[i].children[0];
        for (j=1; j<level.waypoints[i].childCount; j++) {
            linkedWaypoints = linkedWaypoints + " " + level.waypoints[i].children[j];
        }
        logPrint(csvIndex+","+x+" "+y+" "+z+","+linkedWaypoints+"\n");
    }
}

/**
 * @brief UMI draws the waypoints on the map
 * @threaded
 *
 * @param labelWaypoints boolean Show each waypoint index and its linked indices?
 *
 * @returns nothing
 */
devDrawWaypoints(labelWaypoints)
{
    debugPrint("in _umi::devDrawWaypoints()", "fn", level.nonVerbose);

    // wait until someone is in the game to see the waypoints before we draw them
    while (level.activePlayers == 0) {
        wait 0.5;
    }

    player = scripts\include\adminCommon::getPlayerByShortGuid(getDvar("admin_forced_guid"));
    while(1)
    {
        /#
        location = player.origin + (50,50,100);
        Print3D(location,"TEST!",(1,0,0),0.5,10);
        #/
        wait 0.05; //for 20 fps (default is \sv_fps 20)
    }
//     while (1) {
//         for (i=0; i<level.WpCount; i++) {
//             for (j=0; j<level.Wp[i].linked.size; j++) {
// //                 Line( <start>, <end>, <color>, <depthTest>, <duration> )
//                 line(level.Wp[i].origin + (0,0,20), level.Wp[i].linked[j].origin + (0,0,20), (0.9, 0.7, 0.6), false, 5);
//                 Print3d(level.Wp[i].origin + (0,0,50), "Waypoint", (1.0, 0.8, 0.5), 1, 3 );
//             }
//         }
//         wait 0.25;
//     }
}

/**
 * @brief UMI writes the player's current position to the server log
 * Intended to help add/edit waypoints to maps lacking them.  Should be called
 * from an admin command, or perhaps from a keybinding.
 *
 * @returns nothing
 */
devRecordWaypoint()
{}

/**
 * @brief UMI writes entities with defined classname and/or targetname properties to the server log
 *
 * @returns nothing
 */
devDumpEntities()
{
    debugPrint("in _umi::devDumpEntities()", "fn", level.nonVerbose);

    ents = getentarray();
    for (i=0; i<ents.size; i++) {
        if (isDefined(ents[i].classname)) {
            noticePrint(i + ": classname: " + ents[i].classname);
        }
        if (isDefined(ents[i].targetname)) {
            noticePrint(i + ": targetname: " + ents[i].targetname);
        }
    }
}

/**
 * @brief UMI to build equipment stores by tradespawns
 *
 * @param equipmentShops string Space-separated list of tradespawn array indices,
 * e.g. @code buildWeaponShopsByTradespawns("1 3 5 7"); @endcode
 *
 * @pre tradespawns have been loaded into level.tradespawns
 * @returns nothing
 * @since RotU 2.2.1
 */
buildShopsByTradespawns(equipmentShops, havePrefabModels)
{
    debugPrint("in _umi::buildShopsByTradespawns()", "fn", level.nonVerbose);

    if (!isDefined(havePrefabModels)) {havePrefabModels = false;}

    noticePrint("Map: RotU prefers _umi::buildShopsByTargetname(targetname).");
    noticePrint("Map: You may call _umi::modName() to determine which mod is trying to load the map.");

    shops = strTok(equipmentShops, " ");
    if (!isDefined(level.tradespawns[int(shops[0])])) {
        errorPrint("Map: No equipment shop tradespawns defined, or tradespawns haven't been loaded().");
        return;
    }

    for (i=0; i<shops.size; i++) {
        tradespawn = level.tradespawns[int(shops[i])];
        shop = spawn("script_model", tradespawn.origin);
        if (isDefined(shop)) {
            shop.angles = tradespawn.angles;
            shop setModel("ad_sodamachine");
        }

        // a column vector for the xmodel's centroid
        centroid = zeros(2,1);
        // 20.2 is approx. x-coord of 2-D centroid of xmodel, i.e. x bar
        setValue(centroid,1,1,20.2);
        // 15.8 is approx. y-coord of 2-D centroid of xmodel, i.e. y bar.  Negative
        // sign is needed due to location of origin in the xmodel
        setValue(centroid,2,1,-15.8);
        // phi is the angle the xmodel is rotated through
        phi = tradespawn.angles[1];
        // create standard rotation matrix
        A = eye(2);
        setValue(A,1,1,cos(phi));
        setValue(A,1,2,-1*sin(phi));
        setValue(A,2,1,sin(phi));
        setValue(A,2,2,cos(phi));
        // apply the rotation matrix
        R = matrixMultiply(A, centroid);
        // now (x,y) hold the proper rotated position offset relative to tradespawn.origin
        x = value(R,1,1);
        y = value(R,2,1);
        level scripts\players\_usables::addUsable(shop, "extras", "Press [USE] to buy upgrades!", 96);
        createTeamObjpoint(tradespawn.origin + (x,y,85), "hud_ammo", 1);

        // spawn a solid trigger_radius to simulate xmodel actually being solid
        level.solid = spawn("trigger_radius", (0, 0, 0), 0, 22, 122 );
        level.solid.origin = tradespawn.origin + (x,y,0);
        level.solid.angles = tradespawn.angles;
        level.solid setContents(1);
    }
}

/**
 * @brief UMI to build equipment shops by targetname
 *
 * @param targetname string The name of the entities' targetname attribute,
 * e.g. @code buildShopsByTargetname("weaponupgrade"); @endcode
 *
 * "weaponupgrade" is the targetname traditionally used by RotU
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildShopsByTargetname(targetname)
{
    debugPrint("in _umi::buildShopsByTargetname()", "fn", level.nonVerbose);

    ents = getentarray(targetname, "targetname");
    if (ents.size == 0) {
        errorPrint("Map: No equipment shops (entities matching targetname: " + targetname + ") found.");
        return;
    }

    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        level scripts\players\_usables::addUsable(ent, "extras", "Press [USE] to buy upgrades!", 96);
        createTeamObjpoint(ent.origin+(0,0,72), "hud_ammo", 1);
    }
}

/**
 * @brief UMI to build weapons shop/upgrade by targetname
 *
 * @param targetname string The name of the entities' targetname attribute,
 * e.g. @code buildWeaponShopsByTargetname("ammostock"); @endcode
 * "ammostock" is the targetname traditionally used by RotU
 * @param loadTime int ???
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildWeaponShopsByTargetname(targetname, loadTime)
{
    debugPrint("in _umi::buildWeaponShopsByTargetname()", "fn", level.nonVerbose);

    ents = getentarray(targetname, "targetname");
    if (ents.size == 0) {
        errorPrint("Map: No weapon shops (entities matching targetname: " + targetname + ") found.");
        return;
    }

    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        ent.loadtime = loadTime;
        if (level.ammoStockType == "weapon") {
            level scripts\players\_usables::addUsable(ent, "ammobox", "Press [USE] for a weapon! (^1"+level.dvar["surv_waw_costs"]+"^7)", 96);
            createTeamObjpoint(ent.origin+(0,0,72), "hud_weapons", 1);
        } else if (level.ammoStockType == "upgrade") {
            level scripts\players\_usables::addUsable(ent, "ammobox", "Press [USE] to upgrade your weapon!", 96);
            createTeamObjpoint(ent.origin+(0,0,72), "hud_weapons", 1);
        } else if (level.ammoStockType == "ammo") {
            level scripts\players\_usables::addUsable(ent, "ammobox", "Hold [USE] to restock ammo", 96);
        } else {
            errorPrint("level.ammoStockType isn't recognized.");
        }
    }
}

/**
 * @brief UMI to build weapons shop/upgrade by tradespawns
 *
 * @param weaponShops string Space-separated list of tradespawn array indices,
 * e.g. @code buildWeaponShopsByTradespawns("0 2 4 6"); @endcode
 *
 * @pre tradespawns have been loaded into level.tradespawns
 * @returns nothing
 * @since RotU 2.2.1
 */
buildWeaponShopsByTradespawns(weaponShops, havePrefabModels)
{
    debugPrint("in _umi::buildWeaponShopsByTradespawns()", "fn", level.nonVerbose);

    if (!isDefined(havePrefabModels)) {havePrefabModels = false;}

    noticePrint("Map: RotU prefers _umi::buildWeaponShopsByTargetname(targetname).");
    noticePrint("Map: You may call _umi::modName() to determine which mod is trying to load the map.");

    weapons = strTok(weaponShops, " ");
    if (!isDefined(level.tradespawns[int(weapons[0])])) {
        errorPrint("Map: No weapon shop tradespawns defined, or tradespawns haven't been loaded().");
        return;
    }

    for (i=0; i<weapons.size; i++) {
        tradespawn = level.tradespawns[int(weapons[i])];
        weaponupgrade = spawn("script_model", tradespawn.origin);
        if (isDefined(weaponupgrade)) {
            weaponupgrade.angles = tradespawn.angles;
            weaponupgrade setModel("com_plasticcase_green_big");

            // spawn a solid trigger_radius to simulate xmodel actually being solid
            level.solid = spawn("trigger_radius", (0, 0, 0), 0, 21, 27 );
            level.solid.origin = tradespawn.origin;
            level.solid.angles = tradespawn.angles;
            level.solid setContents(1);

            level scripts\players\_usables::addUsable(weaponupgrade, "ammobox", "Press [USE] to upgrade your weapon!", 96);
            createTeamObjpoint(tradespawn.origin + (0,0,72), "hud_weapons", 1);
        }
    }
}

/**
 * @brief UMI converts BTD/ROZO waypoints into RotU waypoints
 *
 * @pre waypoints loaded into memory in level.waypoints
 * @returns nothing
 * @since RotU 2.2.1
 */
convertToNativeWaypoints()
{
    debugPrint("in _umi::convertToNativeWaypoints()", "fn", level.lowVerbosity);

    if ((isDefined(level.WpCount)) && (level.WpCount > 0)) {
        noticePrint("Map: Native waypoints are already loaded, nothing to convert.");
        return;
    }
    fileName =  "waypoints/"+ tolower(getdvar("mapname")) + "_wp.csv";
    testCount = int(TableLookup(fileName, 0, 0, 1));
    if ((isDefined(testCount)) && (testCount > 0)) {
        noticePrint("Map: Native waypoints will be loaded from the fast file, nothing to convert.");
        return;
    }
    if (level.waypoints.size == 0) {
        errorPrint("Map: No waypoints loaded in level.waypoints to convert.");
        return;
    }

    level.Wp = [];
    level.WpCount = 0;

    level.WpCount = level.waypoints.size;
    // Add in all of the waypoints
    for (i=0; i<level.WpCount; i++) {
        waypoint = spawnstruct();
        level.Wp[i] = waypoint;

        waypoint.origin = level.waypoints[i].origin;
        waypoint.isLinking = false;
        waypoint.ID = i;
    }
    // Now link the waypoints
    for (i=0; i<level.WpCount; i++) {
        waypoint = level.Wp[i];
        waypoint.linkedCount = level.waypoints[i].childCount;
        //         noticePrint("waypoint: " + i + " origin: " + waypoint.origin);
        for (j=0; j<waypoint.linkedCount; j++) {
            waypoint.linked[j] = level.Wp[level.waypoints[i].children[j]];
            //             noticePrint("waypoint: " + i + " is linked to waypoint " + level.waypoints[i].children[j]);
        }
        // Error catching
        if (!isdefined(waypoint.linked)) {
            iprintlnbold("^1UNLINKED WAYPOINT: " + waypoint.ID + " AT: " +  waypoint.origin);
        }
    }

    // Now that the ROZO waypoints are in memory in RotU format, we can free the
    // memory used by the ROZO waypoints
    level.waypoints = [];
}

/**
 * @brief UMI to build zombie spawn points by the entities' classname property
 *
 * @param classname string The value of the entities' classname property
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildZombieSpawnsByClassname(classname)
{
    debugPrint("in _umi::buildZombieSpawnsByClassname()", "fn", level.nonVerbose);

    ents = getEntArray(classname, "classname");
    if (ents.size == 0) {
        errorPrint("Map: No zombie spawn points (entities matching classname: " + classname + ") found.");
        return;
    }
    for (i=0; i<ents.size; i++) {
        count = i + 1;
        // set targetname property of the spawnpoints so they work with RotU
        ents[i].targetname = "spawngroup"+count;
        buildZombieSpawnByTargetname(ents[i].targetname, 1);
    }
}

/**
 * @brief UMI to build a zombie spawn point by an entity's targetname property
 *
 * @param targetname string The value of the entities' targetname property
 * @param priority int A zombie has a (priority / totalPriority) chance of being spawned here
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildZombieSpawnByTargetname(targetname, priority)
{
    debugPrint("in _umi::buildZombieSpawnByTargetname()", "fn", level.nonVerbose);

    ents = getentarray(targetname, "targetname");
    if (ents.size == 0) {
        errorPrint("Map: No zombie spawn point (entity matching targetname: " + targetname + ") found.");
        return;
    }

    scripts\gamemodes\_survival::addSpawn(targetname, priority);
}

/**
 * @brief UMI to build player spawn points by entities' classname property
 *
 * @param classname string The value of the classname to use for player spawn points
 * @param enabled boolean ???
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
addPlayerSpawnsByClassname(classname, enabled)
{
    debugPrint("in _umi::addPlayerSpawnsByClassname()", "fn", level.lowVerbosity);

    // Do nothing, RotU doesn't need to add player spawns
}

/**
 * @brief UMI to build player spawn points by entities' targetname property
 *
 * @param targetname string The value of the targetname to use for player spawn points
 * @param enabled boolean ???
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
addPlayerSpawnsByTargetname(targetname, enabled)
{
    debugPrint("in _umi::addPlayerSpawnsByTargetname()", "fn", level.lowVerbosity);

    // Do nothing, RotU doesn't need to add player spawns
}

/**
 * @brief UMI builds all barricades of the given targetname in the map
 *
 * @param targetname string The value of the entities' targetname property
 * @param partCount int The number of parts in barricades with this targetname
 * @param health int The initial and max hitpoints for the barricade
 * @param deathFx object A precached effect (via loadFx()) played when the barricade is destroyed
 * @param buildFx object A precached effect (via loadFx()) played when the barricade is rebuilt
 * @param dropAll boolean Optional, defaults to false
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildBarricadesByTargetname(targetname, partCount, health, deathFx, buildFx, dropAll)
{
    debugPrint("in _umi::buildBarricadesByTargetname()", "fn", level.lowVerbosity);

    if (!isdefined(dropAll)) {dropAll = false;}

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        level.barricades[level.barricades.size] = ent;
        for (j=0; j<partCount; j++) {
            ent.parts[j] = ent getClosestEntity(ent.target + j);
            /// @bug if the part isn't defined, try skipping this part
            if (!isDefined(ent.parts[j])) {
                logPrint("j: " + j + " jth part is not defined.\n");
            }
            ent.parts[j].startPosition = ent.parts[j].origin;
            //             buildBarricade("staticbarricade", 4, 400, level.barricadefx,level.barricadefx);
        }
        ent.hp = int(health);
        ent.maxhp = int(health);;
        ent.partsSize = partCount;
        ent.deathFx = deathFx;
        ent.buildFx = buildFx;
        ent.occupied = false;
        ent.dropAll = dropAll;
        ent thread scripts\players\_barricades::makeBarricade();
    }
}

/**
 * @brief UMI builds all barricades of the given classname in the map
 *
 * @param classname string The value of the entities' classname property
 * @param partCount int The number of parts in barricades with this targetname
 * @param health int The initial and max hitpoints for the barricade
 * @param deathFx object A precached effect (via loadFx()) played when the barricade is destroyed
 * @param buildFx object A precached effect (via loadFx()) played when the barricade is rebuilt
 * @param dropAll boolean Optional, defaults to false
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildBarricadesByClassname(classname, partCount, health, deathFx, buildFx, dropAll)
{
    debugPrint("in _umi::buildBarricadesByClassname()", "fn", level.lowVerbosity);

    // Do nothing, RotU builds barricades by targetname
}

/**
 * @brief UMI builds weapons that can be picked up based on a targetname
 *
 * @param targetname string The name of the entities' targetname property
 * @param itemText string The English name of the weapon
 * @param weapon string The game name of the weapon, i.e. m14_mp
 * @param weaponType string The type of the weapon
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildWeaponPickupByTargetname(targetname, itemText, weapon, weaponType)
{
    debugPrint("in _umi::buildWeaponPickupByTargetname()", "fn", level.lowVerbosity);

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        ent.myWeapon = weapon;
        ent.wep_type = weaponType;
        level scripts\players\_usables::addUsable(ent, "weaponpickup", "Press [USE] to pick up " + itemText, 96);
    }
}

/**
 * @brief UMI builds weapons that can be picked up based on a classname
 *
 * @param classname string The name of the entities' classname property
 * @param itemText string The English name of the weapon
 * @param weapon string The game name of the weapon, i.e. m14_mp
 * @param weaponType string The type of the weapon
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildWeaponPickupByClassname(classname, itemText, weapon, weaponType)
{
    debugPrint("in _umi::buildWeaponPickupByClassname()", "fn", level.lowVerbosity);

    // Do nothing, RotU doesn't build pickup weapons by classname
}

/**
 * @brief Sets whether the BTD waypoints are preferred if both BTD and CSV waypoints are available
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
setPreferBtdWaypoints(value)
{
    debugPrint("in _umi::setPreferBtdWaypoints()", "fn", level.lowVerbosity);

    level.preferBtdWaypoints = value;
}

/**
 * @brief UMI stops loading the map until the first player is actually ready to play
 *
 * Call this function before calling any map functions that require at least one
 * player to be in the game.
 *
 * @returns nothing
 */
waitUntilFirstPlayerSpawns()
{
    debugPrint("in _umi::waitUntilFirstPlayerSpawns()", "fn", level.lowVerbosity);

    noticePrint("Map: First call to wait(), it is now too late to precache models or load fx.");
    wait .5;

    scripts\gamemodes\_gamemodes::initGameMode();

    while (level.activePlayers == 0) {
        wait .5;
    }
}

/**
 * @brief UMI begins the actual gameplay
 *
 * @returns nothing
 */
startGame()
{
    debugPrint("in _umi::startGame()", "fn", level.nonVerbose);

    scripts\gamemodes\_survival::beginGame();
}

/**
 * @brief UMI deletes all entities with the given classname property
 *
 * @param classname string The value of the entities' classname property
 *
 * @returns nothing
 */
deleteEntitiesByClassname(classname)
{
    debugPrint("in _umi::deleteEntitiesByClassname()", "fn", level.nonVerbose);

    ents = getentarray(classname, "classname");
    for (i=0; i<ents.size; i++) {
        ents[i] delete();
    }
}

/**
 * @brief UMI deletes all entities with the given targetname property
 *
 * @param targetname string The value of the entities' targetname property
 *
 * @returns nothing
 */
deleteEntitiesByTargetname(targetname)
{
    debugPrint("in _umi::deleteEntitiesByTargetname()", "fn", level.nonVerbose);

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ents[i] delete();
    }
}

/**
 * @brief UMI deletes entities with a targetname of "oldschool_pickup"
 *
 * This deletes weapon and perk pickups on CoD4 stock maps, like mp_bog
 *
 * @returns nothing
 */
deletePickupItems()
{
    debugPrint("in _umi::deletePickupItems()", "fn", level.nonVerbose);

    deleteEntitiesByTargetname("oldschool_pickup");
}

//
// Unified Mapping Interface (UMI) Private Functions
//
// These functions should not be used by map makers, as they are subject to change
// and/or deletion without notice, at the consensus of the developers of the various
// mods.  They are generally utility functions that help make the interface work
// across various mods.
//

/**
 * @brief If both BTD and CVS waypoints are available, prefer the BTD waypoints?
 *
 * @returns boolean Whether the mapper or server operator prefers the BTD waypoints
 * @since RotU 2.2.1
 */
preferBtdWaypoints()
{
    debugPrint("in _umi::preferBtdWaypoints()", "fn", level.lowVerbosity);

    if (isDefined(level.preferBtdWaypoints)) {return level.preferBtdWaypoints;}
    else {return false;}
}

/**
 * @brief Is this map using the unified mapping interface?
 *
 * @returns boolean true if the map uses UMI, false otherwise
 */
isUmiMap()
{
    debugPrint("in _umi::isUmiMap()", "fn", level.lowVerbosity);

    /// @todo implement me
    return false;
}

/**
 * @brief Attempts to determine the name of the mod loading the map
 * @private
 *
 * @returns string The name of the mod, or an empty string if undetermined
 */
privateGuessModName()
{
    return "rotu";
}


//
// Unified Mapping Interface (UMI) Reserved Functions
//
// These functions are reserved for future use as public functions at the consensus
// of the developers of the various mods.  Calling them will not cause a compile
// or a runtime error, but they are't implemented. Any mod developer can implement
// and begin using one of these reserved functions at any time.
//
/**
 * @brief A hook for a function to initialize waypoints
 * @reserved
 *
 * @returns nothing
 */
initWaypoints()
{}

/**
 * @brief A hook for a function to initialize game setup
 * @reserved
 *
 * @returns nothing
 */
initSetup()
{}

/**
 * @brief A hook for a function to initialize barricades
 * @reserved
 *
 * @returns nothing
 */
initBarricades()
{}

/**
 * @brief A hook for a function to load waypoints
 * @reserved
 *
 * @returns nothing
 */
loadWaypoints()
{}

/**
 * @brief A hook for a function to load tradespawns
 * @reserved
 *
 * @returns nothing
 */
loadTradespawn()
{}


//
// RotU legacy functions
//
// These are the function calls in RotU _zombiescript.gsc file as of RotU 2.2.
// They are here for backwards compatibility for old maps.  These functions just
// forward the function call to the appropriate UMI function.
//

/**
 * @brief Builds weapon shops for RotU maps using old _zombiescript.gsc calls
 *
 * @param targetname string The value of the entities' targetname property
 * @param loadTime int ???
 *
 * @returns nothing
 */
buildAmmoStock(targetname, loadTime)
{
    debugPrint("in _umi::buildAmmoStock()", "fn", level.nonVerbose);

    setNativeMapType("rotu");
    level.isUmiMap = false;

    buildWeaponShopsByTargetname(targetname, loadTime);
}

/**
 * @brief Builds equipment shops for RotU maps using old _zombiescript.gsc calls
 *
 * @param targetname string The value of the entities' targetname property
 *
 * @returns nothing
 */
buildWeaponUpgrade(targetname)
{
    debugPrint("in _umi::buildWeaponUpgrade()", "fn", level.nonVerbose);

    setNativeMapType("rotu");
    level.isUmiMap = false;

    buildShopsByTargetname(targetname);
}

/**
 * @brief Builds a zombie spawn point for RotU maps using old _zombiescript.gsc calls
 *
 * @param targetname string The value of the entities' targetname property,
 * traditionally "spawngroup[n]", where n is an integer
 * @param priority int A zombie has a priority / totalPriority chance of being spawned here
 *
 * @returns nothing
 */
buildSurvSpawn(targetname, priority)
{
    debugPrint("in _umi::buildSurvSpawn()", "fn", level.nonVerbose);

    buildZombieSpawnByTargetname(targetname, priority);
}

/**
 * @brief Waits to start the game until the first player chooses their class and is spawned
 *
 * @returns nothing
 */
waittillStart()
{
    debugPrint("in _umi::waittillStart()", "fn", level.lowVerbosity);

    waitUntilFirstPlayerSpawns();
}

/**
 * @brief Begins the first wave of a RotU survival game
 *
 * @returns nothing
 */
startSurvWaves()
{
    debugPrint("in _umi::startSurvWaves()", "fn", level.nonVerbose);

    startGame();
}

/**
 * @brief Builds all barricades of the given targetname in the map
 *
 * @param targetname string The value of the entities' targetname property
 * @param partCount int The number of parts in barricades with this targetname
 * @param health int The initial and max hitpoints for the barricade
 * @param deathFx object A precached effect (via loadFx()) played when the barricade is destroyed
 * @param buildFx object A precached effect (via loadFx()) played when the barricade is rebuilt
 * @param dropAll boolean Optional, defaults to false
 *
 * @returns nothing
 */
buildBarricade(targetname, partCount, health, deathFx, buildFx, dropAll)
{
    debugPrint("in _umi::buildBarricade()", "fn", level.lowVerbosity);

    buildBarricadesByTargetname(targetname, partCount, health, deathFx, buildFx, dropAll);
}

/**
 * @brief Builds a weapon that can be picked up from an old RotU map using _zombiescript.gsc
 *
 * @param targetname string The name of the entities' targetname property
 * @param itemText string The English name of the weapon
 * @param weapon string The game name of the weapon, i.e. m14_mp
 * @param weaponType string The type of the weapon
 *
 * @returns nothing
 */
buildWeaponPickup(targetname, itemText, weapon, weaponType)
{
    debugPrint("in _umi::buildWeaponPickup()", "fn", level.lowVerbosity);

    buildWeaponPickupByTargetname(targetname, itemText, weapon, weaponType);
}

/// rotu unused ?
setWeaponHandling(id)
{
    debugPrint("in _umi::setWeaponHandling()", "fn", level.lowVerbosity);

    level.onGiveWeapons = id;
}

/// rotu unused ?
setSpawnWeapons(primary, secondary)
{
    debugPrint("in _umi::setSpawnWeapons()", "fn", level.lowVerbosity);

    level.spawnPrimary = primary;
    level.spawnSecondary = secondary;
}

/// rotu unused ?
buildParachutePickup(targetname)
{
    debugPrint("in _umi::buildParachutePickup()", "fn", level.lowVerbosity);

    ents = getentarray(targetname, "targetname");
    //for (i=0; i<ents.size; i++)
    //ents[i] thread scripts\players\_parachute::parachutePickup();
}

/// rotu unused ?
setWorldVision(vision, transitiontime)
{
    debugPrint("in _umi::setWorldVision()", "fn", level.lowVerbosity);

    visionSetNaked(vision, transitiontime);
    level.vision = vision;
}

/// rotu unused ?
setGameMode(mode)
{
    debugPrint("in _umi::setGameMode()", "fn", level.lowVerbosity);

    level.gameMode = mode;
    waittillframeend;
}

/// rotu unused ?
setPlayerSpawns(targetname)
{
    debugPrint("in _umi::setPlayerSpawns()", "fn", level.lowVerbosity);

    level.playerspawns = targetname;
}


//
// ROZO legacy functions
//
// These are the function calls used for mapping purposes as of ROZO 0.5.
// They are here for backwards compatibility for old maps.  These functions just
// forward the function call to the appropriate UMI function.
//

/**
 * @brief Builds zombie spawn points for old ROZO maps
 *
 * @returns nothing
 */
addDefaultZombieSpawns()
{
    debugPrint("in _umi::addDefaultZombieSpawns()", "fn", level.nonVerbose);

    buildZombieSpawnsByClassname("mp_dm_spawn");
}

/**
 * @brief Builds weapon shops and equipment shops using old ROZO calls
 *
 * @param weapons string Space-separated list of tradespawn array indices
 * @param shops string Space-separated list of tradespawn array indices
 *
 * e.g. @code placeShops("0 2 4 6", "1 3 5 7"); @endcode
 *
 * @returns nothing
 */
placeShops(weapons, shops)
{
    debugPrint("in _umi::placeShops()", "fn", level.nonVerbose);

    setNativeMapType("rozo");
    level.isUmiMap = false;

    // We need to force ROZO maps to waittillStart() or we can't create the usables
    waittillStart();

    buildWeaponShopsByTradespawns(weapons);
    buildShopsByTradespawns(shops);
}

/**
 * @brief Converts waypoints for old ROZO maps
 *
 * @returns nothing
 */
convertWaypoints()
{
    debugPrint("in _umi::convertWaypoints()", "fn", level.lowVerbosity);

    convertToNativeWaypoints();
}

/**
 * @brief Adds a new position as a default target for zombies that don't see a player
 *
 * @param origin A tuple containing the map position to be the default target
 *
 * @returns nothing
 */
zombieDefaultTarget(origin)
{
    debugPrint("in _umi::zombieDefaultTarget()", "fn", level.lowVerbosity);

    // Do nothing, RotU doesn't need to set default targets for zombies
}

mapThink()
{
    debugPrint("in _umi::mapThink()", "fn", level.lowVerbosity);

    // Do nothing, ROZO internal function
}

setPlayerModels()
{
    debugPrint("in _umi::setPlayerModels()", "fn", level.lowVerbosity);

    // Do nothing, ROZO internal function
}

getFreeStruct(structs, additional)
{
    debugPrint("in _umi::getFreeStruct()", "fn", level.lowVerbosity);

    // Do nothing, ROZO internal function
}

addDefaultPlayerSpawns(swap)
{
    debugPrint("in _umi::addDefaultPlayerSpawns()", "fn", level.lowVerbosity);

    // Do nothing, RotU doesn't need to add default player spawns
}

addPlayerSpawns(classname, enabled)
{
    debugPrint("in _umi::addPlayerSpawns()", "fn", level.lowVerbosity);

    // Do nothing, RotU doesn't need to add player spawns
}

