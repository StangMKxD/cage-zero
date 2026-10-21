--!strict
-- tests/e2e/TestHarness.luau
-- Lightweight, self-contained opaque-box testing harness for Roblox Luau

export type AssertionFailure = {
	suiteName: string,
	testName: string,
	message: string,
	expected: any,
	actual: any,
}

export type TestResult = {
	suiteName: string,
	name: string,
	passed: boolean,
	durationMs: number,
	errorMsg: string?,
}

export type SuiteSummary = {
	suiteName: string,
	total: number,
	passed: number,
	failed: number,
	tests: { TestResult },
}

export type GlobalSummary = {
	status: "PASSED" | "FAILED",
	totalTests: number,
	passedTests: number,
	failedTests: number,
	totalAssertions: number,
	durationMs: number,
	suites: { [string]: SuiteSummary },
	failures: { AssertionFailure },
}

local TestHarness = {}

local currentSuiteName = "DefaultSuite"
local currentTestName = "DefaultTest"
local testPassState = true
local testErrorMessage: string? = nil

local totalAssertions = 0
local suites: { [string]: SuiteSummary } = {}
local failures: { AssertionFailure } = {}

function TestHarness.Reset()
	currentSuiteName = "DefaultSuite"
	currentTestName = "DefaultTest"
	testPassState = true
	testErrorMessage = nil
	totalAssertions = 0
	suites = {}
	failures = {}
end

function TestHarness.Describe(suiteName: string, suiteFn: () -> ())
	currentSuiteName = suiteName
	if not suites[suiteName] then
		suites[suiteName] = {
			suiteName = suiteName,
			total = 0,
			passed = 0,
			failed = 0,
			tests = {},
		}
	end
	suiteFn()
end

function TestHarness.Test(testName: string, testFn: () -> ())
	currentTestName = testName
	testPassState = true
	testErrorMessage = nil

	local suite = suites[currentSuiteName]
	if not suite then
		suite = {
			suiteName = currentSuiteName,
			total = 0,
			passed = 0,
			failed = 0,
			tests = {},
		}
		suites[currentSuiteName] = suite
	end

	local startTime = os.clock()
	local success, err = pcall(testFn)
	local durationMs = (os.clock() - startTime) * 1000.0

	suite.total += 1

	if not success then
		testPassState = false
		testErrorMessage = tostring(err)
		table.insert(failures, {
			suiteName = currentSuiteName,
			testName = currentTestName,
			message = "Test threw unhandled error: " .. tostring(err),
			expected = "Clean execution",
			actual = tostring(err),
		})
	end

	if testPassState then
		suite.passed += 1
	else
		suite.failed += 1
	end

	table.insert(suite.tests, {
		suiteName = currentSuiteName,
		name = testName,
		passed = testPassState,
		durationMs = durationMs,
		errorMsg = testErrorMessage,
	})
end

local function recordFailure(msg: string, expected: any, actual: any)
	testPassState = false
	testErrorMessage = msg
	table.insert(failures, {
		suiteName = currentSuiteName,
		testName = currentTestName,
		message = msg,
		expected = expected,
		actual = actual,
	})
end

