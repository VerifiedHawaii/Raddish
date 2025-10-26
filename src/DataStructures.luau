--[[
    DataStructures.lua
]]

local CacheManager = require(script.Parent.CacheManager)
local HttpService = game:GetService("HttpService")

local DataStructures = {}

-- ============ HASH OPERATIONS ============

-- HSET - Set hash field
function DataStructures:HSet(hash, field, value, ttl)
	local hashTable = CacheManager:Get(hash) or {}
	hashTable[field] = value
	CacheManager:Set(hash, hashTable, ttl)
	return true
end

-- HGET - Get hash field
function DataStructures:HGet(hash, field)
	local hashTable = CacheManager:Get(hash)
	return hashTable and hashTable[field]
end

-- HGETALL - Get all hash fields
function DataStructures:HGetAll(hash)
	return CacheManager:Get(hash) or {}
end

-- HDEL - Delete hash field
function DataStructures:HDel(hash, field)
	local hashTable = CacheManager:Get(hash)
	if hashTable then
		hashTable[field] = nil
		CacheManager:Set(hash, hashTable)
		return true
	end
	return false
end

-- HEXISTS - Check if hash field exists
function DataStructures:HExists(hash, field)
	local hashTable = CacheManager:Get(hash)
	return hashTable and hashTable[field] ~= nil
end

-- HKEYS - Get all hash keys
function DataStructures:HKeys(hash)
	local hashTable = CacheManager:Get(hash) or {}
	local keys = {}
	for k in pairs(hashTable) do
		table.insert(keys, k)
	end
	return keys
end

-- HVALS - Get all hash values
function DataStructures:HVals(hash)
	local hashTable = CacheManager:Get(hash) or {}
	local values = {}
	for _, v in pairs(hashTable) do
		table.insert(values, v)
	end
	return values
end

-- HLEN - Get hash length
function DataStructures:HLen(hash)
	local hashTable = CacheManager:Get(hash) or {}
	local count = 0
	for _ in pairs(hashTable) do
		count = count + 1
	end
	return count
end

-- ============ LIST OPERATIONS ============

-- LPUSH - Push to left (beginning) of list
function DataStructures:LPush(key, value, ttl)
	local list = CacheManager:Get(key) or {}
	table.insert(list, 1, value)
	CacheManager:Set(key, list, ttl)
	return #list
end

-- RPUSH - Push to right (end) of list
function DataStructures:RPush(key, value, ttl)
	local list = CacheManager:Get(key) or {}
	table.insert(list, value)
	CacheManager:Set(key, list, ttl)
	return #list
end

-- LPOP - Pop from left (beginning) of list
function DataStructures:LPop(key)
	local list = CacheManager:Get(key)
	if list and #list > 0 then
		local value = table.remove(list, 1)
		CacheManager:Set(key, list)
		return value
	end
	return nil
end

-- RPOP - Pop from right (end) of list
function DataStructures:RPop(key)
	local list = CacheManager:Get(key)
	if list and #list > 0 then
		local value = table.remove(list)
		CacheManager:Set(key, list)
		return value
	end
	return nil
end

