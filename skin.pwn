#if defined _included_ownable_skins
    #endinput
#endif

#define _included_ownable_skins


#include <YSI_Coding\y_hooks>


#define MAX_PLAYER_SKINS 5


enum skinData
{
    skinRecordId,
    skinId,
    bool:isPrimary
}
static
    playerSkinInfo[MAX_PLAYERS][MAX_PLAYER_SKINS][skinData],
    skinUserId[MAX_PLAYERS];


static createSkinsTable()
{
    mysql_query(handle, "CREATE TABLE IF NOT EXISTS skin (id INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id INT(11) UNSIGNED NOT NULL, skin_id INT(11) UNSIGNED NOT NULL DEFAULT 2, is_primary BOOLEAN NOT NULL DEFAULT false, UNIQUE KEY unique_combination (user_id, skin_id))");
}

static addPlayerSkin(userId, skin)
{
    new query[128];

    format(query, sizeof query, "INSERT INTO skin (user_id, skin_id) VALUES (%d, %d)", userId, skin);
    mysql_query(handle, query);

    format(query, sizeof query, "SELECT id FROM skin WHERE user_id = %d AND skin_id = %d LIMIT 1", userId, skin);
    new Cache:result = mysql_query(handle, query);

    new record_id = 0;
    cache_get_value_name_int(0, "id", record_id);

    cache_delete(result);   

    return record_id;
}

static updatePlayerSkin(recordId, skin, is_primary)
{
    new query[128];
    format(query, sizeof query, "UPDATE skin SET skin_id = %d, is_primary = %d WHERE id = %d", skin, is_primary, recordId);
    mysql_query(handle, query);
}

static deletePlayerSkin(recordId)
{
    new query[128];
    format(query, sizeof query, "DELETE FROM skin WHERE id = %d", recordId);
    mysql_query(handle, query);
}

static loadPlayerSkins(playerid, userId)
{
    new query[64], rows;
    format(query, sizeof query, "SELECT id, skin_id FROM skin WHERE user_id = %i LIMIT %d", userId, MAX_PLAYER_SKINS);
    new Cache:result = mysql_query(handle, query);

    cache_get_row_count(rows);

    for(new i; i < rows; i++)
    {
        cache_get_value_name_int(i, "id", playerSkinInfo[playerid][i][skinRecordId]);
        cache_get_value_name_int(i, "skin_id", playerSkinInfo[playerid][i][skinId]);
        cache_get_value_name_bool(i, "is_primary", playerSkinInfo[playerid][i][isPrimary]);
    }

    cache_delete(result);    
}

static savePlayerSkins(playerid)
{
    for(new i; i < MAX_PLAYER_SKINS; i++)
    {
        for(new x; x < MAX_PLAYER_SKINS; x++)
        {
            if(i != x && playerSkinInfo[playerid][i][skinId] == playerSkinInfo[playerid][x][skinId])
            {
                playerSkinInfo[playerid][x][skinId] = 0;
            }
        }

        if(playerSkinInfo[playerid][i][skinRecordId])
        {
            if(!playerSkinInfo[playerid][i][skinId])
            {
                deletePlayerSkin(playerSkinInfo[playerid][i][skinRecordId]);
            }
            else
            {
                updatePlayerSkin(playerSkinInfo[playerid][i][skinRecordId], playerSkinInfo[playerid][i][skinId], playerSkinInfo[playerid][i][isPrimary]);
            }
        }
        else
        {
            if(playerSkinInfo[playerid][i][skinId])
            {
                new record_id = addPlayerSkin(skinUserId[playerid], playerSkinInfo[playerid][i][skinId]);
            
                if(record_id)
                {
                    updatePlayerSkin(record_id, playerSkinInfo[playerid][i][skinId], playerSkinInfo[playerid][i][isPrimary]);
                }
            }            
        }
    }
}

static getPlayerSkinsNumber(playerid)
{
    new number_of_skins = 0;
 
    for(new i; i < MAX_PLAYER_SKINS; i++)
    {
        if(playerSkinInfo[playerid][i][skinId]) number_of_skins++;
    }

    return number_of_skins;
}


hook OnUserLoggedIn(playerid)
{
    if(!IsPlayerConnected(playerid)) return false;

    loadPlayerSkins(playerid, skinUserId[playerid]);

    return true;    
}


hook OnGameModeInit()
{
    createSkinsTable();
}

