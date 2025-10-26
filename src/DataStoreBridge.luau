--[[
    DataStoreBridge.lua
]]

local DataStoreService = game:GetService("DataStoreService")
local CacheManager = require(script.Parent.CacheManager)

local DataStoreBridge = {}
DataStoreBridge.__index = DataStoreBridge

-- Config
local WRITE_BACK_INTERVAL = 30 -- seconds
local USE_WRITE_THROUGH = true -- Write immediately to DataStore

local dirtyKeys = {} -- Track modified keys for write-back

function DataStoreBridge.new()
	local self = setmetatable({}, DataStoreBridge)

	-- Start write-back loop if not using write-through
	if not USE_WRITE_THROUGH then
		task.spawn(function()
			self:_startWriteBackLoop()
		end)
	end

	return self
end

-- Get with cache (read-through)
function DataStoreBridge:GetWithCache(player, key, defaultValue, ttl)
	local cacheKey = player.UserId .. "_" .. key

	-- Check cache first
	local cached = CacheManager:Get(cacheKey)
	if cached ~= nil then
		return cached
	end

	-- Cache miss, fetch from DataStore
	local success, value = pcall(function()
		local dataStore = DataStoreService:GetDataStore(key)
		return dataStore:GetAsync(tostring(player.UserId))
	end)

	if not success then
		warn("[DataStoreBridge] Failed to get from DataStore:", value)
		return defaultValue
	end

	value = value or defaultValue

	-- Store in cache
	CacheManager:Set(cacheKey, value, ttl or 300)

	return value
end

-- Set with cache (write-through or write-back)
function DataStoreBridge:SetWithCache(player, key, value, ttl)
	local cacheKey = player.UserId .. "_" .. key

	-- Update cache immediately
	CacheManager:Set(cacheKey, value, ttl or 300)

	if USE_WRITE_THROUGH then
		-- Write-through: Update DataStore immediately
		self:_writeToDataStore(player, key, value)
	else
		-- Write-back: Mark as dirty for later write
		dirtyKeys[cacheKey] = {
			player = player,
			key = key,
			value = value
		}
	end

	return true
end

-- Increment with cache
function DataStoreBridge:IncrementWithCache(player, key, delta, defaultValue, ttl)
	delta = delta or 1
	local current = self:GetWithCache(player, key, defaultValue or 0, ttl)

	if type(current) ~= "number" then
		warn("[DataStoreBridge] Cannot increment non-number value")
		return nil
	end

	local newValue = current + delta
	self:SetWithCache(player, key, newValue, ttl)

	return newValue
end

-- Invalidate cache (force reload from DataStore)
function DataStoreBridge:InvalidateCache(player, key)
	local cacheKey = player.UserId .. "_" .. key
	CacheManager:Delete(cacheKey)

	-- Remove from dirty keys if present
	dirtyKeys[cacheKey] = nil

	return true
end

-- Flush dirty keys to DataStore (manual flush)
function DataStoreBridge:Flush()
	local count = 0

	for cacheKey, data in pairs(dirtyKeys) do
		self:_writeToDataStore(data.player, data.key, data.value)
		dirtyKeys[cacheKey] = nil
		count = count + 1
	end

	return count
end

-- Flush specific player data
function DataStoreBridge:FlushPlayer(player)
	local count = 0
	local prefix = tostring(player.UserId) .. "_"

	for cacheKey, data in pairs(dirtyKeys) do
		if string.sub(cacheKey, 1, #prefix) == prefix then
			self:_writeToDataStore(data.player, data.key, data.value)
			dirtyKeys[cacheKey] = nil
			count = count + 1
		end
	end

	return count
end

-- Private: Write to DataStore
function DataStoreBridge:_writeToDataStore(player, key, value)
	local success, err = pcall(function()
		local dataStore = DataStoreService:GetDataStore(key)
		dataStore:SetAsync(tostring(player.UserId), value)
	end)

	if not success then
		warn("[DataStoreBridge] Failed to write to DataStore:", err)
		return false
	end

	return true
end

-- Private: Write-back loop
function DataStoreBridge:_startWriteBackLoop()
	while true do
		task.wait(WRITE_BACK_INTERVAL)

		local flushed = self:Flush()

		if flushed > 0 then
			print("[DataStoreBridge] Flushed", flushed, "dirty keys to DataStore")
		end
	end
end

-- Handle player leaving (flush their data)
game.Players.PlayerRemoving:Connect(function(player)
	local bridge = DataStoreBridge.new()
	local flushed = bridge:FlushPlayer(player)

	if flushed > 0 then
		print("[DataStoreBridge] Flushed", flushed, "keys for player", player.Name)
	end
end)

return DataStoreBridge.new()