#include "..\script_macros.hpp"
/*
    File: fn_asyncCall.sqf    

    Description:
    Commits an asynchronous call to ExtDB

    Parameters:
        0: STRING (Query to be ran).
        1: INTEGER (1 = ASYNC + not return for update/insert, 2 = ASYNC + return for query's).
        3: BOOL (True to return a single array, false to return multiple entries).
*/
private["_queryResult","_queryResultOrigin","_key","_return","_loop"];
params [["_queryStmt", "",[""]], ["_mode", 1,[0]], ["_multiarr", false,[false]]];

_key = EXTDB format["%1:%2:%3",_mode,FETCH_CONST(wasp_sql_id),_queryStmt];

if (_mode isEqualTo 1) exitWith {true};

_key = call compile format["%1",_key];
_key = (_key # 1);
_queryResult = EXTDB format["4:%1", _key];

//Make sure the data is received
if (_queryResult isEqualTo "[3]") then {
    for "_i" from 0 to 1 step 0 do {
        if (!(_queryResult isEqualTo "[3]")) exitWith {};
        _queryResult = EXTDB format["4:%1", _key];
    };
};

if (_queryResult isEqualTo "[5]") then {
    _loop = true;
    for "_i" from 0 to 1 step 0 do { // extDB2 returned that result is Multi-Part Message
        _queryResult = "";
        for "_i" from 0 to 1 step 0 do {
            _pipe = EXTDB format["5:%1", _key];
            if (_pipe isEqualTo "") exitWith {_loop = false};
            _queryResult = _queryResult + _pipe;
        };
        if (!_loop) exitWith {};
    };
};

_queryResultOrigin = _queryResult;
_queryResult = call compile _queryResult;
if(isNil "_queryResult") exitWith {
	if(!isNil "_queryResultOrigin") then {
		["ERROR", "EXTDB3 fn_asyncCall.sqf: Can't compile query result. Original result: [%1]. Query: [%2].",
			_queryResultOrigin, format["%1:%2:%3",_mode,FETCH_CONST(wasp_sql_id),_queryStmt]] Call WFCO_FNC_LogContent;
	} else {
		["ERROR", "EXTDB3 fn_asyncCall.sqf: Can't compile query result. Query: [%2].",
			format["%1:%2:%3",_mode,FETCH_CONST(wasp_sql_id),_queryStmt]] Call WFCO_FNC_LogContent;
	};
};
if ((_queryResult # 0) isEqualTo 0) exitWith {diag_log format ["extDB3: Protocol Error: %1", _queryResult]; []};
_return = (_queryResult # 1);
if (!_multiarr && count _return > 0) then {
    _return = (_return # 0);
};

_return;
