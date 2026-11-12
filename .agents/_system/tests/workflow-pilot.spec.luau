--!strict
-- ==============================================================================
-- Project Last Wave: 18-Case Automated Workflow Pilot Test Suite
-- Path: .agents/_system/tests/workflow-pilot.spec.luau
-- Author: Workflow Engine & 18-Case Pilot Test Subagent
-- Description: Automated Lune test suite verifying all 18 pilot cases
--              from Section 11 of the Master Prompt.
-- ==============================================================================

local fs = require("@lune/fs")
local serde = require("@lune/serde")

-- Relative require to workflow engine
local WorkflowEngine = require("../workflows/workflow-engine")

local passedCount = 0
local failedCount = 0
local totalCases = 19

local function runCase(caseId: string, caseName: string, testFn: () -> ())
	local fullTitle = string.format("%s: %s", caseId, caseName)
	local ok, err = pcall(testFn)
	if ok then
		passedCount += 1
		print(string.format("PASS [%s] %s", caseId, caseName))
	else
		failedCount += 1
		print(string.format("FAIL [%s] %s: %s", caseId, caseName, tostring(err)))
	end
end

print("======================================================================")
print("PROJECT LAST WAVE: EXECUTING 18-CASE WORKFLOW PILOT TEST SUITE")
print("======================================================================")

