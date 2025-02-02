local tm=love.timer
local data=love.data

local fs=love.filesystem
local int,rnd=math.floor,math.random
local sub=string.sub
local char,byte=string.char,string.byte
local ins,rem=table.insert,table.remove

local gameSetting={
	--Tuning
	"das","arr","dascut","sddas","sdarr",
	"ihs","irs","ims","RS","swap",

	--System
	"skin","face",

	--Graphic
	"block","ghost","center","smooth","grid","bagLine",
	"lockFX","dropFX","moveFX","clearFX","splashFX","shakeFX","atkFX",
	"text","score","warn","highCam","nextPos",
}
local function copyGameSetting()
	local S={}
	for _,key in next,gameSetting do
		if type(SETTING[key])=="table"then
			S[key]=copyList(SETTING[key])
		else
			S[key]=SETTING[key]
		end
	end
	return S
end

function destroyPlayers()
	for i=#PLAYERS,1,-1 do
		local P=PLAYERS[i]
		if P.canvas then P.canvas:release()end
		while P.field[1]do
			FREEROW.discard(rem(P.field))
			FREEROW.discard(rem(P.visTime))
		end
		if P.AI_mode=="CC"then
			CC.free(P.bot_opt)
			CC.free(P.bot_wei)
			CC.destroy(P.AI_bot)
			P.AI_mode=false
		end
		PLAYERS[i]=nil
	end
	for i=#PLAYERS.alive,1,-1 do
		PLAYERS.alive[i]=nil
	end
	collectgarbage()
end

function restoreVirtualKey()
	for i=1,#VK_org do
		local B,O=virtualkey[i],VK_org[i]
		B.ava=O.ava
		B.x=O.x
		B.y=O.y
		B.r=O.r
		B.isDown=false
		B.pressTime=0
	end
	for k,v in next,PLAYERS[1].keyAvailable do
		if not v then
			virtualkey[k].ava=false
		end
	end
end

function copyQuestArgs()
	local ENV=CUSTOMENV
	local str=""..
		ENV.holdCount..
		(ENV.ospin and"O"or"Z")..
		(ENV.missionKill and"M"or"Z")..
		ENV.sequence
	return str
end
function pasteQuestArgs(str)
	if #str<4 then return end
	local ENV=CUSTOMENV
	ENV.holdCount=		byte(str,1)-48
	ENV.ospin=			byte(str,2)~=90
	ENV.missionKill=	byte(str,3)~=90
	ENV.sequence=		sub(str,4)
end

--Encoding Functions
--Sep symbol: 33 (!)
--Safe char: 34~126
--[[
	Count: 34~96
	Block: 97~125
	Encode: A[B] sequence, A = block ID, B = repeat times, no B means do not repeat.
	Example: "abcdefg" is [SZJLTOI], "a^aDb)" is [Z*63,Z*37,S*10]
]]
function copySequence()
	local BAG=BAG
	local str=""

	local count=1
	for i=1,#BAG+1 do
		if BAG[i+1]~=BAG[i]or count==64 then
			str=str..char(96+BAG[i])
			if count>1 then
				str=str..char(32+count)
				count=1
			end
		else
			count=count+1
		end
	end

	return str
end
function pasteSequence(str)
	local b

	local bag={}
	local reg
	for i=1,#str do
		b=byte(str,i)
		if not reg then
			if b>=97 and b<=125 then
				reg=b-96
			else
				return
			end
		else
			if b>=97 and b<=125 then
				ins(bag,reg)
				reg=b-96
			elseif b>=34 and b<=96 then
				for _=1,b-32 do
					ins(bag,reg)
				end
				reg=false
			end
		end
	end
	if reg then
		ins(bag,reg)
	end

	BAG=bag
	return true
end

function newBoard(f)--Generate a new board
	if f then
		return copyList(f)
	else
		local F={}
		for i=1,20 do F[i]={0,0,0,0,0,0,0,0,0,0}end
		return F
	end
