--[[	iLux - Penta Rainbows by Apple 
		Special Thanks to Icy for being my testing bitch and being open to every sorts of testing. ^-^

		FUCK YEAH, IT'S A MOTHERFUCKING UNICORN! Cheers to Rafaelinux!
	                          ,`,`,`,`,                   
	    . . . .               `\`\`\`\;                   
	    `\`\`\`\`,            ~|;!;!;\!                   
	     ~\;\;\;\|\          (--,!!!~`!       .           
	    (--,\\\===~\         (--,|||~`!     ./            
	     (--,\\\===~\         `,-,~,=,:. _,//             
	      (--,\\\==~`\        ~-=~-.---|\;/J,             
	       (--,\\\((```==.    ~'`~/       a |             
	         (-,.\\('('(`\\.  ~'=~|     \_.  \            
	            (,--(,(,(,'\\. ~'=|       \\_;>           
	              (,-( ,(,(,;\\ ~=/        \              
	              (,-/ (.(.(,;\\,/          )             
	               (,--/,;,;,;,\\         ./------.       
	                 (==,-;-'`;'         /_,----`. \      
	         ,.--_,__.-'                    `--.  ` \     
	        (='~-_,--/        ,       ,!,___--. \  \_)    
	       (-/~(     |         \   ,_-         | ) /_|    
	       (~/((\    )\._,      |-'         _,/ /         
	        \\))))  /   ./~.    |           \_\;          
	     ,__/////  /   /.## )  / @##.                     
	      '===~'   |  |#@&:(, <. &%%::&@##.               
	              #/ / %%00  \. \0000000%%:&@#            
	           #@&/ /          \_\      '00%:&@#          
	        #@&:/_!/            >_\         '0%:&@#       
	      #@&:%0                              0%:&@#      
	    #@&:%0                                  0%:&@#    
	  #@&:%0                                     0%:&@#   
	  "" ' "                                       " ' "" 	]]

if myHero.charName ~= "Lux" then return end

if VIP_USER then require "Collision" end
if FileExist(LIB_PATH.."Prodiction.lua") then require "Prodiction" end
if FileExist(LIB_PATH.."iSAC.lua") then iSAC = true require "iSAC" end

--[[ Config ]]--

local HK1 = string.byte("A")
local HK2 = string.byte("T")
local HK3 = string.byte("C") 
local HK4 = string.byte("X") -- Derp, not used but still here.
local SafeBet = 20 -- %
local AutoShieldPerc = 5 -- %
local damageSafetyNet = 2 --%
local minHitChance = 0.3 -- VIP Users only.
local drawPrediction = false
local OnlyEWhenQNotReadyAndTargetCanMove = false
local minMinionsForEFarm = 2
local useNewCombo = true
local tpProMaxTick = 20

local Testing = false -- Warning: Do not enable. It turns your computer into a fruit, which you don't want. 

--[[ Constants ]]--

local QRange, QSpeed, QDelay, QWidth = 1150, 1175, 0.250, 80
local WRange = 1050
local ERange, ESpeed, EDelay, ERadius = 1100, 1300, 0.150, 275
local RRange, RSpeed, RDelay, RWidth = 3340, math.huge, 0.700, 200

local igniteRange = 600
local defaultItemRange = 700

--[[ Script Variables ]]--

local ts = TargetSelector(TARGET_LESS_CAST,QRange,DAMAGE_MAGIC,false)
local tsAA = TargetSelector(TARGET_LESS_CAST,600,DAMAGE_MAGIC,false)
local tpQ = VIP_USER and TargetPredictionVIP(QRange, QSpeed, QDelay, QWidth) or TargetPrediction(QRange, QSpeed/1000, QDelay*1000, QWidth)
local tpQCollision = VIP_USER and Collision(QRange, QSpeed, QDelay, QWidth) or nil
local tpE = VIP_USER and TargetPredictionVIP(ERange, ESpeed, EDelay, ERadius*2) or TargetPrediction(ERange, ESpeed/1000, EDelay*1000, ERadius*2)
local tpR = VIP_USER and TargetPredictionVIP(RRange, RSpeed, RDelay, RWidth) or TargetPrediction(RRange, 100, RDelay*1000, RWidth)
local tpProPos = {
	[_Q] = {},
	[_E] = {},
	[_R] = {}, }
local tpPro = ProdictManager and ProdictManager.GetInstance() or nil
local tpProQ = tpPro and tpPro:AddProdictionObject(_Q, QRange, QSpeed, QDelay, QWidth, myHero, (Testing and function(unit, pos, spell) CastSpell(_Q, pos.x, pos.z) end or function(unit, pos, spell) if not unit or not pos then return end tpProPos[_Q][unit.networkID] = {pos = pos, updateTick = GetTickCount()} end)) or nil
local tpProE = tpPro and tpPro:AddProdictionObject(_E, ERange, ESpeed, EDelay, ERadius*2, myHero, (Testing and function(unit, pos, spell) CastSpell(_E, pos.x, pos.z) end or function(unit, pos, spell) if not unit or not pos then return end tpProPos[_E][unit.networkID] = {pos = pos, updateTick = GetTickCount()} end)) or nil
local tpProR = tpPro and tpPro:AddProdictionObject(_R, RRange, RSpeed, RDelay, RWidth, myHero, (Testing and function(unit, pos, spell) CastSpell(_R, pos.x, pos.z) end or function(unit, pos, spell) if not unit or not pos then return end tpProPos[_R][unit.networkID] = {pos = pos, updateTick = GetTickCount()} end)) or nil
local iOW = iSAC and iOrbWalker(550, true) or nil

local igniteSlot = nil
local EParticle = nil
local QStatus = 0
local TriggerEOnLand = false
local TriggerEOnLandFarm = false
local enemyMinions = {}
local updateTextTimers = {}
local pingTimer = {}
local CurrentTick = GetTickCount()
local FriendlySmite = {}

local items = {
	ZHONYAS = {id = 3157, slot = nil, ready = false},
	WOOGLETS = {id = 3090, slot = nil, ready = false},
	itemsList = {
		["BRK"] = {id = 3153, slot = nil, ready = false, useOnKill = false},
		["EXEC"] = {id = 3123, slot = nil, ready = false, useOnKill = false},
		["YOGH"] = {id = 3142, slot = nil, ready = false, useOnKill = false},
		["RANO"] = {id = 3143, slot = nil, ready = false, useOnKill = false},
		["MARU"] = {id = 3042, slot = nil, ready = false, useOnKill = false},
	
		["DFG"] = {id = 3128, slot = nil, ready = false, useOnKill = true},
		["HXG"] = {id = 3146, slot = nil, ready = false, useOnKill = true},
		["BWC"] = {id = 3144, slot = nil, ready = false, useOnKill = true},
		["BLACKFIRE"] = {id = 3188, slot = nil, READY = false, useOnKill = true},
	},
	passiveItemsList = {
		["LIANDRYS"] = {id = 3151, slot = nil},
	},
}

local jungleObjects = {
	["TT_Spiderboss7.1.1"] = {object = nil, isCamp = true},
	["Worm12.1.1"] = {object = nil, isCamp = true},
	["Dragon6.1.1"] = {object = nil, isCamp = true},
	["AncientGolem1.1.1"] = {object = nil, isCamp = true},
	["AncientGolem7.1.1"] = {object = nil, isCamp = true},
}

--[[ Core Callbacks ]]--

function OnLoad()
	iLuxConfig = scriptConfig("iLux - Penta Rainbows", "iLux")

	iLuxConfig:addParam("sep", "-=[ Hotkeys ]=-", SCRIPT_PARAM_INFO, "")
	iLuxConfig:addParam("pewpew","PewPew!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	iLuxConfig:addParam("harass", "Poke!", SCRIPT_PARAM_ONKEYDOWN, false, HK2)
	iLuxConfig:addParam("autoFarm", "Munching Minions", SCRIPT_PARAM_ONKEYDOWN, false, HK3)

	iLuxConfig:addParam("sep", "-=[ Combo Settings ]=-", SCRIPT_PARAM_INFO, "")
	if tpPro then iLuxConfig:addParam("tpPro", "Use Prodiction", SCRIPT_PARAM_ONOFF, true) end
	iLuxConfig:addParam("QWithSingleCollide", "Q With Single Minion Collision", SCRIPT_PARAM_ONOFF, false)
	iLuxConfig:addParam("UseUlt", "Ultimate in Combo", SCRIPT_PARAM_ONOFF, true)
	if iSAC then iLuxConfig:addParam("orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true) end
	iLuxConfig:addParam("moveToMouse", "Move To Mouse During PewPew", SCRIPT_PARAM_ONOFF, false)

	iLuxConfig:addParam("sep", "-=[ Auto Settings ]=-", SCRIPT_PARAM_INFO, "")
	iLuxConfig:addParam("AutoTriggerE", "Auto Trigger E", SCRIPT_PARAM_ONOFF, true)
	iLuxConfig:addParam("AutoTriggerEMin", "Min Enemies for E", SCRIPT_PARAM_SLICE, 1, 1, 5, 0)
	iLuxConfig:addParam("AutoUlt", "Auto Ultimate", SCRIPT_PARAM_ONOFF, true)
	iLuxConfig:addParam("AutoShield", "Auto Shield", SCRIPT_PARAM_ONOFF, true)
	iLuxConfig:addParam("SmartSave", "Smart Save Items", SCRIPT_PARAM_ONOFF, true)
	iLuxConfig:addParam("SafeBet", "Smart Save Health %", SCRIPT_PARAM_SLICE, SafeBet or 20, 1, 100, 0)

	iLuxConfig:addParam("sep", "-=[ Munching Settings ]=-", SCRIPT_PARAM_INFO, "")
	iLuxConfig:addParam("moveToMouseFarm", "Move to Mouse while Munching?", SCRIPT_PARAM_ONOFF, false)
	iLuxConfig:addParam("useEFarm", "Use E while Munching?", SCRIPT_PARAM_ONOFF, false)
	iLuxConfig:addParam("StealTzeBuffs", "Steal Tze Buffs?", SCRIPT_PARAM_ONOFF, false)
	iLuxConfig:addParam("NoRageStealz", "Don't enrage jungler?", SCRIPT_PARAM_ONOFF, true)

	iLuxConfig:addParam("sep", "-=[ Other Settings ]=-", SCRIPT_PARAM_INFO, "")
	iLuxConfig:addParam("drawcircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	iLuxConfig:addParam("damageText", "Kill Text", SCRIPT_PARAM_ONOFF, true)
	iLuxConfig:addParam("ultAlert", "Ult Notifier", SCRIPT_PARAM_ONOFF, true)

	iLuxConfig:permaShow("pewpew")
	iLuxConfig:permaShow("harass")
	iLuxConfig:permaShow("autoFarm")

	ts.name = "Lux"
	iLuxConfig:addTS(ts)

	igniteSlot = ((myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and SUMMONER_2) or nil)
	enemyMinions = minionManager(MINION_ENEMY, ERange, myHero, MINION_SORT_HEALTH_ASC)

	for i = 1, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object and object.valid and jungleObjects[object.name] and jungleObjects[object.name].isCamp then
			jungleObjects[object.name].object = object
		end
	end
	for _, ally in pairs(GetAllyHeroes()) do
		if ally:GetSpellData(SUMMONER_1).name == "SummonerSmite" or ally:GetSpellData(SUMMONER_2).name == "SummonerSmite" then
			FriendlySmite[#FriendlySmite+1] = ally
		end
	end
end

function OnTick()
	CurrentTick = GetTickCount()
	ts:update()
	enemyMinions:update()
	updateItems()
	if iOW then iOW.AARange = GetDistance(myHero.minBBox) + myHero.range end
	if EParticle ~= nil and not EParticle.valid then EParticle = nil end

	if not myHero.dead then
		AutoIgnite()
		AutoUlt()
		if ValidTarget(ts.target) then
			if iLuxConfig.tpPro then
				tpProQ:EnableTarget(ts.target, true)
				tpProE:EnableTarget(ts.target, true)
				tpProR:EnableTarget(ts.target, true)
			end
			if iLuxConfig.pewpew then 
				if iLuxConfig.tpPro and Testing then 
					newPewPewTesting()
				elseif useNewCombo then
					newPewPew()
				else
					PewPew()
				end
			end
			if iLuxConfig.harass then
				Poke()
			end
		end
		if iLuxConfig.pewpew and not (_G.AutoCarry and _G.AutoCarry.MainMenu.AutoCarry) then
			if iSAC then
				if iLuxConfig.orbwalk then
					tsAA.range = iOW.AARange
					tsAA:update()
					iOW:Orbwalk(mousePos, tsAA.target)
				elseif iLuxConfig.moveToMouse then
					iOW:Move(mousePos)
				end
			elseif iLuxConfig.moveToMouse then
				myHero:MoveTo(mousePos.x, mousePos.z)
			end
		end
		if EParticle and ((TriggerEOnLand or TriggerEOnLandFarm) or iLuxConfig.AutoTriggerE or iLuxConfig.pewpew) then
			AutoTriggerE()
		end
		if iLuxConfig.autoFarm and not (iLuxConfig.pewpew or iLuxConfig.harass) then autoFarm() end
		if iLuxConfig.damageText then damageText() end
		if iLuxConfig.StealTzeBuffs then StealTzeBuffs() end
	end
end

function OnCreateObj(object)
	if object.name:find("LuxLightstrike_tar") and GetDistance(object, lastEPos) < 100 then
		EParticle = object
	elseif object.name:find("LuxBlitz_nova") then
		EParticle = nil
		TriggerEOnLand = false
		TriggerEOnLandFarm = false
	elseif jungleObjects[object.name] and jungleObjects[object.name].isCamp then
		jungleObjects[object.name].object = object
	end
end

function OnDeleteObj(object)
	if object.name:find("LuxBlitz_nova") then
		EParticle = nil
		TriggerEOnLand = false
		TriggerEOnLandFarm = false
	elseif jungleObjects[object.name] and jungleObjects[object.name].isCamp then
		jungleObjects[object.name].object = nil
	end
end

function OnDraw()
	if not myHero.dead and iLuxConfig.drawcircles then
		if myHero:CanUseSpell(_Q) == READY or myHero:CanUseSpell(_E) == READY then
			DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0xFF80FF00)
		end

		if myHero:CanUseSpell(_R) == READY then
			DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0xFF80FF00)
		end

		if iOW then
			DrawCircle(myHero.x, myHero.y, myHero.z, iOW.AARange, 0xFF80FF00)
		end

		if EParticle then
			DrawCircle(EParticle.x, EParticle.y, EParticle.z, ERadius, 0xFF80FF00)
		end

		if drawPrediction then
			if myHero:CanUseSpell(_Q) == READY and ValidTarget(ts.target) and GetQPrediction(ts.target) ~= nil then
				tpQCollision:DrawCollision(myHero, GetQPrediction(ts.target))
			end
	
			if VIP_USER and myHero:CanUseSpell(_E) == READY and ValidTarget(ts.target) then
				local _,_,tempEPos = tpE:GetPrediction(ts.target)
				local EPos = tpE:GetHitChance(ts.target) > minHitChance and tempEPos or nil
				if EPos then
					DrawCircle(EPos.x, EPos.y, EPos.z, 275, 0xFFFF0000)
				end
			end
		end

		if ValidTarget(ts.target) then
			for i = 1, 10 do
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, 90+i, 0xFFFF0000)
			end
		end

		for i, minion in ipairs(enemyMinions.objects) do
			if minion and ValidTarget(minion, QRange) then
				if minion.health < (getDmg("AD", minion, myHero) + (TargetHaveBuff("luxilluminatingfraulein", minion) and getDmg("P", minion, myHero) or 0)) then
					for j = 1, 3 do
						DrawCircle(minion.x, minion.y, minion.z, 50+j, 0xFF80FF00)
					end
				elseif minion.health < getDmg("E", minion, myHero) then
					for j = 1, 3 do
						DrawCircle(minion.x, minion.y, minion.z, 50+j, 0xFFFF0000)
					end
				end
			end
		end
	end
end

--[[ Combat Functions ]]--

function newPewPewTesting() -- Experimental
	tpProQ:EnableTarget(myHero, false)
	tpProE:EnableTarget(myHero, false)
	tpProR:EnableTarget(myHero, false)
	if ts.target.canMove and myHero:CanUseSpell(_Q) == READY then
		tpProQ:EnableTarget(ts.target, true)
	elseif not ts.target.canMove then
		local calcDmg = calculateDamage(ts.target, true, true)
		local passiveOn = TargetHaveBuff("luxilluminatingfraulein", ts.target)
		if calcDmg.E + (passiveOn and calcDmg.passive or 0) > ts.target.health then
			if myHero:CanUseSpell(_E) == READY and not EParticle then
				tpProE:EnableTarget(ts.target, true)
				TriggerEOnLand = true
				TriggerEOnLandFarm = false
			elseif EParticle and myHero:CanUseSpell(_E) == READY and GetDistance(EParticle, ts.target) < ERadius then
				CastSpell(_E)
			end
		elseif calcDmg.Q + (passiveOn and calcDmg.passive or 0) > ts.target.health then
			if myHero:CanUseSpell(_Q) == READY then tpProQ:EnableTarget(ts.target, true) end
		elseif QPos and EPos and calcDmg.Q + calcDmg.E + (passiveOn and calcDmg.passive * 2 or calcDmg.passive) > ts.target.health then
			if myHero:CanUseSpell(_Q) == READY then tpProQ:EnableTarget(ts.target, true) end
			if myHero:CanUseSpell(_E) == READY and not EParticle then
				tpProE:EnableTarget(ts.target, true)
				TriggerEOnLand = true
				TriggerEOnLandFarm = false
			elseif EParticle and myHero:CanUseSpell(_E) == READY and GetDistance(EParticle, ts.target) < ERadius then
				CastSpell(_E)
			end
		elseif ((calcDmg.DFG > 0 or calcDmg.BLACKFIRE > 0) and 1.2 * (calcDmg.Q + calcDmg.E) or (calcDmg.Q + calcDmg.E)) + calcDmg.items + calcDmg.ignite > ts.target.health then
			for item, itemInfo in pairs(items.itemsList) do
				if itemInfo.ready and itemInfo.useOnKill then
					CastSpell(itemInfo.slot, ts.target)
				end
			end
			if myHero:CanUseSpell(_Q) == READY then tpProQ:EnableTarget(ts.target, true) end
			if myHero:CanUseSpell(_E) == READY and not EParticle then
				tpProE:EnableTarget(ts.target, true)
				TriggerEOnLand = true
				TriggerEOnLandFarm = false
			elseif EParticle and myHero:CanUseSpell(_E) == READY and GetDistance(EParticle, ts.target) < ERadius then
				CastSpell(_E)
			end
			if igniteSlot and myHero:CanUseSpell(igniteSlot) == READY then CastSpell(igniteSlot, ts.target) end
		elseif iLuxConfig.UseUlt and myHero:CanUseSpell(_R) == READY and RPos and calcDmg.total > ts.target.health then
			for item, itemInfo in pairs(items.itemsList) do
				if itemInfo.ready and itemInfo.useOnKill then
					CastSpell(itemInfo.slot, ts.target)
				end
			end
			if myHero:CanUseSpell(_Q) == READY then tpProQ:EnableTarget(ts.target, true) end
			if myHero:CanUseSpell(_E) == READY and not EParticle then
				tpProE:EnableTarget(ts.target, true)
				TriggerEOnLand = true
				TriggerEOnLandFarm = false
			elseif EParticle and myHero:CanUseSpell(_E) == READY and GetDistance(EParticle, ts.target) < ERadius then
				CastSpell(_E)
			end
			if igniteSlot and myHero:CanUseSpell(igniteSlot) == READY then CastSpell(igniteSlot, ts.target) end
			if myHero:CanUseSpell(_R) == READY then tpProR:EnableTarget(ts.target, true) end
		else
			if myHero:CanUseSpell(_Q) == READY then tpProQ:EnableTarget(ts.target, true) end
			if myHero:CanUseSpell(_E) == READY and not EParticle then
				tpProE:EnableTarget(ts.target, true)
				TriggerEOnLand = true
				TriggerEOnLandFarm = false
			elseif EParticle and myHero:CanUseSpell(_E) == READY and GetDistance(EParticle, ts.target) < ERadius then
				CastSpell(_E)
			end
		end
	elseif myHero:CanUseSpell(_E) == READY and EPos and (not OnlyEWhenQNotReadyAndTargetCanMove or myHero:CanUseSpell(_Q) ~= READY) then
		if not EParticle then
			tpProE:EnableTarget(ts.target, true)
			TriggerEOnLand = true
			TriggerEOnLandFarm = false
		elseif EParticle and myHero:CanUseSpell(_E) == READY and GetDistance(EParticle, ts.target) < ERadius then
			CastSpell(_E)
		end
	end
end

function newPewPew()
	local QPos = myHero:CanUseSpell(_Q) == READY and GetQPrediction(ts.target)
	local EPos = myHero:CanUseSpell(_E) == READY and GetEPrediction(ts.target) or EParticle
	local RPos = myHero:CanUseSpell(_R) == READY and GetRPrediction(ts.target)
	if ts.target.canMove and myHero:CanUseSpell(_Q) == READY and QPos then
		CastSpell(_Q, QPos.x, QPos.z)
	elseif not ts.target.canMove then
		local calcDmg = calculateDamage(ts.target, true, true, (QPos or 1), (EPos or 1))
		local passiveOn = TargetHaveBuff("luxilluminatingfraulein", ts.target)
		if calcDmg.E + (passiveOn and calcDmg.passive or 0) > ts.target.health then
			if myHero:CanUseSpell(_E) == READY and not EParticle and EPos then
				CastSpell(_E, EPos and EPos.x or ts.target.x, EPos and EPos.z or ts.target.z)
				TriggerEOnLand = true
				TriggerEOnLandFarm = false
			elseif EParticle and myHero:CanUseSpell(_E) == READY and GetDistance(EParticle, ts.target) < ERadius then
				CastSpell(_E)
			end
		elseif calcDmg.Q + (passiveOn and calcDmg.passive or 0) > ts.target.health then
			if myHero:CanUseSpell(_Q) == READY then CastSpell(_Q, QPos and QPos.x or ts.target.x, QPos and QPos.z or ts.target.z) end
		elseif QPos and EPos and calcDmg.Q + calcDmg.E + (passiveOn and calcDmg.passive * 2 or calcDmg.passive) > ts.target.health then
			if myHero:CanUseSpell(_Q) == READY then CastSpell(_Q, QPos and QPos.x or ts.target.x, QPos and QPos.z or ts.target.z) end
			if myHero:CanUseSpell(_E) == READY and not EParticle and EPos then
				CastSpell(_E, EPos and EPos.x or ts.target.x, EPos and EPos.z or ts.target.z)
				TriggerEOnLand = true
				TriggerEOnLandFarm = false
			elseif EParticle and myHero:CanUseSpell(_E) == READY and GetDistance(EParticle, ts.target) < ERadius then
				CastSpell(_E)
			end
		elseif (calcDmg.DFG > 0 and 1.2 * ((QPos and calcDmg.Q or 0) + (EPos and calcDmg.E or 0)) or (QPos and calcDmg.Q or 0) + (EPos and calcDmg.E or 0)) + calcDmg.items + calcDmg.ignite > ts.target.health then
			for item, itemInfo in pairs(items.itemsList) do
				if itemInfo.ready and itemInfo.useOnKill then
					CastSpell(itemInfo.slot, ts.target)
				end
			end
			if myHero:CanUseSpell(_Q) == READY then CastSpell(_Q, QPos and QPos.x or ts.target.x, QPos and QPos.z or ts.target.z) end
			if myHero:CanUseSpell(_E) == READY and not EParticle and EPos then
				CastSpell(_E, EPos and EPos.x or ts.target.x, EPos and EPos.z or ts.target.z)
				TriggerEOnLand = true
				TriggerEOnLandFarm = false
			elseif EParticle and myHero:CanUseSpell(_E) == READY and GetDistance(EParticle, ts.target) < ERadius then
				CastSpell(_E)
			end
			if igniteSlot and myHero:CanUseSpell(igniteSlot) == READY then CastSpell(igniteSlot, ts.target) end
		elseif iLuxConfig.UseUlt and myHero:CanUseSpell(_R) == READY and RPos and calcDmg.total > ts.target.health then
			for item, itemInfo in pairs(items.itemsList) do
				if itemInfo.ready and itemInfo.useOnKill then
					CastSpell(itemInfo.slot, ts.target)
				end
			end
			if myHero:CanUseSpell(_Q) == READY then CastSpell(_Q, QPos and QPos.x or ts.target.x, QPos and QPos.z or ts.target.z) end
			if myHero:CanUseSpell(_E) == READY and not EParticle and EPos then
				CastSpell(_E, EPos and EPos.x or ts.target.x, EPos and EPos.z or ts.target.z)
				TriggerEOnLand = true
				TriggerEOnLandFarm = false
			elseif EParticle and myHero:CanUseSpell(_E) == READY and GetDistance(EParticle, ts.target) < ERadius then
				CastSpell(_E)
			end
			if igniteSlot and myHero:CanUseSpell(igniteSlot) == READY then CastSpell(igniteSlot, ts.target) end
			CastSpell(_R, RPos and RPos.x or ts.target.x, RPos and RPos.z or ts.target.z)
		else
			if QPos then CastSpell(_Q, QPos.x, QPos.z) end
			if EPos then
				if not EParticle then
					CastSpell(_E, EPos and EPos.x or ts.target.x, EPos and EPos.z or ts.target.z)
					TriggerEOnLand = true
					TriggerEOnLandFarm = false
				elseif GetDistance(EParticle, ts.target) < ERadius then
					CastSpell(_E)
				end
			end
		end
	elseif myHero:CanUseSpell(_E) == READY and EPos and (not OnlyEWhenQNotReadyAndTargetCanMove or myHero:CanUseSpell(_Q) ~= READY) then
		if not EParticle then
			CastSpell(_E, EPos.x, EPos.z)
			TriggerEOnLand = true
			TriggerEOnLandFarm = false
		elseif GetDistance(EParticle, ts.target) < ERadius then
			CastSpell(_E)
		end
	end
end

function PewPew()
	if ValidTarget(ts.target) then
		local QPos = GetQPrediction(ts.target)
		local EPos = GetEPrediction(ts.target)
		if ts.target.canMove and myHero:CanUseSpell(_Q) == READY and QPos then
			CastSpell(_Q, QPos.x, QPos.z)
			QStatus = 1
		elseif not ts.target.canMove then
			local calcDmg = calculateDamage(ts.target, true, true, QPos, EPos)
			if calcDmg.E > ts.target.health then
				if not EParticle then
					CastSpell(_E, ts.target.x, ts.target.z)
					TriggerEOnLand = true
					TriggerEOnLandFarm = false
				elseif GetDistance(EParticle, ts.target) < ERadius then
					CastSpell(_E)
				end
			elseif QPos and calcDmg.Q > ts.target.health then
				CastSpell(_Q, QPos.x, QPos.z)
			elseif QPos and calcDmg.Q + calcDmg.E > ts.target.health then
				CastSpell(_Q, QPos.x, QPos.z)
				if not EParticle then
					CastSpell(_E, ts.target.x, ts.target.z)
					TriggerEOnLand = true
					TriggerEOnLandFarm = false
				elseif GetDistance(EParticle, ts.target) < ERadius then
					CastSpell(_E)
				end
			elseif (calcDmg.DFG > 0 and 1.2 * ((QPos and calcDmg.Q or 0) + calcDmg.E) or (QPos and calcDmg.Q or 0) + calcDmg.E) + calcDmg.items + calcDmg.ignite > ts.target.health then
				for item, itemInfo in pairs(items.itemsList) do
					if itemInfo.ready then
						CastSpell(itemInfo.slot, ts.target)
					end
				end
				if QPos then CastSpell(_Q, QPos.x, QPos.z) end
				if not EParticle then
					CastSpell(_E, ts.target.x, ts.target.z)
					TriggerEOnLand = true
					TriggerEOnLandFarm = false
				elseif GetDistance(EParticle, ts.target) < ERadius then
					CastSpell(_E)
				end
				if igniteSlot then CastSpell(igniteSlot, ts.target) end
			elseif iLuxConfig.UseUlt and (QPos and calcDmg.total or calcDmg.total - calcDmg.Q) > ts.target.health then
				for item, itemInfo in pairs(items.itemsList) do
					if itemInfo.ready then
						CastSpell(itemInfo.slot, ts.target)
					end
				end
				if QPos then CastSpell(_Q, QPos.x, QPos.z) end
				if not EParticle then
					CastSpell(_E, ts.target.x, ts.target.z)
					TriggerEOnLand = true
					TriggerEOnLandFarm = false
				elseif GetDistance(EParticle, ts.target) < ERadius then
					CastSpell(_E)
				end
				if igniteSlot then CastSpell(igniteSlot, ts.target) end
				CastSpell(_R, ts.target.x, ts.target.z)
			else
				if QPos then CastSpell(_Q, QPos.x, QPos.z) end
				if not EParticle then
					CastSpell(_E, ts.target.x, ts.target.z)
					TriggerEOnLand = true
					TriggerEOnLandFarm = false
				elseif GetDistance(EParticle, ts.target) < ERadius then
					CastSpell(_E)
				end
			end
		elseif myHero:CanUseSpell(_E) == READY and EPos and QStatus ~= 3 and (OnlyEWhenQNotReadyAndTargetCanMove and myHero:CanUseSpell(_Q) ~= READY or not OnlyEWhenQNotReadyAndTargetCanMove) then
			if not EParticle then
				CastSpell(_E, EPos.x, EPos.z)
				TriggerEOnLand = true
				TriggerEOnLandFarm = false
			elseif GetDistance(EParticle, ts.target) < ERadius then
				CastSpell(_E)
			end
		end
	end
end

function Poke()
	if myHero:CanUseSpell(_E) == READY then
		if not EParticle then
			local EPos = GetEPrediction(ts.target)
			if EPos then
				CastSpell(_E, EPos.x, EPos.z)
				TriggerEOnLand = true
				TriggerEOnLandFarm = false
			end
		elseif GetDistance(EParticle, ts.target) < ERadius then
			CastSpell(_E)
		end
	end
end

function autoFarm()
	local killableMinions = {}
	local killablePoints = {}
	for i, minion in ipairs(enemyMinions.objects) do
		if minion and minion.valid and ValidTarget(minion) and (TargetHaveBuff("luxilluminatingfraulein", minion) and getDmg("P", minion, myHero) + getDmg("E", minion, myHero) or getDmg("E", minion, myHero)) > minion.health then
			table.insert(killableMinions, minion)
			table.insert(killablePoints, Vector(minion))
		end
	end
	if myHero:CanUseSpell(_E) == READY and iLuxConfig.useEFarm then
		if not EParticle then
			if #killableMinions >= minMinionsForEFarm then
				local mec = MEC(killablePoints)
				local spellPos = mec:Compute().center
				local PosMinionCount = 0
				for i, minion in ipairs(killableMinions) do
					if GetDistance(minion, spellPos) < ERadius then
						PosMinionCount = PosMinionCount + 1
						if PosMinionCount >= 2 then
							CastSpell(_E, spellPos.x, spellPos.z)
							TriggerEOnLand = false
							TriggerEOnLandFarm = true
							return
						end
					end
				end
			end
		else
			local PosMinionCount = 0
			for i, minion in ipairs(killableMinions) do
				if GetDistance(minion, EParticle) < ERadius then
					PosMinionCount = PosMinionCount + 1
					if PosMinionCount >= minMinionsForEFarm then
						CastSpell(_E)
						return
					end
				end
			end
		end
	end
	for i, minion in ipairs(killableMinions) do
		if minion and minion.valid and ValidTarget(minion) and (TargetHaveBuff("luxilluminatingfraulein", minion) and getDmg("P", minion, myHero) + getDmg("AD", minion, myHero) * 1.1 or getDmg("AD", minion, myHero) * 1.1) > minion.health then
			myHero:Attack(minion)
			return
		end
	end
	if iLuxConfig.moveToMouseFarm then
		myHero:MoveTo(mousePos.x, mousePos.z)
	end
end

function AutoUlt()
	if myHero:CanUseSpell(_R) == READY then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) and (TargetHaveBuff("luxilluminatingfraulein", enemy) and getDmg("P", enemy, myHero) + getDmg("R", enemy, myHero) or getDmg("R", enemy, myHero)) > enemy.health then
				if iLuxConfig.ultAlert then
					if pingTimer[enemy.charName] == nil or pingTimer[enemy.charName] < GetTickCount() - 10000 then
						PingSignal(PING_NORMAL, enemy.x, enemy.y, enemy.z, 2)
						pingTimer[enemy.charName] = GetTickCount()
					end
				end
				--if ValidTarget(enemy, RRange) and iLuxConfig.AutoUlt and (not ts.target or (enemy.networkID ~= ts.target.networkID or (not EParticle or myHero:CanUseSpell(_E) == READY))) then
				if ValidTarget(enemy, RRange) and iLuxConfig.AutoUlt then
					if iLuxConfig.tpPro then tpProR:EnableTarget(enemy, true) end
					local RPos = GetRPrediction(enemy)
					if RPos then
						CastSpell(_R, RPos.x, RPos.z)
						return
					end
				end
			end
		end
	end
	--tpProR:EnableTarget(myHero, false)
end

function AutoTriggerE()
	if TriggerEOnLandFarm then
		CastSpell(_E)
		return
	else
		local count = 0
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) and GetDistance(enemy, EParticle) < ERadius then
				if TriggerEOnLand then
					CastSpell(_E)
					return
				else
					count = count + 1
					if count >= iLuxConfig.AutoTriggerEMin then
						CastSpell(_E)
						return
					end
				end
			end	
		end
	end
end

function StealTzeBuffs()
	if myHero:CanUseSpell(_R) == READY then
		for _, jungleMob in pairs(jungleObjects) do
			if jungleMob and jungleMob.isCamp then
				local tempMob = jungleMob.object
				if tempMob ~= nil and tempMob.valid and tempMob.visible and not tempMob.dead and GetDistance(tempMob) < RRange then
					if iLuxConfig.NoRageStealz then
						for _, ally in pairs(FriendlySmite) do
							if GetDistance(ally, tempMob) < 600 then return end
						end
					end
					if getDmg("R", tempMob, myHero) >  tempMob.health then
						CastSpell(_R, tempMob.x, tempMob.z)
					end
				end
			end
		end
	end
end

function AutoIgnite()
	if igniteSlot and myHero:CanUseSpell(igniteSlot) == READY then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, igniteRange) and enemy.health < getDmg("IGNITE", enemy, myHero) then
				CastSpell(igniteSlot, enemy)
			end
		end
	end
end

--[[ Prediction and Calculations ]]--

function GetQPrediction(enemy)
	if iLuxConfig.tpPro then
		--local tpProPosSub = tpProPos[_Q][enemy.networkID]
		--if tpProPosSub and CurrentTick - tpProPosSub.updateTick < tpProMaxTick then
		--	local QPos = tpProPosSub.pos
		--	if QPos then
		--		local willCollide, collideArray = tpQCollision:GetMinionCollision(myHero, QPos)
		--		if not willCollide or (iLuxConfig.QWithSingleCollide and #collideArray <= 1) then
		--			return QPos
		--		else
		--			return nil
		--		end
		--	else
		--		return nil
		--	end
		--else
		--	return nil
		--end
		local QPos, _, QHitChance = tpProQ:GetPrediction(enemy)
		if minHitChance ~= 0 and QHitChance < minHitChance then return nil end
		local willCollide, collideArray = tpQCollision:GetMinionCollision(myHero, QPos)
		if not willCollide or (iLuxConfig.QWithSingleCollide and #collideArray <= 1) then
			return QPos
		else
			return nil
		end
	elseif VIP_USER then
		if minHitChance ~= 0 and tpQ:GetHitChance(enemy) < minHitChance then return nil end
		local _,_,QPos = tpQ:GetPrediction(enemy)
		local willCollide, collideArray = tpQCollision:GetMinionCollision(myHero, QPos)
		if not willCollide or (iLuxConfig.QWithSingleCollide and #collideArray <= 1) then
			return QPos
		else
			return nil
		end
	else
		return tpQ:GetPrediction(enemy)
	end
end

function GetEPrediction(enemy)
	if iLuxConfig.tpPro then
		--local tpProPosSub = tpProPos[_E][enemy.networkID]
		--return tpProPosSub and CurrentTick - tpProPosSub.updateTick < tpProMaxTick and tpProPosSub.pos or nil
		local EPos, _, EHitChance = tpProE:GetPrediction(enemy)
		if minHitChance == 0 or EHitChance > minHitChance then return EPos end
	elseif VIP_USER then
		if minHitChance ~= 0 and tpE:GetHitChance(enemy) < minHitChance then return nil end
		local _,_,EPos = tpE:GetPrediction(enemy)
		return EPos
	else
		return tpE:GetPrediction(enemy)
	end
end

function GetRPrediction(enemy)
	if iLuxConfig.tpPro then
		--local tpProPosSub = tpProPos[_E][enemy.networkID]
		--if tpProPosSub and CurrentTick - tpProPosSub.updateTick < tpProMaxTick then
		--	return tpProPosSub.pos or nil
		----else
		----	local RPos, _, hitchance = tpProR:GetPrediction(enemy)
		----	if RPos and (minHitChance == 0 or hitchance > minHitChance) then
		----		return RPos
		----	end
		--end
		local RPos, _, RHitChance = tpProR:GetPrediction(enemy)
		if minHitChance == 0 or RHitChance > minHitChance then return RPos end
	elseif VIP_USER then
		if minHitChance ~= 0 and tpR:GetHitChance(enemy) < minHitChance then return nil end
		local _,_,RPos = tpR:GetPrediction(enemy)
		return RPos
	else
		return tpR:GetPrediction(enemy)
	end
end

function calculateDamage(enemy, checkRange, readyCheck, QPos, EPos)
	--local QPos = GetQPrediction(enemy)
	--local _,_,tempEPos = tpE:GetPrediction(enemy)
	--local EPos = tpE:GetHitChance(enemy) > minHitChance and tempEPos or nil
	local safeNet = 1 - damageSafetyNet / 100
	local returnDamage = {}
	returnDamage.Qbase = (( (myHero:CanUseSpell(_Q) == READY or not readyCheck) and ((iLuxConfig.tpPro and Testing) or ((QPos and QPos ~= 1 and GetDistance({x = QPos.x, z = QPos.z}) < QRange or (QPos ~= 1 and GetDistance(enemy) < QRange)) and not checkRange)) and getDmg("Q", enemy, myHero)) or 0 )
	--returnDamage.Wbase = (( (myHero:CanUseSpell(_W) == READY or not readyCheck) and (GetDistance(enemy) < WRange or not checkRange) and getDmg("W", enemy, myHero)) or 0 )
	returnDamage.Ebase = (( (myHero:CanUseSpell(_E) == READY or not readyCheck) and ((iLuxConfig.tpPro and Testing) or ((EPos and EPos ~= 1 and (EPos ~= EParticle and GetDistance({x = EPos.x, z = EPos.z}) < ERange or GetDistance(EParticle, enemy) < ERadius) or (EPos ~= 1 and GetDistance(enemy) < ERange)) and not checkRange)) and getDmg("E", enemy, myHero)) or 0 )
	returnDamage.Rbase = (( (myHero:CanUseSpell(_R) == READY or not readyCheck) and (GetDistance(enemy) < RRange or not checkRange) and getDmg("R", enemy, myHero)) or 0 )
	returnDamage.DFG = (( (items.itemsList["DFG"].ready or (items.itemsList["DFG"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("DFG", enemy, myHero)) or 0 )
	returnDamage.HXG = (( (items.itemsList["HXG"].ready or (items.itemsList["HXG"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("HXG", enemy, myHero)) or 0 )
	returnDamage.BWC = (( (items.itemsList["BWC"].ready or (items.itemsList["BWC"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("BWC", enemy, myHero)) or 0 )
	returnDamage.BLACKFIRE = (( (items.itemsList["BLACKFIRE"].ready or (items.itemsList["BLACKFIRE"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("BLACKFIRE", enemy, myHero)) or 0 )
	returnDamage.LIANDRYS = (( items.passiveItemsList["LIANDRYS"].slot and getDmg("LIANDRYS", enemy, myHero)) or 0)
	--returnDamage.BLACKFIRE = (( items.passiveItemsList["BLACKFIRE"].slot and getDmg("BLACKFIRE", enemy, myHero)) or 0)
	returnDamage.ignite = (( igniteSlot and (myHero:CanUseSpell(igniteSlot) == READY or not readyCheck) and (GetDistance(enemy) < igniteRange or not checkRange) and getDmg("IGNITE", enemy, myHero)) or 0)
	returnDamage.passive = getDmg("P", enemy, myHero)

	returnDamage.onSpell = (returnDamage.LIANDRYS + returnDamage.BLACKFIRE) * safeNet
	returnDamage.Q = (returnDamage.Qbase + returnDamage.onSpell) * safeNet
	--returnDamage.W = (returnDamage.Wbase + returnDamage.onSpell) * safeNet
	returnDamage.E = (returnDamage.Ebase + returnDamage.onSpell) * safeNet
	returnDamage.R = (returnDamage.Rbase + returnDamage.onSpell) * safeNet
	returnDamage.QWE = returnDamage.Q --[[+ returnDamage.W]] + returnDamage.E + returnDamage.passive * safeNet
	returnDamage.QWER = returnDamage.QWE + returnDamage.R
	returnDamage.items = (returnDamage.DFG + returnDamage.HXG + returnDamage.BWC) * safeNet

	returnDamage.total = ((returnDamage.DFG > 0 and 1.2 * returnDamage.QWER or returnDamage.QWER) + returnDamage.items + returnDamage.ignite) * safeNet

	return returnDamage
end

function updateItems()
	for item, itemInfo in pairs(items.itemsList) do
		itemInfo.slot = GetInventorySlotItem(itemInfo.id)		
		itemInfo.ready = (itemInfo.slot and myHero:CanUseSpell(itemInfo.slot) == READY or false)
	end
	for item, itemInfo in pairs(items.passiveItemsList) do
		itemInfo.slot = GetInventorySlotItem(itemInfo.id)
	end
	items["ZHONYAS"].slot = GetInventorySlotItem(items["ZHONYAS"].id)		
	items["ZHONYAS"].ready = (items["ZHONYAS"].slot and myHero:CanUseSpell(items["ZHONYAS"].slot) == READY or false)
	items["WOOGLETS"].slot = GetInventorySlotItem(items["WOOGLETS"].id)		
	items["WOOGLETS"].ready = (items["WOOGLETS"].slot and myHero:CanUseSpell(items["WOOGLETS"].slot) == READY or false)
end

function damageText()
	local damageTextList = {"Poor Enemy", "Ultimate!", "Nuke!", "Risky"}
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			if updateTextTimers[enemy.charName] == nil then
				updateTextTimers[enemy.charName] = 30
			elseif updateTextTimers[enemy.charName] > 1 then
				updateTextTimers[enemy.charName] = updateTextTimers[enemy.charName] - 1
			elseif updateTextTimers[enemy.charName] == 1 then			
				local calcDmg = calculateDamage(enemy, false, true)
				local killMode = (calcDmg.QWE > enemy.health and 1) or (calcDmg.R > enemy.health and 2) or (calcDmg.QWER > enemy.health and 3) or (calcDmg.total > enemy.health and 4) or 0
				if killMode > 0 then PrintFloatText(enemy, 0, damageTextList[killMode]) end
				updateTextTimers[enemy.charName] = 30
			end
		end
	end
end

--[[ Garbage Bin ]]--

function OnProcessSpell(object, spell)

	if object.isMe and spell.name == "LuxLightStrikeKugel" then lastEPos = spell.startPos end

	if object == nil or spell == nil or not object.valid then return end

	if ((items["WOOGLETS"].ready or items["ZHONYAS"].ready) and iLuxConfig.SmartSave) or (myHero:CanUseSpell(_W) == READY and iLuxConfig.AutoShield) then
		if ValidTarget(object) and not myHero.dead and not (object.name:find("Minion_") or object.name:find("Odin")) then
			if object.type == "obj_AI_Hero" then
				local spellType = getSpellType(object, spell.name)
				if spellType ~= nil then

					-- Basic Attacks
					if spellType == "BAttack" or spellType == "CAttack" then
						local baseADmg = getDmg("AD", myHero, object)
						local onHitDmg = 0
							+ ((GetInventoryHaveItem(3078, object) and getDmg("TRINITY", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3186, object) and getDmg("KITAES", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3087, object) and getDmg("STATIKK", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3100, object) and getDmg("LICHBANE", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3114, object) and getDmg("MALADY", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3153, object) and getDmg("RUINEDKING", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3042, object) and getDmg("MURAMANA", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3091, object) and getDmg("WITSEND", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3057, object) and getDmg("SHEEN", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3025, object) and getDmg("ICEBORN", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3184, object) and 80) or 0)
						local PhysDamage = (spellType == "BAttack" and (baseADmg + onHitDmg) * 1.07 + ((GetInventoryHaveItem(3209, object) and getDmg("SPIRITLIZARD", myHero, object)) or 0)) or (spellType == "CAttack" and (GetInventoryHaveItem(3031, object) and (baseADmg * 2.5 + onHitDmg) * 1.07 + ((GetInventoryHaveItem(3209, object) and getDmg("SPIRITLIZARD", myHero, object)) or 0)) or (baseADmg * 1.5 + onHitDmg) * 1.07 + ((GetInventoryHaveItem(3209, object) and getDmg("SPIRITLIZARD", myHero, object)) or 0))
	
						if spell.endPos ~= nil and GetDistance(spell.endPos) < 50 then
							if myHero.health - PhysDamage < myHero.maxHealth * (iLuxConfig.SafeBet / 100) then
								if items["WOOGLETS"].ready and iLuxConfig.SmartSave then
									CastSpell(items["WOOGLETS"].slot)
								elseif items["ZHONYAS"].ready and iLuxConfig.SmartSave then
									CastSpell(items["ZHONYAS"].slot)
								end
							elseif myHero:CanUseSpell(_W) == READY and iLuxConfig.AutoShield and PhysDamage / myHero.maxHealth > AutoShieldPerc / 100 then
								local bestAlly = nil
								for i, tempAlly in ipairs(GetAllyHeroes()) do
									if GetDistance(tempAlly) < WRange then
										if bestAlly == nil or bestAlly.health > tempAlly.health then
											bestAlly = tempAlly
										end
									end
								end
								CastSpell(_W, bestAlly ~= nil and bestAlly.x or object.x, bestAlly ~= nil and bestAlly.z or object.z)
							end
						end

					-- QWER Attacks
					elseif string.find("QWER", spellType) then
						local onHitSpellDmg = 0
							+ ((GetInventoryHaveItem(3151, object) and getDmg("LIANDRYS", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3042, object) and getDmg("MURAMANA",myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3188, object) and getDmg("BLACKFIRE", myHero, object)) or 0)
						local spellDamage = (getDmg(spellType, myHero, object) + onHitSpellDmg) * 1.07 + (GetInventoryHaveItem(3209) and getDmg("SPIRITLIZARD", myHero, object) or 0)
						local skillType, skillRadius, skillMaxDistance = skillData[object.charName][spellType]["type"], skillData[object.charName][spellType]["radius"], skillData[object.charName][spellType]["maxdistance"]
						if (skillType == 0 and checkhitaoe(object, spell.endPos, 80, myHero, 0)) or (skillType == 1 and checkhitlinepass(object, spell.endPos, skillRadius, skillMaxDistance, myHero, 50)) or (skillType == 2 and checkhitlinepoint(object, spell.endPos, skillRadius, myHero, 50)) or (skillType == 3 and checkhitaoe(object, spell.endPos, skillRadius, myHero, 50)) or (skillType == 4 and checkhitcone(object, spell.endPos, skillRadius, skillMaxDistance, myHero, 50)) or (skillType == 5 and checkhitwall(object, spell.endPos, skillRadius, skillMaxDistance, myHero, 50)) or (skillType == 6 and (checkhitlinepass(object, spell.endPos, skillRadius, skillMaxDistance, myHero, 50) or checkhitlinepass(object, Vector(object)*2-spell.endPos, skillRadius, skillMaxDistance, myHero, 50))) then
							if myHero.health - spellDamage < myHero.maxHealth * (iLuxConfig.SafeBet / 100) then
								if items["WOOGLETS"].ready and iLuxConfig.SmartSave then
									CastSpell(items["WOOGLETS"].slot)
								elseif items["ZHONYAS"].ready and iLuxConfig.SmartSave then
									CastSpell(items["ZHONYAS"].slot)
							elseif myHero:CanUseSpell(_W) == READY and iLuxConfig.AutoShield and spellDamage / myHero.maxHealth > AutoShieldPerc / 100 then
								local bestAlly = nil
								for i, tempAlly in ipairs(GetAllyHeroes()) do
									if GetDistance(tempAlly) < WRange then
										if bestAlly == nil or bestAlly.health > tempAlly.health then
											bestAlly = tempAlly
										end
									end
								end
								CastSpell(_W, bestAlly ~= nil and bestAlly.x or object.x, bestAlly ~= nil and bestAlly.z or object.z)
								end
							end
						end
					end
				end
			end
		end
	end
end