-- LRANGE - Get range of list elements
function DataStructures:LRange(key, start, stop)
	local list = CacheManager:Get(key) or {}
	local result = {}

	-- Handle negative indices
	if start < 0 then start = #list + start + 1 end
	if stop < 0 then stop = #list + stop + 1 end

	for i = start, math.min(stop, #list) do
		table.insert(result, list[i])
	end

	return result
end

-- LLEN - Get list length
function DataStructures:LLen(key)
	local list = CacheManager:Get(key) or {}
	return #list
end

-- LINDEX - Get element at index
function DataStructures:LIndex(key, index)
	local list = CacheManager:Get(key)
	if not list then return nil end

	if index < 0 then
		index = #list + index + 1
	end

	return list[index]
end

-- ============ SET OPERATIONS ============

-- SADD - Add to set
function DataStructures:SAdd(key, member, ttl)
	local set = CacheManager:Get(key) or {}
	set[member] = true
	CacheManager:Set(key, set, ttl)
	return true
end

-- SREM - Remove from set
function DataStructures:SRem(key, member)
	local set = CacheManager:Get(key)
	if set then
		set[member] = nil
		CacheManager:Set(key, set)
		return true
	end
	return false
end

-- SISMEMBER - Check if member in set
function DataStructures:SIsMember(key, member)
	local set = CacheManager:Get(key)
	return set and set[member] == true
end

-- SMEMBERS - Get all set members
function DataStructures:SMembers(key)
	local set = CacheManager:Get(key) or {}
	local members = {}
	for member in pairs(set) do
		table.insert(members, member)
	end
	return members
end

-- SCARD - Get set cardinality (size)
function DataStructures:SCard(key)
	local set = CacheManager:Get(key) or {}
	local count = 0
	for _ in pairs(set) do
		count = count + 1
	end
	return count
end

-- ============ SORTED SET OPERATIONS ============

-- ZADD - Add to sorted set with score
function DataStructures:ZAdd(key, score, member, ttl)
	local sortedSet = CacheManager:Get(key) or {}

	-- Remove existing entry if present
	for i, entry in ipairs(sortedSet) do
		if entry.member == member then
			table.remove(sortedSet, i)
			break
		end
	end

	-- Add new entry
	table.insert(sortedSet, {score = score, member = member})

	-- Sort by score
	table.sort(sortedSet, function(a, b)
		if a.score == b.score then
			return tostring(a.member) < tostring(b.member)
		end
		return a.score < b.score
	end)

	CacheManager:Set(key, sortedSet, ttl)
	return true
end

-- ZREM - Remove from sorted set
function DataStructures:ZRem(key, member)
	local sortedSet = CacheManager:Get(key)
	if sortedSet then
		for i, entry in ipairs(sortedSet) do
			if entry.member == member then
				table.remove(sortedSet, i)
				CacheManager:Set(key, sortedSet)
				return true
			end
		end
	end
	return false
end

-- ZRANGE - Get range by index
function DataStructures:ZRange(key, start, stop, withScores)
	local sortedSet = CacheManager:Get(key) or {}
	local result = {}

	if start < 0 then start = #sortedSet + start + 1 end
	if stop < 0 then stop = #sortedSet + stop + 1 end

	for i = start, math.min(stop, #sortedSet) do
		if withScores then
			table.insert(result, {
				member = sortedSet[i].member,
				score = sortedSet[i].score
			})
		else
			table.insert(result, sortedSet[i].member)
		end
	end

	return result
end

-- ZRANGEBYSCORE - Get range by score
function DataStructures:ZRangeByScore(key, minScore, maxScore, withScores)
	local sortedSet = CacheManager:Get(key) or {}
	local result = {}

	for _, entry in ipairs(sortedSet) do
		if entry.score >= minScore and entry.score <= maxScore then
			if withScores then
				table.insert(result, {
					member = entry.member,
					score = entry.score
				})
			else
				table.insert(result, entry.member)
			end
		end
	end

	return result
end

-- ZSCORE - Get score of member
function DataStructures:ZScore(key, member)
	local sortedSet = CacheManager:Get(key)
	if sortedSet then
		for _, entry in ipairs(sortedSet) do
			if entry.member == member then
				return entry.score
			end
		end
	end
	return nil
end

-- ZCARD - Get sorted set size
function DataStructures:ZCard(key)
	local sortedSet = CacheManager:Get(key) or {}
	return #sortedSet
end

-- ZINCRBY - Increment score
function DataStructures:ZIncrBy(key, increment, member, ttl)
	local currentScore = self:ZScore(key, member) or 0
	return self:ZAdd(key, currentScore + increment, member, ttl)
end

-- ZRANK - Get rank (index) of member
function DataStructures:ZRank(key, member)
	local sortedSet = CacheManager:Get(key)
	if sortedSet then
		for i, entry in ipairs(sortedSet) do
			if entry.member == member then
				return i - 1 -- 0-indexed
			end
		end
	end
	return nil
end

return DataStructures