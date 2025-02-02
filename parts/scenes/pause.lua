local gc=love.graphics

local int=math.floor
local sin,log=math.sin,math.log10
local format=string.format

local SCR,setFont,mStr=SCR,setFont,mStr

local fnsRankColor={
	Z=COLOR.lYellow,
	S=COLOR.lGrey,
	A=COLOR.sky,
	B=COLOR.lGreen,
	C=COLOR.magenta,
	D=COLOR.dGreen,
	E=COLOR.red,
	F=COLOR.dRed,
}

local scene={}

local timer--Animation timer
local form--Form of clear & spins
local radar--Radar chart
local val--Radar chart normalizer
local standard--Standard hexagon
local chartColor--Color of radar chart
local rank--Current rank
local trophy--Current trophy
local trophyColor--Current trophy color

function scene.sceneInit(org)
	if org:find("setting")then
		TEXT.show(text.needRestart,640,440,50,"fly",.6)
	end
	local P=PLAYERS[1]
	local S=P.stat

	timer=org=="play"and 0 or 50

	form={
		format("%s / %s",toTime(S.frame/60),toTime(S.time)),
		format("%d/%d/%d",S.key,S.rotate,S.hold),
		format("%d  %.2fPPS",S.piece,S.piece/S.time),
		format("%d(%d)  %.2fLPM",S.row,S.dig,S.row/S.time*60),
		format("%d(%d)  %.2fAPM",S.atk,S.digatk,S.atk/S.time*60),
		format("%d(%d-%d)",S.pend,S.recv,S.recv-S.pend),
		format("%d/%d/%d/%d",S.clears[1],S.clears[2],S.clears[3],S.clears[4]),
		format("(%d)/%d/%d/%d",S.spins[1],S.spins[2],S.spins[3],S.spins[4]),
		format("%d/%d ; %d/%d",S.b2b,S.b3b,S.pc,S.hpc),
		format("%d/%dx/%.2f%%",S.extraPiece,S.maxFinesseCombo,S.finesseRate*20/S.piece),
	}
	--From right-down, 60 degree each
	radar={
		(S.off+S.dig)/S.time*60,--DefPM
		(S.atk+S.dig)/S.time*60,--ADPM
		S.atk/S.time*60,		--AtkPM
		S.send/S.time*60,		--SendPM
		S.piece/S.time*24,		--LinePM
		S.dig/S.time*60,		--DigPM
	}
	val={1/80,1/80,1/80,1/60,1/100,1/40}

	--Normalize Values
	for i=1,6 do
		val[i]=val[i]*radar[i]if val[i]>1.26 then val[i]=1.26+log(val[i]-.26)end
	end

	for i=1,6 do
		radar[i]=format("%.2f",radar[i])..text.radarData[i]
	end
	local f=1
	for i=1,6 do
		if val[i]>.5 then f=2 end
		if val[i]>1 then f=3 break end
	end
	if f==1 then	 chartColor,f={.4,.9,.5},1.25	--Vegetable
	elseif f==2 then chartColor,f={.4,.7,.9},1		--Normal
	elseif f==3 then chartColor,f={1,.3,.3},.626	--Diao
	end
	standard={
		120*.5*f,	120*3^.5*.5*f,
		120*-.5*f,	120*3^.5*.5*f,
		120*-1*f,	120*0*f,
		120*-.5*f,	120*-3^.5*.5*f,
		120*.5*f,	120*-3^.5*.5*f,
		120*1*f,	120*0*f,
	}

	for i=6,1,-1 do
		val[2*i-1],val[2*i]=val[i]*standard[2*i-1],val[i]*standard[2*i]
	end

	if P.result=="WIN"and P.stat.piece>4 then
		local acc=P.stat.finesseRate*.2/P.stat.piece
		rank=
			acc==1. and"Z"or
			acc>.97 and"S"or
			acc>.94 and"A"or
			acc>.87 and"B"or
			acc>.70 and"C"or
			acc>.50 and"D"or
			acc>.30 and"E"or
			"F"
		if acc==1 then
			trophy=text.finesse_ap
			trophyColor=COLOR.yellow
		elseif P.stat.maxFinesseCombo==P.stat.piece then
			trophy=text.finesse_fc
			trophyColor=COLOR.lCyan
		end
	else
		rank,trophy=nil
	end
	if not(GAME.result or GAME.replaying)then
		GAME.pauseCount=GAME.pauseCount+1
	end
	if org~="play"and GAME.prevBG then
		BG.set(GAME.prevBG)
	end