function TestHarness.Expect(actual: any)
	totalAssertions += 1

	return {
		toBe = function(expected: any, customMsg: string?)
			if actual ~= expected then
				local msg = customMsg or string.format("Expected %s but got %s", tostring(expected), tostring(actual))
				recordFailure(msg, expected, actual)
			end
		end,

		toNotBe = function(expected: any, customMsg: string?)
			if actual == expected then
				local msg = customMsg or string.format("Expected value not to be %s", tostring(expected))
				recordFailure(msg, "not " .. tostring(expected), actual)
			end
		end,

		toBeTrue = function(customMsg: string?)
			if actual ~= true then
				local msg = customMsg or string.format("Expected true but got %s", tostring(actual))
				recordFailure(msg, true, actual)
			end
		end,

		toBeFalse = function(customMsg: string?)
			if actual ~= false then
				local msg = customMsg or string.format("Expected false but got %s", tostring(actual))
				recordFailure(msg, false, actual)
			end
		end,

		toBeNil = function(customMsg: string?)
			if actual ~= nil then
				local msg = customMsg or string.format("Expected nil but got %s", tostring(actual))
				recordFailure(msg, nil, actual)
			end
		end,

		toNotBeNil = function(customMsg: string?)
			if actual == nil then
				local msg = customMsg or "Expected non-nil value but got nil"
				recordFailure(msg, "non-nil", nil)
			end
		end,

		toBeCloseTo = function(expected: number, tolerance: number?, customMsg: string?)
			local tol = tolerance or 1e-4
			if typeof(actual) ~= "number" or math.abs(actual - expected) > tol then
				local msg = customMsg or string.format("Expected %f to be close to %f (tol: %f)", actual, expected, tol)
				recordFailure(msg, expected, actual)
			end
		end,

		toBeGreaterThan = function(expected: number, customMsg: string?)
			if typeof(actual) ~= "number" or actual <= expected then
				local msg = customMsg or string.format("Expected %s > %s", tostring(actual), tostring(expected))
				recordFailure(msg, "> " .. tostring(expected), actual)
			end
		end,

		toBeGreaterThanOrEqual = function(expected: number, customMsg: string?)
			if typeof(actual) ~= "number" or actual < expected then
				local msg = customMsg or string.format("Expected %s >= %s", tostring(actual), tostring(expected))
				recordFailure(msg, ">= " .. tostring(expected), actual)
			end
		end,

		toBeLessThan = function(expected: number, customMsg: string?)
			if typeof(actual) ~= "number" or actual >= expected then
				local msg = customMsg or string.format("Expected %s < %s", tostring(actual), tostring(expected))
				recordFailure(msg, "< " .. tostring(expected), actual)
			end
		end,

		toBeLessThanOrEqual = function(expected: number, customMsg: string?)
			if typeof(actual) ~= "number" or actual > expected then
				local msg = customMsg or string.format("Expected %s <= %s", tostring(actual), tostring(expected))
				recordFailure(msg, "<= " .. tostring(expected), actual)
			end
		end,

		toBeVector3CloseTo = function(expected: Vector3, tolerance: number?, customMsg: string?)
			local tol = tolerance or 1e-3
			if typeof(actual) ~= "Vector3" then
				recordFailure("Actual value is not a Vector3: " .. typeof(actual), expected, actual)
				return
			end
			local diff = (actual - expected).Magnitude
			if diff > tol then
				local msg = customMsg or string.format(
					"Expected Vector3(%f, %f, %f) close to (%f, %f, %f), diff = %f > tol %f",
					actual.X, actual.Y, actual.Z,
					expected.X, expected.Y, expected.Z,
					diff, tol
				)
				recordFailure(msg, expected, actual)
			end
		end,

		toBeWithinBounds = function(minVec: Vector3, maxVec: Vector3, customMsg: string?)
			if typeof(actual) ~= "Vector3" then
				recordFailure("Actual value is not a Vector3", minVec, actual)
				return
			end
			local inX = actual.X >= minVec.X and actual.X <= maxVec.X
			local inY = actual.Y >= minVec.Y and actual.Y <= maxVec.Y
			local inZ = actual.Z >= minVec.Z and actual.Z <= maxVec.Z
			if not (inX and inY and inZ) then
				local msg = customMsg or string.format(
					"Vector3(%f, %f, %f) out of bounds [%f..%f, %f..%f, %f..%f]",
					actual.X, actual.Y, actual.Z,
					minVec.X, maxVec.X, minVec.Y, maxVec.Y, minVec.Z, maxVec.Z
				)
				recordFailure(msg, { min = minVec, max = maxVec }, actual)
			end
		end,
	}
end

function TestHarness.GetSummary(totalDurationMs: number): GlobalSummary
	local total = 0
	local passed = 0
	local failed = 0

	for _, suite in pairs(suites) do
		total += suite.total
		passed += suite.passed
		failed += suite.failed
	end

	return {
		status = if failed == 0 then "PASSED" else "FAILED",
		totalTests = total,
		passedTests = passed,
		failedTests = failed,
		totalAssertions = totalAssertions,
		durationMs = totalDurationMs,
		suites = suites,
		failures = failures,
	}
end

return table.freeze(TestHarness)
