printl("Loading Secrets...")
printl("Secrets.nut has succesfully been bypassed! Alternative .nut is now in action!")

IncludeScript("sha256-32bit.nut")

//round variables
isSaxxyRound <- null
isTiltRound <- null
ForceClassRoundClass <- null
isHeadRound <- null
isTorsoRound <- null
developers_are_janitors <- false //for testing

gemcount <- 0

function AttachmentSecret(player,attachname=null,type=0,template=null){

	if (template){
		local point_template = Entities.FindByName(null,template)
		local spawned_ents = point_template.GetScriptScope().SpawnTemplate(point_template)
		local parent_ent = null
		foreach (ent in spawned_ents){
			if (spawned_ents.len() == 1){
				parent_ent = ent
				break
			}
			if (ent.GetClassname() == "func_brush"){
				parent_ent = ent
				break
			}
		}
		attachname = parent_ent.GetName()
	}
	local attachprop = Entities.FindByName(null,attachname)
	//randomize name so it's unlikely two will be the same (if there are two)
	//by now all parenting has applied and handles have been acquired so name is irrelevant
	local salt = RandomInt(0,32768)
	attachname = attachname + salt
	attachprop.KeyValueFromString("targetname",attachname)

	local attach_player = player
	if (typeof player == "string")
		attach_player = Entities.FindByName(null,player)
	attach_player.KeyValueFromString("targetname","attachplayer_"+attachname)

	local lmm = SpawnEntityFromTable("logic_measure_movement",{
		targetname="lmm_"+attachname
		MeasureTarget="attachplayer_"+attachname
		Target=attachname
		MeasureReference="lmm_"+attachname
		TargetReference="lmm_"+attachname
		MeasureType=type
	})
	ents_to_kill[GetUserID(attach_player)].extend([lmm,attachprop])
}


combo_lock_codes <- {
	cemetary = ["1234",""]
	burger = ["2143",""]
}

function ComboLock(codetype,invalue){
	local combo = combo_lock_codes[codetype][0]
	local combolog = combo_lock_codes[codetype][1] + invalue
	if (combo.slice(0,combolog.len()) == combolog){
		if (combo.len() == combolog.len()){
			switch (codetype) {
				case "cemetary" :
					EntFire("ghost_button*","Lock",0)
					EntFire("ghost_button_win","Unlock",0.01)
					break
				case "burger" :
					EntFire("burger_button*","Lock",0)
					EntFire("burger_button_win","Unlock",0.01)
					break
			}
		}
		else{
			combo_lock_codes[codetype][1] = combolog
			return
		}
	}
	combo_lock_codes[codetype][1] = ""
}

function AttachGun(){
	if (!activator.GetScriptScope().weaponholder){
		local gunum = RandomInt(1,8)
		local guntemplate = Entities.FindByName(null,"cs" + gunum + "_template")
		local spawned_ents = guntemplate.GetScriptScope().SpawnTemplate(guntemplate)
		foreach (spawned_ent in spawned_ents){
			if(spawned_ent.GetClassname() == "func_brush"){
				//delay necessary
				EntFireByHandle(spawned_ent,"SetParent","!activator",0.02,activator,activator)
				EntFireByHandle(spawned_ent,"SetParentAttachment","back_lower",0.04,"","")
				guns_to_kill[GetUserID(activator)].append(spawned_ent)
			}
		}
		activator.GetScriptScope().weaponholder = true
	}
}

function AmericanPsycho(){
	GiveWeapon("tf_weapon_fireaxe",2,activator,[["bleeding duration",5,-1]])
	activator.EmitSound("jb_jungle/hip_to_be_square.mp3")
	activator.GetScriptScope().bateman = true
}

