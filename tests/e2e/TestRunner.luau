--!strict
-- tests/e2e/TestRunner.luau
-- Master Test Runner for Cage Zero E2E Test Suite (Tiers 1 to 4)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Types = require(Shared:WaitForChild("Types"))

local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("services")
local CagePhysicsService = require(Services:WaitForChild("CagePhysicsService"))

local TestHarness = require(script.Parent:WaitForChild("TestHarness"))

local function getModule(name: string)
	local child = script.Parent:FindFirstChild(name)
	if child then
		return require(child)
	end
	return nil
end

-- Option A Cleanup: Legacy Tier 1 suites (PlayerActions, AirLean, StateJump, BallPop, SkillMoves) excised.

local TestRunner = {}

function TestRunner.RunPlayerActions(): any
	print(string.format("[TestRunner] %s retired under Option A cleanup baseline.", "RunPlayerActions"))
	return { totalTests = 0, passedTests = 0, failedTests = 0, totalAssertions = 0, durationMs = 0, status = "RETIRED", failures = {} }
end

function TestRunner.RunSkillMovesAndDefense(): any
	print(string.format("[TestRunner] %s retired under Option A cleanup baseline.", "RunSkillMovesAndDefense"))
	return { totalTests = 0, passedTests = 0, failedTests = 0, totalAssertions = 0, durationMs = 0, status = "RETIRED", failures = {} }
end

function TestRunner.RunAirLeanPhysics(): any
	print(string.format("[TestRunner] %s retired under Option A cleanup baseline.", "RunAirLeanPhysics"))
	return { totalTests = 0, passedTests = 0, failedTests = 0, totalAssertions = 0, durationMs = 0, status = "RETIRED", failures = {} }
end

function TestRunner.RunStateJumpPhysics(): any
	print(string.format("[TestRunner] %s retired under Option A cleanup baseline.", "RunStateJumpPhysics"))
	return { totalTests = 0, passedTests = 0, failedTests = 0, totalAssertions = 0, durationMs = 0, status = "RETIRED", failures = {} }
end

function TestRunner.RunBallPopPhysics(): any
	print(string.format("[TestRunner] %s retired under Option A cleanup baseline.", "RunBallPopPhysics"))
	return { totalTests = 0, passedTests = 0, failedTests = 0, totalAssertions = 0, durationMs = 0, status = "RETIRED", failures = {} }
end

function TestRunner.RunAll(): any
	TestHarness.Reset()
	local startTime = os.clock()

	print("================================================================================")
	print("                 CAGE ZERO E2E TEST SUITE RUNNER (TIERS 1-4)                    ")
	print("================================================================================")

	local Tier1 = getModule("Tier1_FeatureCoverage")
	local Tier2 = getModule("Tier2_BoundaryCornerCases")
	local Tier3 = getModule("Tier3_CrossFeatureCombos")
	local Tier4 = getModule("Tier4_RealWorldRallyScenarios")

	if Tier1 then
		print("\n>>> Executing Tier 1: Feature Coverage (F01-F21)...")
		Tier1.run(CagePhysicsService, Constants, Types)
	end
	if Tier2 then
		print(">>> Executing Tier 2: Boundary & Corner Cases...")
		Tier2.run(CagePhysicsService, Constants, Types)
	end
	if Tier3 then
		print(">>> Executing Tier 3: Cross-Feature Combinations...")
		Tier3.run(CagePhysicsService, Constants, Types)
	end
	if Tier4 then
		print(">>> Executing Tier 4: Real-World Rally Scenarios...")
		Tier4.run(CagePhysicsService, Constants, Types)
	end

	local durationMs = (os.clock() - startTime) * 1000.0
	local summary = TestHarness.GetSummary(durationMs)

	print("\n================================================================================")
	print(string.format("TEST RUN STATUS: %s", summary.status))
	print(string.format("Total Tests:      %d", summary.totalTests))
	print(string.format("Passed Tests:     %d", summary.passedTests))
	print(string.format("Failed Tests:     %d", summary.failedTests))
	print(string.format("Total Assertions: %d", summary.totalAssertions))
	print(string.format("Execution Time:   %.2f ms", summary.durationMs))
	print("================================================================================")

	if summary.failedTests > 0 then
		print("\nFAILED TEST DETAILS:")
		for i, failure in ipairs(summary.failures) do
			print(string.format("[%d] %s > %s: %s", i, failure.suiteName, failure.testName, failure.message))
		end
	end

	return summary
end

return TestRunner