end
function copyBoard(page)--Copy the [page] board
	local F=FIELD[page or 1]
	local str=""
	local H=0

	for y=20,1,-1 do
		for x=1,10 do
			if F[y][x]~=0 then
				H=y
				goto topFound
			end
		end
	end
	::topFound::

	--Encode field
	for y=1,H do
		local S=""
		local L=F[y]
		for x=1,10 do
			S=S..char(L[x]+1)
		end
		str=str..S
	end
	return data.encode("string","base64",data.compress("string","zlib",str))
end
function copyBoards()
	local out={}
	for i=1,#FIELD do
		out[i]=copyBoard(i)
	end
	return table.concat(out,"!")
end
function pasteBoard(str,page)--Paste [str] data to [page] board
	if not page then page=1 end
	if not FIELD[page]then FIELD[page]=newBoard()end
	local F=FIELD[page]
	local _,__

	--Decode
	_,str=pcall(data.decode,"string","base64",str)
	if not _ then return end
	_,str=pcall(data.decompress,"string","zlib",str)
	if not _ then return end

	local fX,fY=1,1--*ptr for Field(r*10+(c-1))
	local p=1
	while true do
		_=byte(str,p)--1byte

		--Str end
		if not _ then
			if fX~=1 then
				return
			else
				break
			end
		end

		__=_%32-1--Block id
		if __>26 then return end--Illegal blockid
		_=int(_/32)--Mode id

		F[fY][fX]=__
		if fX<10 then
			fX=fX+1
		else
			fY=fY+1
			if fY>20 then break end
			fX=1
		end
		p=p+1
	end

	for y=fY,20 do
		for x=1,10 do
			F[y][x]=0
		end
	end

	return true
end

--[[
	Mission: 34~114
	Count: 115~126
	Encode: [A] or [AB] sequence, A = mission ID, B = repeat times, no B means do not repeat.

	_1=01,_2=02,_3=03,_4=04,
	A1=05,A2=06,A3=07,A4=08,
	PC=09,
	Z1=11,Z2=12,Z3=13,
	S1=21,S2=22,S3=23,
	J1=31,J2=32,J3=33,
	L1=41,L2=42,L3=43,
	T1=51,T2=52,T3=53,
	O1=61,O2=62,O3=63,O4=64,
	I1=71,I2=72,I3=73,I4=74,
]]
function copyMission()
	local _
	local MISSION=MISSION
	local str=""

	local count=1
	for i=1,#MISSION+1 do
		if MISSION[i+1]~=MISSION[i]or count==13 then
			_=33+MISSION[i]
			str=str..char(_)
			if count>1 then
				str=str..char(113+count)
				count=1
			end
		else
			count=count+1
		end
	end

	return str
end
function pasteMission(str)
	local b
	local mission={}
	local reg
	for i=1,#str do
		b=byte(str,i)
		if not reg then
			if b>=34 and b<=114 then
				reg=b-33
			else
				return
			end
		else
			if b>=34 and b<=114 then
				if missionEnum[reg]then
					ins(mission,reg)
					reg=b-33
				else
					return
				end
			elseif b>=115 and b<=126 then
				for _=1,b-113 do
					ins(mission,reg)
				end
				reg=false
			end
		end
	end
	if reg then
		ins(mission,reg)
	end

	MISSION=mission
	return true
end

function freshDate()
	local date=os.date("%Y/%m/%d")
	if STAT.date~=date then
		STAT.date=date
		STAT.todayTime=0
		LOG.print(text.newDay,"message")
	end
end
function legalGameTime()
	if
		(SETTING.lang==1 or SETTING.lang==2 or SETTING.lang==7)and
		RANKS.sprint_10<4 and
		(not RANKS.sprint_40 or RANKS.sprint_40<3)
	then
		if STAT.todayTime<14400 then
			return true
		elseif STAT.todayTime<21600 then
			LOG.print(text.playedLong,"warning")
			return true
		else
			LOG.print(text.playedTooMuch,"warning")
			return false
		end
	end
	return true