function OnRoundEvents(player){
	ResetSecretAttributes(player)
	if (isSaxxyRound)
		GiveWeapon("saxxy",423,player)
	if (isTiltRound)
		ApplyTilt(player)
	if (ForceClassRoundClass){
		if (player.GetPlayerClass() != ForceClassRoundClass){
			NetProps.SetPropInt(player, "m_PlayerClass.m_iClass", ForceClassRoundClass)
    		NetProps.SetPropInt(player, "m_Shared.m_iDesiredPlayerClass", ForceClassRoundClass)
    		player.ForceRespawn()
		}
	}
	if (isTorsoRound)
		RandomizeHeadSize(player)
	if (isHeadRound)
		RandomizeHeadSize(player)
	if(InHashlist(player,does_it_for_free) || (developers_are_janitors && InHashlist(player,developer_hashes))){
		AttachmentSecret(player,null,0,"janny_template")
	}
	if (InHashlist(player,janitor_hashes) || (developers_are_janitors && InHashlist(player,developer_hashes)))
		AttachmentSecret(player,null,0,"janitor_template")
}

function OnStartRoundEvents(){
	foreach(player in player_array){
		if(InHashlist(player,does_it_for_free) || (developers_are_janitors && InHashlist(player,developer_hashes))){
			EmitSoundOnClient("janny",player)
		}
	}
}

function ActivateSaxxyRound(){
	foreach(ent in player_array){
		if(ent.IsAlive()){
			GiveWeapon(saxxy_enum[ent.GetPlayerClass()],423,ent)
		}
	}
	isSaxxyRound = true
	EmitGlobalSoundscript("gold")
}

saxxy_enum <- [
	"tf_weapon_fireaxe",	//MULTI-CLASS
	"tf_weapon_bat",	//SCOUT
	"tf_weapon_club",	//SNIPER
	"tf_weapon_shovel",	//SOLDIER
	"tf_weapon_bottle",	//DEMO
	"tf_weapon_bonesaw",	//MEDIC
	"tf_weapon_fireaxe",	//HEAVY
	"tf_weapon_fireaxe",	//PYRO
	"tf_weapon_knife",	//SPY
	"tf_weapon_wrench",	//ENGINEER
	"tf_weapon_fireaxe",	//CIVILIAN
]
function GiveWeapon(className, itemID, player, attributes = [],model=null,level=1)
{
    local weapon = Entities.CreateByClassname(className);
    NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", itemID);
    NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true);
    NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true);
    NetProps.SetPropEntity(weapon, "m_hOwnerEntity",player)
    NetProps.SetPropEntity(weapon, "m_hOwner",player)
    NetProps.SetPropEntity(weapon, "m_hEffectEntity",player)
	NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iEntityQuality", 0)
	NetProps.SetPropInt(weapon,"m_AttributeManager.m_Item.m_iEntityLevel",level)
    weapon.SetTeam(player.GetTeam());

    foreach(attribute in attributes){
    	if (typeof attribute == "array")
    		weapon.AddAttribute(attribute[0], attribute[1], attribute[2])
    	else
    		weapon.AddAttribute(attribute,1,-1)
    }

    if (model){
    	//do something
    }

    Entities.DispatchSpawn(weapon);

    player.Weapon_Equip(weapon);

    for (local i = 0; i < 7; i++)
    {
        local heldWeapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i);
        if (heldWeapon == null || !heldWeapon.IsValid())
            continue;
        if (heldWeapon.GetSlot() != weapon.GetSlot())
            continue;
        heldWeapon.Destroy();
        NetProps.SetPropEntityArray(player, "m_hMyWeapons", weapon, i);
        break;
    }

    player.Weapon_Switch(weapon);
    weapon.ReapplyProvision()
    return weapon;
}

function ResetSecretAttributes(player){
	local player_weps = player.iterateWeps()
	foreach (wep in player_weps){
		wep.RemoveAttribute("mod weapon blocks healing")
	}
	local attrlist = ["head scale","torso scale"]
	foreach (attr in attrlist){
		player.RemoveCustomAttribute(attr)
	}
}

function SlipperyRound(){
	Convars.SetValue("sv_Friction",0)
	EmitGlobalSoundscript("slip")
}

function EnableTilt(){
	foreach(ent in player_array)
		ApplyTilt(ent)
	isTiltRound = true
}

