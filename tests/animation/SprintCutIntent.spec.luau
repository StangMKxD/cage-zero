--!strict
-- Run against an isolated BallService clone and an actual grounded R15 fixture.
-- A table identity supplies UserId/Character; no Player creation or network events.
return function(Service: any, player: any, character: Model)
	local checks = 0
	local function check(value: boolean, message: string)
		checks += 1
		assert(value, message)
	end
	Service.SetPossessor(player.UserId)
	local cut = { cut = "FrontLeft", cutId = 1, direction = Vector3.new(-1, 0, -1).Unit, character = character }
	character:SetAttribute("IsSprinting", false)
	check(not Service.SetDribbleCutIntent(player, cut), "Walking cannot start sprint cut")
	character:SetAttribute("IsSprinting", true)
	check(not Service.SetDribbleCutIntent(player, { cut = "unknown", cutId = 1, direction = Vector3.zAxis, character = character }), "Unknown cut")
	check(not Service.SetDribbleCutIntent(player, { cut = "FrontLeft", cutId = 0 / 0, direction = Vector3.zAxis, character = character }), "NaN sequence")
	check(not Service.SetDribbleCutIntent(player, { cut = "FrontLeft", cutId = 1, direction = Vector3.new(math.huge, 0, 0), character = character }), "Infinite direction")
	local forged = Instance.new("Model")
	check(not Service.SetDribbleCutIntent(player, { cut = "FrontLeft", cutId = 1, direction = Vector3.zAxis, character = forged }), "Forged character")
	forged:Destroy()
	check(Service.SetDribbleCutIntent(player, cut), "Valid current-carrier cut")
	check(not Service.SetDribbleCutIntent(player, cut), "Duplicate start cannot reset timeline")
	local function marker(phase: string, foot: string, id: number?, clip: string?): boolean
		return Service.SetDribbleTouchIntent(player, {
			character = character, clip = clip or "RF02_CutDiagFrontLeft_AW_R15_v01",
			isCut = true, cutId = id or 1, phase = phase, foot = foot,
		})
	end
	check(not marker("Trap", "L"), "Early trap rejected")
	check(not marker("Strike", "L"), "Early/out-of-order strike rejected")
	task.wait(0.06)
	check(not marker("Trap", "R"), "Wrong trapping foot")
	check(not marker("Trap", "L", 99), "Stale/forged sequence")
	check(not marker("Trap", "L", 1, "RF02_CutDiagBackLeft_AS_R15_v01"), "Wrong clip")
	check(marker("Trap", "L"), "Matching trap marker accepted")
	check(not marker("Trap", "L"), "Trap replay rejected")
	check(not Service.SetDribbleTouchIntent(player, { character = character, clip = "RF02_RunDribble_R15_v01", foot = "L", isCut = false }), "Background loop cannot strike trapped ball")
	check(not marker("Release", "L"), "Release before strike rejected")
	task.wait(0.05)
	check(marker("Strike", "L"), "Matching strike accepted")
	check(not marker("Strike", "L"), "Strike replay rejected")
	check(character:GetAttribute("ServerDribbleCutBallPhase") == "Struck", "Server owns strike phase")
	check(not marker("Release", "L"), "Premature release rejected")
	check(not Service.SetDribbleCutIntent(player, {cancel=true,cutId=1,character=character}), "Live carrier cannot cancel the committed cut")
	character:SetAttribute("IsSprinting",false)
	task.wait(0.56)
	check(marker("Release", "L"), "Matching release accepted")
	check(not Service.SetDribbleTouchIntent(player, { character = character, clip = "RF02_RunDribble_R15_v01", foot = "L", isCut = false }), "Run marker stays suppressed until the visible cut blends out")
	check(not Service.SetDribbleCutIntent(player, { cancel = true, cutId = 99, character = character }), "Other sequence cannot cancel")
	task.wait(0.05)
	check(Service.SetDribbleCutIntent(player, { cancel = true, cutId = 1, character = character }), "Matching completion accepted after commitment")
	check(not Service.SetDribbleCutIntent(player, cut), "Old sequence cannot restart after cancel")
	check(not marker("Strike", "L"), "Late marker after cancellation rejected")
	character:SetAttribute("IsSprinting", false)
	task.wait(0.14)
	check(not Service.SetDribbleCutIntent(player, { cut = "FrontLeft", cutId = 2, direction = Vector3.zAxis, character = character }), "Expired sprint context cannot start a cut")
	return { checks = checks, status = "PASS" }
end