end
function mergeStat(stat,delta)
	for k,v in next,delta do
		if type(v)=="table"then
			if type(stat[k])=="table"then
				mergeStat(stat[k],v)
			end
		else
			if stat[k]then
				stat[k]=stat[k]+v
			end
		end
	end
end

--Functions for royale mode
function randomTarget(P)--Return a random opponent for P
	if #PLAYERS.alive>1 then
		local R
		repeat
			R=PLAYERS.alive[rnd(#PLAYERS.alive)]
		until R~=P
		return R
	end
end
function freshMostDangerous()
	GAME.mostDangerous,GAME.secDangerous=false,false
	local m,m2=0,0
	for i=1,#PLAYERS.alive do
		local h=#PLAYERS.alive[i].field
		if h>=m then
			GAME.mostDangerous,GAME.secDangerous=PLAYERS.alive[i],GAME.mostDangerous
			m,m2=h,m
		elseif h>=m2 then
			GAME.secDangerous=PLAYERS.alive[i]
			m2=h
		end
	end

	for i=1,#PLAYERS.alive do
		if PLAYERS.alive[i].atkMode==3 then
			PLAYERS.alive[i]:freshTarget()
		end
	end
end
function freshMostBadge()
	GAME.mostBadge,GAME.secBadge=false,false
	local m,m2=0,0
	for i=1,#PLAYERS.alive do
		local P=PLAYERS.alive[i]
		local b=P.badge
		if b>=m then
			GAME.mostBadge,GAME.secBadge=P,GAME.mostBadge
			m,m2=b,m
		elseif b>=m2 then
			GAME.secBadge=P
			m2=b
		end
	end

	for i=1,#PLAYERS.alive do
		if PLAYERS.alive[i].atkMode==4 then
			PLAYERS.alive[i]:freshTarget()
		end
	end
end
function royaleLevelup()
	GAME.stage=GAME.stage+1
	local spd
	TEXT.show(text.royale_remain:gsub("$1",#PLAYERS.alive),640,200,40,"beat",.3)
	if GAME.stage==2 then
		spd=30
	elseif GAME.stage==3 then
		spd=15
		for _,P in next,PLAYERS.alive do
			P.gameEnv.garbageSpeed=.6
		end
		if PLAYERS[1].alive then BGM.play("cruelty")end
	elseif GAME.stage==4 then
		spd=10
		for _,P in next,PLAYERS.alive do
			P.gameEnv.pushSpeed=3
		end
	elseif GAME.stage==5 then
		spd=5
		for _,P in next,PLAYERS.alive do
			P.gameEnv.garbageSpeed=1
		end
	elseif GAME.stage==6 then
		spd=3
		if PLAYERS[1].alive then BGM.play("final")end
	end
	for _,P in next,PLAYERS.alive do
		P.gameEnv.drop=spd
	end
	if GAME.curMode.name:find("ultimate")then
		for i=1,#PLAYERS.alive do
			local P=PLAYERS.alive[i]
			P.gameEnv.drop=int(P.gameEnv.drop*.3)
			if P.gameEnv.drop==0 then
				P.curY=P.ghoY
				P:set20G(true)
			end
		end
	end
end

function pauseGame()
	if not SCN.swapping then
		GAME.restartCount=0--Avoid strange darkness
		if not GAME.replaying then
			for i=1,#PLAYERS do
				local l=PLAYERS[i].keyPressing
				for j=1,#l do
					if l[j]then
						PLAYERS[i]:releaseKey(j)
					end
				end
			end
		end
		SCN.swapTo("pause","none")
	end
end
function resumeGame()
	SCN.swapTo("play","none")
end
function applyCustomGame()
	for k,v in next,CUSTOMENV do
		GAME.modeEnv[k]=v
	end
	if BAG[1]then
		GAME.modeEnv.bag=BAG
	else
		GAME.modeEnv.bag=nil
	end
	if MISSION[1]then
		GAME.modeEnv.mission=MISSION
	else
		GAME.modeEnv.mission=nil
	end
end
function loadGame(M,ifQuickPlay)--Load a mode and go to game scene
	freshDate()
	if legalGameTime()then
		if MODES[M].score then STAT.lastPlay=M end
		GAME.curModeName=M
		GAME.curMode=MODES[M]
		GAME.modeEnv=GAME.curMode.env
		drawableText.modeName:set(text.modes[M][1])
		drawableText.levelName:set(text.modes[M][2])
		GAME.init=true
		SCN.go("play",ifQuickPlay and"swipeD"or"fade_togame")
		SFX.play("enter")
	end
end
function initPlayerPosition(sudden)--Set initial position for every player
	local L=PLAYERS.alive
	if not sudden then
		for i=1,#L do
			L[i]:setPosition(640,#L<=5 and 360 or -62,0)
		end
	end

	local method=sudden and"setPosition"or"movePosition"
	L[1][method](L[1],340,75,1)
	if #L<=5 then
		if L[2]then L[2][method](L[2],965,390,.5)end
		if L[3]then L[3][method](L[3],965,30,.5)end
		if L[4]then L[4][method](L[4],20,390,.5)end
		if L[5]then L[5][method](L[5],20,30,.5)end
	elseif #L==49 then
		local n=2
		for i=1,4 do for j=1,6 do
			L[n][method](L[n],78*i-54,115*j-98,.09)
			n=n+1
		end end
		for i=9,12 do for j=1,6 do
			L[n][method](L[n],78*i+267,115*j-98,.09)
			n=n+1
		end end
	elseif #L==99 then
		local n=2
		for i=1,7 do for j=1,7 do
			L[n][method](L[n],46*i-36,97*j-72,.068)
			n=n+1
		end end
		for i=15,21 do for j=1,7 do
			L[n][method](L[n],46*i+264,97*j-72,.068)
			n=n+1
		end end
	end
end
local function tick_showMods()
	local time=0
	while true do
		coroutine.yield()
		time=time+1
		if time%20==0 then
			local M=GAME.mod[time/20]
			if M then
				TEXT.show(M.id,700+(time-20)%120*4,36,45,"spin",.5)
			else
				return
			end
		end
	end
end
function resetGameData(args)
	if not args then args=""end
	if PLAYERS[1]and not GAME.replaying and(GAME.frame>400 or GAME.result)then
		mergeStat(STAT,PLAYERS[1].stat)
		STAT.todayTime=STAT.todayTime+PLAYERS[1].stat.time
	end

	GAME.result=false
	GAME.warnLVL0=0
	GAME.warnLVL=0
	if args:find("r")then
		GAME.frame=0
		GAME.recording=false
		GAME.replaying=1
	else
		GAME.frame=150-SETTING.reTime*15
		GAME.seed=rnd(1046101471,2662622626)
		GAME.pauseTime=0
		GAME.pauseCount=0
		GAME.saved=false
		GAME.setting=copyGameSetting()
		GAME.rep={}
		GAME.recording=true
		GAME.replaying=false
		GAME.rank=0
		math.randomseed(tm.getTime())
	end

	destroyPlayers()
	GAME.curMode.load()
	initPlayerPosition(args:find("q"))
	restoreVirtualKey()
	if GAME.modeEnv.task then
		for i=1,#PLAYERS do
			PLAYERS[i]:newTask(GAME.modeEnv.task)
		end
	end
	BG.set(GAME.modeEnv.bg)
	BGM.play(GAME.modeEnv.bgm)

	TEXT.clear()
	if GAME.modeEnv.royaleMode then
		for i=1,#PLAYERS do
			PLAYERS[i]:changeAtk(randomTarget(PLAYERS[i]))
		end
		GAME.stage=false
		GAME.mostBadge=false
		GAME.secBadge=false
		GAME.mostDangerous=false
		GAME.secDangerous=false
		GAME.stage=1
	end
	STAT.game=STAT.game+1
	FREEROW.reset(30*#PLAYERS)
	TASK.removeTask_code(tick_showMods)
	TASK.new(tick_showMods)
	SFX.play("ready")
	collectgarbage()
end
function gameStart()
	SFX.play("start")
	for P=1,#PLAYERS do
		P=PLAYERS[P]
		P.control=true
		P.timing=true
		P:popNext()
	end
end
function scoreValid()--Check if any unranked mods are activated
	for _,M in next,GAME.mod do
		if M.unranked then
			return false
		end
	end
	return true
end
--[[
	Byte data format: (1 byte each period)
		KeyID, dt, KeyID, dt, ......
	KeyID range from 1 to 20, negative when release key
	dt from 0 to infinity, 0~254 when 0~254, read next byte as dt(if there is an 255, add next byte to dt as well)

	Example:
		1,6, -1,20, 2,0, -2,255,0, 4,255,255,255,62, ......
	This means:
		Press key1 at 6f
		Release key1 at 26f (6+20)
		Press key2 at the same time(26+0)
		Release key 2 after 255+0 frame
		Press key 4 after 255+255+255+62 frame
		......
]]
function dumpRecording(list,ptr)
	local out=""
	local buffer=""
	local prevFrm=0
	ptr=ptr or 1
	while list[ptr]do
		--Check buffer size
		if #buffer>10 then
			out=out..buffer
			buffer=""
		end

		--Encode time
		local t=list[ptr]-prevFrm
		prevFrm=list[ptr]
		while t>=255 do
			buffer=buffer.."\255"
			t=t-255
		end
		buffer=buffer..char(t)

		--Encode key
		t=list[ptr+1]
		buffer=buffer..char(t>0 and t or 256+t)

		--Step
		ptr=ptr+2
	end
	return out..buffer
end
function pumpRecording(str,L)
	-- str=data.decode("string","base64",str)
	local len=#str
	local p=1

	local list,curFrm
	if L then
		list=L
		curFrm=L[#L-1]or 0
	else
		list={}
		curFrm=0
	end

	while p<=len do
		--Read delta time
		::nextByte::
		local b=byte(str,p)
		if b==255 then
			curFrm=curFrm+255
			p=p+1
			goto nextByte
		end
		curFrm=curFrm+b
		list[#list+1]=curFrm
		p=p+1

		b=byte(str,p)
		if b>127 then
			b=b-256
		end
		list[#list+1]=b
		p=p+1
	end
	return list
end

local noRecList={"custom","solo","round","techmino"}
local function getModList()
	local res={}
	for _,v in next,GAME.mod do
		if v.sel>0 then
			ins(res,{v.no,v.sel})
		end
	end
	return res
end
function saveRecording()
	--Filtering modes that cannot be saved
	for _,v in next,noRecList do
		if GAME.curModeName:find(v)then
			LOG.print("Cannot save recording of this mode now!",COLOR.sky)
			return
		end
	end

	--File contents
	local fileName="replay/"..os.date("%Y_%m_%d_%a_%H%M%S.rep")
	local fileHead=
		os.date("%Y/%m/%d_%A_%H:%M:%S\n")..
		GAME.curModeName.."\n"..
		VERSION_NAME.."\n"..
		(USER.username or"Player")
	local fileBody=
		GAME.seed.."\n"..
		json.encode(GAME.setting).."\n"..
		json.encode(getModList()).."\n"..
		dumpRecording(GAME.rep)

	--Write file
	if not fs.getInfo(fileName)then
		fs.write(fileName,fileHead.."\n"..data.compress("string","zlib",fileBody))
		ins(REPLAY,fileName)
		FILE.save(REPLAY,"conf/replay")
		return true
	else
		LOG.print("Save failed: File already exists")
	end
end