function DisableTilt(){
	foreach(ent in player_array){
		local eyeangle = ent.EyeAngles()
		ent.SnapEyeAngles(QAngle(eyeangle.x,eyeangle.y,0))
	}
	isTiltRound = false
}

function ApplyTilt(player){
	local random = RandomInt(0,1)
	local angle = QAngle(0,0,0)
	if (random == 0)
		angle = QAngle(player.EyeAngles().x,player.EyeAngles().y,90)
	else
		angle = QAngle(player.EyeAngles().x,player.EyeAngles().y,-90)
	player.SnapEyeAngles(angle)
}


function MedievalChat(side){
	local gamerules = Entities.FindByClassname(null,"tf_gamerules")
	NetProps.SetPropBool(gamerules,"m_bPlayingMedieval",side)
}

function ForceClassRound(selectedclass){
	ForceClassRoundClass = selectedclass
	foreach(ent in player_array){
		local entorigin = ent.GetOrigin()
		local entangles = ent.EyeAngles()
		local entvelocity = ent.GetAbsVelocity()
		ent.ForceRespawn()
		ent.SetOrigin(entorigin)
		ent.SnapEyeAngles(entangles)
		ent.SetVelocity(entvelocity)
	}
}

function RandomizeHeadSize(player){
	//random float from 1.5 to 4.0
	player.AddCustomAttribute("head scale",RandomInt(15,40)/10.0,-1)
}

function EnableHeadRound(){
	foreach(ent in player_array)
		RandomizeHeadSize(ent)
	isHeadRound = true
}

function DisableHeadRound(){
	foreach(ent in player_array)
		ent.AddCustomAttribute("head scale",1.0,-1)
	isHeadRound = false
}

function RandomizeTorsoSize(player){
	if (RandomInt(0,1) == 0)
		player.AddCustomAttribute("torso scale",0.5,-1)
	else
		player.AddCustomAttribute("torso scale",2.0,-1)
}

function EnableTorsoRound(){
	foreach(ent in player_array)
		RandomizeTorsoSize(ent)
	isTorsoRound = true
}

function DisableTorsoRound(){
	foreach(ent in player_array)
		ent.AddCustomAttribute("torso scale",1.0,-1)
	isTorsoRound = false
}

function ActivatePhonograph(){
	EntFire("phonograph_button","Unlock")
}

//diamond pickaxe code
//courtesy of berke
//thanks for this!

const strPickaxeModel = "models/berke1/jailbreak1/amazonjungle1/diamondpickaxe1.mdl"

flOldDroppedWeaponLifeTime <- 0
PlayerLeftoverWearableInfos <- []

function RemoveLeftoverWearables(iUserID, bShouldRemoveEntity = true)
// By Berke "STEAM_0:0:95142811"
{
	local iCounter = 0;

	foreach (PlayerLeftoverWearableInfo in PlayerLeftoverWearableInfos)
	{
		if (PlayerLeftoverWearableInfo.iPlayerUserID == iUserID)
		{
			if (iCounter == PlayerLeftoverWearableInfos.len() - 1 && !Convars.GetFloat("tf_dropped_weapon_lifetime"))
				Convars.SetValue("tf_dropped_weapon_lifetime", flOldDroppedWeaponLifeTime);

			if (bShouldRemoveEntity)
			{
				local hWearable = PlayerLeftoverWearableInfo.hPlayerWearable;

				if (hWearable.IsValid())
					hWearable.Kill();
			}

			PlayerLeftoverWearableInfos.remove(iCounter)

			break;
		}

		iCounter++;
	}
}

