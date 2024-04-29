# credit-validator

Route your client to server communications through this request-limit manager. Allows you to connect 'cap reached' signals (Requires :Fire method) and enable player kicks when reaching the cap threshold numerous times.

Example:
```lua
local request_limiter = RequestLimiter.new(15, 5, 2)

