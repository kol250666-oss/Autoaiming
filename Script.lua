--自瞄通用脚本 使用黑曜石UI
--功能: 自瞄(非静默) NPC/玩家 头部/胸部 FOV圈 ESP透视
local P=game:GetService("Players")local R=game:GetService("RunService")local U=game:GetService("UserInputService")local W=game:GetService("Workspace")local L=P.LocalPlayer

--加载黑曜石UI
local repo="https://raw.githubusercontent.com/ATLASTEAM01/Obsidian/main/"
local Library
local ok1,lib=pcall(function()return loadstring(game:HttpGet(repo.."Library.lua"))()end)
if ok1 and lib then Library=lib else return end
local ok2,tm=pcall(function()return loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()end)
local ok3,sm=pcall(function()return loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()end)
local ThemeManager=ok2 and tm or nil
local SaveManager=ok3 and sm or nil
local Options=Library.Options
local Toggles=Library.Toggles

local C=W.CurrentCamera or W:FindFirstChildWhichIsA("Camera")
W:GetPropertyChangedSignal("CurrentCamera"):Connect(function()C=W.CurrentCamera or W:FindFirstChildWhichIsA("Camera")end)

--Drawing安全创建
local function nd(t)local o,p=pcall(function()return Drawing.new(t)end)return o and p or nil end

--颜色预设
local CP={["白色"]=Color3.fromRGB(255,255,255),["红色"]=Color3.fromRGB(255,60,60),["绿色"]=Color3.fromRGB(60,255,100),["蓝色"]=Color3.fromRGB(60,150,255),["黄色"]=Color3.fromRGB(255,230,0),["紫色"]=Color3.fromRGB(180,60,255),["青色"]=Color3.fromRGB(0,255,230),["粉色"]=Color3.fromRGB(255,100,200),["橙色"]=Color3.fromRGB(255,150,0),["灰色"]=Color3.fromRGB(150,150,150)}

--全局配置
local K={Aim={En=false,FOV=150,Dist=500,TP="Head",WC=true,TC=true,Tgt="Player",FF=true,FY=200,Sm=false,Sp=0.15,Pd=true,PS=0.2},FC={En=false,Cl=Color3.fromRGB(255,255,255),Tr=50,Fl=false,Th=1},ESP={En=false,Bx=true,HB=true,Nm=true,Ds=true,Tr=false,Sk=false,VC=false,TC=true,MD=1000,Cl=Color3.fromRGB(60,255,100),TCe=false,EVC=Color3.fromRGB(255,60,60),ENC=Color3.fromRGB(150,150,150),MVC=Color3.fromRGB(60,150,255),MNC=Color3.fromRGB(150,150,150),PE=true,PIC=Color3.fromRGB(255,60,60),NPC=false,NC=Color3.fromRGB(255,150,0),NIC=Color3.fromRGB(150,150,150),BE=false,BC=Color3.fromRGB(255,230,0),BIC=Color3.fromRGB(150,150,150)}}