end
function scene.sceneBack()
	love.keyboard.setKeyRepeat(true)
	STAT.todayTime=STAT.todayTime+PLAYERS[1].stat.time
	if not GAME.replaying and(GAME.frame>400 or GAME.result)and not GAME.result then
		mergeStat(STAT,PLAYERS[1].stat)
		FILE.save(STAT,"conf/data")
	end
end

function scene.keyDown(key)
	if key=="q"then
		SCN.back()
	elseif key=="escape"then
		resumeGame()
	elseif key=="s"then
		GAME.prevBG=BG.cur
		SCN.go("setting_sound")
	elseif key=="r"then
		resetGameData()
		SCN.swapTo("play","none")
	elseif key=="p"then
		if(GAME.result or GAME.replaying)and #PLAYERS==1 then
			resetGameData("r")
			SCN.swapTo("play","none")
		end
	elseif key=="o"then
		if(GAME.result or GAME.replaying)and #PLAYERS==1 and not GAME.saved and saveRecording()then
			GAME.saved=true
		end
	end
end

function scene.update(dt)
	if not(GAME.result or GAME.replaying)then
		GAME.pauseTime=GAME.pauseTime+dt
	end
	if timer<50 then
		timer=timer+1
	end
end

local hexList={1,0,.5,1.732*.5,-.5,1.732*.5}
for i=1,6 do hexList[i]=hexList[i]*150 end
local textPos={90,131,-90,131,-200,-25,-90,-181,90,-181,200,-25}
local dataPos={90,143,-90,143,-200,-13,-90,-169,90,-169,200,-13}
function scene.draw()
	local T=timer*.02
	if T<1 or GAME.result then SCN.scenes.play.draw()end

	--Dark BG
	local _=T
	if GAME.result then _=_*.7 end
	gc.setColor(.15,.15,.15,_)
	gc.push("transform")
		gc.origin()
		gc.rectangle("fill",0,0,SCR.w,SCR.h)
	gc.pop()

	--Pause Info
	setFont(25)
	if GAME.pauseCount>0 then
		gc.setColor(1,.4,.4,T)
		gc.print(text.pauseCount..":["..GAME.pauseCount.."] "..format("%.2f",GAME.pauseTime).."s",40,180)
	end

	gc.setColor(1,1,1,T)

	--Result Text
	setFont(35)
	mText(GAME.result and drawableText[GAME.result]or drawableText.pause,640,50-10*(5-timer*.1)^1.5)

	--Mode Info
	_=drawableText.modeName
	gc.draw(_,40,240)
	gc.draw(drawableText.levelName,60+_:getWidth(),240)

	--Infos
	if GAME.frame>180 then
		gc.setLineWidth(2)
		--Finesse rank & trophy
		if rank then
			gc.setColor(1,1,1,T*.2)
			gc.rectangle("fill",35,305,465,405)

			setFont(60)
			local c=fnsRankColor[rank]
			gc.setColor(c[1],c[2],c[3],T)
			gc.print(rank,420,635)
			if trophy then
				setFont(40)
				gc.setColor(trophyColor[1],trophyColor[2],trophyColor[3],T*2-1)
				gc.printf(trophy,100-120*(1-T^.5),650,300,"right")
			end

			gc.setColor(1,1,1,T)
			gc.rectangle("line",35,305,465,405)
			gc.line(35,620,500,620)
		else
			gc.setColor(1,1,1,T*.2)
			gc.rectangle("fill",35,305,465,350)
			gc.setColor(1,1,1,T)
			gc.rectangle("line",35,305,465,350)
		end

		_=form
		setFont(25)
		for i=1,10 do
			gc.print(text.pauseStat[i],40,270+35*i)
			gc.printf(_[i],195,270+35*i,300,"right")
		end
	end

	--Mods
	if #GAME.mod>0 then
		if scoreValid()then
			gc.setColor(.7,.7,.7,T)
			gc.rectangle("line",775,560,490,140)
			gc.setColor(.7,.7,.7,T*.26)
			gc.rectangle("fill",775,560,490,140)
		else
			gc.setColor(1,0,0,T)
			gc.rectangle("line",775,560,490,140)
			gc.setColor(1,0,0,T*.26)
			gc.rectangle("fill",775,560,490,140)
		end
		setFont(35)
		for _,M in next,MODOPT do
			if M.sel>0 then
				_=M.color
				gc.setColor(_[1],_[2],_[3],T)
				mStr(M.id,810+M.no%8*60,560+int(M.no/8)*45)
			end
		end
	end

	--Level rank
	if GAME.rank>0 then
		local str=text.ranks[GAME.rank]
		setFont(80)

		gc.setColor(0,0,0,T*.3)
		gc.print(str,46,-14,nil,1.8)
		gc.print(str,46,-6,nil,1.8)
		gc.print(str,54,-14,nil,1.8)
		gc.print(str,54,-6,nil,1.8)

		gc.setColor(0,0,0,T*.15)
		gc.print(str,46,-10,nil,1.8)
		gc.print(str,54,-10,nil,1.8)
		gc.print(str,50,-14,nil,1.8)
		gc.print(str,50,-6,nil,1.8)

		local L=rankColor[GAME.rank]
		gc.setColor(L[1],L[2],L[3],T)
		gc.print(str,50,-10,nil,1.8)
	end

	--Radar Chart
	if T>.5 and GAME.frame>180 then
		T=T*2-1
		gc.setLineWidth(2)
		gc.push("transform")
			gc.translate(1026,370)

			--Polygon
			gc.push("transform")
				gc.scale((3-2*T)*T)
				gc.setColor(1,1,1,T*(.5+.3*sin(TIME()*6.26)))gc.polygon("line",standard)
				gc.setColor(chartColor[1],chartColor[2],chartColor[3],T*.626)
				for i=1,9,2 do
					gc.polygon("fill",0,0,val[i],val[i+1],val[i+2],val[i+3])
				end
				gc.polygon("fill",0,0,val[11],val[12],val[1],val[2])
				gc.setColor(1,1,1,T)gc.polygon("line",val)
			gc.pop()

			--Axes
			gc.setColor(1,1,1,T)
			for i=1,3 do
				local x,y=hexList[2*i-1],hexList[2*i]
				gc.line(-x,-y,x,y)
			end

			--Texts
			local C
			_=TIME()%6.2832
			if _>3.1416 then
				gc.setColor(1,1,1,-T*sin(_))
				setFont(35)
				C,_=text.radar,textPos
			else
				gc.setColor(1,1,1,T*sin(_))
				setFont(20)
				C,_=radar,dataPos
			end
			for i=1,6 do
				mStr(C[i],_[2*i-1],_[2*i])
			end
		gc.pop()
	end
end

scene.widgetList={
	WIDGET.newButton{name="setting",	x=1120,	y=70,	w=240,h=90,	color="lBlue",	font=35,code=WIDGET.lnk_pressKey("s")},
	WIDGET.newButton{name="replay",		x=535,	y=250,	w=200,h=100,color="lYellow",font=30,code=WIDGET.lnk_pressKey("p"),hide=function()return not(GAME.result or GAME.replaying)or #PLAYERS>1 end},
	WIDGET.newButton{name="save",		x=745,	y=250,	w=200,h=100,color="green",	font=30,code=WIDGET.lnk_pressKey("o"),hide=function()return not(GAME.result or GAME.replaying)or #PLAYERS>1 or GAME.saved end},
	WIDGET.newButton{name="resume",		x=640,	y=367,	w=240,h=100,color="lGreen",	font=30,code=WIDGET.lnk_pressKey("escape")},
	WIDGET.newButton{name="restart",	x=640,	y=483,	w=240,h=100,color="lRed",	font=35,code=WIDGET.lnk_pressKey("r")},
	WIDGET.newButton{name="quit",		x=640,	y=600,	w=240,h=100,font=35,code=WIDGET.lnk_BACK},
}

return scene