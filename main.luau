local RemoteCredits = {}
RemoteCredits.__index = RemoteCredits

function RemoteCredits.new(credit_cap: number, refill_rate_per_second: number, timeout: number)
	local self = setmetatable({}, RemoteCredits)
	
	self.refill_rate = refill_rate_per_second or 3
	self.credit_cap = credit_cap or 15
	self.timeout = timeout or 2
	
	self._threshold_limit = 9999
	self._apply_kick = false
	self.player_info = {}
	--[[
	[123456789] = {
		last_request = 323523523523523523,
		credits = 6,
		thresholds_passed = 1
	}
	
	]]
	
	return self
end

function RemoteCredits:_CalcRefill(player: Player)
	local ms_time = DateTime.now().UnixTimestampMillis
	local player_info = self.player_info[player.UserId]
	
	local refill = math.min(
		math.floor(self.credit_cap-player_info.credits, ((ms_time-player_info.last_request)/1000) * self.refill_rate)
	)
	return refill
end

function RemoteCredits:capReachedSignal(signal: any)
	self._cap_signal = signal
end

function RemoteCredits:enableKick(threshold: number)
	self._threshold_limit = threshold
	self._apply_kick = true
end

function RemoteCredits:deductCredit(player: Player)
	local to_refill = self:_CalcRefill(player)
	self.player_info[player.UserId].credits += to_refill
	
	local credits_left = self.player_info[player.UserId].credits
	if credits_left <= 0 then
		self.player_info[player.UserId].thresholds_passed += 1
		if self._apply_kick and self.player_info[player.UserId].thresholds_passed >= self._threshold_limit then
			player:Kick('Passed remote call limit. Do not spam request buttons after multiple warnings.')
			self.player_info[player.UserId] = nil
		end
		
		self._cap_signal:Fire(player)
		return false
	else
		self.player_info[player.UserId].credits -= 1
		
		return true
	end
end

function RemoteCredits:Route(player: Player, func, ...): any
	if self:deductCredit(player) then
		return func(...)
	else
		error('Player reached credit cap.')
	end
end

function RemoteCredits:addPlayer(player: Player)
	self.player_info[player.UserId] = {
		last_request = 0,
		credits = self.credit_cap,
		thresholds_passed = 0
	}
end

return RemoteCredits
