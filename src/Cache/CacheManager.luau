--[[
    CacheManager.lua
]]

local CacheManager = {}
CacheManager.__index = CacheManager

-- Configuration
local MAX_CACHE_SIZE = 10000 -- Maximum number of cached items
local DEFAULT_TTL = 300 -- Default TTL in seconds (5 minutes)

-- Cache storage
local cache = {}
local cacheMetadata = {}
local accessOrder = {} -- For LRU tracking

function CacheManager.new()
	local self = setmetatable({}, CacheManager)

	-- Start cleanup task
	task.spawn(function()
		self:_startCleanupLoop()
	end)

	return self
end

-- SET with TTL (Time To Live)
function CacheManager:Set(key, value, ttl)
	-- Check if we need to evict (LRU)
	if not cache[key] and self:GetSize() >= MAX_CACHE_SIZE then
		self:_evictLRU()
	end

	cache[key] = value
	cacheMetadata[key] = {
		timestamp = os.time(),
		ttl = ttl or DEFAULT_TTL,
		lastAccess = os.time()
	}

	-- Update access order
	self:_updateAccessOrder(key)

	return true
end

-- GET with automatic expiration check
function CacheManager:Get(key)
	local metadata = cacheMetadata[key]

	if not metadata then
		return nil
	end

	-- Check expiration
	if self:_isExpired(key) then
		self:Delete(key)
		return nil
	end

	-- Update last access time
	metadata.lastAccess = os.time()
	self:_updateAccessOrder(key)

	return cache[key]
end

-- DELETE key
function CacheManager:Delete(key)
	cache[key] = nil
	cacheMetadata[key] = nil

	-- Remove from access order
	for i, k in ipairs(accessOrder) do
		if k == key then
			table.remove(accessOrder, i)
			break
		end
	end

	return true
end

-- EXISTS - Check if key exists and is not expired
function CacheManager:Exists(key)
	if not cache[key] then
		return false
	end

	if self:_isExpired(key) then
		self:Delete(key)
		return false
	end

	return true
end

-- EXPIRE - Set TTL on existing key
function CacheManager:Expire(key, ttl)
	if not cacheMetadata[key] then
		return false
	end

	cacheMetadata[key].ttl = ttl
	cacheMetadata[key].timestamp = os.time()

	return true
end

-- TTL - Get remaining time to live
function CacheManager:TTL(key)
	local metadata = cacheMetadata[key]

	if not metadata then
		return -2 -- Key doesn't exist
	end

	if not metadata.ttl then
		return -1 -- No expiration
	end

	local elapsed = os.time() - metadata.timestamp
	local remaining = metadata.ttl - elapsed

	return remaining > 0 and remaining or -2
end

-- KEYS - Find all keys matching pattern (simple pattern matching)
function CacheManager:Keys(pattern)
	local keys = {}

	-- Convert simple pattern (* and ?) to Lua pattern
	local luaPattern = pattern:gsub("%*", ".*"):gsub("%?", ".")

	for key in pairs(cache) do
		if not self:_isExpired(key) and string.match(key, luaPattern) then
			table.insert(keys, key)
		end
	end

	return keys
end

-- FLUSHALL - Clear all cache
function CacheManager:FlushAll()
	cache = {}
	cacheMetadata = {}
	accessOrder = {}
	return true
end

-- Get cache size
function CacheManager:GetSize()
	local count = 0
	for _ in pairs(cache) do
		count = count + 1
	end
	return count
end

-- Get cache stats
function CacheManager:GetStats()
	return {
		size = self:GetSize(),
		maxSize = MAX_CACHE_SIZE,
		keys = self:Keys(".*")
	}
end

-- Private: Check if key is expired
function CacheManager:_isExpired(key)
	local metadata = cacheMetadata[key]

	if not metadata or not metadata.ttl then
		return false
	end

	local elapsed = os.time() - metadata.timestamp
	return elapsed > metadata.ttl
end

-- Private: LRU eviction
function CacheManager:_evictLRU()
	if #accessOrder == 0 then
		return
	end

	-- Remove least recently used (first in list)
	local lruKey = accessOrder[1]
	self:Delete(lruKey)

	print("[CacheManager] Evicted LRU key:", lruKey)
end

-- Private: Update access order for LRU
function CacheManager:_updateAccessOrder(key)
	-- Remove key from current position
	for i, k in ipairs(accessOrder) do
		if k == key then
			table.remove(accessOrder, i)
			break
		end
	end

	-- Add to end (most recently used)
	table.insert(accessOrder, key)
end

-- Private: Cleanup loop for expired keys
function CacheManager:_startCleanupLoop()
	while true do
		task.wait(10) -- Check every 10 seconds

		local expiredKeys = {}

		for key in pairs(cache) do
			if self:_isExpired(key) then
				table.insert(expiredKeys, key)
			end
		end

		for _, key in ipairs(expiredKeys) do
			self:Delete(key)
		end

		if #expiredKeys > 0 then
			print("[CacheManager] Cleaned up", #expiredKeys, "expired keys")
		end
	end
end

return CacheManager.new()