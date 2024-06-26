# RequestLimiter

Route your client to server communications through this request-limit manager. Allows you to connect 'cap reached' signals (Requires :Fire method) and enable player kicks when reaching the cap threshold numerous times.

Example:
```lua
local rs = game:GetService('ReplicatedStorage')
local sss = game:GetService('ServerScriptService')

local RequestLimiter = require(sss:WaitForChild('RequestLimiter'))

local request_limiter = RequestLimiter.new()
request_limiter:capReachedSignal(SignalService.RemoteCalls__Capped)
request_limiter:enableKick(4)

local remote_funcs = {}
for i, rm: RemoteFunction in rs:WaitForChild('RemoteEvents').PlayerData.FromClient:GetChildren() do
	remote_funcs[rm.Name] = rm
end

local funcs_callbacks = {
	GetEquippedGear = function(p: Player)
		return request_limiter:Route(p, function()
			local player_data = PlayerDataService.GetPlayerDataInstance(p)
			return player_data:EquippedGears()	
		end)
	end,

for k, v in pairs(remote_funcs) do
	v.OnServerInvoke = funcs_callbacks[k]
end
```
Result:
![image](https://github.com/PogoDigitalism/Request-Limiter/assets/107322523/0741b88f-a6db-453f-898e-dcfdb1646fe9)
