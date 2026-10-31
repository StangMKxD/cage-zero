--!strict
-- E passes; mouse buttons shoot. Release predicts the swing immediately; server owns contact and ball velocity.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Provider=game:GetService("KeyframeSequenceProvider")
local Shared=RS:WaitForChild("Shared")
local Config=require(Shared.configs.ShotConfigs)
local Actions=require(Shared.configs.FootballActionConfigs)
local Rules=require(Shared.ShotRules)
local Timing=require(Shared.FootballActionRules)
local Animation=require(Shared.FootballAnimation)
local player=Players.LocalPlayer
local Controller={}
local initialized=false
local serial=0
local char: Model?=nil
local held: any=nil
local kind="Shot"
local curveSide=1
local beganAt=0
local lastAimSent=0
local shownId: number?=nil
local tracks={}
local ids={}
local chargeTrack: AnimationTrack?=nil
local releaseTrack: AnimationTrack?=nil
local connections={}
local generation=0
local label: TextLabel?=nil
local function remote(): RemoteEvent return RS.CageZeroRemotes.BallActionRequest end
local function stopCharge()
 for _,set in tracks do for _,key in {"standing","moving"} do if set[key] then set[key]:Stop(0.04) end end end
 chargeTrack=nil
end
local function cancel()
 if char and (held or char:GetAttribute("ShotActive")) then remote():FireServer({action=kind,phase="Cancel",id=serial}) end
 held=nil;stopCharge()
 if releaseTrack then releaseTrack:Stop(0.1) end
 if char then char:SetAttribute("ShotCharging",false);char:SetAttribute("ShotActive",false) end
end
local function updateCharge(restart: boolean)
 if not char then return end
 local hum=char:FindFirstChildOfClass("Humanoid");local root=hum and hum.RootPart
 local moving=hum and (hum.MoveDirection.Magnitude>0.1 or root and Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude>1.5)
 local set=tracks[kind];local nextTrack=set and set[if moving then "moving" else "standing"]
 if not nextTrack or (not restart and nextTrack==chargeTrack and nextTrack.IsPlaying) then return end
 local phase=if restart or not chargeTrack then 0 else math.min(chargeTrack.TimePosition,Actions.ChargeEntrySec)
 if chargeTrack then chargeTrack:Stop(0.12) end
 chargeTrack=nextTrack;nextTrack:Play(0.12,1,if phase>=Actions.ChargeEntrySec then 0 else 1);nextTrack.TimePosition=phase
end
local function releaseVisual(stamp: number?)
 stopCharge()
 if not char then return end
 releaseTrack=tracks[kind] and tracks[kind].release
 if releaseTrack then
  char:SetAttribute("ShotActive",true);releaseTrack:Play(0.06)
  if stamp then releaseTrack.TimePosition=math.clamp(workspace:GetServerTimeNow()-stamp,0,Timing.Duration(kind)) end
 end
end
local function bind(character: Model)
 cancel();generation+=1;local gen=generation
 for _,c in connections do c:Disconnect() end;table.clear(connections)
 for _,set in tracks do for _,t in set do t:Destroy() end end;table.clear(tracks)
 releaseTrack=nil;chargeTrack=nil
 char=character;shownId=nil
 local hum=character:WaitForChild("Humanoid",10)
 local animator=hum and hum:WaitForChild("Animator",5)
 if not animator or generation~=gen then return end
 for _,action in {"Shot","Pass"} do
  local config=Actions[action]
  if not ids[action] then
   if not Run:IsStudio() then warn("[Football] Published animation IDs required");return end
   local options={
    release={start=config.HoldAt,finish=config.EndSource,rate=config.Rate,loop=false,priority=Enum.AnimationPriority.Action2},
    standing={finish=config.HoldAt,rate=config.HoldAt/Actions.ChargeEntrySec,loop=false,priority=Enum.AnimationPriority.Action2},
    moving={finish=config.HoldAt,rate=config.HoldAt/Actions.ChargeEntrySec,loop=false,priority=Enum.AnimationPriority.Action2,movingCharge=true},
   }
   ids[action]={}
   for name,opt in options do local seq=Animation.Build(action,opt);seq.Name=action.."_"..name
    ids[action][name]=Provider:RegisterKeyframeSequence(seq);seq:Destroy() end
  end
  tracks[action]={}
  for name,id in ids[action] do local a=Instance.new("Animation");a.AnimationId=id;a.Name=action.."_"..name
   local t=animator:LoadAnimation(a);a:Destroy();t.Priority=Enum.AnimationPriority.Action2;t.Looped=false;tracks[action][name]=t end
 end
 table.insert(connections,hum.Died:Connect(cancel))
 table.insert(connections,character:GetAttributeChangedSignal("ServerShotPhase"):Connect(function()
  if char~=character or character:GetAttribute("ServerShotId")~=serial then return end
  local phase=character:GetAttribute("ServerShotPhase")
  if phase=="Windup" and shownId~=serial then
   shownId=serial;kind=character:GetAttribute("ServerShotKind") or kind
   releaseVisual(character:GetAttribute("ServerShotStart"))
  elseif phase=="Cancelled" or phase=="Rejected" then cancel()

  end
 end))