--骨骼表
local Bn={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local B6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

--工具函数
local function isAlive(c)if not c then return false end local h=c:FindFirstChildOfClass("Humanoid")return h~=nil and h.Health>0 end
local function getRoot(c)if not c then return nil end return c:FindFirstChild("HumanoidRootPart")or c:FindFirstChild("Torso")or c:FindFirstChild("LowerTorso")end
local function getHead(c)return c and c:FindFirstChild("Head")end
local function getChest(c)if not c then return nil end return c:FindFirstChild("UpperTorso")or c:FindFirstChild("Torso")end
local function isTeammateAim(p)if not K.Aim.TC then return false end if not L.Team or not p.Team then return false end return p.Team==L.Team end
local function isTeammateESP(p)if not K.ESP.TC then return false end if not L.Team or not p.Team then return false end return p.Team==L.Team end
local function isBot(m)local n=m.Name:lower()return n:find("bot")~=nil end
local function isVisible(t,c)if not t then return false end local o=C.CFrame.Position local d=t.Position-o local r=RaycastParams.new()r.FilterDescendantsInstances={L.Character,c}r.FilterType=Enum.RaycastFilterType.Exclude r.RespectCanCollide=true local h=W:Raycast(o,d,r)return not h or h.Instance:IsDescendantOf(c)end
local function getAimPoint()if K.Aim.FF then local v=C.ViewportSize return Vector2.new(v.X/2,K.Aim.FY)else return U:GetMouseLocation()end end

--==================== NPC缓存系统 ====================
local npcCache={}
local npcTimer=0
local function refreshNpcs()
npcCache={}
for _,m in ipairs(W:GetDescendants())do
if m:IsA("Model") and not P:GetPlayerFromCharacter(m)then
local h=m:FindFirstChildOfClass("Humanoid")
local r=m:FindFirstChild("HumanoidRootPart")or m:FindFirstChild("Torso")
if h and r and h.Health>0 then
npcCache[m]=true
end
end
end
end

--==================== 速度缓存(预判用) ====================
local velCache={}local velTimer=0
local function refreshVel()
for _,p in ipairs(P:GetPlayers())do
if p~=L and p.Character then
local r=getRoot(p.Character)
if r then
local key=p
if velCache[key]then
local dt=tick()-velCache[key].t
if dt>0 then velCache[key].vel=(r.Position-velCache[key].pos)/dt end
velCache[key].pos=r.Position velCache[key].t=tick()
else velCache[key]={pos=r.Position,vel=Vector3.zero,t=tick()}end
end
end
end
for m in pairs(npcCache)do
local r=getRoot(m)
if r then
if velCache[m]then
local dt=tick()-velCache[m].t
if dt>0 then velCache[m].vel=(r.Position-velCache[m].pos)/dt end
velCache[m].pos=r.Position velCache[m].t=tick()
else velCache[m]={pos=r.Position,vel=Vector3.zero,t=tick()}end
end
end end

--==================== 获取最佳目标(玩家+NPC) ====================
local function getTarget()
local cp,cd,cv=nil,math.huge,Vector3.zero
local a=getAimPoint()
local co=C.CFrame.Position

--扫描玩家
if K.Aim.Tgt=="Player" or K.Aim.Tgt=="Both"then
for _,p in ipairs(P:GetPlayers())do
if p~=L and isAlive(p.Character)and not isTeammateAim(p)then
local c=p.Character
local r=getRoot(c)local h=getHead(c)
if r and h then
local d3=(r.Position-co).Magnitude
if d3<=K.Aim.Dist then
local ck=r
if K.Aim.TP=="Head"then ck=h
elseif K.Aim.TP=="Chest"then ck=getChest(c)or r end
local sp,os2=C:WorldToViewportPoint(ck.Position)
if os2 then
local sd=(Vector2.new(sp.X,sp.Y)-a).Magnitude
if sd<=K.Aim.FOV and sd<cd then
local canSee=not K.Aim.WC or isVisible(ck,c)
if canSee then cp=ck cd=sd cv=(velCache[p]and velCache[p].vel)or Vector3.zero end
end
end
end
end
end
end
end

--扫描NPC
if K.Aim.Tgt=="NPC" or K.Aim.Tgt=="Both"then
for m in pairs(npcCache)do
if m.Parent and isAlive(m)then
local r=getRoot(m)local h=getHead(m)
if r and h then
local d3=(r.Position-co).Magnitude
if d3<=K.Aim.Dist then
local ck=r
if K.Aim.TP=="Head"then ck=h
elseif K.Aim.TP=="Chest"then ck=getChest(m)or r end
local sp,os2=C:WorldToViewportPoint(ck.Position)
if os2 then
local sd=(Vector2.new(sp.X,sp.Y)-a).Magnitude
if sd<=K.Aim.FOV and sd<cd then
local canSee=not K.Aim.WC or isVisible(ck,m)
if canSee then cp=ck cd=sd cv=(velCache[m]and velCache[m].vel)or Vector3.zero end
end
end
end
end
end
end
end

return cp,cv
end

--==================== FOV圈GUI ====================
local FG=Instance.new("ScreenGui")FG.Name="FOVGui"FG.IgnoreGuiInset=true FG.ResetOnSpawn=false FG.Parent=L:WaitForChild("PlayerGui")
local FF=Instance.new("Frame",FG)FF.AnchorPoint=Vector2.new(0.5,0.5)FF.Position=UDim2.new(0.5,0,0,K.Aim.FY)FF.Size=UDim2.fromOffset(K.Aim.FOV*2,K.Aim.FOV*2)FF.BackgroundTransparency=1 FF.Visible=false
Instance.new("UICorner",FF).CornerRadius=UDim.new(1,0)
local FS=Instance.new("UIStroke",FF)FS.Thickness=1 FS.Color=K.FC.Cl FS.Transparency=K.FC.Tr/100

--==================== ESP系统 ====================
local vCache={}local vTimer=0
local function refreshVis()
local cnt=0
for _,p in ipairs(P:GetPlayers())do if p~=L and p.Character then cnt=cnt+1
if cnt>20 then vCache[p]=false
else local char=p.Character local o=C.CFrame.Position local pts={"Head","UpperTorso","Torso","HumanoidRootPart"}local rp2=RaycastParams.new()rp2.FilterType=Enum.RaycastFilterType.Exclude rp2.FilterDescendantsInstances={L.Character,char}local v=false
for _,pn in ipairs(pts)do local pt=char:FindFirstChild(pn)if pt then local d=pt.Position-o local h=W:Raycast(o,d,rp2)if not h or(h.Position-pt.Position).Magnitude<5 then v=true break end end end
vCache[p]=v end end end end

local EO={}
local function ce()local e={}
e.BO={nd("Line"),nd("Line"),nd("Line"),nd("Line")}for _,l in ipairs(e.BO)do if l then l.Thickness=3 l.Color=Color3.fromRGB(0,0,0)l.Visible=false end end
e.B={nd("Line"),nd("Line"),nd("Line"),nd("Line")}for _,l in ipairs(e.B)do if l then l.Thickness=1 l.Visible=false end end
e.HO=nd("Line")if e.HO then e.HO.Thickness=4 e.HO.Color=Color3.fromRGB(0,0,0)e.HO.Visible=false end
e.HB=nd("Line")if e.HB then e.HB.Thickness=2 e.HB.Visible=false end
e.N=nd("Text")if e.N then e.N.Size=14 e.N.Center=true e.N.Outline=true e.N.Color=Color3.fromRGB(255,255,255)e.N.Visible=false end
e.D=nd("Text")if e.D then e.D.Size=13 e.D.Center=true e.D.Outline=true e.D.Color=Color3.fromRGB(200,200,200)e.D.Visible=false end
e.T=nd("Line")if e.T then e.T.Thickness=1 e.T.Visible=false end
e.S={}for i=1,14 do e.S[i]=nd("Line")if e.S[i]then e.S[i].Thickness=1 e.S[i].Visible=false end end
return e end
local function re(e)if not e then return end for _,l in ipairs(e.BO)do pcall(function()l:Remove()end)end for _,l in ipairs(e.B)do pcall(function()l:Remove()end)end for _,l in ipairs(e.S)do pcall(function()l:Remove()end)end for _,o in pairs({e.HO,e.HB,e.N,e.D,e.T})do pcall(function()o:Remove()end)end end
local function he(e)if not e then return end for _,l in ipairs(e.BO)do l.Visible=false end for _,l in ipairs(e.B)do l.Visible=false end for _,l in ipairs(e.S)do l.Visible=false end for _,o in pairs({e.HO,e.HB,e.N,e.D,e.T})do o.Visible=false end end
for _,p in ipairs(P:GetPlayers())do if p~=L then EO[p]=ce()end end
P.PlayerAdded:Connect(function(p)if p~=L then EO[p]=ce()end end)
P.PlayerRemoving:Connect(function(p)if EO[p]then re(EO[p])EO[p]=nil end end)

--NPC ESP对象池
local NPC_ESP={}
local NPC_POOL=30
for i=1,NPC_POOL do NPC_ESP[i]={obj=ce(),model=nil}end

--==================== 主渲染循环 ====================
R:BindToRenderStep("AimUniversal",Enum.RenderPriority.Camera.Value+1,function()
--FOV圈
local sf=K.FC.En FF.Visible=sf
FF.Size=UDim2.fromOffset(K.Aim.FOV*2,K.Aim.FOV*2)
local fpos=K.Aim.FF and UDim2.new(0.5,0,0,K.Aim.FY)or UDim2.new(0.5,0,0.5,0)
FF.Position=fpos FF.BackgroundColor3=K.FC.Cl FF.BackgroundTransparency=(K.FC.Fl and K.FC.Tr/100)or 1
FS.Color=K.FC.Cl FS.Thickness=K.FC.Th FS.Transparency=K.FC.Tr/100

--自瞄逻辑(非静默 直接移动摄像机)
if K.Aim.En then
local tgt,vel=getTarget()
if tgt then
local camPos=C.CFrame.Position
local aimPos=tgt.Position
--预判: 根据目标速度计算未来位置
if K.Aim.Pd then
aimPos=aimPos+vel*K.Aim.PS
end
if K.Aim.Sm and K.Aim.Sp<1 then
--平滑自瞄 插值
local targetCF=CFrame.new(camPos,aimPos)
C.CFrame=C.CFrame:Lerp(targetCF,K.Aim.Sp)
else
C.CFrame=CFrame.new(camPos,aimPos)
end
end
end

--ESP
if not K.ESP.En then for _,e in pairs(EO)do he(e)end for i=1,NPC_POOL do he(NPC_ESP[i].obj)end return end
local vp={}for _,p in ipairs(P:GetPlayers())do vp[p]=true end
for p,e in pairs(EO)do if not vp[p]then re(e)EO[p]=nil end end
local now=tick()
if now-vTimer>0.15 then vTimer=now refreshVis()end
if now-npcTimer>2 then npcTimer=now refreshNpcs()end
if now-velTimer>0.05 then velTimer=now refreshVel()end

local myChar=L.Character local myRoot=myChar and getRoot(myChar)

local function ue(p,e)
if p==L or not p.Parent then he(e)return end
if not K.ESP.PE then he(e)return end
local c=p.Character if not c or not isAlive(c)then he(e)return end
if K.ESP.TC and isTeammateESP(p)then he(e)return end
local r=getRoot(c)local h=getHead(c)local hu=c:FindFirstChildOfClass("Humanoid")
if not r or not h or not hu then he(e)return end
local dist3D=myRoot and(r.Position-myRoot.Position).Magnitude or(r.Position-C.CFrame.Position).Magnitude
if dist3D>K.ESP.MD then he(e)return end
local headPos=h.Position local feetPos=r.Position-Vector3.new(0,3,0)local topPos=headPos+Vector3.new(0,0.5,0)
local rs,ron=C:WorldToViewportPoint(r.Position)local hs=C:WorldToViewportPoint(topPos)local fs=C:WorldToViewportPoint(feetPos)
if not ron or rs.Z<=0 then he(e)return end

local vis=vCache[p]or false
local col=K.ESP.Cl
local isEnemy=L.Team and p.Team and p.Team~=L.Team
if K.ESP.TCe then if isEnemy then col=vis and K.ESP.EVC or K.ESP.ENC else col=vis and K.ESP.MVC or K.ESP.MNC end
elseif K.ESP.VC then col=vis and K.ESP.Cl or K.ESP.PIC end

local boxTop,boxBottom=hs.Y,fs.Y local boxH=math.abs(boxBottom-boxTop)local boxW=boxH*0.6 local cx=rs.X
if K.ESP.Bx then
e.B[1].From=Vector2.new(cx-boxW/2,boxTop)e.B[1].To=Vector2.new(cx+boxW/2,boxTop)
e.B[2].From=Vector2.new(cx+boxW/2,boxTop)e.B[2].To=Vector2.new(cx+boxW/2,boxBottom)
e.B[3].From=Vector2.new(cx+boxW/2,boxBottom)e.B[3].To=Vector2.new(cx-boxW/2,boxBottom)
e.B[4].From=Vector2.new(cx-boxW/2,boxBottom)e.B[4].To=Vector2.new(cx-boxW/2,boxTop)
e.BO[1].From=e.B[1].From e.BO[1].To=e.B[1].To e.BO[2].From=e.B[2].From e.BO[2].To=e.B[2].To e.BO[3].From=e.B[3].From e.BO[3].To=e.B[3].To e.BO[4].From=e.B[4].From e.BO[4].To=e.B[4].To
for i=1,4 do e.B[i].Color=col e.B[i].Visible=true e.BO[i].Visible=true end
else for i=1,4 do e.B[i].Visible=false e.BO[i].Visible=false end end

if K.ESP.HB then local hp=math.clamp(hu.Health/hu.MaxHealth,0,1)local hH=boxH*hp
e.HB.Visible=true e.HB.Color=Color3.fromHSV(hp/2.5,0.89,0.75)e.HB.From=Vector2.new(cx-boxW/2-6,boxBottom)e.HB.To=Vector2.new(cx-boxW/2-6,boxBottom-hH)
e.HO.Visible=true e.HO.From=Vector2.new(cx-boxW/2-6,boxTop)e.HO.To=Vector2.new(cx-boxW/2-6,boxBottom)
else e.HB.Visible=false e.HO.Visible=false end

if K.ESP.Nm then e.N.Visible=true e.N.Text=p.DisplayName e.N.Position=Vector2.new(cx,boxTop-18)e.N.Color=col else e.N.Visible=false end
if K.ESP.Ds then e.D.Visible=true e.D.Text=string.format("%.0f",dist3D).."m"e.D.Position=Vector2.new(cx,boxBottom+2)else e.D.Visible=false end
if K.ESP.Tr then local v=C.ViewportSize e.T.Visible=true e.T.From=Vector2.new(v.X/2,v.Y)e.T.To=Vector2.new(cx,boxBottom)e.T.Color=col else e.T.Visible=false end
if K.ESP.Sk then local bones=c:FindFirstChild("Torso")and B6 or Bn
for i,b in ipairs(bones)do if e.S[i]then local p1=c:FindFirstChild(b[1])local p2=c:FindFirstChild(b[2])if p1 and p2 then local s1,o1=C:WorldToViewportPoint(p1.Position)local s2,o2=C:WorldToViewportPoint(p2.Position)if o1 and o2 and s1.Z>0 and s2.Z>0 then e.S[i].From=Vector2.new(s1.X,s1.Y)e.S[i].To=Vector2.new(s2.X,s2.Y)e.S[i].Color=col e.S[i].Visible=true else e.S[i].Visible=false end else e.S[i].Visible=false end end end
for i=#bones+1,14 do if e.S[i]then e.S[i].Visible=false end end
else for i=1,14 do if e.S[i]then e.S[i].Visible=false end end end end

for p,e in pairs(EO)do ue(p,e)end

--NPC/Bot ESP渲染
local npcIdx=1
if K.ESP.NPC or K.ESP.BE then
for m in pairs(npcCache)do
if npcIdx>NPC_POOL then break end
local isB=isBot(m)
local showThis=(isB and K.ESP.BE)or(not isB and K.ESP.NPC)
if showThis and m.Parent and isAlive(m)then
local e=NPC_ESP[npcIdx].obj
local r=getRoot(m)local h=getHead(m)local hu=m:FindFirstChildOfClass("Humanoid")
if r and h and hu then
local dist3D=myRoot and(r.Position-myRoot.Position).Magnitude or(r.Position-C.CFrame.Position).Magnitude
if dist3D<=K.ESP.MD then
local headPos=h.Position local feetPos=r.Position-Vector3.new(0,3,0)local topPos=headPos+Vector3.new(0,0.5,0)
local rs,ron=C:WorldToViewportPoint(r.Position)local hs=C:WorldToViewportPoint(topPos)local fs=C:WorldToViewportPoint(feetPos)
if ron and rs.Z>0 then
local col,icol
if isB then col=K.ESP.BC icol=K.ESP.BIC else col=K.ESP.NC icol=K.ESP.NIC end
if K.ESP.VC then local visNpc=isVisible(h,m)col=visNpc and col or icol end
local boxTop,boxBottom=hs.Y,fs.Y local boxH=math.abs(boxBottom-boxTop)local boxW=boxH*0.6 local cx=rs.X
if K.ESP.Bx then
e.B[1].From=Vector2.new(cx-boxW/2,boxTop)e.B[1].To=Vector2.new(cx+boxW/2,boxTop)
e.B[2].From=Vector2.new(cx+boxW/2,boxTop)e.B[2].To=Vector2.new(cx+boxW/2,boxBottom)
e.B[3].From=Vector2.new(cx+boxW/2,boxBottom)e.B[3].To=Vector2.new(cx-boxW/2,boxBottom)
e.B[4].From=Vector2.new(cx-boxW/2,boxBottom)e.B[4].To=Vector2.new(cx-boxW/2,boxTop)
e.BO[1].From=e.B[1].From e.BO[1].To=e.B[1].To e.BO[2].From=e.B[2].From e.BO[2].To=e.B[2].To e.BO[3].From=e.B[3].From e.BO[3].To=e.B[3].To e.BO[4].From=e.B[4].From e.BO[4].To=e.B[4].To
for i=1,4 do e.B[i].Color=col e.B[i].Visible=true e.BO[i].Visible=true end
else for i=1,4 do e.B[i].Visible=false e.BO[i].Visible=false end end
if K.ESP.HB then local hp=math.clamp(hu.Health/hu.MaxHealth,0,1)local hH=boxH*hp
e.HB.Visible=true e.HB.Color=Color3.fromHSV(hp/2.5,0.89,0.75)e.HB.From=Vector2.new(cx-boxW/2-6,boxBottom)e.HB.To=Vector2.new(cx-boxW/2-6,boxBottom-hH)
e.HO.Visible=true e.HO.From=Vector2.new(cx-boxW/2-6,boxTop)e.HO.To=Vector2.new(cx-boxW/2-6,boxBottom)
else e.HB.Visible=false e.HO.Visible=false end
if K.ESP.Nm then e.N.Visible=true e.N.Text=m.Name e.N.Position=Vector2.new(cx,boxTop-18)e.N.Color=col else e.N.Visible=false end
if K.ESP.Ds then e.D.Visible=true e.D.Text=string.format("%.0f",dist3D).."m"e.D.Position=Vector2.new(cx,boxBottom+2)else e.D.Visible=false end
if K.ESP.Tr then local v=C.ViewportSize e.T.Visible=true e.T.From=Vector2.new(v.X/2,v.Y)e.T.To=Vector2.new(cx,boxBottom)e.T.Color=col else e.T.Visible=false end
npcIdx=npcIdx+1
else he(e)end
else he(e)end
else he(e)end
end
end
end
--隐藏未使用的NPC ESP槽位
for i=npcIdx,NPC_POOL do he(NPC_ESP[i].obj)end
end)

--初始化NPC缓存
refreshNpcs()

--==================== 黑曜石UI界面 ====================
local Window=Library:CreateWindow({Title="自瞄通用脚本",Footer="v1.0",Center=true,AutoShow=true})
local Tabs={Main=Window:AddTab("自瞄","crosshair"),ESP=Window:AddTab("ESP","eye"),UI=Window:AddTab("UI设置","settings")}

--==================== 标签页1: 自瞄 ====================
local AimBox=Tabs.Main:AddLeftGroupbox("自瞄设置")
local aimToggle=AimBox:AddToggle("AimEnabled",{Text="开启自瞄",Default=false})
aimToggle:OnChanged(function(v)K.Aim.En=v end)
aimToggle:AddKeyPicker("AimKey",{Default="MB2",SyncToggleState=true,Mode="Hold",Text="自瞄按键"})
AimBox:AddDropdown("AimTarget",{Text="目标类型",Default="Player",Values={"Player","NPC","Both"}}):OnChanged(function(v)K.Aim.Tgt=v end)
AimBox:AddDropdown("AimPart",{Text="瞄准部位",Default="Head",Values={"Head","Chest"}}):OnChanged(function(v)K.Aim.TP=v end)
AimBox:AddSlider("AimFOV",{Text="FOV范围",Default=150,Min=50,Max=1000,Rounding=0,Suffix="px"}):OnChanged(function(v)K.Aim.FOV=v end)
AimBox:AddSlider("AimDist",{Text="最大距离",Default=500,Min=50,Max=5000,Rounding=0,Suffix="格"}):OnChanged(function(v)K.Aim.Dist=v end)
AimBox:AddToggle("AimWall",{Text="穿墙自瞄",Default=true}):OnChanged(function(v)K.Aim.WC=v end)
AimBox:AddToggle("AimTeam",{Text="队伍检测",Default=true}):OnChanged(function(v)K.Aim.TC=v end)

local AimBox2=Tabs.Main:AddRightGroupbox("自瞄辅助")
AimBox2:AddToggle("AimSmooth",{Text="平滑自瞄",Default=false}):OnChanged(function(v)K.Aim.Sm=v end)
AimBox2:AddSlider("AimSpeed",{Text="平滑速度",Default=15,Min=1,Max=100,Rounding=0,Suffix=""}):OnChanged(function(v)K.Aim.Sp=v/100 end)
AimBox2:AddToggle("AimPred",{Text="预判自瞄",Default=true}):OnChanged(function(v)K.Aim.Pd=v end)
AimBox2:AddSlider("AimPredStr",{Text="预判强度",Default=20,Min=1,Max=100,Rounding=0,Suffix=""}):OnChanged(function(v)K.Aim.PS=v/100 end)
AimBox2:AddToggle("AimFixedFOV",{Text="启用固定FOV(移动端)",Default=true}):OnChanged(function(v)K.Aim.FF=v end)
AimBox2:AddSlider("AimFY",{Text="固定FOV Y轴位置",Default=200,Min=50,Max=500,Rounding=0,Suffix="px"}):OnChanged(function(v)K.Aim.FY=v end)

--==================== FOV圈设置 ====================
local FOVBox=Tabs.Main:AddLeftGroupbox("FOV圆圈")
FOVBox:AddToggle("FCEn",{Text="显示FOV圆圈",Default=false}):OnChanged(function(v)K.FC.En=v end)
FOVBox:AddDropdown("FCColor",{Text="圆圈颜色",Default="白色",Values={"白色","红色","绿色","蓝色","黄色","紫色","青色","粉色","橙色"}}):OnChanged(function(v)K.FC.Cl=CP[v]FS.Color=CP[v]end)
FOVBox:AddSlider("FCTr",{Text="圆圈透明度",Default=50,Min=0,Max=100,Rounding=0,Suffix="%"}):OnChanged(function(v)K.FC.Tr=v end)
FOVBox:AddSlider("FCTh",{Text="圆圈粗度",Default=1,Min=1,Max=10,Rounding=0,Suffix=""}):OnChanged(function(v)K.FC.Th=v FS.Thickness=v end)
FOVBox:AddToggle("FCFl",{Text="圆圈填充",Default=false}):OnChanged(function(v)K.FC.Fl=v end)

--==================== 标签页2: ESP ====================
local ESPBox=Tabs.ESP:AddLeftGroupbox("ESP设置")
ESPBox:AddToggle("ESPEn",{Text="开启ESP",Default=false}):OnChanged(function(v)K.ESP.En=v end)
ESPBox:AddSlider("ESPMD",{Text="最大显示距离",Default=1000,Min=50,Max=20000,Rounding=0,Suffix="格"}):OnChanged(function(v)K.ESP.MD=v end)

local ESPVis=Tabs.ESP:AddLeftGroupbox("视觉元素")
ESPVis:AddToggle("ESPBox",{Text="显示方框",Default=true}):OnChanged(function(v)K.ESP.Bx=v end)
ESPVis:AddToggle("ESPHealth",{Text="显示血条",Default=true}):OnChanged(function(v)K.ESP.HB=v end)
ESPVis:AddToggle("ESPName",{Text="显示名字",Default=true}):OnChanged(function(v)K.ESP.Nm=v end)
ESPVis:AddToggle("ESPDist",{Text="显示距离",Default=true}):OnChanged(function(v)K.ESP.Ds=v end)
ESPVis:AddToggle("ESPTracer",{Text="显示连线",Default=false}):OnChanged(function(v)K.ESP.Tr=v end)
ESPVis:AddToggle("ESPSkeleton",{Text="显示骨骼",Default=false}):OnChanged(function(v)K.ESP.Sk=v end)

local ESPChk=Tabs.ESP:AddRightGroupbox("检测设置")
ESPChk:AddToggle("ESPVis",{Text="可见性检测",Default=false}):OnChanged(function(v)K.ESP.VC=v end)
ESPChk:AddToggle("ESPTeam",{Text="队伍检测",Default=true}):OnChanged(function(v)K.ESP.TC=v end)
ESPChk:AddDropdown("ESPColor",{Text="玩家可见颜色",Default="绿色",Values={"白色","红色","绿色","蓝色","黄色","紫色","青色","粉色","橙色","灰色"}}):OnChanged(function(v)K.ESP.Cl=CP[v]end)
ESPChk:AddDropdown("ESPPIC",{Text="玩家不可见颜色",Default="红色",Values={"白色","红色","绿色","蓝色","黄色","紫色","青色","粉色","橙色","灰色"}}):OnChanged(function(v)K.ESP.PIC=CP[v]end)

local ESPTeam=Tabs.ESP:AddRightGroupbox("队伍颜色")
ESPTeam:AddToggle("ESPTeamColor",{Text="启用队伍颜色",Default=false}):OnChanged(function(v)K.ESP.TCe=v end)
ESPTeam:AddDropdown("ESPEVC",{Text="敌方可见",Default="红色",Values={"白色","红色","绿色","蓝色","黄色","紫色","青色","粉色","橙色","灰色"}}):OnChanged(function(v)K.ESP.EVC=CP[v]end)
ESPTeam:AddDropdown("ESPENC",{Text="敌方不可见",Default="灰色",Values={"白色","红色","绿色","蓝色","黄色","紫色","青色","粉色","橙色","灰色"}}):OnChanged(function(v)K.ESP.ENC=CP[v]end)
ESPTeam:AddDropdown("ESPMVC",{Text="我方可见",Default="蓝色",Values={"白色","红色","绿色","蓝色","黄色","紫色","青色","粉色","橙色","灰色"}}):OnChanged(function(v)K.ESP.MVC=CP[v]end)
ESPTeam:AddDropdown("ESPMNC",{Text="我方不可见",Default="灰色",Values={"白色","红色","绿色","蓝色","黄色","紫色","青色","粉色","橙色","灰色"}}):OnChanged(function(v)K.ESP.MNC=CP[v]end)

local ESPTgt=Tabs.ESP:AddLeftGroupbox("透视目标")
ESPTgt:AddToggle("ESPPlayer",{Text="透视玩家",Default=true}):OnChanged(function(v)K.ESP.PE=v end)
ESPTgt:AddToggle("ESPNpc",{Text="透视NPC",Default=false}):OnChanged(function(v)K.ESP.NPC=v end)
ESPTgt:AddToggle("ESPBot",{Text="透视Bots",Default=false}):OnChanged(function(v)K.ESP.BE=v end)

local ESPNpcCol=Tabs.ESP:AddRightGroupbox("NPC颜色")
ESPNpcCol:AddDropdown("ESPNpcC",{Text="NPC可见颜色",Default="橙色",Values={"白色","红色","绿色","蓝色","黄色","紫色","青色","粉色","橙色","灰色"}}):OnChanged(function(v)K.ESP.NC=CP[v]end)
ESPNpcCol:AddDropdown("ESPNpcIC",{Text="NPC不可见颜色",Default="灰色",Values={"白色","红色","绿色","蓝色","黄色","紫色","青色","粉色","橙色","灰色"}}):OnChanged(function(v)K.ESP.NIC=CP[v]end)

local ESPBotCol=Tabs.ESP:AddRightGroupbox("Bots颜色")
ESPBotCol:AddDropdown("ESPBotC",{Text="Bots可见颜色",Default="黄色",Values={"白色","红色","绿色","蓝色","黄色","紫色","青色","粉色","橙色","灰色"}}):OnChanged(function(v)K.ESP.BC=CP[v]end)
ESPBotCol:AddDropdown("ESPBotIC",{Text="Bots不可见颜色",Default="灰色",Values={"白色","红色","绿色","蓝色","黄色","紫色","青色","粉色","橙色","灰色"}}):OnChanged(function(v)K.ESP.BIC=CP[v]end)

--==================== 标签页3: UI设置 ====================
local UIBox=Tabs.UI:AddLeftGroupbox("关于")
UIBox:AddLabel({Text="自瞄通用脚本 v1.0"})
UIBox:AddLabel({Text="使用黑曜石UI(Obsidian)"})
UIBox:AddLabel({Text="此脚本为AI脚本 如被圈钱概不负责"})

local OpBox=Tabs.UI:AddLeftGroupbox("操作")
OpBox:AddButton({Text="卸载脚本",Callback=function()
K.Aim.En=false K.ESP.En=false K.FC.En=false
pcall(function()R:UnbindFromRenderStep("AimUniversal")end)
for _,e in pairs(EO)do re(e)end table.clear(EO)
for i=1,NPC_POOL do re(NPC_ESP[i].obj)end
pcall(function()FG:Destroy()end)
pcall(function()Library:Destroy()end)
end})

--ThemeManager和SaveManager
if ThemeManager then
ThemeManager:SetLibrary(Library)
if SaveManager then
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
SaveManager:SetFolder("AimUniversal/Configs")
SaveManager:BuildConfigSection(Tabs.UI)
end
ThemeManager:ApplyToTab(Tabs.UI)
if SaveManager then SaveManager:LoadAutoloadConfig()end
end