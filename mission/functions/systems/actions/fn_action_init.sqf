/*
	File: fn_action_init.sqf
	Author: Cerebral
	Modified: @dijksterhuis
	Public: No
	
	Description:
		Init player actions
	
	Parameter(s): none
	
	Returns:
	
	Example(s):
		call vn_mf_fnc_action_init;
*/

if (isNil "vn_mf_actions_player") then
{
	vn_mf_actions_player = player;
};

if (isNil "vn_mf_actions_initialized" || vn_mf_actions_player != player) then //arma's  variable system is asinine
{
	vn_mf_actions_player = player;
	vn_mf_actions_initialized = 1;
	call vn_mf_fnc_action_destroy_respawn;
	call vn_mf_fnc_action_capture_player;
	//call vn_mf_fnc_action_arrest_player;
	//call vn_mf_fnc_release_from_arrest_player;
	/*
	disabled by @dijksterhuis for curators

	call vn_mf_fnc_action_destroy_task;
	call vn_mf_fnc_action_gather_intel;
	call vn_mf_fnc_action_radiotap;
	*/
	"vn_holdActionAdd_layer" cutText ["","PLAIN"];
};

