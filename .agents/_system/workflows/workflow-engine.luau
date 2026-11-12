--!strict
-- ==============================================================================
-- Project Last Wave: Roblox Production Multi-Agent Workflow Engine
-- Path: .agents/_system/workflows/workflow-engine.luau
-- Author: Workflow Engine & 18-Case Pilot Test Subagent
-- Description: Deterministic Pure-Luau Workflow Router, State Manager,
--              Handoff Validator, Lock Manager & Quality Gate Evaluator
-- ==============================================================================

local WorkflowEngine = {}

-- ==============================================================================
-- SHA-256 Pure Luau Implementation (using bit32)
-- ==============================================================================
local function sha256(msg: string): string
	local K = {
		0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
		0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
		0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
		0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
		0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
		0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
		0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
		0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
		0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
		0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
		0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
		0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
		0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
		0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
		0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
		0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
	}

	local H = {
		0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
		0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
	}

	local len = #msg
	local extra = { string.byte(msg, 1, len) }
	table.insert(extra, 0x80)
	while (#extra + 8) % 64 ~= 0 do
		table.insert(extra, 0x00)
	end

	local bitLen = len * 8
	for i = 7, 0, -1 do
		local b = bit32.band(bit32.rshift(bitLen, i * 8), 0xff)
		table.insert(extra, b)
	end

	local W = table.create(64, 0)
	for chunk = 1, #extra, 64 do
		for t = 0, 15 do
			local idx = chunk + t * 4
			W[t + 1] = bit32.bor(
				bit32.lshift(extra[idx], 24),
				bit32.lshift(extra[idx + 1], 16),
				bit32.lshift(extra[idx + 2], 8),
				extra[idx + 3]
			)
		end
		for t = 16, 63 do
			local s0 = bit32.bxor(bit32.rrotate(W[t - 15 + 1], 7), bit32.rrotate(W[t - 15 + 1], 18), bit32.rshift(W[t - 15 + 1], 3))
			local s1 = bit32.bxor(bit32.rrotate(W[t - 2 + 1], 17), bit32.rrotate(W[t - 2 + 1], 19), bit32.rshift(W[t - 2 + 1], 10))
			W[t + 1] = bit32.band(W[t - 16 + 1] + s0 + W[t - 7 + 1] + s1, 0xffffffff)
		end

		local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
		for t = 0, 63 do
			local S1 = bit32.bxor(bit32.rrotate(e, 6), bit32.rrotate(e, 11), bit32.rrotate(e, 25))
			local ch = bit32.bxor(bit32.band(e, f), bit32.band(bit32.bnot(e), g))
			local temp1 = bit32.band(h + S1 + ch + K[t + 1] + W[t + 1], 0xffffffff)
			local S0 = bit32.bxor(bit32.rrotate(a, 2), bit32.rrotate(a, 13), bit32.rrotate(a, 22))
			local maj = bit32.bxor(bit32.band(a, b), bit32.band(a, c), bit32.band(b, c))
			local temp2 = bit32.band(S0 + maj, 0xffffffff)

			h = g
			g = f
			f = e
			e = bit32.band(d + temp1, 0xffffffff)
			d = c
			c = b
			b = a
			a = bit32.band(temp1 + temp2, 0xffffffff)
		end

		H[1] = bit32.band(H[1] + a, 0xffffffff)
		H[2] = bit32.band(H[2] + b, 0xffffffff)
		H[3] = bit32.band(H[3] + c, 0xffffffff)
		H[4] = bit32.band(H[4] + d, 0xffffffff)
		H[5] = bit32.band(H[5] + e, 0xffffffff)
		H[6] = bit32.band(H[6] + f, 0xffffffff)
		H[7] = bit32.band(H[7] + g, 0xffffffff)
		H[8] = bit32.band(H[8] + h, 0xffffffff)
	end

	local hex = ""
	for i = 1, 8 do
		hex ..= string.format("%08x", H[i])
	end
	return hex
end
WorkflowEngine.sha256 = sha256

-- ==============================================================================
-- 1. Scope & Project Classifier
-- ==============================================================================
export type ClassificationResult = {
	activated: boolean,
	reason: string,
	matchedKeywords: { string },
	detectedDomains: { string },
}

local OUT_OF_SCOPE_PATTERNS = {
	"c#", "csharp", "dotnet", "%.net", "react", "nextjs",
	"web_frontend", "web frontend", "fleet_verify", "vms_management",
	"angular", "vue", "python_django", "django", "spring_boot", "springboot",
	"asp%.net",
}

local ROBLOX_KEYWORDS = {
	"roblox", "studio", "rojo", "luau", "r15", "r6",
	"animation", "vfx", "combat", "weapon", "sword", "combo",
	"ui", "hud", "screengui", "screen_gui", "remoteevent", "remotefunction",
	"npc", "wave", "spawner", "profilestore", "datastore", "microprofiler",
	"particle", "beam", "trail", "slash", "hitbox", "project-last-wave",
	-- Thai Keywords
	"อนิเมชั่น", "แอนิเมชัน", "เอฟเฟกต์", "ดาบ", "คอมโบ",
	"ต่อสู้", "อาวุธ", "สกิล", "ปุ่ม", "หน้าจอ", "เมนู",
	"รีโมท", "บอท", "มอนสเตอร์", "คลื่น", "ซอมบี้", "navbar",
	"แปลงร่าง",
}

function WorkflowEngine.classifyPrompt(prompt: string, context: { [string]: any }?): ClassificationResult
	local lower = string.lower(prompt)

	-- Check explicit out-of-scope patterns first
	for _, pattern in OUT_OF_SCOPE_PATTERNS do
		if string.find(lower, pattern) ~= nil then
			return {
				activated = false,
				reason = "OUT_OF_SCOPE_NON_ROBLOX",
				matchedKeywords = { pattern },
				detectedDomains = {},
			}
		end
	end

	-- Check for Roblox / Last Wave domain keywords
	local matched = {}
	local domains = {}
	for _, kw in ROBLOX_KEYWORDS do
		if string.find(lower, string.lower(kw), 1, true) ~= nil then
			table.insert(matched, kw)
		end
	end

	if #matched > 0 then
		if string.find(lower, "combat") or string.find(lower, "คอมโบ") or string.find(lower, "ดาบ") or string.find(lower, "ต่อสู้") then
			table.insert(domains, "combat_system")
		end
		if string.find(lower, "animation") or string.find(lower, "r15") or string.find(lower, "อนิเมชั่น") or string.find(lower, "แปลงร่าง") then
			table.insert(domains, "r15_animation")
		end
		if string.find(lower, "vfx") or string.find(lower, "เอฟเฟกต์") or string.find(lower, "particle") or string.find(lower, "beam") then
			table.insert(domains, "vfx_particles_beams_trails")
		end
		if string.find(lower, "ui") or string.find(lower, "hud") or string.find(lower, "navbar") or string.find(lower, "หน้าจอ") or string.find(lower, "เมนู") then
			table.insert(domains, "ui_hud_screen_gui")
		end
		if string.find(lower, "remoteevent") or string.find(lower, "remotefunction") or string.find(lower, "รีโมท") then
			table.insert(domains, "remote_event_networking")
		end
		if string.find(lower, "npc") or string.find(lower, "wave") or string.find(lower, "ซอมบี้") or string.find(lower, "คลื่น") or string.find(lower, "บอท") then
			table.insert(domains, "npc_ai_and_wave_spawning")
		end

		return {
			activated = true,
			reason = "ROBLOX_IN_SCOPE",
			matchedKeywords = matched,
			detectedDomains = domains,
		}
	end

	-- Fallback check for context
	if context and context.project == "project-last-wave" then
		return {
			activated = true,
			reason = "ROBLOX_IN_SCOPE",
			matchedKeywords = { "context_project_match" },
			detectedDomains = { "general_roblox_task" },
		}
	end

	return {
		activated = false,
		reason = "OUT_OF_SCOPE_NON_ROBLOX",
		matchedKeywords = {},
		detectedDomains = {},
	}
end

-- ==============================================================================
-- 2. Task Slug Normalizer & Run Manager
-- ==============================================================================
export type TaskRunInfo = {
	taskId: string,
	slug: string,
	runId: string,
	runNumber: number,
	isContinuation: boolean,
	taskDirectory: string,
	runDirectory: string,
	status: string,
}

local WINDOWS_RESERVED_NAMES = {
	CON = true, PRN = true, AUX = true, NUL = true,
	COM1 = true, COM2 = true, COM3 = true, COM4 = true,
	COM5 = true, COM6 = true, COM7 = true, COM8 = true, COM9 = true,
	LPT1 = true, LPT2 = true, LPT3 = true, LPT4 = true,
	LPT5 = true, LPT6 = true, LPT7 = true, LPT8 = true, LPT9 = true,
}

function WorkflowEngine.normalizeSlug(rawTitleOrPrompt: string): string
	if not rawTitleOrPrompt or #rawTitleOrPrompt == 0 then
		return "task-untitled"
	end

	-- 1. Strip forbidden Windows characters: <>:"/\|?* and control characters
	local cleaned = ""
	for i = 1, #rawTitleOrPrompt do
		local byte = string.byte(rawTitleOrPrompt, i)
		if byte >= 32 and byte ~= 60 and byte ~= 62 and byte ~= 58 and byte ~= 34 and byte ~= 47 and byte ~= 92 and byte ~= 124 and byte ~= 63 and byte ~= 42 then
			cleaned ..= string.sub(rawTitleOrPrompt, i, i)
		end
	end

	-- 2. Replace whitespace and underscores with hyphens
	cleaned = string.gsub(cleaned, "[%s_]+", "-")

	-- 3. Lowercase ASCII characters while preserving UTF-8 multibyte characters
	local result = ""
	local i = 1
	while i <= #cleaned do
		local byte = string.byte(cleaned, i)
		if byte < 128 then
			local ch = string.sub(cleaned, i, i)
			result ..= string.lower(ch)
			i += 1
		else
			-- Multi-byte UTF-8 sequence (e.g. Thai characters)
			local len = 1
			if byte >= 240 then
				len = 4
			elseif byte >= 224 then
				len = 3
			elseif byte >= 192 then
				len = 2
			end
			result ..= string.sub(cleaned, i, i + len - 1)
			i += len
		end
	end

	-- 4. Collapse consecutive hyphens
	result = string.gsub(result, "%-+", "-")

	-- 5. Trim leading and trailing hyphens and dots
	result = string.gsub(result, "^[%-%.]+", "")
	result = string.gsub(result, "[%-%.]+$", "")

	-- 6. Max length limit: 64 characters (UTF-8 safe boundary)
	if #result > 64 then
		local cut = string.sub(result, 1, 64)
		result = string.gsub(cut, "[%-%.]+$", "")
	end

	if #result == 0 then
		result = "task-untitled"
	end

	-- 7. Check Windows reserved filenames
	local upper = string.upper(result)
	if WINDOWS_RESERVED_NAMES[upper] then
		result = "task-" .. result
	end

	return result
end

function WorkflowEngine.generateTaskId(dateString: string?, sequenceNumber: number?): string
	local d = dateString or os.date("%Y%m%d")
	local seq = sequenceNumber or 1
	return string.format("TASK-%s-%03d", d, seq)
end

export type TaskRecord = {
	taskId: string,
	slug: string,
	runs: { string }?,
}

function WorkflowEngine.resolveTaskAndRun(params: {
	prompt: string?,
	slug: string?,
	taskId: string?,
	existingTasks: { TaskRecord }?,
	rootDir: string?,
	isContinuation: boolean?,
}): TaskRunInfo
	local prompt = params.prompt or ""
	local slug = params.slug or WorkflowEngine.normalizeSlug(prompt)
	local rootDir = params.rootDir or ".agents/tasks"
	local existingTasks = params.existingTasks or {}

	-- Detect continuation
	local matchedTask: TaskRecord? = nil
	local isContinuation = params.isContinuation == true

	if params.taskId then
		for _, task in existingTasks do
			if task.taskId == params.taskId then
				matchedTask = task
				isContinuation = true
				break
			end
		end
	end

	if not matchedTask then
		for _, task in existingTasks do
			if task.slug == slug then
				matchedTask = task
				isContinuation = true
				break
			end
		end
	end

	-- Check if prompt embeds a known taskId pattern
	if not matchedTask and prompt ~= "" then
		local embeddedId = string.match(prompt, "TASK%-%d%d%d%d%d%d%d%d%-%d%d%d")
		if embeddedId then
			for _, task in existingTasks do
				if task.taskId == embeddedId then
					matchedTask = task
					isContinuation = true
					break
				end
			end
		end
	end

	local taskId: string
	local finalSlug = slug
	local runNumber = 1
	local runId = "run_01"

	if isContinuation and matchedTask then
		taskId = matchedTask.taskId
		finalSlug = matchedTask.slug
		local runs = matchedTask.runs or { "run_01" }
		local maxRun = 0
		for _, r in runs do
			local num = tonumber(string.match(r, "run_(%d+)"))
			if num and num > maxRun then
				maxRun = num
			end
		end
		runNumber = maxRun + 1
		runId = string.format("run_%02d", runNumber)
	else
		taskId = params.taskId or WorkflowEngine.generateTaskId(nil, #existingTasks + 1)
		runNumber = 1
		runId = "run_01"
		isContinuation = false
	end

	local taskDirectory = string.format("%s/%s", rootDir, finalSlug)
	local runDirectory = string.format("%s/%s", taskDirectory, runId)

	return {
		taskId = taskId,
		slug = finalSlug,
		runId = runId,
		runNumber = runNumber,
		isContinuation = isContinuation,
		taskDirectory = taskDirectory,
		runDirectory = runDirectory,
		status = "READY",
	}
end

export type ResumeResult = {
	resumed: boolean,
	taskId: string,
	runId: string,
	stage: string,
	reworkRound: number,
	codeReviewStatus: string?,
	boardState: string,
	status: string,
}

function WorkflowEngine.resumeRun(taskStateOrManifest: any): ResumeResult
	local taskId = taskStateOrManifest.taskId or "TASK-UNKNOWN"
	local runId = taskStateOrManifest.runId or "run_01"
	local stage = taskStateOrManifest.stage or "IMPLEMENTATION"
	local reworkRound = taskStateOrManifest.reworkRound or 0
	local codeReviewStatus = taskStateOrManifest.codeReviewStatus or "PENDING"
	local boardState = taskStateOrManifest.boardState or "IN_PROGRESS"

	return {
		resumed = true,
		taskId = taskId,
		runId = runId,
		stage = stage,
		reworkRound = reworkRound,
		codeReviewStatus = codeReviewStatus,
		boardState = boardState,
		status = "RESUMED_CURRENT_STAGE",
	}
end

-- ==============================================================================
-- 3. Automatic Team Assembler & Combo Router
-- ==============================================================================
export type TeamAssemblyResult = {
	selectedCombos: { string },
	selectedProfiles: { string },
	requiredGates: { string },
	reasons: { [string]: string },
}

local function dedupeAndSort(list: { string }): { string }
	local seen = {}
	local res = {}
	for _, item in list do
		if not seen[item] then
			seen[item] = true
			table.insert(res, item)
		end
	end
	table.sort(res)
	return res
end

function WorkflowEngine.assembleTeam(requirements: {
	taskType: string?,
	description: string?,
	prompt: string?,
	complexity: string?,
	dependencies: { string }?,
	fileOwnership: { string }?,
	riskLevel: string?,
	requiredTools: { string }?,
	qualityRequirements: { string }?,
	isRemoteOrServerDamage: boolean?,
	isPerformanceCritical: boolean?,
}): TeamAssemblyResult
	local text = string.lower((requirements.taskType or "") .. " " .. (requirements.description or "") .. " " .. (requirements.prompt or ""))

	local combos = {}
	local profiles = { "roblox-team-lead" }
	local gates = {}
	local reasons = {}

	local hasAnimation = string.find(text, "animation") ~= nil or string.find(text, "r15") ~= nil or string.find(text, "pose") ~= nil or string.find(text, "rig") ~= nil or string.find(text, "อนิเมชั่น") ~= nil or string.find(text, "แอนิเมชัน") ~= nil
	local hasVFX = string.find(text, "vfx") ~= nil or string.find(text, "particle") ~= nil or string.find(text, "beam") ~= nil or string.find(text, "trail") ~= nil or string.find(text, "slash") ~= nil or string.find(text, "เอฟเฟกต์") ~= nil
	local hasCombat = string.find(text, "combat") ~= nil or string.find(text, "combo") ~= nil or string.find(text, "weapon") ~= nil or string.find(text, "ดาบ") ~= nil or string.find(text, "ต่อสู้") ~= nil or string.find(text, "skill") ~= nil or string.find(text, "hitbox") ~= nil
	local hasUI = string.find(text, "ui") ~= nil or string.find(text, "hud") ~= nil or string.find(text, "gui") ~= nil or string.find(text, "menu") ~= nil or string.find(text, "screengui") ~= nil or string.find(text, "navbar") ~= nil or string.find(text, "หน้าจอ") ~= nil

	local isRemoteOrServerDamage = requirements.isRemoteOrServerDamage == true
		or string.find(text, "remoteevent") ~= nil
		or string.find(text, "remotefunction") ~= nil
		or string.find(text, "server authority") ~= nil
		or string.find(text, "damage calculation") ~= nil
		or string.find(text, "anti-exploit") ~= nil
		or string.find(text, "network") ~= nil
		or string.find(text, "packet") ~= nil

	local isPerformanceCritical = requirements.isPerformanceCritical == true
		or string.find(text, "horde") ~= nil
		or string.find(text, "100+") ~= nil
		or string.find(text, "heavy vfx") ~= nil
		or string.find(text, "large npc") ~= nil
		or string.find(text, "performance risk") ~= nil
		or string.find(text, "microprofiler") ~= nil
		or string.find(text, "lod") ~= nil
		or string.find(text, "memory budget") ~= nil

	-- 1. Animation + VFX composite
	if hasAnimation and hasVFX then
		table.insert(combos, "COMBO-RBX-03")
		table.insert(combos, "COMBO-RBX-04")
		table.insert(combos, "COMBO-RBX-07")
		table.insert(profiles, "animation-artist-r15")
		table.insert(profiles, "vfx-artist")
		table.insert(profiles, "technical-artist")
		table.insert(profiles, "visual-animation-reviewer")
		table.insert(profiles, "roblox-qa-tester")
		table.insert(gates, "RBX-07")
		reasons["COMBO-RBX-03+04"] = "Synchronized R15 Animation and VFX authoring pipeline"
	elseif hasAnimation then
		table.insert(combos, "COMBO-RBX-03")
		table.insert(profiles, "animation-artist-r15")
		table.insert(profiles, "visual-animation-reviewer")
		reasons["COMBO-RBX-03"] = "R15 Rig keyframing and curve polish"
	elseif hasVFX then
		table.insert(combos, "COMBO-RBX-04")
		table.insert(profiles, "vfx-artist")
		table.insert(profiles, "visual-animation-reviewer")
		reasons["COMBO-RBX-04"] = "Particle emitter, beam, and trail styling"
	end

	-- 2. Gameplay Combat
	if hasCombat then
		table.insert(combos, "COMBO-RBX-02")
		table.insert(combos, "COMBO-RBX-07")
		table.insert(profiles, "game-designer")
		table.insert(profiles, "gameplay-engineer")
		table.insert(profiles, "independent-code-reviewer")
		table.insert(profiles, "roblox-qa-tester")
		table.insert(gates, "RBX-07")
		reasons["COMBO-RBX-02"] = "Authoritative combat rules, weapon kits, and state machine"
	end

	-- 3. UI / HUD
	if hasUI then
		table.insert(combos, "COMBO-RBX-05")
		table.insert(profiles, "ui-ux-designer")
		table.insert(profiles, "gameplay-engineer")
		table.insert(profiles, "visual-animation-reviewer")
		reasons["COMBO-RBX-05"] = "Responsive HUD, input prompts, and visual feedback"
	end

	-- 4. RemoteEvent / Damage / Server Authority
	if isRemoteOrServerDamage then
		table.insert(combos, "COMBO-RBX-10")
		table.insert(profiles, "security-anti-exploit-specialist")
		table.insert(gates, "RBX-10")
		reasons["COMBO-RBX-10"] = "Mandatory server-authoritative validation and anti-exploit guard"
	end

	-- 5. Heavy VFX / Large NPC / Performance Risk
	if isPerformanceCritical then
		table.insert(combos, "COMBO-RBX-11")
		table.insert(profiles, "performance-specialist")
		table.insert(gates, "RBX-11")
		reasons["COMBO-RBX-11"] = "Mandatory MicroProfiler tuning, LOD scheduling, and memory budget guard"
	end

	-- Default if empty
	if #combos == 0 then
		table.insert(combos, "COMBO-RBX-01")
		table.insert(profiles, "gameplay-engineer")
		table.insert(profiles, "independent-code-reviewer")
	end

	return {
		selectedCombos = dedupeAndSort(combos),
		selectedProfiles = dedupeAndSort(profiles),
		requiredGates = dedupeAndSort(gates),
		reasons = reasons,
	}
end

-- ==============================================================================
-- 4. Single-Writer File Ownership Lock Manager
-- ==============================================================================
export type LockConflict = {
	file: string,
	heldBySession: string,
	heldByRole: string,
}

export type LockResult = {
	status: "ACQUIRED" | "BLOCKED",
	reason: string?,
	message: string?,
	acquiredFiles: { string }?,
	conflicts: { LockConflict }?,
}

export type LockManager = {
	acquireLocks: (self: LockManager, role: string, sessionId: string, paths: { string }) -> LockResult,
	releaseLocks: (self: LockManager, sessionId: string, paths: { string }?) -> boolean,
	getLockedFiles: (self: LockManager) -> { [string]: { sessionId: string, role: string, acquiredAt: number } },
	isLocked: (self: LockManager, path: string) -> boolean,
}

function WorkflowEngine.newLockManager(): LockManager
	local locks: { [string]: { sessionId: string, role: string, acquiredAt: number } } = {}

	local manager = {}

	function manager:isLocked(path: string): boolean
		return locks[path] ~= nil
	end

	function manager:getLockedFiles()
		local copy = {}
		for k, v in locks do
			copy[k] = { sessionId = v.sessionId, role = v.role, acquiredAt = v.acquiredAt }
		end
		return copy
	end

	function manager:acquireLocks(role: string, sessionId: string, paths: { string }): LockResult
		-- 1. Check TASKS.md write authority
		for _, path in paths do
			local normalizedPath = string.gsub(path, "\\", "/")
			if string.find(normalizedPath, "TASKS%.md$") ~= nil or normalizedPath == "TASKS.md" then
				if role ~= "roblox-team-lead" and role ~= "workflow-manager" then
					return {
						status = "BLOCKED",
						reason = "UNAUTHORIZED_TASK_BOARD_WRITER",
						message = string.format("Role '%s' is not authorized to lock or write to TASKS.md. Only roblox-team-lead/workflow-manager is permitted.", role),
						conflicts = {},
					}
				end
			end
		end

		-- 2. Check for concurrent file ownership conflicts
		local conflicts: { LockConflict } = {}
		for _, path in paths do
			local current = locks[path]
			if current and current.sessionId ~= sessionId then
				table.insert(conflicts, {
					file = path,
					heldBySession = current.sessionId,
					heldByRole = current.role,
				})
			end
		end

		if #conflicts > 0 then
			return {
				status = "BLOCKED",
				reason = "CONCURRENT_FILE_OWNERSHIP_CONFLICT",
				message = string.format("Detected concurrent lock conflict on %d file(s)", #conflicts),
				conflicts = conflicts,
			}
		end

		-- 3. Acquire all locks
		local now = os.time()
		for _, path in paths do
			locks[path] = {
				sessionId = sessionId,
				role = role,
				acquiredAt = now,
			}
		end

		return {
			status = "ACQUIRED",
			acquiredFiles = paths,
		}
	end

	function manager:releaseLocks(sessionId: string, paths: { string }?): boolean
		if paths then
			for _, path in paths do
				local current = locks[path]
				if current and current.sessionId == sessionId then
					locks[path] = nil
				end
			end
		else
			for path, info in locks do
				if info.sessionId == sessionId then
					locks[path] = nil
				end
			end
		end
		return true
	end

	return (manager :: any) :: LockManager
end

-- ==============================================================================
-- 5. Multi-Hop Handoff Engine
-- ==============================================================================
export type HandoffContract = {
	taskId: string,
	runId: string,
	idempotencyKey: string,
	sender: {
		role: string,
		sessionId: string,
	},
	recipient: {
		role: string,
		sessionId: string?,
	},
	sessionIdentity: string,
	scope: string,
	acceptanceCriteria: { string },
	baseGitSha: string,
	changedFiles: { string },
	changeSummary: string,
	testResults: {
		passed: number,
		failed: number,
		details: string?,
	},
	evidenceRefs: { string },
	requiredNextAction: string,
	deliveryState: "PENDING" | "DELIVERED" | "ACKNOWLEDGED" | "DELIVERY_UNCONFIRMED",
}

export type HandoffResult = {
	status: "DISPATCHED" | "CACHED_RECEIPT" | "BLOCKED",
	reason: string?,
	message: string?,
	idempotentReplay: boolean?,
	deliveryState: string?,
	receiptId: string?,
	missingFields: { string }?,
	blindRetryBlocked: boolean?,
}

export type HandoffEngine = {
	validateAndDispatchHandoff: (self: HandoffEngine, contract: HandoffContract, simulateTimeout: boolean?) -> HandoffResult,
	acknowledgeReceipt: (self: HandoffEngine, idempotencyKey: string, recipientSessionId: string) -> boolean,
	getCachedReceipt: (self: HandoffEngine, idempotencyKey: string) -> HandoffResult?,
}

local MANDATORY_HANDOFF_FIELDS = {
	"taskId", "runId", "idempotencyKey", "sender", "recipient",
	"sessionIdentity", "scope", "acceptanceCriteria", "baseGitSha",
	"changedFiles", "changeSummary", "testResults", "evidenceRefs",
	"requiredNextAction", "deliveryState",
}

function WorkflowEngine.newHandoffEngine(): HandoffEngine
	local receipts: { [string]: HandoffResult } = {}
	local dispatchedContracts: { [string]: HandoffContract } = {}

	local engine = {}

	function engine:getCachedReceipt(idempotencyKey: string): HandoffResult?
		return receipts[idempotencyKey]
	end

	function engine:validateAndDispatchHandoff(contract: HandoffContract, simulateTimeout: boolean?): HandoffResult
		-- 1. Idempotency Check
		if receipts[contract.idempotencyKey] then
			local cached = receipts[contract.idempotencyKey]
			return {
				status = "CACHED_RECEIPT",
				idempotentReplay = true,
				receiptId = cached.receiptId,
				deliveryState = cached.deliveryState,
				message = "Returned cached handoff receipt without side effects",
			}
		end

		-- 2. Validate mandatory fields
		local missing: { string } = {}
		for _, field in MANDATORY_HANDOFF_FIELDS do
			local val = (contract :: any)[field]
			if val == nil then
				table.insert(missing, field)
			elseif type(val) == "string" and #val == 0 then
				table.insert(missing, field)
			elseif type(val) == "table" and (field == "sender" or field == "recipient") then
				if not val.role or #val.role == 0 then
					table.insert(missing, field .. ".role")
				end
			end
		end

		if #missing > 0 then
			return {
				status = "BLOCKED",
				reason = "INVALID_HANDOFF_CONTRACT",
				message = string.format("Handoff contract missing %d required field(s)", #missing),
				missingFields = missing,
			}
		end

		-- 3. Enforce Separation of Duties (SoD)
		if contract.recipient.sessionId and contract.sender.sessionId == contract.recipient.sessionId then
			return {
				status = "BLOCKED",
				reason = "SELF_APPROVAL_PROHIBITED",
				message = "Separation of Duties violation: Implementer cannot review or approve its own work.",
			}
		end

		-- 4. Check unconfirmed delivery / timeout
		if simulateTimeout or contract.deliveryState == "DELIVERY_UNCONFIRMED" then
			local unconfirmedResult: HandoffResult = {
				status = "BLOCKED",
				reason = "DELIVERY_UNCONFIRMED",
				deliveryState = "DELIVERY_UNCONFIRMED",
				blindRetryBlocked = true,
				message = "Recipient acknowledgment timed out. Blind retries halted to prevent split-brain execution.",
			}
			return unconfirmedResult
		end

		-- 5. Dispatch success & record receipt
		local receiptId = string.format("RCPT-%s-%s", contract.taskId, string.sub(contract.idempotencyKey, 1, 8))
		local result: HandoffResult = {
			status = "DISPATCHED",
			receiptId = receiptId,
			deliveryState = "DELIVERED",
			idempotentReplay = false,
			message = "Handoff successfully validated and dispatched to recipient",
		}

		receipts[contract.idempotencyKey] = result
		dispatchedContracts[contract.idempotencyKey] = contract
		return result
	end

	function engine:acknowledgeReceipt(idempotencyKey: string, recipientSessionId: string): boolean
		local cached = receipts[idempotencyKey]
		if not cached then
			return false
		end
		cached.deliveryState = "ACKNOWLEDGED"
		return true
	end

	return (engine :: any) :: HandoffEngine
end

-- ==============================================================================
-- 6. Review, QA, Rework Loop & 3-Strike Circuit Breaker
-- ==============================================================================
export type StageEvaluation = {
	stage: string,
	result: "PASS" | "FAIL",
	evaluatedBy: { role: string, sessionId: string },
	evidenceRefs: { string }?,
	findings: { string }?,
}

export type StageTransitionResult = {
	status: "STAGE_ADVANCED" | "REWORK_DISPATCHED" | "ESCALATED" | "BLOCKED",
	currentStage: string,
	reworkRound: number,
	codeReviewStatus: string,
	boardState: string,
	reason: string?,
	message: string?,
	findings: { string }?,
}

export type StageManager = {
	getCurrentStage: (self: StageManager) -> string,
	getReworkRound: (self: StageManager) -> number,
	getCodeReviewStatus: (self: StageManager) -> string,
	getBoardState: (self: StageManager) -> string,
	processStageResult: (self: StageManager, evaluation: StageEvaluation) -> StageTransitionResult,
}

function WorkflowEngine.newStageManager(initialState: {
	stage: string?,
	reworkRound: number?,
	codeReviewStatus: string?,
	boardState: string?,
}?): StageManager
	local currentStage = (initialState and initialState.stage) or "IMPLEMENTATION"
	local reworkRound = (initialState and initialState.reworkRound) or 0
	local codeReviewStatus = (initialState and initialState.codeReviewStatus) or "PENDING"
	local boardState = (initialState and initialState.boardState) or "IN_PROGRESS"

	local manager = {}

	function manager:getCurrentStage() return currentStage end
	function manager:getReworkRound() return reworkRound end
	function manager:getCodeReviewStatus() return codeReviewStatus end
	function manager:getBoardState() return boardState end

	function manager:processStageResult(evaluation: StageEvaluation): StageTransitionResult
		-- 1. Missing Evidence Gate for PASS
		if evaluation.result == "PASS" then
			if not evaluation.evidenceRefs or #evaluation.evidenceRefs == 0 then
				return {
					status = "BLOCKED",
					currentStage = currentStage,
					reworkRound = reworkRound,
					codeReviewStatus = codeReviewStatus,
					boardState = boardState,
					reason = "MISSING_EVIDENCE_FOR_PASS",
					message = "Cannot advance stage with PASS without empirical test results or evidence references",
				}
			end
		end

		-- 2. Stale Code Review Gate for QA Verification
		if evaluation.stage == "QA_VERIFICATION" and codeReviewStatus == "STALE_REQUIRES_RERUN" then
			return {
				status = "BLOCKED",
				currentStage = currentStage,
				reworkRound = reworkRound,
				codeReviewStatus = codeReviewStatus,
				boardState = boardState,
				reason = "CODE_REVIEW_STALE_REQUIRES_RERUN",
				message = "Cannot perform QA verification while code review is STALE_REQUIRES_RERUN. Implementer must submit fix and Code Review must pass first.",
			}
		end

		-- 3. Handle CODE_REVIEW failure
		if evaluation.stage == "CODE_REVIEW" and evaluation.result == "FAIL" then
			reworkRound += 1
			-- 3-Strike Circuit Breaker: after 2 failed rework rounds, halt before Round 3
			if reworkRound >= 2 then
				boardState = "ESCALATED"
				currentStage = "ESCALATED"
				return {
					status = "ESCALATED",
					currentStage = currentStage,
					reworkRound = reworkRound,
					codeReviewStatus = "FAILED",
					boardState = boardState,
					reason = "MAX_REWORK_ROUNDS_EXCEEDED",
					message = "Rework threshold reached (2 failed rework rounds). Circuit breaker triggered; automatic rework halted for Owner/Lead escalation.",
					findings = evaluation.findings,
				}
			end

			currentStage = "REWORK_IMPLEMENTATION"
			codeReviewStatus = "FAILED"
			return {
				status = "REWORK_DISPATCHED",
				currentStage = currentStage,
				reworkRound = reworkRound,
				codeReviewStatus = codeReviewStatus,
				boardState = boardState,
				reason = "CODE_REVIEW_FINDINGS",
				findings = evaluation.findings,
				message = "Code review failed. Routed back to Implementer with findings.",
			}
		end

		-- 4. Handle QA_VERIFICATION failure
		if evaluation.stage == "QA_VERIFICATION" and evaluation.result == "FAIL" then
			reworkRound += 1
			if reworkRound >= 2 then
				boardState = "ESCALATED"
				currentStage = "ESCALATED"
				return {
					status = "ESCALATED",
					currentStage = currentStage,
					reworkRound = reworkRound,
					codeReviewStatus = "STALE_REQUIRES_RERUN",
					boardState = boardState,
					reason = "MAX_REWORK_ROUNDS_EXCEEDED",
					message = "Rework threshold reached (2 failed rework rounds). Circuit breaker triggered; automatic rework halted for Owner/Lead escalation.",
					findings = evaluation.findings,
				}
			end

			-- Code review must be marked stale after tester fails
			currentStage = "REWORK_IMPLEMENTATION"
			codeReviewStatus = "STALE_REQUIRES_RERUN"
			return {
				status = "REWORK_DISPATCHED",
				currentStage = currentStage,
				reworkRound = reworkRound,
				codeReviewStatus = codeReviewStatus,
				boardState = boardState,
				reason = "QA_TEST_FAILURE",
				findings = evaluation.findings,
				message = "QA verification failed. Routed back to Implementer. Prior code review marked STALE_REQUIRES_RERUN.",
			}
		end

		-- 4. Advance from IMPLEMENTATION to CODE_REVIEW
		if currentStage == "IMPLEMENTATION" or currentStage == "REWORK_IMPLEMENTATION" then
			if evaluation.result == "PASS" then
				currentStage = "CODE_REVIEW"
				codeReviewStatus = "PENDING"
				return {
					status = "STAGE_ADVANCED",
					currentStage = currentStage,
					reworkRound = reworkRound,
					codeReviewStatus = codeReviewStatus,
					boardState = boardState,
					message = "Implementation complete with evidence. Advanced to Code Review.",
				}
			end
		end

		-- 5. Advance from CODE_REVIEW to QA_VERIFICATION
		if currentStage == "CODE_REVIEW" and evaluation.result == "PASS" then
			currentStage = "QA_VERIFICATION"
			codeReviewStatus = "PASSED"
			return {
				status = "STAGE_ADVANCED",
				currentStage = currentStage,
				reworkRound = reworkRound,
				codeReviewStatus = codeReviewStatus,
				boardState = boardState,
				message = "Code Review passed. Advanced to QA Verification.",
			}
		end

		-- 6. Advance from QA_VERIFICATION to COMPLETED
		if currentStage == "QA_VERIFICATION" and evaluation.result == "PASS" then
			if codeReviewStatus == "STALE_REQUIRES_RERUN" then
				return {
					status = "BLOCKED",
					currentStage = currentStage,
					reworkRound = reworkRound,
					codeReviewStatus = codeReviewStatus,
					boardState = boardState,
					reason = "CODE_REVIEW_STALE_REQUIRES_RERUN",
					message = "Cannot complete QA while prior code review is STALE_REQUIRES_RERUN. Code review must pass first.",
				}
			end

			currentStage = "COMPLETED"
			boardState = "READY_FOR_LEAD_CLOSEOUT"
			return {
				status = "STAGE_ADVANCED",
				currentStage = currentStage,
				reworkRound = reworkRound,
				codeReviewStatus = codeReviewStatus,
				boardState = boardState,
				message = "QA verification passed. Advanced to Lead closeout.",
			}
		end

		return {
			status = "STAGE_ADVANCED",
			currentStage = currentStage,
			reworkRound = reworkRound,
			codeReviewStatus = codeReviewStatus,
			boardState = boardState,
		}
	end

	return (manager :: any) :: StageManager
end

-- ==============================================================================
-- 7. Owner Approval Gate
-- ==============================================================================
export type AutonomousActionRequest = {
	actionType: string,
	requestedBy: string,
	ownerApproval: boolean?,
	stangApproved: boolean?,
	details: string?,
}

export type GateCheckResult = {
	status: "ALLOWED" | "BLOCKED",
	reason: string,
	actionType: string,
	message: string?,
}

local RESTRICTED_ACTIONS = {
	["git_commit"] = true,
	["git_push"] = true,
	["gh_pr_create"] = true,
	["pr_create"] = true,
	["studio_publish"] = true,
	["studio_save_place"] = true,
	["git_clean"] = true,
	["git_reset"] = true,
}

function WorkflowEngine.checkAutonomousActionGate(request: AutonomousActionRequest): GateCheckResult
	local actionType = string.lower(request.actionType)

	if RESTRICTED_ACTIONS[actionType] then
		if request.ownerApproval == true or request.stangApproved == true then
			return {
				status = "ALLOWED",
				reason = "OWNER_EXPLICIT_APPROVAL_VERIFIED",
				actionType = request.actionType,
				message = string.format("Action '%s' approved by Project Owner Stang.", request.actionType),
			}
		else
			return {
				status = "BLOCKED",
				reason = "OWNER_APPROVAL_REQUIRED",
				actionType = request.actionType,
				message = string.format("Autonomous '%s' is strictly prohibited. Explicit authorization from Stang is required.", request.actionType),
			}
		end
	end

	return {
		status = "ALLOWED",
		reason = "NON_RESTRICTED_ACTION",
		actionType = request.actionType,
		message = "Action is within standard working-tree permissions.",
	}
end

-- ==============================================================================
-- 7b. Production Integration Guard (Sandbox -> Production is a separate workflow)
-- ==============================================================================
export type IntegrationAttempt = {
	referenceId: string,
	referenceStatus: string?,
	ownerDirective: string?,
	targetPaths: { string }?,
}

export type IntegrationGateResult = {
	status: "ALLOWED" | "BLOCKED",
	reason: string,
	message: string,
}

-- Only an explicit Owner integration command naming the exact reference ID counts.
-- "ผ่าน" / "approved" alone means APPROVED_REFERENCE and never reaches this gate as authorization.
function WorkflowEngine.checkProductionIntegration(attempt: IntegrationAttempt): IntegrationGateResult
	local directive = attempt.ownerDirective or ""
	local refId = attempt.referenceId
	local isIntegrationCommand = directive ~= ""
		and string.find(directive, refId, 1, true) ~= nil
		and (string.find(directive, "นำ", 1, true) ~= nil and string.find(directive, "ไปใช้จริง", 1, true) ~= nil)

	if attempt.referenceStatus ~= "APPROVED_REFERENCE" and attempt.referenceStatus ~= "INTEGRATION_REQUESTED" then
		return {
			status = "BLOCKED",
			reason = "REFERENCE_NOT_APPROVED",
			message = "Only an APPROVED_REFERENCE can be considered for integration.",
		}
	end

	if not isIntegrationCommand then
		return {
			status = "BLOCKED",
			reason = "PRODUCTION_INTEGRATION_NOT_AUTHORIZED",
			message = "No Owner integration command naming " .. refId .. ". 'ผ่าน' means APPROVED_REFERENCE only.",
		}
	end

	return {
		status = "ALLOWED",
		reason = "INTEGRATION_WORKFLOW_MAY_START",
		message = "Owner integration command present: start the separate Integration Workflow (plan first, no direct copy of sandbox code into src/).",
	}
end

-- ==============================================================================
-- 8. Legacy Data Preservation Checker
-- ==============================================================================
export type LegacyFileRecord = {
	path: string,
	sha256: string,
	sizeBytes: number,
}

export type PreservationCheckResult = {
	status: "PRESERVED" | "DATA_LOSS_DETECTED",
	totalFiles: number,
	matches: boolean,
	missingFiles: { string },
	corruptedFiles: { string },
	fileRecords: { [string]: LegacyFileRecord },
}

function WorkflowEngine.verifyLegacyPreservation(
	filesData: { [string]: string },
	expectedInventory: { [string]: string }?
): PreservationCheckResult
	local records: { [string]: LegacyFileRecord } = {}
	local missing: { string } = {}
	local corrupted: { string } = {}
	local total = 0

	for path, content in filesData do
		total += 1
		local hash = sha256(content)
		records[path] = {
			path = path,
			sha256 = hash,
			sizeBytes = #content,
		}
	end

	if expectedInventory then
		for expectedPath, expectedHash in expectedInventory do
			local actual = records[expectedPath]
			if not actual then
				table.insert(missing, expectedPath)
			elseif actual.sha256 ~= expectedHash then
				table.insert(corrupted, expectedPath)
			end
		end
	end

	local isPreserved = (#missing == 0) and (#corrupted == 0) and (total > 0)

	return {
		status = if isPreserved then "PRESERVED" else "DATA_LOSS_DETECTED",
		totalFiles = total,
		matches = isPreserved,
		missingFiles = missing,
		corruptedFiles = corrupted,
		fileRecords = records,
	}
end

return WorkflowEngine
