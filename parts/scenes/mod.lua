local gc=love.graphics
local kb=love.keyboard
local ins,rem=table.insert,table.remove

local function modComp(a,b)
	return a.no<b.no
end
local function remMod(M)
	for i=1,#GAME.mod do
		if GAME.mod[i]==M then
			rem(GAME.mod,i)
			return
		end
	end
end
local function toggleMod(M,back)
	if M.sel==0 then
		ins(GAME.mod,M)
		table.sort(GAME.mod,modComp)
	end
	if M.list then
		if back then
			M.sel=(M.sel-1)%(#M.list+1)
		else
			M.sel=(M.sel+1)%(#M.list+1)
		end
	else
		M.sel=1-M.sel
	end
	if M.sel==0 then
		remMod(M)
	end
	if M.unranked then
		SFX.play("move",.6)
		SFX.play("lock")
	else
		SFX.play("move")
		SFX.play("lock",.6)
	end
end

local scene={}

local selected--Mod selected

function scene.sceneInit()
	selected=false
	BG.set("tunnel")
end

function scene.mouseMove(x,y)
	selected=false
	for _,M in next,MODOPT do
		if(x-M.x)^2+(y-M.y)^2<2000 then
			selected=M
			break
		end
	end
end
function scene.mouseDown(x,y,k)
	for _,M in next,MODOPT do
		if(x-M.x)^2+(y-M.y)^2<2000 then
			toggleMod(M,k==2 or kb.isDown("lshift","rshift"))
			break
		end
	end
end
function scene.touchMove(_,x,y)
	scene.mouseMove(x,y)
end
function scene.touchDown(_,x,y)
	scene.mouseMove(x,y)
	scene.mouseDown(x,y)
end
function scene.keyDown(key)
	if key=="tab"or key=="delete"then
		if GAME.mod[1]then
			while GAME.mod[1]do
				rem(GAME.mod).sel=0
			end
			SFX.play("hold")
		end
	elseif #key==1 then
		for _,M in next,MODOPT do
			if key==M.key then
				toggleMod(M,kb.isDown("lshift","rshift"))
				selected=M
				break
			end
		end
	elseif key=="escape"then
		SCN.back()
	end
end

function scene.update()
	for _,M in next,MODOPT do
		if M.sel==0 then
			if M.time>0 then
				M.time=M.time-1
			end
		else
			if M.time<10 then
				M.time=M.time+1
			end
		end
	end
end
function scene.draw()
	setFont(40)
	gc.setLineWidth(5)
	for _,M in next,MODOPT do
		gc.push("transform")
		gc.translate(M.x,M.y)
		local t=M.time*.01--t range:0~0.1
		gc.scale(1+3*t)
		gc.rotate(t)
			local rad,side
			if M.unranked then
				rad,side=45,5
			else
				rad=40
			end
			local color=M.color
			gc.setColor(color[1],color[2],color[3],5*t)
			gc.circle("fill",0,0,rad,side)

			gc.setColor(color)
			gc.circle("line",0,0,rad,side)
			gc.setColor(1,1,1)
			mStr(M.id,0,-28)
			if M.sel>0 and M.list then
				setFont(25)
				gc.setColor(1,1,1,10*t)
				mStr(M.list[M.sel],20,8)
				setFont(40)
			end

			if M.list then
				gc.setColor(1,1,1,t*6)
				gc.arc("line","open",0,0,rad+6,0,(M.sel/#M.list)*6.2832)
			end
		gc.pop()
	end

	gc.setColor(1,1,1)
	if selected then
		setFont(30)
		gc.printf(text.modInfo[selected.name],70,540,950)
	else
		setFont(25)
		gc.printf(text.modInstruction,70,540,950)
	end
end

scene.widgetList={
	WIDGET.newText{name="title",	x=80,y=50,font=70,align="L"},
	WIDGET.newText{name="unranked",	x=1200,y=60,color="yellow",font=50,align="R",hide=function()return scoreValid()end},
	WIDGET.newButton{name="reset",	x=1140,y=540,w=170,h=80,font=25,code=WIDGET.lnk_pressKey("tab")},
	WIDGET.newButton{name="back",	x=1140,y=640,w=170,h=80,font=40,code=WIDGET.lnk_BACK},
}

return scene