function GivePickaxe()
// By Berke "STEAM_0:0:95142811"
{
	for (local iSlot = 0; iSlot <= 2; iSlot++)
	{
		local hOldWeapon = NetProps.GetPropEntityArray(activator, "m_hMyWeapons", iSlot);

		if (hOldWeapon && hOldWeapon.GetSlot() == 2)
		{
			local iViewModelArmsIndex = NetProps.GetPropInt(hOldWeapon, "m_iViewModelIndex");

			hOldWeapon.Kill();

			local flCurrentDroppedWeaponLifeTime = Convars.GetFloat("tf_dropped_weapon_lifetime");

			if (flCurrentDroppedWeaponLifeTime)
			{
				local iCurrentDroppedWeaponLifeTime = flCurrentDroppedWeaponLifeTime.tointeger();

				flOldDroppedWeaponLifeTime = flCurrentDroppedWeaponLifeTime - iCurrentDroppedWeaponLifeTime ? flCurrentDroppedWeaponLifeTime : iCurrentDroppedWeaponLifeTime;

				Convars.SetValue("tf_dropped_weapon_lifetime", 0);
			}

			local hWeapon = Entities.CreateByClassname("tf_weapon_shovel");

			NetProps.SetPropInt(hWeapon, "m_nRenderMode", Constants.ERenderMode.kRenderTransColor);
			NetProps.SetPropInt(hWeapon, "m_clrRender", 0);
			NetProps.SetPropBool(hWeapon, "m_bValidatedAttachedEntity", true);
			NetProps.SetPropInt(hWeapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 128);
			NetProps.SetPropBool(hWeapon, "m_AttributeManager.m_Item.m_bInitialized", true);
			if (activator.GetPlayerClass() != 3)
				NetProps.SetPropBool(hWeapon, "m_AttributeManager.m_Item.m_bOnlyIterateItemViewAttributes", true);

			local attributes = [
			["dmg bonus while half dead",1.25,-1],
			["restore health on kill",50,-1],
			["speed_boost_on_kill",3,-1]
			]

			foreach(attribute in attributes){
		    	hWeapon.AddAttribute(attribute[0], attribute[1], attribute[2])
		    }

		    hWeapon.RemoveAttribute("dmg penalty while half alive")

			local hWearableViewModel1 = Entities.CreateByClassname("tf_wearable_vm");

			NetProps.SetPropInt(hWearableViewModel1, "m_nModelIndex", iViewModelArmsIndex);
			NetProps.SetPropBool(hWearableViewModel1, "m_bValidatedAttachedEntity", true);
			NetProps.SetPropEntity(hWearableViewModel1, "m_hWeaponAssociatedWith", hWeapon);

			local hWearableViewModel2 = Entities.CreateByClassname("tf_wearable_vm");

			PrecacheModel(strPickaxeModel);

			hWearableViewModel2.SetModel(strPickaxeModel);
			NetProps.SetPropBool(hWearableViewModel2, "m_bValidatedAttachedEntity", true);
			NetProps.SetPropEntity(hWearableViewModel2, "m_hWeaponAssociatedWith", hWeapon);

			NetProps.SetPropEntity(hWeapon, "m_hExtraWearableViewModel", hWearableViewModel2);

			local hWearable = Entities.CreateByClassname("tf_wearable");

			hWearable.SetModel(strPickaxeModel);
			NetProps.SetPropBool(hWearable, "m_bValidatedAttachedEntity", true);
			NetProps.SetPropEntity(hWearable, "m_hWeaponAssociatedWith", hWeapon);

			NetProps.SetPropEntity(hWeapon, "m_hExtraWearable", hWearable);

			local iTeam = activator.GetTeam();

			hWeapon.SetTeam(iTeam);

			hWearableViewModel1.SetTeam(iTeam);

			hWearableViewModel2.SetTeam(iTeam);

			hWearable.SetTeam(iTeam);

			Entities.DispatchSpawn(hWeapon);

			EntFireByHandle(hWeapon, "DisableShadow", "", 0, null, null);

			hWearableViewModel1.KeyValueFromString("classname", "entity_rocket");

			Entities.DispatchSpawn(hWearableViewModel1);

			hWearableViewModel2.KeyValueFromString("classname", "entity_rocket");

			Entities.DispatchSpawn(hWearableViewModel2);

			NetProps.SetPropInt(hWearable, "m_fEffects", Constants.FEntityEffects.EF_BONEMERGE | Constants.FEntityEffects.EF_BONEMERGE_FASTCULL);
			NetProps.SetPropEntity(hWearable, "m_hOwnerEntity", activator);
			hWearable.AddSolidFlags(Constants.FSolid.FSOLID_NOT_SOLID);
			NetProps.SetPropBool(hWearable, "m_bValidatedAttachedEntity", true);
			NetProps.SetPropEntity(hWearable, "m_hWeaponAssociatedWith", hWeapon);
			hWearable.SetAbsOrigin(activator.GetOrigin());
			hWearable.SetAbsAngles(activator.GetAbsAngles());
			EntFireByHandle(hWearable, "SetParent", "!activator", 0, activator, null);

			hWearable.KeyValueFromString("classname", "customweapon1wearable1");

			Entities.DispatchSpawn(hWearable);

			activator.Weapon_Equip(hWeapon);

			if (activator.GetPlayerClass() != Constants.ETFClass.TF_CLASS_SOLDIER)
			{
				hWeapon.SetModel("models/weapons/c_models/c_soldier_arms.mdl");
				hWeapon.SetCustomViewModel("models/weapons/c_models/c_soldier_arms.mdl");
				NetProps.SetPropInt(hWeapon, "m_iViewModelIndex", GetModelIndex("models/weapons/c_models/c_soldier_arms.mdl"));
			}

			activator.EquipWearableViewModel(hWearableViewModel1);

			activator.EquipWearableViewModel(hWearableViewModel2);

			PlayerLeftoverWearableInfos.push(
			{
				iPlayerUserID = NetProps.GetPropIntArray(Entities.FindByClassname(null, "tf_player_manager"), "m_iUserID", activator.GetEntityIndex()),
				hPlayerWearable = hWearable
			});

			NetProps.SetPropEntityArray(activator, "m_hMyWeapons", hWeapon, iSlot);

			activator.Weapon_Switch(hWeapon);

			break;
		}
	}
}