end
local function inputKey(input: InputObject): any
 return if input.UserInputType==Enum.UserInputType.Keyboard then input.KeyCode else input.UserInputType
end
function Controller.Init()
 if initialized then return end;initialized=true
 local gui=Instance.new("ScreenGui");gui.Name="ShotChargeHUD";gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
 local text=Instance.new("TextLabel");text.Size=UDim2.fromOffset(220,30);text.Position=UDim2.new(0.5,-110,0.75,0)
 text.BackgroundTransparency=0.2;text.BackgroundColor3=Color3.fromRGB(18,22,28);text.TextColor3=Color3.fromRGB(255,230,140);text.TextSize=18;text.Visible=false;text.Parent=gui;label=text
 player.CharacterAdded:Connect(function(c) task.spawn(bind,c) end);if player.Character then task.spawn(bind,player.Character) end
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and held==Enum.UserInputType.MouseButton2 then
   if input.KeyCode==Enum.KeyCode.A then curveSide=-1 elseif input.KeyCode==Enum.KeyCode.D then curveSide=1 end
   return
  end
  if processed or UIS:GetFocusedTextBox() or held then return end
  local key=inputKey(input)
  if key~=Enum.KeyCode.E and key~=Enum.UserInputType.MouseButton1 and key~=Enum.UserInputType.MouseButton2 then return end
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  if not char or not hum or hum.Health<=0 or hum.FloorMaterial==Enum.Material.Air or char:GetAttribute("ShotActive")==true then return end
  kind=if key==Enum.KeyCode.E then "Pass" else "Shot"
  curveSide=if UIS:IsKeyDown(Enum.KeyCode.A) then -1 else 1
  if not tracks[kind] then return end
  serial+=1;held=key;beganAt=os.clock();lastAimSent=0;char:SetAttribute("ShotCharging",true);updateCharge(true)
  local camera=workspace.CurrentCamera
  remote():FireServer({action=kind,phase="Begin",id=serial,aim=camera and Rules.Aim(camera.CFrame.LookVector)})
 end)
 UIS.InputEnded:Connect(function(input)
  if not held or inputKey(input)~=held then return end
  local curve=if held==Enum.UserInputType.MouseButton2 then curveSide else 0
  held=nil
  local camera=workspace.CurrentCamera;local aim=camera and Rules.Aim(camera.CFrame.LookVector)
  if not char or not aim or UIS:GetFocusedTextBox() then cancel();return end
  char:SetAttribute("ShotCharging",false);char:SetAttribute("ShotVisualAim",aim)
  shownId=serial;releaseVisual(nil)
  remote():FireServer({action=kind,phase="Release",id=serial,aim=aim,curve=curve})
 end)
 UIS.WindowFocusReleased:Connect(cancel)
 Run.PreAnimation:Connect(function()
  if held and chargeTrack and chargeTrack.IsPlaying and chargeTrack.TimePosition>=Actions.ChargeEntrySec then
   chargeTrack.TimePosition=Actions.ChargeEntrySec;chargeTrack:AdjustSpeed(0)
  end
 end)
 Run.RenderStepped:Connect(function()
  if held and char then updateCharge(false) end
  if held and char and workspace.CurrentCamera then
   local aim=Rules.Aim(workspace.CurrentCamera.CFrame.LookVector)
   if aim then
    char:SetAttribute("ShotChargeAim",aim)
    local now=os.clock()
    if now-lastAimSent>=0.1 then lastAimSent=now;remote():FireServer({action=kind,phase="Aim",id=serial,aim=aim}) end
   end
  end
  if held and (not char or os.clock()-beganAt>Config.ChargeTimeoutSec) then cancel() end
  if char and char:GetAttribute("ShotActive")==true and releaseTrack and not releaseTrack.IsPlaying then char:SetAttribute("ShotActive",false) end
  text.Visible=held~=nil
  if held then text.Text=string.format("%s %d%%",if kind=="Pass" then "ส่ง" else "ยิง",math.clamp((os.clock()-beganAt)/Timing.MaxChargeSec(kind),0,1)*100) end
 end)
