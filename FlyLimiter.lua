local FlyLimiter = {}
FlyLimiter.__index = FlyLimiter

function FlyLimiter.new(credit_cap: number, refill_rate_per_second: number, timeout: number, name: string?)
	local self = setmetatable({}, FlyLimiter)

	self.name = name or "FlyLimiter"

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
		thresholds_passed = 1,
		request_amount = 0
	}
	
	]]

	return self
end

function FlyLimiter:_CalcRefill(player: Player)
	local ms_time = DateTime.now().UnixTimestampMillis
	local player_info = self.player_info[player.UserId]

	local refill = math.floor(
		math.min(self.credit_cap-player_info.credits, ((ms_time-player_info.last_request)/1000) * self.refill_rate)
	)
	return refill
end

function FlyLimiter:capReachedSignal(signal: any)
	self._cap_signal = signal
end

function FlyLimiter:enableKick(threshold: number)
	self._threshold_limit = threshold
	self._apply_kick = true
end

function FlyLimiter:deductCredit(player: Player)
	local to_refill = self:_CalcRefill(player)

	self.player_info[player.UserId].credits += to_refill

	local credits_left = self.player_info[player.UserId].credits
	if credits_left <= 0 then
		self.player_info[player.UserId].thresholds_passed += 1
		if self._apply_kick and self.player_info[player.UserId].thresholds_passed >= self._threshold_limit then
			player:Kick('Passed remote call limit. Do not spam request buttons after multiple warnings.')
			self.player_info[player.UserId] = nil
		end

		if self._cap_signal then
			self._cap_signal:Fire(player, self.timeout, self._threshold_limit-self.player_info[player.UserId].thresholds_passed)
		end
		return false
	else
		self.player_info[player.UserId].request_amount += 1
		self.player_info[player.UserId].last_request = DateTime.now().UnixTimestampMillis
		self.player_info[player.UserId].credits -= 1

		return true
	end
end

function FlyLimiter:Route(player: Player, func, func_name: string?): any
	func_name = func_name or ""
	--warn("--> "..func_name.." ROUTED", player.Name)
	if not self.player_info[player.UserId] then
		self:addPlayer(player)
	end

	if self:deductCredit(player) then
		warn(player.Name, self.player_info[player.UserId].request_amount)

		self.player_info[player.UserId].last_request = DateTime.now().UnixTimestampMillis
		return func()
	else
		error(player.Name..' Player reached credit cap.')
	end
end

function FlyLimiter:addPlayer(player: Player)
	self.player_info[player.UserId] = {
		last_request = 0,
		credits = self.credit_cap,
		thresholds_passed = 0,
		request_amount = 0
	}
end

return FlyLimiter