//developer commands
/////////////////////////////////////////
//SERVER OWNERS OR NOSY PEOPLE READ THIS
/////////////////////////////////////////
//These are commands intended to be used F O R F U N by the map developers
//These will NEVER be used to gain a gameplay advantage, nor will they be abused
//These are purely for the entertainment of the entire server
//and will be utilized almost exclusively on freedays
//
//As an additional note to my biggest, hotpocket eating fan -
//I'm already banned and this only checks for my main
//so don't get pissy and try to get the map removed over this.
//blow me!
dev_room <- Vector(2616,-1184,24)
function OnSayEvents(table){
	local player = GetPlayerFromUserID(table.userid)
	//please read developer commands section for this
	if (InHashlist(player,developer_hashes)){
		switch (table.text) {
			case "gtdr" :
				DeveloperRoom(player)
				break
			case "tb" :
				TeleportBack(player)
				break
			case "condump_on" :
				PowerPlay(player,true)
				break
			case "condump_off" :
				PowerPlay(player,false)
				break
			case "vrl" :
				GiveValveRocketLauncher(player)
				break
		}
	}
	if (InHashlist(player,developer_hashes) || InHashlist(player,vip_hashes)){
		switch (table.text) {
			case "gr" :
				GiveWeapon("tf_weapon_wrench",169,player)
				break
			case "medievalon" :
				MedievalChat(true)
				break
			case "medievaloff" :
				MedievalChat(false)
				break
			case "saxxy" :
				ActivateSaxxyRound()
				break
			case "help" :
				HelpMenu(player)
				break
		}

	}
}