-- ------------------------------------------------------------------------------
-- Case 01: Prompt Roblox -> Workflow Activated
-- ------------------------------------------------------------------------------
runCase("Case 01", "Prompt Roblox -> Workflow Activated", function()
	local prompts = {
		"สร้างระบบคอมโบโจมตีดาบ R15 พร้อมอนิเมชั่นและเอฟเฟกต์ดาบอนิเมะ VFX",
		"Fix RemoteEvent replication for CombatCoordinator damage calculation in Roblox Studio",
		"Optimize NPC horde pathfinding and wave spawning with MicroProfiler",
		"งานแก้navbar และเมนู UI HUD ใน Luau Rojo",
	}

	for _, p in prompts do
		local res = WorkflowEngine.classifyPrompt(p)
		assert(res.activated == true, string.format("Expected prompt '%s' to be activated", p))
		assert(res.reason == "ROBLOX_IN_SCOPE", string.format("Expected reason ROBLOX_IN_SCOPE for '%s', got '%s'", p, res.reason))
		assert(#res.matchedKeywords > 0, "Expected at least one matched keyword")
	end
end)

-- ------------------------------------------------------------------------------
-- Case 02: Prompt .NET/Web/fleet_verify -> Roblox Workflow NOT Activated
-- ------------------------------------------------------------------------------
runCase("Case 02", "Prompt .NET/Web/fleet_verify -> Roblox Workflow NOT Activated", function()
	local nonRobloxPrompts = {
		"Build a React web frontend with NextJS for fleet_verify",
		"Create a C# .NET microservice API for vms_management",
		"Setup Django REST backend and Vue admin dashboard",
		"Write an Angular SPA connecting to Spring Boot microservices",
		"Deploy ASP.NET core pipeline for inventory tracking",
	}

	for _, p in nonRobloxPrompts do
		local res = WorkflowEngine.classifyPrompt(p)
		assert(res.activated == false, string.format("Expected prompt '%s' to be rejected", p))
		assert(res.reason == "OUT_OF_SCOPE_NON_ROBLOX", string.format("Expected OUT_OF_SCOPE_NON_ROBLOX for '%s', got '%s'", p, res.reason))
		assert(#res.detectedDomains == 0, "Non-Roblox prompt should have zero detected domains")
	end
end)

-- ------------------------------------------------------------------------------
-- Case 03: Existing Roblox Prompt -> Resume Task and increment run_02, run_03
-- ------------------------------------------------------------------------------
runCase("Case 03", "Existing Roblox Prompt -> Resume Task and increment run_02, run_03", function()
	local mockTasks = {
		{
			taskId = "TASK-20261110-001",
			slug = "ระบบคอมโบโจมตี-ichigo",
			runs = { "run_01" },
		},
		{
			taskId = "TASK-20261110-002",
			slug = "งานแก้navbar-เมนูหลัก",
			runs = { "run_01", "run_02" },
		},
	}

	-- Continuation test 1: continuing task 1 (has run_01 -> should produce run_02)
	local res1 = WorkflowEngine.resolveTaskAndRun({
		prompt = "ปรับปรุงดาบ Ichigo ต่อเนื่องจาก TASK-20261110-001",
		existingTasks = mockTasks,
		rootDir = ".agents/_system/tests/fixtures/mock-tasks",
	})
	assert(res1.isContinuation == true, "Expected isContinuation to be true")
	assert(res1.taskId == "TASK-20261110-001", "Expected taskId to remain stable immutable")
	assert(res1.runId == "run_02", string.format("Expected run_02, got %s", res1.runId))
	assert(res1.runNumber == 2, "Expected runNumber == 2")
	assert(res1.slug == "ระบบคอมโบโจมตี-ichigo", "Expected slug to match existing task folder")

	-- Continuation test 2: continuing task 2 (has run_01, run_02 -> should produce run_03)
	local res2 = WorkflowEngine.resolveTaskAndRun({
		slug = "งานแก้navbar-เมนูหลัก",
		isContinuation = true,
		existingTasks = mockTasks,
		rootDir = ".agents/_system/tests/fixtures/mock-tasks",
	})
	assert(res2.isContinuation == true, "Expected isContinuation to be true")
	assert(res2.taskId == "TASK-20261110-002", "Expected taskId to match task 2")
	assert(res2.runId == "run_03", string.format("Expected run_03, got %s", res2.runId))
	assert(res2.runNumber == 3, "Expected runNumber == 3")
end)

-- ------------------------------------------------------------------------------
-- Case 04: New Roblox Prompt -> New Task Folder with normalized Windows-safe slug and distinct taskId
-- ------------------------------------------------------------------------------
runCase("Case 04", "New Roblox Prompt -> New Task Folder with normalized Windows-safe slug and distinct taskId", function()
	local rawPrompt = 'งานแก้:navbar/เมนูหลัก? *สำคัญ* <VFX> "v1.0" | CON'
	local normalizedSlug = WorkflowEngine.normalizeSlug(rawPrompt)

	-- Verify Windows forbidden characters <>:"/\|?* are completely absent
	local forbidden = { "<", ">", ":", '"', "/", "\\", "|", "%?", "%*" }
	for _, ch in forbidden do
		assert(string.find(normalizedSlug, ch) == nil, string.format("Forbidden character '%s' found in slug '%s'", ch, normalizedSlug))
	end

	-- Verify reserved name CON is protected
	local upperSlug = string.upper(normalizedSlug)
	assert(upperSlug ~= "CON", "Reserved name CON was not escaped")

	-- Verify resolveTaskAndRun assigns distinct taskId and run_01
	local res = WorkflowEngine.resolveTaskAndRun({
		prompt = rawPrompt,
		existingTasks = {},
		rootDir = ".agents/_system/tests/fixtures/mock-tasks",
	})
	assert(res.isContinuation == false, "New task should not be a continuation")
	assert(res.runId == "run_01", "New task initial run must be run_01")
	assert(res.runNumber == 1, "New task initial run number must be 1")
	assert(string.match(res.taskId, "^TASK%-%d%d%d%d%d%d%d%d%-%d%d%d$") ~= nil, string.format("taskId '%s' does not match pattern TASK-YYYYMMDD-NNN", res.taskId))
end)

-- ------------------------------------------------------------------------------
-- Case 05: Auto Team Selection -> Selects accurate Profiles & Combos across domains
-- ------------------------------------------------------------------------------
runCase("Case 05", "Auto Team Selection -> Selects accurate Profiles & Combos across domains", function()
	-- 1. Animation R15 only
	local t1 = WorkflowEngine.assembleTeam({ prompt = "Create R15 character animation keyframing" })
	assert(table.find(t1.selectedCombos, "COMBO-RBX-03") ~= nil, "Expected COMBO-RBX-03 for Animation")
	assert(table.find(t1.selectedProfiles, "animation-artist-r15") ~= nil, "Expected animation-artist-r15")
	assert(table.find(t1.selectedProfiles, "visual-animation-reviewer") ~= nil, "Expected visual-animation-reviewer")

	-- 2. VFX only
	local t2 = WorkflowEngine.assembleTeam({ prompt = "Author slash ribbon VFX particles and beams" })
	assert(table.find(t2.selectedCombos, "COMBO-RBX-04") ~= nil, "Expected COMBO-RBX-04 for VFX")
	assert(table.find(t2.selectedProfiles, "vfx-artist") ~= nil, "Expected vfx-artist")

	-- 3. Animation + VFX composite
	local t3 = WorkflowEngine.assembleTeam({ prompt = "Build synced R15 animation with sword trail VFX" })
	assert(table.find(t3.selectedCombos, "COMBO-RBX-03") ~= nil, "Expected COMBO-RBX-03")
	assert(table.find(t3.selectedCombos, "COMBO-RBX-04") ~= nil, "Expected COMBO-RBX-04")
	assert(table.find(t3.selectedCombos, "COMBO-RBX-07") ~= nil, "Expected COMBO-RBX-07")
	assert(table.find(t3.selectedProfiles, "technical-artist") ~= nil, "Expected technical-artist")
	assert(table.find(t3.selectedProfiles, "roblox-qa-tester") ~= nil, "Expected roblox-qa-tester")
	assert(table.find(t3.requiredGates, "RBX-07") ~= nil, "Expected RBX-07 gate")

	-- 4. Gameplay Combat
	local t4 = WorkflowEngine.assembleTeam({ prompt = "Implement combo attack damage rules and weapon hitboxes" })
	assert(table.find(t4.selectedCombos, "COMBO-RBX-02") ~= nil, "Expected COMBO-RBX-02")
	assert(table.find(t4.selectedCombos, "COMBO-RBX-07") ~= nil, "Expected COMBO-RBX-07")
	assert(table.find(t4.selectedProfiles, "game-designer") ~= nil, "Expected game-designer")
	assert(table.find(t4.selectedProfiles, "gameplay-engineer") ~= nil, "Expected gameplay-engineer")
	assert(table.find(t4.selectedProfiles, "independent-code-reviewer") ~= nil, "Expected independent-code-reviewer")

	-- 5. UI / HUD
	local t5 = WorkflowEngine.assembleTeam({ prompt = "Design responsive HUD screen GUI and navbar menu" })
	assert(table.find(t5.selectedCombos, "COMBO-RBX-05") ~= nil, "Expected COMBO-RBX-05")
	assert(table.find(t5.selectedProfiles, "ui-ux-designer") ~= nil, "Expected ui-ux-designer")
	assert(table.find(t5.selectedProfiles, "visual-animation-reviewer") ~= nil, "Expected visual-animation-reviewer")
end)

-- ------------------------------------------------------------------------------
-- Case 06: Multi-hop chain Lead -> Specialist -> Reviewer -> Tester -> Lead completes cleanly
-- ------------------------------------------------------------------------------
runCase("Case 06", "Multi-hop chain Lead -> Specialist -> Reviewer -> Tester -> Lead completes cleanly", function()
	local handoffEngine = WorkflowEngine.newHandoffEngine()
	local stageManager = WorkflowEngine.newStageManager({ stage = "IMPLEMENTATION" })

	-- Hop 1: Implementer finishes work, dispatches to Reviewer
	local contract1: WorkflowEngine.HandoffContract = {
		taskId = "TASK-20261110-001",
		runId = "run_01",
		idempotencyKey = "IDEMP-HOP-01-CODE",
		sender = { role = "gameplay-engineer", sessionId = "sess_implementer_01" },
		recipient = { role = "independent-code-reviewer", sessionId = "sess_reviewer_01" },
		sessionIdentity = "sess_implementer_01",
		scope = "Implement Getsuga combo hitboxes",
		acceptanceCriteria = { "Pure domain validation", "Finite number guard" },
		baseGitSha = "d5575ad2a1",
		changedFiles = { "src/shared/domain/CombatRules.luau" },
		changeSummary = "Added getsuga combo multiplier and damage validation",
		testResults = { passed = 12, failed = 0, details = "All unit tests pass" },
		evidenceRefs = { "evidence/run_01/unit-tests.log" },
		requiredNextAction = "Perform independent code review",
		deliveryState = "PENDING",
	}

	local res1 = handoffEngine:validateAndDispatchHandoff(contract1)
	assert(res1.status == "DISPATCHED", "Expected Hop 1 to be DISPATCHED")
	assert(handoffEngine:acknowledgeReceipt("IDEMP-HOP-01-CODE", "sess_reviewer_01") == true, "Expected ACK success")

	local tr1 = stageManager:processStageResult({
		stage = "IMPLEMENTATION",
		result = "PASS",
		evaluatedBy = { role = "gameplay-engineer", sessionId = "sess_implementer_01" },
		evidenceRefs = { "evidence/run_01/unit-tests.log" },
	})
	assert(tr1.currentStage == "CODE_REVIEW", "Stage should advance to CODE_REVIEW")

	-- Hop 2: Reviewer passes, dispatches to Tester
	local contract2: WorkflowEngine.HandoffContract = {
		taskId = "TASK-20261110-001",
		runId = "run_01",
		idempotencyKey = "IDEMP-HOP-02-REVIEW",
		sender = { role = "independent-code-reviewer", sessionId = "sess_reviewer_01" },
		recipient = { role = "roblox-qa-tester", sessionId = "sess_tester_01" },
		sessionIdentity = "sess_reviewer_01",
		scope = "Review Getsuga combo hitboxes",
		acceptanceCriteria = { "Code review clean", "No style violations" },
		baseGitSha = "d5575ad2a1",
		changedFiles = { "src/shared/domain/CombatRules.luau" },
		changeSummary = "Code review approved without objections",
		testResults = { passed = 12, failed = 0 },
		evidenceRefs = { "evidence/run_01/code-review.md" },
		requiredNextAction = "Execute QA integration playtest",
		deliveryState = "PENDING",
	}
	local res2 = handoffEngine:validateAndDispatchHandoff(contract2)
	assert(res2.status == "DISPATCHED", "Expected Hop 2 to be DISPATCHED")
	assert(handoffEngine:acknowledgeReceipt("IDEMP-HOP-02-REVIEW", "sess_tester_01") == true, "Expected ACK success")

	local tr2 = stageManager:processStageResult({
		stage = "CODE_REVIEW",
		result = "PASS",
		evaluatedBy = { role = "independent-code-reviewer", sessionId = "sess_reviewer_01" },
		evidenceRefs = { "evidence/run_01/code-review.md" },
	})
	assert(tr2.currentStage == "QA_VERIFICATION", "Stage should advance to QA_VERIFICATION")

	-- Hop 3: Tester passes, dispatches to Team Lead for closeout
	local contract3: WorkflowEngine.HandoffContract = {
		taskId = "TASK-20261110-001",
		runId = "run_01",
		idempotencyKey = "IDEMP-HOP-03-TEST",
		sender = { role = "roblox-qa-tester", sessionId = "sess_tester_01" },
		recipient = { role = "roblox-team-lead", sessionId = "sess_lead_01" },
		sessionIdentity = "sess_tester_01",
		scope = "Empirical QA playtest on combat-test.project.json",
		acceptanceCriteria = { "Lune spec pass", "No runtime errors" },
		baseGitSha = "d5575ad2a1",
		changedFiles = { "src/shared/domain/CombatRules.luau" },
		changeSummary = "All QA tests passed with 100% assertions",
		testResults = { passed = 81, failed = 0 },
		evidenceRefs = { "evidence/run_01/qa-playtest.log" },
		requiredNextAction = "Lead closeout and Stang UAT preparation",
		deliveryState = "PENDING",
	}
	local res3 = handoffEngine:validateAndDispatchHandoff(contract3)
	assert(res3.status == "DISPATCHED", "Expected Hop 3 to be DISPATCHED")
	assert(handoffEngine:acknowledgeReceipt("IDEMP-HOP-03-TEST", "sess_lead_01") == true, "Expected ACK success")

	local tr3 = stageManager:processStageResult({
		stage = "QA_VERIFICATION",
		result = "PASS",
		evaluatedBy = { role = "roblox-qa-tester", sessionId = "sess_tester_01" },
		evidenceRefs = { "evidence/run_01/qa-playtest.log" },
	})
	assert(tr3.currentStage == "COMPLETED", "Final stage must reach COMPLETED")
	assert(tr3.boardState == "READY_FOR_LEAD_CLOSEOUT", "Board state should be READY_FOR_LEAD_CLOSEOUT")
end)

-- ------------------------------------------------------------------------------
-- Case 07: Missing/Invalid Handoff -> BLOCKED (INVALID_HANDOFF_CONTRACT)
-- ------------------------------------------------------------------------------
runCase("Case 07", "Missing/Invalid Handoff -> BLOCKED (INVALID_HANDOFF_CONTRACT)", function()
	local handoffEngine = WorkflowEngine.newHandoffEngine()

	-- Subtest A: Missing evidenceRefs and baseGitSha
	local invalidContract: any = {
		taskId = "TASK-20261110-001",
		runId = "run_01",
		idempotencyKey = "IDEMP-INVALID-01",
		sender = { role = "gameplay-engineer", sessionId = "sess_01" },
		recipient = { role = "independent-code-reviewer" },
		sessionIdentity = "sess_01",
		scope = "Combat changes",
		acceptanceCriteria = { "Done" },
		-- baseGitSha is missing!
		changedFiles = { "file1.luau" },
		changeSummary = "Some change",
		testResults = { passed = 1, failed = 0 },
		-- evidenceRefs is missing!
		requiredNextAction = "Review",
		deliveryState = "PENDING",
	}

	local res = handoffEngine:validateAndDispatchHandoff(invalidContract)
	assert(res.status == "BLOCKED", "Expected BLOCKED status for invalid contract")
	assert(res.reason == "INVALID_HANDOFF_CONTRACT", string.format("Expected INVALID_HANDOFF_CONTRACT, got %s", tostring(res.reason)))
	assert(res.missingFields ~= nil and #res.missingFields >= 2, "Expected missingFields to list missing fields")

	-- Subtest B: Separation of Duties violation (self-approval)
	local sodViolationContract: WorkflowEngine.HandoffContract = {
		taskId = "TASK-20261110-001",
		runId = "run_01",
		idempotencyKey = "IDEMP-SOD-01",
		sender = { role = "gameplay-engineer", sessionId = "sess_alice_01" },
		recipient = { role = "independent-code-reviewer", sessionId = "sess_alice_01" }, -- SAME SESSION!
		sessionIdentity = "sess_alice_01",
		scope = "Self approval attempt",
		acceptanceCriteria = { "None" },
		baseGitSha = "d5575ad2a1",
		changedFiles = { "file1.luau" },
		changeSummary = "Self reviewed change",
		testResults = { passed = 5, failed = 0 },
		evidenceRefs = { "evidence/dummy.log" },
		requiredNextAction = "Self approve",
		deliveryState = "PENDING",
	}

	local resSod = handoffEngine:validateAndDispatchHandoff(sodViolationContract)
	assert(resSod.status == "BLOCKED", "Expected SoD violation to be BLOCKED")
	assert(resSod.reason == "SELF_APPROVAL_PROHIBITED", string.format("Expected SELF_APPROVAL_PROHIBITED, got %s", tostring(resSod.reason)))
end)

-- ------------------------------------------------------------------------------
-- Case 08: Review Failure -> Routes back to Implementer with Findings
-- ------------------------------------------------------------------------------
runCase("Case 08", "Review Failure -> Routes back to Implementer with Findings", function()
	local stageManager = WorkflowEngine.newStageManager({ stage = "CODE_REVIEW", reworkRound = 0 })

	local findings = {
		"Finite number guard missing on attack vector input in NetworkRouter",
		"Potential division by zero when calculating knockback magnitude",
	}

	local tr = stageManager:processStageResult({
		stage = "CODE_REVIEW",
		result = "FAIL",
		evaluatedBy = { role = "independent-code-reviewer", sessionId = "sess_reviewer_01" },
		findings = findings,
	})

	assert(tr.status == "REWORK_DISPATCHED", "Expected REWORK_DISPATCHED")
	assert(tr.currentStage == "REWORK_IMPLEMENTATION", string.format("Expected REWORK_IMPLEMENTATION, got %s", tr.currentStage))
	assert(tr.reworkRound == 1, "Rework round should increment to 1")
	assert(tr.findings ~= nil and #tr.findings == 2, "Expected reviewer findings to be attached")
	assert(tr.codeReviewStatus == "FAILED", "codeReviewStatus should be FAILED")
end)

-- ------------------------------------------------------------------------------
-- Case 09: Tester Failure -> Routes back to Implementer AND forces Re-review (STALE_REQUIRES_RERUN)
-- ------------------------------------------------------------------------------
runCase("Case 09", "Tester Failure -> Routes back to Implementer AND forces Re-review (STALE_REQUIRES_RERUN)", function()
	local stageManager = WorkflowEngine.newStageManager({
		stage = "QA_VERIFICATION",
		reworkRound = 0,
		codeReviewStatus = "PASSED",
	})

	-- QA test fails
	local tr = stageManager:processStageResult({
		stage = "QA_VERIFICATION",
		result = "FAIL",
		evaluatedBy = { role = "roblox-qa-tester", sessionId = "sess_tester_01" },
		findings = { "Hitbox raycast clipped through wall geometry during playtest" },
	})

	assert(tr.status == "REWORK_DISPATCHED", "Expected REWORK_DISPATCHED")
	assert(tr.currentStage == "REWORK_IMPLEMENTATION", "Expected route back to REWORK_IMPLEMENTATION")
	assert(tr.codeReviewStatus == "STALE_REQUIRES_RERUN", string.format("Expected STALE_REQUIRES_RERUN, got %s", tr.codeReviewStatus))

	-- Verify that subsequent QA pass without re-reviewing code is strictly blocked!
	local trPrematureQA = stageManager:processStageResult({
		stage = "QA_VERIFICATION",
		result = "PASS",
		evaluatedBy = { role = "roblox-qa-tester", sessionId = "sess_tester_01" },
		evidenceRefs = { "evidence/premature-qa.log" },
	})
	assert(trPrematureQA.status == "BLOCKED", "Premature QA pass must be BLOCKED when code review is stale")
	assert(trPrematureQA.reason == "CODE_REVIEW_STALE_REQUIRES_RERUN", "Expected reason CODE_REVIEW_STALE_REQUIRES_RERUN")
end)

-- ------------------------------------------------------------------------------
-- Case 10: Missing Evidence -> Rejects PASS (MISSING_EVIDENCE_FOR_PASS)
-- ------------------------------------------------------------------------------
runCase("Case 10", "Missing Evidence -> Rejects PASS (MISSING_EVIDENCE_FOR_PASS)", function()
	local stageManager = WorkflowEngine.newStageManager({ stage = "IMPLEMENTATION" })

	-- Case 10A: evidenceRefs is empty table
	local trEmpty = stageManager:processStageResult({
		stage = "IMPLEMENTATION",
		result = "PASS",
		evaluatedBy = { role = "gameplay-engineer", sessionId = "sess_01" },
		evidenceRefs = {}, -- EMPTY!
	})
	assert(trEmpty.status == "BLOCKED", "Expected BLOCKED for empty evidence")
	assert(trEmpty.reason == "MISSING_EVIDENCE_FOR_PASS", string.format("Expected MISSING_EVIDENCE_FOR_PASS, got %s", tostring(trEmpty.reason)))

	-- Case 10B: evidenceRefs is nil
	local trNil = stageManager:processStageResult({
		stage = "IMPLEMENTATION",
		result = "PASS",
		evaluatedBy = { role = "gameplay-engineer", sessionId = "sess_01" },
		evidenceRefs = nil, -- NIL!
	})
	assert(trNil.status == "BLOCKED", "Expected BLOCKED for nil evidence")
	assert(trNil.reason == "MISSING_EVIDENCE_FOR_PASS", "Expected MISSING_EVIDENCE_FOR_PASS")
end)

-- ------------------------------------------------------------------------------
-- Case 11: High-Risk Server/Remote Change -> Mandatory RBX-10 Security Gate & security-anti-exploit-specialist
-- ------------------------------------------------------------------------------
runCase("Case 11", "High-Risk Server/Remote Change -> Mandatory RBX-10 Security Gate & security-anti-exploit-specialist", function()
	local prompt = "Add UnreliableRemoteEvent network replication for server damage calculation and projectile hits"
	local team = WorkflowEngine.assembleTeam({
		prompt = prompt,
		isRemoteOrServerDamage = true,
	})

	assert(table.find(team.selectedCombos, "COMBO-RBX-10") ~= nil, "Expected COMBO-RBX-10 in combos")
	assert(table.find(team.selectedProfiles, "security-anti-exploit-specialist") ~= nil, "Expected security-anti-exploit-specialist profile")
	assert(table.find(team.requiredGates, "RBX-10") ~= nil, "Expected RBX-10 Security Gate in requiredGates")
	assert(team.reasons["COMBO-RBX-10"] ~= nil, "Expected justification reason for COMBO-RBX-10")
end)

-- ------------------------------------------------------------------------------
-- Case 12: Heavy VFX / Large NPC Performance Risk -> Mandatory RBX-11 Performance Gate & performance-specialist
-- ------------------------------------------------------------------------------
runCase("Case 12", "Heavy VFX / Large NPC Performance Risk -> Mandatory RBX-11 Performance Gate & performance-specialist", function()
	local prompt = "Spawn 100+ zombie horde mobs with heavy VFX slash explosions and LOD distance scheduler"
	local team = WorkflowEngine.assembleTeam({
		prompt = prompt,
		isPerformanceCritical = true,
	})

	assert(table.find(team.selectedCombos, "COMBO-RBX-11") ~= nil, "Expected COMBO-RBX-11 in combos")
	assert(table.find(team.selectedProfiles, "performance-specialist") ~= nil, "Expected performance-specialist profile")
	assert(table.find(team.requiredGates, "RBX-11") ~= nil, "Expected RBX-11 Performance Gate in requiredGates")
	assert(team.reasons["COMBO-RBX-11"] ~= nil, "Expected justification reason for COMBO-RBX-11")
end)

-- ------------------------------------------------------------------------------
-- Case 13: Concurrent File Ownership Conflict -> BLOCKED (CONCURRENT_FILE_OWNERSHIP_CONFLICT)
-- ------------------------------------------------------------------------------
runCase("Case 13", "Concurrent File Ownership Conflict -> BLOCKED (CONCURRENT_FILE_OWNERSHIP_CONFLICT)", function()
	local lockManager = WorkflowEngine.newLockManager()

	local targetFile = "src/server/application/CombatCoordinator.luau"

	-- Session 1 acquires lock
	local r1 = lockManager:acquireLocks("gameplay-engineer", "sess_worker_alpha", { targetFile })
	assert(r1.status == "ACQUIRED", "Session 1 should acquire lock successfully")
	assert(lockManager:isLocked(targetFile) == true, "targetFile should be locked")

	-- Session 2 tries to acquire lock on same file -> MUST BE BLOCKED
	local r2 = lockManager:acquireLocks("technical-artist", "sess_worker_beta", { targetFile })
	assert(r2.status == "BLOCKED", "Session 2 must be BLOCKED on concurrent file")
	assert(r2.reason == "CONCURRENT_FILE_OWNERSHIP_CONFLICT", string.format("Expected CONCURRENT_FILE_OWNERSHIP_CONFLICT, got %s", tostring(r2.reason)))
	assert(r2.conflicts ~= nil and #r2.conflicts == 1, "Expected 1 conflict entry")
	assert(r2.conflicts[1].heldBySession == "sess_worker_alpha", "Expected heldBySession == sess_worker_alpha")

	-- Unauthorized attempt to lock TASKS.md by a non-lead role
	local rTasks = lockManager:acquireLocks("gameplay-engineer", "sess_worker_alpha", { "docs/plans/TASKS.md" })
	assert(rTasks.status == "BLOCKED", "Non-lead role must be BLOCKED from writing TASKS.md")
	assert(rTasks.reason == "UNAUTHORIZED_TASK_BOARD_WRITER", "Expected UNAUTHORIZED_TASK_BOARD_WRITER")

	-- Lead role acquiring TASKS.md -> succeeds
	local rLeadTasks = lockManager:acquireLocks("roblox-team-lead", "sess_lead_01", { "docs/plans/TASKS.md" })
	assert(rLeadTasks.status == "ACQUIRED", "Lead role should acquire TASKS.md lock successfully")

	-- Release Session 1 lock, then Session 2 can acquire
	lockManager:releaseLocks("sess_worker_alpha", { targetFile })
	local r3 = lockManager:acquireLocks("technical-artist", "sess_worker_beta", { targetFile })
	assert(r3.status == "ACQUIRED", "Session 2 should acquire lock after release")
end)

-- ------------------------------------------------------------------------------
-- Case 14: Agent Delivery Failure / No ACK -> DELIVERY_UNCONFIRMED and halts blind retry
-- ------------------------------------------------------------------------------
runCase("Case 14", "Agent Delivery Failure / No ACK -> DELIVERY_UNCONFIRMED and halts blind retry", function()
	local handoffEngine = WorkflowEngine.newHandoffEngine()

	local contract: WorkflowEngine.HandoffContract = {
		taskId = "TASK-20261110-014",
		runId = "run_01",
		idempotencyKey = "IDEMP-TIMEOUT-01",
		sender = { role = "gameplay-engineer", sessionId = "sess_sender_01" },
		recipient = { role = "roblox-qa-tester", sessionId = "sess_tester_offline" },
		sessionIdentity = "sess_sender_01",
		scope = "Network timeout probe",
		acceptanceCriteria = { "Delivery verified" },
		baseGitSha = "d5575ad2a1",
		changedFiles = { "src/shared/domain/CombatRules.luau" },
		changeSummary = "Delivery timeout test",
		testResults = { passed = 1, failed = 0 },
		evidenceRefs = { "evidence/timeout.log" },
		requiredNextAction = "QA Verification",
		deliveryState = "PENDING",
	}

	-- Simulate timeout / missing ACK
	local res = handoffEngine:validateAndDispatchHandoff(contract, true --[[ simulateTimeout ]])
	assert(res.status == "BLOCKED", "Expected BLOCKED status on timeout")
	assert(res.reason == "DELIVERY_UNCONFIRMED", string.format("Expected DELIVERY_UNCONFIRMED, got %s", tostring(res.reason)))
	assert(res.deliveryState == "DELIVERY_UNCONFIRMED", "Expected deliveryState DELIVERY_UNCONFIRMED")
	assert(res.blindRetryBlocked == true, "Expected blindRetryBlocked == true to halt infinite retry loops")
end)

-- ------------------------------------------------------------------------------
-- Case 15: Rework Loop Limit (2 failed rework rounds) -> ESCALATED before Round 3
-- ------------------------------------------------------------------------------
runCase("Case 15", "Rework Loop Limit (2 failed rework rounds) -> ESCALATED before Round 3", function()
	local stageManager = WorkflowEngine.newStageManager({
		stage = "IMPLEMENTATION",
		reworkRound = 0,
		boardState = "IN_PROGRESS",
	})

	-- Advance to Code Review
	stageManager:processStageResult({
		stage = "IMPLEMENTATION",
		result = "PASS",
		evaluatedBy = { role = "gameplay-engineer", sessionId = "sess_01" },
		evidenceRefs = { "evidence/run_01/build.log" },
	})

	-- Failure 1: Reviewer rejects implementation (rework round becomes 1)
	local tr1 = stageManager:processStageResult({
		stage = "CODE_REVIEW",
		result = "FAIL",
		evaluatedBy = { role = "independent-code-reviewer", sessionId = "sess_rev_01" },
		findings = { "Issue 1: Missing bounds check" },
	})
	assert(tr1.status == "REWORK_DISPATCHED", "Expected REWORK_DISPATCHED on 1st rework")
	assert(tr1.reworkRound == 1, "Rework round should be 1")
	assert(tr1.boardState == "IN_PROGRESS", "Board state should remain IN_PROGRESS")

	-- Advance back to Code Review after rework 1
	stageManager:processStageResult({
		stage = "REWORK_IMPLEMENTATION",
		result = "PASS",
		evaluatedBy = { role = "gameplay-engineer", sessionId = "sess_01" },
		evidenceRefs = { "evidence/run_01/fix1.log" },
	})

	-- Failure 2: Reviewer rejects implementation again (rework round becomes 2)
	-- Threshold reached! Must ESCALATE and halt before starting Round 3!
	local tr2 = stageManager:processStageResult({
		stage = "CODE_REVIEW",
		result = "FAIL",
		evaluatedBy = { role = "independent-code-reviewer", sessionId = "sess_rev_01" },
		findings = { "Issue 2: Persistent memory leak in particle cache" },
	})
	assert(tr2.status == "ESCALATED", string.format("Expected ESCALATED status on 2nd rework failure, got %s", tr2.status))
	assert(tr2.boardState == "ESCALATED", "Board state must become ESCALATED")
	assert(tr2.reason == "MAX_REWORK_ROUNDS_EXCEEDED", string.format("Expected MAX_REWORK_ROUNDS_EXCEEDED, got %s", tostring(tr2.reason)))
	assert(stageManager:getBoardState() == "ESCALATED", "StageManager board state must report ESCALATED")
end)

-- ------------------------------------------------------------------------------
-- Case 16: Owner Approval Gate -> Blocks autonomous git commit / git push / Studio publish
-- ------------------------------------------------------------------------------
runCase("Case 16", "Owner Approval Gate -> Blocks autonomous git commit / git push / Studio publish", function()
	local forbiddenActions = {
		"git_commit",
		"git_push",
		"gh_pr_create",
		"studio_publish",
		"studio_save_place",
	}

	for _, act in forbiddenActions do
		-- Autonomous attempt without Stang approval -> MUST BE BLOCKED
		local checkDenied = WorkflowEngine.checkAutonomousActionGate({
			actionType = act,
			requestedBy = "independent-code-reviewer",
			ownerApproval = false,
		})
		assert(checkDenied.status == "BLOCKED", string.format("Autonomous '%s' must be BLOCKED", act))
		assert(checkDenied.reason == "OWNER_APPROVAL_REQUIRED", string.format("Expected OWNER_APPROVAL_REQUIRED for '%s', got %s", act, checkDenied.reason))

		-- With explicit Stang owner approval -> ALLOWED
		local checkAllowed = WorkflowEngine.checkAutonomousActionGate({
			actionType = act,
			requestedBy = "roblox-team-lead",
			ownerApproval = true,
			stangApproved = true,
		})
		assert(checkAllowed.status == "ALLOWED", string.format("Explicitly approved '%s' must be ALLOWED", act))
		assert(checkAllowed.reason == "OWNER_EXPLICIT_APPROVAL_VERIFIED", "Expected OWNER_EXPLICIT_APPROVAL_VERIFIED")
	end
end)

-- ------------------------------------------------------------------------------
-- Case 17: Legacy Data Preservation -> Verifies legacy inventory checksums remain intact with zero file loss
-- ------------------------------------------------------------------------------
runCase("Case 17", "Legacy Data Preservation -> Verifies legacy inventory checksums remain intact with zero file loss", function()
	-- Read fixture mock-legacy files
	local f1 = fs.readFile(".agents/_system/tests/fixtures/mock-legacy/sentinel-briefing.md")
	local f2 = fs.readFile(".agents/_system/tests/fixtures/mock-legacy/worker-dispatch.md")

	local testFiles = {
		[".agents/_system/tests/fixtures/mock-legacy/sentinel-briefing.md"] = f1,
		[".agents/_system/tests/fixtures/mock-legacy/worker-dispatch.md"] = f2,
	}

	-- Calculate baseline checksums
	local baselineInventory = {
		[".agents/_system/tests/fixtures/mock-legacy/sentinel-briefing.md"] = WorkflowEngine.sha256(f1),
		[".agents/_system/tests/fixtures/mock-legacy/worker-dispatch.md"] = WorkflowEngine.sha256(f2),
	}

	local presCheck = WorkflowEngine.verifyLegacyPreservation(testFiles, baselineInventory)
	assert(presCheck.status == "PRESERVED", "Expected status PRESERVED")
	assert(presCheck.matches == true, "Expected matches == true")
	assert(presCheck.totalFiles == 2, "Expected 2 total files preserved")
	assert(#presCheck.missingFiles == 0, "Expected zero missing files")
	assert(#presCheck.corruptedFiles == 0, "Expected zero corrupted files")

	-- Also verify that real legacy `.agents/teamwork/` directory has non-zero files and remains intact
	if fs.isDir(".agents/teamwork") then
		local teamworkEntries = fs.readDir(".agents/teamwork")
		assert(#teamworkEntries > 0, "Expected existing .agents/teamwork directory to contain legacy folders")
	end
end)

-- ------------------------------------------------------------------------------
-- Case 18: Restart / Resume -> Reads existing state and resumes current run without creating a duplicate run_XX
-- ------------------------------------------------------------------------------
runCase("Case 18", "Restart / Resume -> Reads existing state and resumes current run without creating a duplicate run_XX", function()
	-- Load fixture sample-manifest.yaml
	local manifestContent = fs.readFile(".agents/_system/tests/fixtures/sample-manifest.yaml")
	local manifestData = serde.decode("yaml", manifestContent)

	assert(manifestData.taskId == "TASK-20261110-042", "Expected manifest taskId match")
	assert(manifestData.runId == "run_02", "Expected manifest runId to be run_02")
	assert(manifestData.stage == "CODE_REVIEW", "Expected manifest stage to be CODE_REVIEW")

	-- Call resumeRun
	local resumeRes = WorkflowEngine.resumeRun(manifestData)

	assert(resumeRes.resumed == true, "Expected resumed == true")
	assert(resumeRes.taskId == "TASK-20261110-042", "Expected taskId to match manifest")
	assert(resumeRes.runId == "run_02", "Must resume current runId (run_02) WITHOUT creating run_03 or duplicate folder")
	assert(resumeRes.stage == "CODE_REVIEW", "Must resume at current stage (CODE_REVIEW)")
	assert(resumeRes.reworkRound == 1, "Must preserve reworkRound == 1")
	assert(resumeRes.status == "RESUMED_CURRENT_STAGE", "Expected status RESUMED_CURRENT_STAGE")
end)

-- ------------------------------------------------------------------------------
-- Case 19: Integration Guard -> BLOCKED PRODUCTION_INTEGRATION_NOT_AUTHORIZED without Owner integration command
-- ------------------------------------------------------------------------------
runCase("Case 19", "Integration Guard -> BLOCKED PRODUCTION_INTEGRATION_NOT_AUTHORIZED without Owner integration command", function()
	local ref = "REF-GOKU-COMBAT-001"

	local noDirective = WorkflowEngine.checkProductionIntegration({ referenceId = ref, referenceStatus = "APPROVED_REFERENCE" })
	assert(noDirective.status == "BLOCKED" and noDirective.reason == "PRODUCTION_INTEGRATION_NOT_AUTHORIZED", "No directive must be blocked")

	local bareApproval = WorkflowEngine.checkProductionIntegration({
		referenceId = ref,
		referenceStatus = "APPROVED_REFERENCE",
		ownerDirective = "ผ่าน",
	})
	assert(bareApproval.reason == "PRODUCTION_INTEGRATION_NOT_AUTHORIZED", "'ผ่าน' alone must never authorize integration")

	local wrongRef = WorkflowEngine.checkProductionIntegration({
		referenceId = ref,
		referenceStatus = "APPROVED_REFERENCE",
		ownerDirective = "นำ REF-OTHER-009 ไปใช้จริง",
	})
	assert(wrongRef.status == "BLOCKED", "Directive naming a different reference must be blocked")

	local notApproved = WorkflowEngine.checkProductionIntegration({
		referenceId = ref,
		referenceStatus = "EXPERIMENTING",
		ownerDirective = "นำ " .. ref .. " ไปใช้จริง",
	})
	assert(notApproved.reason == "REFERENCE_NOT_APPROVED", "Non-approved reference must be blocked even with a directive")

	local authorized = WorkflowEngine.checkProductionIntegration({
		referenceId = ref,
		referenceStatus = "APPROVED_REFERENCE",
		ownerDirective = "นำ " .. ref .. " ไปใช้จริง",
	})
	assert(authorized.status == "ALLOWED", "Explicit Owner integration command naming the reference may start the Integration Workflow")
end)

-- ------------------------------------------------------------------------------
-- Final Summary & Assertion
-- ------------------------------------------------------------------------------
print("======================================================================")
print(string.format("PILOT TEST RESULTS: %d / %d PASSED, %d FAILED", passedCount, totalCases, failedCount))
print("======================================================================")

assert(failedCount == 0, string.format("Pilot test suite failed with %d error(s)", failedCount))
assert(passedCount == totalCases, string.format("Expected all %d pilot cases to pass, but only %d passed", totalCases, passedCount))