hook OnPlayerConnect(playerid)
{
    for(new i; i < MAX_PLAYER_SKINS; i++)
    {
        playerSkinInfo[playerid][i][skinRecordId] = 0;
        playerSkinInfo[playerid][i][skinId] = 0;
    }
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == 1001)
    {
        if(response)
        {
            SetPVarInt(playerid, "skins_dialog_action", listitem);

            new header[8];
            format(header, sizeof header, "%d - %d", listitem, playerSkinInfo[playerid][listitem][skinId]);

            ShowPlayerDialog(playerid, 1002, DIALOG_STYLE_LIST, header, "DRESS UP\nDELETE", "Accept", "CLOSE");
        }
    }
    if(dialogid == 1002)
    {
        if(response)
        {
            new slot_id = GetPVarInt(playerid, "skins_dialog_action");

            if(listitem == 0)
            {
                setPlayerPrimarySkin(playerid, slot_id);
            }
            if(listitem == 1)
            {
                removePlayerOwnSkin(playerid, slot_id);
            }
        }
        DeletePVar(playerid, "skins_dialog_action");
    }
}

hook OnPlayerSpawn(playerid)
{
    new skin_id = getPlayerOwnSkin(playerid, 0);

    SetPlayerSkin(playerid, skin_id);
}

hook OnPlayerDisconnect(playerid, reason)
{
    savePlayerSkins(playerid);
}


setUserForSkins(playerid, user_id)
{
    skinUserId[playerid] = user_id;
}


stock getPlayerOwnSkin(playerid, slot_id)
{
    return playerSkinInfo[playerid][slot_id][skinId];
}

stock setPlayerOwnSkin(playerid, slot_id, skin)
{
    if(slot_id > MAX_PLAYER_SKINS) return false;
    
    new number_of_skins = getPlayerSkinsNumber(playerid);

    if(slot_id > number_of_skins) slot_id = number_of_skins;

    playerSkinInfo[playerid][slot_id][skinId] = skin;

    if(number_of_skins == 1)
    {
        playerSkinInfo[playerid][slot_id][isPrimary] = true;
    }

    return true;
}

stock setPlayerPrimarySkin(playerid, slot_id)
{
    if(slot_id > MAX_PLAYER_SKINS) return false;

    for(new i; i < MAX_PLAYER_SKINS; i++)
    {
        if(i == slot_id && playerSkinInfo[playerid][i][skinId])
        {
            playerSkinInfo[playerid][i][isPrimary] = true;

            SetPlayerSkin(playerid, playerSkinInfo[playerid][i][skinId]);
        }
        else playerSkinInfo[playerid][i][isPrimary] = false;
    }

    return true;
}

stock getPlayerPrimarySkin(playerid)
{
    for(new i; i < MAX_PLAYER_SKINS; i++)
    {
        if(playerSkinInfo[playerid][i][isPrimary]) return playerSkinInfo[playerid][i][skinId];
    }

    return 0;
}

stock removePlayerOwnSkin(playerid, slot_id)
{
    if(slot_id > MAX_PLAYER_SKINS) return false;

    playerSkinInfo[playerid][slot_id][skinId] = 0;

    new number_of_skins = getPlayerSkinsNumber(playerid);

    if(number_of_skins == 1)
    {
        for(new i; i < MAX_PLAYER_SKINS; i++)
        {
            if(playerSkinInfo[playerid][i][skinId]) setPlayerPrimarySkin(playerid, i);
        }
    }

    return true;
}


CMD:skins(playerid)
{
	if(!skinUserId[playerid]) return 1;
	
    new string[128], str[32], number_of_skins = getPlayerSkinsNumber(playerid);

    strcat(string, "SLOT\tSKIN\tStatus\n");

	for(new i = 0; i < MAX_PLAYER_SKINS; i++)
	{
        if(playerSkinInfo[playerid][i][skinId])
        {
            format(str, sizeof str, "%d\t%d\t%s\n", i+1, playerSkinInfo[playerid][i][skinId], playerSkinInfo[playerid][i][isPrimary] ? ("{00FF00}Active{FFFFFF}") : (" "));
            
            strcat(string, str);
        }
	}

    if(number_of_skins <= 1) ShowPlayerDialog(playerid, 1000, DIALOG_STYLE_TABLIST_HEADERS, "My skins", string, "CLOSE", "");
	else ShowPlayerDialog(playerid, 1001, DIALOG_STYLE_TABLIST_HEADERS, "My skins", string, "Next", "CLOSE");

	return 1;
}
