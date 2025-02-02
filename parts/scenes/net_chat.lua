local gc=love.graphics

local ins,rem=table.insert,table.remove
local max,min=math.max,math.min

local texts={}
local remain--People in chat room
local scrollPos--Scroll up length
local newMessage=false--If there is a new message
local heartBeatTimer
local escapeTimer=0

local function focusAtTextbox()
	coroutine.yield()
	WIDGET.sel=WIDGET.active.text
end
local function sendMessage()
	local W=WIDGET.active.text
	if #W.value>0 and wsWrite(W.value)then
		W.value=""
	end
end
local function clearHistory()
	while #texts>1 do rem(texts)end
	scrollPos=1
	SFX.play("fall")
	collectgarbage()
end

local scene={}

function scene.sceneInit()
	heartBeatTimer=0
	remain=false

	if #texts==0 then
		ins(texts,{COLOR.dG,text.chatStart})
	elseif #texts>1 and texts[#texts][1]~=COLOR.dG then
		ins(texts,{COLOR.dG,text.chatHistory})
	end
	scrollPos=#texts
	TASK.new(focusAtTextbox)--Widgets are not initialized, so active after 1 frame
	TASK.new(TICK.ws_read)
	BG.set("none")
end
function scene.sceneBack()
	wsWrite("/quit")
	WSCONN=false
	LOG.print(text.wsDisconnected,"warn")
end

function scene.wheelMoved(_,y)
	wheelScroll(y)
end
function scene.keyDown(k)
	if k=="up"then
		scrollPos=max(scrollPos-1,min(#texts,12))
	elseif k=="down"then
		scrollPos=min(scrollPos+1,#texts)
		if scrollPos==#texts then
			newMessage=false
		end
	elseif k=="return"then
		sendMessage()
	elseif k=="escape"then
		if TIME()-escapeTimer<.6 then
			SCN.back()
		else
			escapeTimer=TIME()
			LOG.print(text.chatQuit,COLOR.orange)
		end
	else
		WIDGET.keyPressed(k)
	end
end

function scene.socketRead(mes)
	if mes:byte()==35 then--system message
		local sep=mes:find(":")
		local cmd=mes:sub(2,sep-1)
		local data=mes:sub(sep+1)
		if cmd=="J"or cmd=="L"then
			sep=data:find("@")
			local num=data:find("#")
			remain=tonumber(data:sub(1,sep-1))
			ins(texts,{
				COLOR.lR,data:sub(sep+1,num-1),
				COLOR.dY,data:sub(num).." ",
				COLOR.Y,(cmd=="J"and text.chatJoin or text.chatLeave),
			})
		end
	else--user message
		local sep=mes:find(":")
		local num=mes:find("#")
		ins(texts,{
			COLOR.W,mes:sub(1,num-1),
			COLOR.dY,mes:sub(num,sep-1).." ",
			COLOR.sky,mes:sub(sep+1),
		})
	end
	if scrollPos==#texts-1 then
		scrollPos=scrollPos+1
	else
		SFX.play("spin_0",.8)
		newMessage=true
	end
end

function scene.update(dt)
	heartBeatTimer=heartBeatTimer+dt
	if heartBeatTimer>42 then
		heartBeatTimer=0
		wsWrite("/ping")
	end
end
function scene.draw()
	setFont(25)
	gc.setColor(1,1,1)
	gc.printf(text.chatRemain,800,10,400,"right")
	gc.print(remain or"?",1205,10)

	setFont(30)
	for i=max(scrollPos-11,1),scrollPos do
		gc.printf(texts[i],40,416-36*(scrollPos-i),1240)
	end

	--Slider
	if #texts>12 then
		gc.setLineWidth(2)
		gc.rectangle("line",10,30,20,420)
		local len=420*12/#texts
		gc.rectangle("fill",13,33+(414-len)*(scrollPos-12)/(#texts-12),14,len)
	end

	--Draw
	if newMessage and scrollPos~=#texts then
		setFont(40)
		gc.setColor(1,TIME()%.4<.2 and 1 or 0,0)
		gc.print("v",8,480)
	end
end

scene.widgetList={
	WIDGET.newTextBox{name="text",	x=40,	y=500,w=980,h=180,font=40},
	WIDGET.newButton{name="clear",	x=1140,	y=440,w=170,h=80,font=40,code=clearHistory,hide=function()return #texts<2 or newMessage end},
	WIDGET.newButton{name="send",	x=1140,	y=540,w=170,h=80,font=40,code=sendMessage},
	WIDGET.newButton{name="back",	x=1140,	y=640,w=170,h=80,font=40,code=WIDGET.lnk_BACK},
}

return scene