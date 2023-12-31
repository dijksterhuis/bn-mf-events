/*
	File: fn_veh_asset_init_vehicle.sqf
	Author: Savage Game Design
	Public: No

	Description:
		Initialises a vehicle on respawn

	Parameter(s):
		_id - ID to give the vehicle [Number]
		_vehicle - Vehicle to initialise [Object]
		_firstInit - Whether this is being called as part of adding the vehicle to the asset system [Boolean, defaults to false]

	Returns: nothing

	Example(s): none
*/

params ["_id", "_vehicle", ["_firstInit", false]];

_vehicle setVariable ["vehAssetId", _id];
[_id] call vn_mf_fnc_veh_asset_add_unlock_action;
[_id] call vn_mf_fnc_veh_asset_set_idle;
_vehicle addEventHandler ["RopeAttach", {[_this # 2 getVariable "vehAssetId"] call vn_mf_fnc_veh_asset_unlock_vehicle}];