end
return Controller


--[============[
Previous behavior retained at Owner request (immediate release / no reverse action).
--!strict
-- E passes; mouse buttons shoot. Server owns charge time, waiting, contact and ball velocity.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Provider=game:GetService("KeyframeSequenceProvider")
local Shared=RS:WaitForChild("Shared")
local Config=require(Shared.configs.ShotConfigs)
local Actions=require(Shared.configs.FootballActionConfigs)
local Rules=require(Shared.ShotRules)
local Timing=require(Shared.FootballActionRules)
local Animation=require(Shared.FootballAnimation)
local player=Players.LocalPlayer
local Controller={}
local initialized=false
local serial=0
local char: Model?=nil
local held: any=nil
local kind="Shot"
local beganAt=0
local pending=false
local shownId: number?=nil
local tracks={}
local ids={}
local chargeTrack: AnimationTrack?=nil
local releaseTrack: AnimationTrack?=nil
local connections={}
local generation=0
local label: TextLabel?=nil
local function remote(): RemoteEvent return RS.CageZeroRemotes.BallActionRequest end
local function stopCharge()
 for _,set in tracks do for _,key in {"standing","moving"} do if set[key] then set[key]:Stop(0.12) end end end
 chargeTrack=nil
end
local function cancel()
 if char and (held or pending or char:GetAttribute("ShotActive")) then remote():FireServer({action=kind,phase="Cancel",id=serial}) end
 held=nil;pending=false;stopCharge()
 if releaseTrack then releaseTrack:Stop(0.1) end
 if char then char:SetAttribute("ShotCharging",false);char:SetAttribute("ShotActive",false) end
end
local function updateCharge(restart: boolean)
 if not char then return end
 local hum=char:FindFirstChildOfClass("Humanoid");local root=hum and hum.RootPart
 local moving=hum and (hum.MoveDirection.Magnitude>0.1 or root and Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude>1.5)
 local set=tracks[kind];local nextTrack=set and set[if moving then "moving" else "standing"]
 if not nextTrack or (not restart and nextTrack==chargeTrack and nextTrack.IsPlaying) then return end
 local phase=if restart or not chargeTrack then 0 else math.min(chargeTrack.TimePosition,Actions.ChargeEntrySec)
 if chargeTrack then chargeTrack:Stop(0.12) end
 chargeTrack=nextTrack;nextTrack:Play(0.12,1,if phase>=Actions.ChargeEntrySec then 0 else 1);nextTrack.TimePosition=phase
end
local function releaseVisual(stamp: number?)
 stopCharge();pending=false
 if not char then return end
 releaseTrack=tracks[kind] and tracks[kind].release
 if releaseTrack then
  char:SetAttribute("ShotActive",true);releaseTrack:Play(0.08)
  if stamp then releaseTrack.TimePosition=math.clamp(workspace:GetServerTimeNow()-stamp,0,Timing.Duration(kind)) end
 end
end
local function bind(character: Model)
 cancel();generation+=1;local gen=generation
 for _,c in connections do c:Disconnect() end;table.clear(connections)
 for _,set in tracks do for _,t in set do t:Destroy() end end;table.clear(tracks)
 releaseTrack=nil;chargeTrack=nil
 char=character;shownId=nil
 local hum=character:WaitForChild("Humanoid",10)
 local animator=hum and hum:WaitForChild("Animator",5)
 if not animator or generation~=gen then return end
 for _,action in {"Shot","Pass"} do
  local config=Actions[action]
  if not ids[action] then
   if not Run:IsStudio() then warn("[Football] Published animation IDs required");return end
   local options={
    release={start=config.HoldAt,finish=config.EndSource,rate=config.Rate,loop=false,priority=Enum.AnimationPriority.Action2},
    standing={finish=config.HoldAt,rate=config.HoldAt/Actions.ChargeEntrySec,loop=false,priority=Enum.AnimationPriority.Action2},
    moving={finish=config.HoldAt,rate=config.HoldAt/Actions.ChargeEntrySec,loop=false,priority=Enum.AnimationPriority.Action2,movingCharge=true},
   }
   ids[action]={}
   for name,opt in options do local seq=Animation.Build(action,opt);seq.Name=action.."_"..name
    ids[action][name]=Provider:RegisterKeyframeSequence(seq);seq:Destroy() end
  end
  tracks[action]={}
  for name,id in ids[action] do local a=Instance.new("Animation");a.AnimationId=id;a.Name=action.."_"..name
   local t=animator:LoadAnimation(a);a:Destroy();t.Priority=Enum.AnimationPriority.Action2;t.Looped=false;tracks[action][name]=t end
 end
 table.insert(connections,hum.Died:Connect(cancel))
 table.insert(connections,character:GetAttributeChangedSignal("ServerShotPhase"):Connect(function()
  if char~=character or character:GetAttribute("ServerShotId")~=serial then return end
  local phase=character:GetAttribute("ServerShotPhase")
  if phase=="Windup" and shownId~=serial then
   shownId=serial;kind=character:GetAttribute("ServerShotKind") or kind
   releaseVisual(character:GetAttribute("ServerShotStart"))
  elseif phase=="Cancelled" or phase=="Rejected" then cancel()
  elseif phase=="Whiff" and pending then releaseVisual(nil)
  end
 end))
end
local function inputKey(input: InputObject): any
 return if input.UserInputType==Enum.UserInputType.Keyboard then input.KeyCode else input.UserInputType
end
function Controller.Init()
 if initialized then return end;initialized=true
 local gui=Instance.new("ScreenGui");gui.Name="ShotChargeHUD";gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
 local text=Instance.new("TextLabel");text.Size=UDim2.fromOffset(220,30);text.Position=UDim2.new(0.5,-110,0.75,0)
 text.BackgroundTransparency=0.2;text.BackgroundColor3=Color3.fromRGB(18,22,28);text.TextColor3=Color3.fromRGB(255,230,140);text.TextSize=18;text.Visible=false;text.Parent=gui;label=text
 player.CharacterAdded:Connect(function(c) task.spawn(bind,c) end);if player.Character then task.spawn(bind,player.Character) end
 UIS.InputBegan:Connect(function(input,processed)
  if processed or UIS:GetFocusedTextBox() or held or pending then return end
  local key=inputKey(input)
  if key~=Enum.KeyCode.E and key~=Enum.UserInputType.MouseButton1 and key~=Enum.UserInputType.MouseButton2 then return end
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  if not char or not hum or hum.Health<=0 or hum.FloorMaterial==Enum.Material.Air or char:GetAttribute("ShotActive")==true then return end
  kind=if key==Enum.KeyCode.E then "Pass" else "Shot"
  if not tracks[kind] then return end
  serial+=1;held=key;beganAt=os.clock();char:SetAttribute("ShotCharging",true);updateCharge(true)
  remote():FireServer({action=kind,phase="Begin",id=serial})
 end)
 UIS.InputEnded:Connect(function(input)
  if not held or inputKey(input)~=held then return end
  local curve=if held==Enum.UserInputType.MouseButton2 then (if UIS:IsKeyDown(Enum.KeyCode.A) then -1 else 1) else 0
  held=nil;pending=true
  local camera=workspace.CurrentCamera;local aim=camera and Rules.Aim(camera.CFrame.LookVector)
  if not char or not aim or UIS:GetFocusedTextBox() then cancel();return end
  char:SetAttribute("ShotCharging",false);char:SetAttribute("ShotVisualAim",aim)
  remote():FireServer({action=kind,phase="Release",id=serial,aim=aim,curve=curve})
 end)
 UIS.WindowFocusReleased:Connect(cancel)
 Run.PreAnimation:Connect(function()
  if (held or pending) and chargeTrack and chargeTrack.IsPlaying and chargeTrack.TimePosition>=Actions.ChargeEntrySec then
   chargeTrack.TimePosition=Actions.ChargeEntrySec;chargeTrack:AdjustSpeed(0)
  end
 end)
 Run.RenderStepped:Connect(function()
  if (held or pending) and char then updateCharge(false) end
  if held and char and workspace.CurrentCamera then char:SetAttribute("ShotChargeAim",workspace.CurrentCamera.CFrame.LookVector) end
  if (held or pending) and (not char or os.clock()-beganAt>Config.ChargeTimeoutSec+Actions.ReleaseWaitSec) then cancel() end
  if char and char:GetAttribute("ShotActive")==true and releaseTrack and not releaseTrack.IsPlaying then char:SetAttribute("ShotActive",false) end
  text.Visible=held~=nil or pending
  if pending then text.Text="รอบอลเข้าเท้า" elseif held then text.Text=string.format("%s %d%%",if kind=="Pass" then "ส่ง" else "ยิง",math.clamp((os.clock()-beganAt)/Config.MaxChargeSec,0,1)*100) end
 end)
end
return Controller

--[========[
Previous implementation retained at Owner request.
--!strict
-- Charge is measured by the server. Animation follows its accepted release timestamp.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Provider = game:GetService("KeyframeSequenceProvider")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.configs.ShotConfigs)
local Rules = require(Shared.ShotRules)
local ClipData = require(script.Parent.Parent.character.DribbleClipData)
local ChargeClipData = require(script.Parent.Parent.character.ShotChargeClipData)
local player = Players.LocalPlayer
local Controller = {}
local initialized = false
local serial = 0
local held: Enum.UserInputType? = nil
local beganAt = 0
local character: Model? = nil
local track: AnimationTrack? = nil
local animationId: string? = nil
local chargeAnimationId: string? = nil
local movingChargeAnimationId: string? = nil
local chargeTracks: {AnimationTrack} = {}
local chargeTrack: AnimationTrack? = nil
local shownId: number? = nil
local pendingRelease = false
local presentationOnly = false
local generation = 0
local connections: {RBXScriptConnection} = {}
local gauge: TextLabel? = nil

local function remote(): RemoteEvent
	return Shared.Parent.CageZeroRemotes.BallActionRequest :: RemoteEvent
end

local function stopChargeTracks(fade: number)
	for _, t in chargeTracks do t:Stop(fade) end
end

local function updateChargePresentation(char: Model, restart: boolean)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = hum and hum.RootPart
	local velocity = root and root.AssemblyLinearVelocity or Vector3.zero
	local moving = hum ~= nil and (hum.MoveDirection.Magnitude > 0.1 or Vector3.new(velocity.X,0,velocity.Z).Magnitude > 1.5)
	local nextTrack = chargeTracks[if moving then 2 else 1]
	if not nextTrack or (not restart and nextTrack == chargeTrack and nextTrack.IsPlaying) then return end
	local phase = if not restart and chargeTrack then math.min(chargeTrack.TimePosition,Config.ChargeHoldAt) else 0
	if chargeTrack then chargeTrack:Stop(Config.ChargeFadeSec) end
	chargeTrack = nextTrack
	nextTrack:Play(Config.ChargeFadeSec,1,if phase >= Config.ChargeHoldAt then 0 else 1)
	nextTrack.TimePosition = phase
end

local function cancel()
	if not presentationOnly and character and (held or pendingRelease or character:GetAttribute("ShotActive") == true) then
		remote():FireServer({action="Shot", phase="Cancel", id=serial})
	end
	held = nil
	pendingRelease = false
	presentationOnly=false
	if track then track:Stop(0.1) end
	stopChargeTracks(0.1)
	if character then
		character:SetAttribute("ShotActive", false)
		character:SetAttribute("ShotCharging", false)
	end
	if gauge then gauge.Visible = false end
end

local function playShotPresentation(char: Model, stamp: number?)
 if not track then return end
 stopChargeTracks(Config.ChargeFadeSec)
 char:SetAttribute("ShotActive",true)
 track:Play(Config.ChargeFadeSec)
 if stamp then track.TimePosition=math.clamp(workspace:GetServerTimeNow()-stamp,0,Config.Duration) end
end

local function bind(char: Model)
	cancel()
	generation += 1
	local gen = generation
	for _, c in connections do c:Disconnect() end
	table.clear(connections)
	if track then track:Destroy(); track = nil end
	for _, t in chargeTracks do t:Destroy() end
	table.clear(chargeTracks);chargeTrack=nil
	character = char
	shownId = nil
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	local animator = hum and hum:WaitForChild("Animator", 5) :: Animator?
	if generation ~= gen or not animator or not hum then return end
	if not animationId then
		if Config.AnimationId ~= "" then animationId = Config.AnimationId
		elseif RunService:IsStudio() then
			local seq = ClipData.BuildKeyframeSequence(Config.ClipName)
			assert(seq, "Shot sequence missing")
			animationId = Provider:RegisterKeyframeSequence(seq)
   local charge = ChargeClipData.Build(false)
   chargeAnimationId = Provider:RegisterKeyframeSequence(charge);charge:Destroy()
   local movingCharge = ChargeClipData.Build(true)
   movingChargeAnimationId = Provider:RegisterKeyframeSequence(movingCharge);movingCharge:Destroy()
			seq:Destroy()
		else warn("[Shot] Published animation ID required"); return end
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = animationId :: string
	anim.Name = Config.ClipName
	track = animator:LoadAnimation(anim)
	anim:Destroy()
	track.Priority = Enum.AnimationPriority.Action2
	track.Looped = false
	for i, id in {chargeAnimationId, movingChargeAnimationId} do
		if id then
			local anim = Instance.new("Animation")
			anim.Name = if i==1 then Config.ChargeClipName else Config.MovingChargeClipName
			anim.AnimationId = id
			local loaded = animator:LoadAnimation(anim);anim:Destroy()
			loaded.Priority = Enum.AnimationPriority.Action2;loaded.Looped=false
			chargeTracks[i] = loaded
		end
	end
	table.insert(connections, track:GetMarkerReachedSignal("BlendOut"):Connect(function()
		if track then track:AdjustWeight(0,0.08) end
	end))
	table.insert(connections, hum.Died:Connect(cancel))
	table.insert(connections, char:GetAttributeChangedSignal("ServerShotPhase"):Connect(function()
		if character ~= char then return end
		local phase = char:GetAttribute("ServerShotPhase")
		local id = char:GetAttribute("ServerShotId")
		if phase == "Windup" and id == serial and shownId ~= id and track then
			pendingRelease = false
			shownId = id :: number
			local stamp=char:GetAttribute("ServerShotStart")
			playShotPresentation(char,if typeof(stamp)=="number" then stamp else nil)
		elseif phase == "Cancelled" or phase == "Rejected" then
			if held then presentationOnly=true;pendingRelease=false else cancel() end
		end
	end))
end

function Controller.Init()
	if initialized then return end
	initialized = true
	local gui = Instance.new("ScreenGui")
	gui.Name = "ShotChargeHUD"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(180, 30)
	label.Position = UDim2.new(0.5, -90, 0.75, 0)
	label.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.fromRGB(255, 230, 140)
	label.TextSize = 18
	label.Visible = false
	label.Parent = gui
	gauge = label
	player.CharacterAdded:Connect(function(char) task.spawn(bind, char) end)
	if player.Character then task.spawn(bind, player.Character) end
	UIS.InputBegan:Connect(function(input, processed)
		if processed or UIS:GetFocusedTextBox() or held then return end
		local key = input.UserInputType
		if key ~= Enum.UserInputType.MouseButton1 and key ~= Enum.UserInputType.MouseButton2 then return end
		local char = character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not char or not hum or hum.Health <= 0 or not track or track.Length <= 0
			or char:GetAttribute("ShotActive") == true
			or hum.FloorMaterial == Enum.Material.Air then return end
		serial += 1
		presentationOnly=char:GetAttribute("IsBallCarrier")~=true
		held, beganAt = key, os.clock()
		char:SetAttribute("ShotCharging", true)
		updateChargePresentation(char,true)
		if not presentationOnly then remote():FireServer({action="Shot", phase="Begin", id=serial}) end
	end)
	UIS.InputEnded:Connect(function(input)
		if not held or input.UserInputType ~= held then return end
		local curve = if held == Enum.UserInputType.MouseButton2
			then (if UIS:IsKeyDown(Enum.KeyCode.A) then -1 else 1) else 0
		held = nil
		pendingRelease = true
		if character then character:SetAttribute("ShotCharging", false) end
		local camera = workspace.CurrentCamera
		local aim = camera and Rules.Aim(camera.CFrame.LookVector)
		if not aim or UIS:GetFocusedTextBox() then cancel(); remote():FireServer({action="Shot",phase="Cancel",id=serial}); return end
		if character then character:SetAttribute("ShotVisualAim",aim) end
  if presentationOnly or not character or character:GetAttribute("IsBallCarrier")~=true then
   pendingRelease=false
   if character then playShotPresentation(character,nil) end
  else remote():FireServer({action="Shot",phase="Release",id=serial,aim=aim,curve=curve}) end
	end)
	UIS.WindowFocusReleased:Connect(cancel)
	RunService.PreAnimation:Connect(function()
		if (held or pendingRelease) and chargeTrack and chargeTrack.IsPlaying and chargeTrack.TimePosition >= Config.ChargeHoldAt then
			chargeTrack.TimePosition=Config.ChargeHoldAt;chargeTrack:AdjustSpeed(0)
		end
	end)
	RunService.RenderStepped:Connect(function()
		local char = character
		if held and char then updateChargePresentation(char,false) end
		if held and char and workspace.CurrentCamera then
			char:SetAttribute("ShotChargeAim", workspace.CurrentCamera.CFrame.LookVector)
		end
		if held and (not char
			or os.clock()-beganAt > Config.ChargeTimeoutSec) then cancel() end
		if char and char:GetAttribute("ShotActive") == true and track then
			if not track.IsPlaying or track.TimePosition >= Config.Duration-0.01 then char:SetAttribute("ShotActive",false) end
		end
		label.Visible = held ~= nil
		if held then label.Text = string.format("ยิง %d%%", math.clamp((os.clock()-beganAt)/Config.MaxChargeSec,0,1)*100) end
	end)
end

return Controller

--[====[
Retired/replaced code retained as comments at Owner request (2026-10-30).
Original complete source is also in the external backup.

local Cut = require(script.Parent.DribbleCutController)

-- Previous section --
			Cut.Cancel()

-- Previous section --
			or char:GetAttribute("DribbleCutActive") == true or hum.FloorMaterial == Enum.Material.Air then return end
]====]

--[====[
Retired/replaced code retained as comments at Owner request (2026-10-30).
Original complete source is also in the external backup.

	if chargeTrack then chargeTrack:Stop(0.1) end

-- Previous section --
 if chargeTrack then chargeTrack:Stop(0.06) end

-- Previous section --
 track:Play(0.06)

-- Previous section --
	if chargeTrack then chargeTrack:Destroy();chargeTrack=nil end

-- Previous section --
   seq.Name = Config.ClipName.."_ChargeUpperBody"
   for _,pose in seq:GetDescendants() do
    if pose:IsA("Pose") and (pose.Name=="LowerTorso" or pose.Name:find("Leg") or pose.Name:find("Foot")) then pose.Weight=0 end
   end
   chargeAnimationId=Provider:RegisterKeyframeSequence(seq)

-- Previous section --
	if chargeAnimationId then
		local charge=Instance.new("Animation");charge.Name="ShotChargeUpperBody";charge.AnimationId=chargeAnimationId
		chargeTrack=animator:LoadAnimation(charge);chargeTrack.Priority=Enum.AnimationPriority.Action2;charge:Destroy()

-- Previous section --
		if chargeTrack then chargeTrack:Play(0.1,1,0);chargeTrack.TimePosition=0 end
]====]

]========]

]============]
