--!strict
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config=require(Shared.configs.KickHitboxConfigs)
local Hitbox=require(Shared.KickHitbox)
local Constants=require(Shared.Constants)
local Controller={}
local initialized=false
function Controller.Init()
	if initialized or not Config.DebugVisible then return end;initialized=true
	local folder=Instance.new("Folder");folder.Name="KickRangePreview_Local";folder.Parent=workspace
	local box=Instance.new("Part");box.Name="FrontKickRange";box.Size=Config.Size;box.Anchored=true
	box.CanCollide=false;box.CanTouch=false;box.CanQuery=false;box.CastShadow=false;box.Transparency=0.86;box.Material=Enum.Material.Neon;box.Parent=folder
	local outline=Instance.new("SelectionBox");outline.Adornee=box;outline.LineThickness=0.035;outline.SurfaceTransparency=1;outline.Parent=box
	local point=Instance.new("Part");point.Name="KickContactPoint";point.Shape=Enum.PartType.Ball;point.Size=Vector3.one*0.28
	point.Anchored=true;point.CanCollide=false;point.CanTouch=false;point.CanQuery=false;point.Material=Enum.Material.Neon;point.Parent=folder
	local billboard=Instance.new("BillboardGui");billboard.Adornee=box;billboard.Size=UDim2.fromOffset(190,32);billboard.StudsOffset=Vector3.new(0,2.5,0);billboard.AlwaysOnTop=true;billboard.Parent=box
	local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.TextSize=17;label.TextStrokeTransparency=0.35;label.Parent=billboard
	local player=Players.LocalPlayer
	local ball: BasePart?=nil
	local searchAt=0
	Run.RenderStepped:Connect(function()
		local char=player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid");local root=hum and hum.RootPart
		local owned=char~=nil and char:GetAttribute("IsBallCarrier")==true
		local phase=char and char:GetAttribute("ServerShotPhase")
		local arranging=owned and (char:GetAttribute("ShotCharging")==true or char:GetAttribute("ShotActive")==true or phase=="Charging" or phase=="Windup")
		local visible=root~=nil and hum~=nil and hum.Health>0 and (not owned or arranging)
		billboard.Enabled=visible
		box.Transparency=if visible then 0.86 else 1
		outline.Visible=visible
		if not visible then point.Transparency=1;return end
		local aim=if arranging then (if char:GetAttribute("ShotCharging")==true then char:GetAttribute("ShotChargeAim") else char:GetAttribute("ShotVisualAim")) or char:GetAttribute("ServerShotAim") else nil
		if typeof(aim)~="Vector3" then aim=nil end
		box.CFrame=Hitbox.Frame(root.CFrame,aim)
		if (not ball or not ball.Parent) and os.clock()>=searchAt then
			searchAt=os.clock()+1
			local found=workspace:FindFirstChild(Constants.BALL_PART_NAME or "CageMatchBall")
			ball=if found and found:IsA("BasePart") then found else nil
		end
		local owner=ball and ball:GetAttribute("PossessorUserId")
		local contact=ball and (arranging or owner==nil or owner==0) and Hitbox.Evaluate(root.CFrame,ball.Position,aim)
		local color=if contact then Color3.fromRGB(90,230,130) else Color3.fromRGB(255,180,65)
		box.Color=color;outline.Color3=color;label.TextColor3=color;point.Color=color
		point.Transparency=if contact then 0 else 1
		if contact then point.Position=contact.point end
		label.Text=if arranging then "จัดบอล · เท้าขวา" elseif contact then string.format("เท้าขวา · แรง %d%%",math.round(contact.powerScale*100)) else "ระยะเตะเท้าขวา"
	end)
end
return Controller