function HelpMenu(player){
	//who even needs help?
	local dev_messages = [
		"\x0007ff0000gtdr\x0007ffffff: Teleport to developer room",
		"\x0007ff0000tb\x0007ffffff: Teleport to previous location",
		"\x0007ff0000condump_on\x0007ffffff: Powerplay on",
		"\x0007ff0000condump_off\x0007ffffff: Powerplay off",
		"\x0007ff0000vrl\x0007ffffff: Valve Rocket Launcher",
	]
	local vip_messages = [
		"\x00070000ffgr\x0007ffffff: Golden Wrench",
		"\x00070000ffmedievalon\x0007ffffff: Enable medieval chat",
		"\x00070000ffmedievaloff\x0007ffffff: Disable medieval chat",
		"\x00070000ffsaxxy\x0007ffffff: Enable saxxy round",
	]
	if (InHashlist(player,developer_hashes)){
		foreach(message in dev_messages){
			ClientPrint(player,3,message)
		}
	}
	if (InHashlist(player,developer_hashes) || InHashlist(player,vip_hashes)){
		foreach(message in vip_messages){
			ClientPrint(player,3,message)
		}
	}
}



function InHashlist(player,hashlist){
	local id = player.GetScriptScope().hash
	foreach(hash in hashlist){
		if (hash == id)
			return true
	}
	return false
}

function IsDeveloper(player){ //used for ingame logic
	return InHashlist(player,developer_hashes)
}

function IsVIP(player){
	return InHashlist(player,vip_hashes)
}

function DeveloperRoom(player){
	//go to the dev room
	player.GetScriptScope().previous_location <- player.GetOrigin()
	player.SetOrigin(dev_room)
}

function TeleportBack(player){
	//return to wherever we were before the command
	player.SetOrigin(player.GetScriptScope().previous_location)
}

function PowerPlay(player,status=true){
	//prevent new medics from healing
	local player_weps = player.iterateWeps()
	foreach (wep in player_weps){
		if (status)
			wep.AddAttribute("mod weapon blocks healing",1,-1)
		else
			wep.RemoveAttribute("mod weapon blocks healing")
	}
	//stop all medics healing us
	foreach(ent in player_array)
		if (ent.GetHealTarget() == player)
			ent.Weapon_Switch(ent.GetLastWeapon())

	//finally, add conditions
	local condlist =
		[5, //uber
		11, //crits
		28, //quick fix
		58, //bullet resist
		59, //blast resist
		60] //fire resist
	foreach (cond in condlist){
		if (status)
			player.AddCond(cond)
		else
			player.RemoveCond(cond)
	}
}

function GiveValveRocketLauncher(player){
	local vrl = GiveWeapon("tf_weapon_rocketlauncher",
		18,
		player,
		[["damage bonus",10100,-1],
		["clip size bonus",1100,-1],
		["fire rate bonus",0.25,-1],
		["heal on hit for rapidfire",250,-1],
		["critboost on kill",10,-1],
		["Projectile speed increased",1.5,-1],
		["mult_player_movespeed_active",2.0,-1]],
		null,
		100)
}

//hashes

// developer_hashes <- [
// 	"b0323d8a7e5ec7de58f84fb48075db93f672790091d82d1e6267d7be7b165070",
// 	"4730f8cb2dcfa459324c08189f29db36f1b5480c9e3ef838a4dcae875e89356d"
// ]

// vip_hashes <- [
// 	"5b95f55c2d22dcf9723f58e91e5c87021edc13f0bf415905bb7a6f4bab5f10c1",
// ]

// does_it_for_free <- [
// 	"5f1e2cd7c27361af2fa67bd8533d057805e021b892fabd1b046628ea76beddb6"
// ]

// janitor_hashes <- [
// 	"5f1e2cd7c27361af2fa67bd8533d057805e021b892fabd1b046628ea76beddb6",
// 	"d5a9a4938a4ccddf2257d538f77d7646173ef16fb05913d5a81b0ca8da5bc89b",
// 	"7ed526ff761a4511e2b966dd5a7ba521d6bd733053be88c89a1b5429117b326c",
// 	"684a681487003a2a3d16a4e5d920e678b0e7c9f2ef54e3a744f0110516b73396",
// 	"f02bc6bc5545e7b881ead210b81185b2acdbf9aa50b34992c73e6981943cd8b7",
// 	"fb8c0b680bd1f00955e6b4e7dbcc6ed747675cf4ded9107073347a3c749d1001"
// ]

printl("Finished loading the edited Secrets!")