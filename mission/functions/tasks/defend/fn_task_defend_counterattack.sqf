/*
	File: fn_task_counterattack.sqf
	Author: Savage Game Design
	Public: No

	Description:
		Primary task to defend a zone against an enemy attack, and clear out nearby entrenchments.
		Uses the state machine task system.

	Parameter(s):
		_taskDataStore - Namespace for storing task info [Object]

	Returns: nothing

	Example(s):
		Not directly called.
*/

/*
	Requires Task Variables:
*/

params ["_taskDataStore"];

_taskDataStore setVariable ["INIT", {
	params ["_taskDataStore"];

	//Required parameters
	private _marker = _taskDataStore getVariable "taskMarker";
	private _markerPos = getMarkerPos _marker;

	/*
	// present in SGD Mike Force, but not used anywhere.
	private _hqs = (localNamespace getVariable ["sites_hq", []]) inAreaArray _marker;
	*/

	private _prepTime = _taskDataStore getVariable ["prepTime", 0];

	_marker setMarkerColor "ColorYellow";
	_marker setMarkerBrush "DiagGrid";


	/*
	if no candidate FOBs, send AI towards the centre of the zone
	hoping they run into players.

	if there are bases within an AO's hexagon radius,
	get nearby FOBs sorted in descending order of the current supplies,
	use the first array item as the target for counter attack.
	*/

	// default attack position is centre of the zone
	private _attackPos = _markerPos;
	private _areaSize = markerSize _marker;

	// search for candidate FOBs within the zone's area.
	private _base_search_area = [_markerPos, _areaSize select 0, _areaSize select 1, 0, false];
	private _candidate_bases_to_attack = para_g_bases inAreaArray _base_search_area apply { [ _x getVariable "para_g_current_supplies", _x] };
	_candidate_bases_to_attack sort false;

	// candidate FOBs exist
	if ((count _candidate_bases_to_attack) > 0) then {

		diag_log format ["Counterattack: Co-Ordinates of FOBs within range of counter attack: %1", _candidate_bases_to_attack apply {getPos (_x # 1)}];

		// get the first FOB from the sorted array
		private _base_to_attack = (_candidate_bases_to_attack # 0 ) # 1;
		diag_log format ["Counterattack: Co-Ordinates of selected FOB: %1", _base_to_attack];

		// overwrite the default attack position
		_attackPos = getPos _base_to_attack;
	};

	diag_log format ["Counterattack: Co-ordinates for counter attack target: %1", _attackPos];

	private _attackTime = serverTime + (_taskDataStore getVariable ["prepTime", 0]);
	_taskDataStore setVariable ["attackTime", _attackTime];
	_taskDataStore setVariable ["attackPos", _attackPos];
	_taskDataStore setVariable ["attackAreaSize", _areaSize];

	if (_prepTime > 0) then 
	{
		["CounterAttackPreparing", ["", (_prepTime / 60) toFixed 0]] remoteExec ["para_c_fnc_show_notification", 0];
		[] call vn_mf_fnc_timerOverlay_removeGlobalTimer;
		["Counterattack In", _attackTime, true] call vn_mf_fnc_timerOverlay_setGlobalTimer;
	};

	[[
		["prepare_zone", _markerPos]
	]] call _fnc_initialSubtasks;
}];

_taskDataStore setVariable ["prepare_zone", {
	params ["_taskDataStore"];

	if (_taskDataStore getVariable "attackTime" > serverTime) exitWith {};

	["CounterAttackImminent", []] remoteExec ["para_c_fnc_show_notification", 0];
	[] call vn_mf_fnc_timerOverlay_removeGlobalTimer;
	["Counter Attack Imminent", serverTime + 180, true] call vn_mf_fnc_timerOverlay_setGlobalTimer;

	//Default to X waves.
	private _baseMultiplier = 5;//PLACEHOLDER VALUE
	//Add a wave for each camp in our origin zone.
	private _infantryMultiplier = _baseMultiplier;

	/*
	add the "attack" objective to the AI objectives task system.

	attackDifficulty determines how large to make the AI groups that attack this objective,
	but it is never set as a variable on this player task so it will only use the default setting provided below.
	*/
	private _attackObjective = [
		_taskDataStore getVariable "attackPos",
		//Difficulty 2, unless specified otherwise.
		_taskDataStore getVariable ["attackDifficulty", 4],
		_infantryMultiplier
	] call para_s_fnc_ai_obj_request_attack;

	_taskDataStore setVariable ["attackObjective", _attackObjective];
	_taskDataStore setVariable ["startTime", serverTime];

	["SUCCEEDED", [["defend_zone", _taskDataStore getVariable "attackPos"]]] call _fnc_finishSubtask;
}];

_taskDataStore setVariable ["defend_zone", {
	params ["_taskDataStore"];

	private _attackPos = _taskDataStore getVariable "attackPos";
	private _areaSize = _taskDataStore getVariable "attackAreaSize";
	private _areaDescriptor = [_attackPos, _areaSize select 0, _areaSize select 1, 0, false];

	//Side check - downed players don't count. Nor do players in aircraft. Ground vehicles are fair game.
	private _alivePlayersInZone = 
		allPlayers inAreaArray _areaDescriptor
		select {alive _x && (side _x == west || side _x == independent) && !(vehicle _x isKindOf "Air") && !(_x getVariable ["vn_revive_incapacitated", false])};

	private _aliveEnemyInZone = 
		allUnits inAreaArray _areaDescriptor 
		select {alive _x && side _x == east};

	private _enemyZoneHeldTime = _taskDataStore getVariable "enemyZoneHeldTime";
	private _lastCheck = _taskDataStore getVariable "lastCheck";
	//Enemy hold the zone if no living players.
	private _enemyHoldZone = count _alivePlayersInZone == 0;

	if (_enemyHoldZone) then {
		if (isNil "_enemyZoneHeldTime") then {
			_enemyZoneHeldTime = 0;
			_lastCheck = serverTime;
		} else {
			//Adding the interval between checks will be close enough to work.
			//We will lose or gain a few seconds but will even out in the long run.
			//Interval is approx 5 +/- 2 seconds from my testing.
			_enemyZoneHeldTime = _enemyZoneHeldTime + (serverTime - _lastCheck);
			_lastCheck = serverTime;
		};
		_taskDataStore setVariable ["enemyZoneHeldTime", _enemyZoneHeldTime];
		_taskDataStore setVariable ["lastCheck", _lastCheck];
	} else {
		_taskDataStore setVariable ["enemyZoneHeldTime", 0];
		_lastCheck = serverTime;
		_taskDataStore setVariable ["lastCheck", _lastCheck];
	};

	private _startTime = _taskDataStore getVariable "startTime";

	private _zone = _taskDataStore getVariable "taskMarker";
	private _garrisonStrength = _taskDataStore getVariable ["attackObjective", objNull] getVariable ["reinforcements_remaining", 0];

	//Zone has been held long enough, or they've killed enough attackers for the AI objective to complete.
	if (serverTime - _startTime > (_taskDataStore getVariable ["holdDuration", 60 * 30]) ||
		isNull (_taskDataStore getVariable "attackObjective") ) exitWith 
	{ //exitWith here to prevent a tie causing the zone to turn green but have new tasks for its capture spawn
		_taskDataStore setVariable ["zoneDefended", true];

		["SUCCEEDED"] call _fnc_finishSubtask;
	};

	//Enemy hold the zone for X seconds, we've failed
	if (
		_enemyHoldZone &&
		{_enemyZoneHeldTime > (_taskDataStore getVariable ["failureTime", 5 * 60])}
	) then {
		["CounterAttackLost", ["", [_zone] call vn_mf_fnc_zone_marker_to_name]] remoteExec ["para_c_fnc_show_notification", 0];
		["FAILED"] call _fnc_finishSubtask;
		["FAILED"] call _fnc_finishTask;
	};
}];

_taskDataStore setVariable ["AFTER_STATES_RUN", {
	params ["_taskDataStore"];

	if (_taskDataStore getVariable ["zoneDefended", false]
	) then {
		["SUCCEEDED"] call _fnc_finishTask;
	};
}];

_taskDataStore setVariable ["FINISH", {
	params ["_taskDataStore"];
	[_taskDataStore getVariable "attackObjective"] call para_s_fnc_ai_obj_finish_objective;
}];
