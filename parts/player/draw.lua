local gc=love.graphics
local gc_push,gc_pop,gc_scale,gc_translate=gc.push,gc.pop,gc.scale,gc.translate
local gc_draw,gc_print,gc_line,gc_rectangle,gc_circle=gc.draw,gc.print,gc.line,gc.rectangle,gc.circle
local gc_setColor,gc_setLineWidth=gc.setColor,gc.setLineWidth
local TIME=love.timer.getTime
local int,ceil,rnd=math.floor,math.ceil,math.random
local max,min,sin=math.max,math.min,math.sin
local format=string.format
local SCR=SCR
local setFont,mStr=setFont,mStr

local frameColorList={
	[0]=COLOR.white,
	COLOR.lGreen,
	COLOR.lBlue,
	COLOR.lPurple,
	COLOR.lOrange,
}
--local function drawCell(y,x,id)gc_draw(SKIN.curText[id],30*x-30,-30*y)end
local function drawGrid(P,alpha)
	local FBN,FUP=P.fieldBeneath,P.fieldUp
	gc_setLineWidth(1)
	gc_setColor(1,1,1,alpha)
	for x=1,9 do
		gc_line(30*x,-10,30*x,600)
	end
	gc_push("transform")
	gc_translate(0,FBN+FUP-30*int((FBN+FUP)/30))
	for y=0,19 do
		gc_line(0,30*y,300,30*y)
	end
	gc_pop()
end
local function drawField(P)
	local V,F=P.visTime,P.field
	local start=int((P.fieldBeneath+P.fieldUp)/30+1)
	local rep=GAME.replaying
	local texture=SKIN.curText
	if P.falling==-1 then--Blocks only
		local t=TIME()*4
		for j=start,min(start+21,#F)do
			for i=1,10 do
				if F[j][i]>0 then
					if V[j][i]>0 then
						gc_setColor(1,1,1,min(V[j][i]*.05,1))
						gc_draw(texture[F[j][i]],30*i-30,-30*j)-- drawCell(j,i,F[j][i])
					elseif rep then
						gc_setColor(1,1,1,.3+.08*sin(.5*(j-i)+t))
						gc_rectangle("fill",30*i-30,-30*j,30,30)
					end
				end
			end
		end
	else--With falling animation
		local ENV=P.gameEnv
		local stepY=ENV.smooth and(P.falling/(ENV.fall+1))^2.5*30 or 30
		local A=P.falling/ENV.fall
		local h=1
		gc_push("transform")
			for j=start,min(start+21,#F)do
				while j==P.clearingRow[h]do
					h=h+1
					gc_translate(0,-stepY)
					gc_setColor(1,1,1,A)
					gc_rectangle("fill",0,30-30*j,300,stepY)
				end
				for i=1,10 do
					if F[j][i]>0 then
						if V[j][i]>0 then
							gc_setColor(1,1,1,min(V[j][i]*.05,1))
							gc_draw(texture[F[j][i]],30*i-30,-30*j)-- drawCell(j,i,F[j][i])
						elseif rep then
							gc_setColor(1,1,1,.2)
							gc_rectangle("fill",30*i-30,-30*j,30,30)
						end
					end
				end
			end
		gc_pop()
	end
end
local function drawFXs(P)
	--LockFX
	for i=1,#P.lockFX do
		local S=P.lockFX[i]
		if S[3]<.5 then
			gc_setColor(1,1,1,2*S[3])
			gc_rectangle("fill",S[1],S[2],60*S[3],30)
		else
			gc_setColor(1,1,1,2-2*S[3])
			gc_rectangle("fill",S[1]+30,S[2],60*S[3]-60,30)
		end
	end

	--DropFX
	for i=1,#P.dropFX do
		local S=P.dropFX[i]
		gc_setColor(1,1,1,.6-S[5]*.6)
		local w=30*S[3]*(1-S[5]*.5)
		gc_rectangle("fill",30*S[1]-30+15*S[3]-w*.5,-30*S[2],w,30*S[4])
	end

	--MoveFX
	local texture=SKIN.curText
	for i=1,#P.moveFX do
		local S=P.moveFX[i]
		gc_setColor(1,1,1,.6-S[4]*.6)
		gc_draw(texture[S[1]],30*S[2]-30,-30*S[3])-- drawCell(S[3],S[2],S[1])
	end

	--ClearFX
	for i=1,#P.clearFX do
		local S=P.clearFX[i]
		local t=S[2]
		local x=t<.3 and 1-(3.3333*t-1)^2 or 1
		local y=t<.2 and 5*t or 1-1.25*(t-.2)
		gc_setColor(1,1,1,y)
		gc_rectangle("fill",150-x*150,15-S[1]*30-y*15,300*x,y*30)
	end
end
local function drawGhost(P,clr)
	gc_setColor(1,1,1,P.gameEnv.ghost)
	local texture=SKIN.curText
	local CB=P.cur.bk
	for i=1,#CB do for j=1,#CB[1]do
		if CB[i][j]then
			gc_draw(texture[clr],30*(j+P.curX-1)-30,-30*(i+P.ghoY-1))-- drawCell(i+P.ghoY-1,j+P.curX-1,clr)
		end
	end end
end
local function drawBlockOutline(P,texture,trans)
	SHADER.alpha:send("a",trans)
	gc.setShader(SHADER.alpha)
	local CB=P.cur.bk
	for i=1,#CB do for j=1,#CB[1]do
		if CB[i][j]then
			local x=30*(j+P.curX)-60-3
			local y=30-30*(i+P.curY)-3
			gc_draw(texture,x,y)
			gc_draw(texture,x+6,y+6)
			gc_draw(texture,x+6,y)
			gc_draw(texture,x,y+6)
		end
	end end
	gc.setShader()
end
local function drawBlock(P,clr)
	gc_setColor(1,1,1)
	local texture=SKIN.curText
	local CB=P.cur.bk
	for i=1,#CB do for j=1,#CB[1]do
		if CB[i][j]then
			gc_draw(texture[clr],30*(j+P.curX-1)-30,-30*(i+P.curY-1))-- drawCell(i+P.curY-1,j+P.curX-1,clr)
		end
	end end
end
local function drawNextPreview(P,B)
	gc_setColor(1,1,1,.8)
	local x=int(6-#B[1]*.5)
	local y=21+ceil(P.fieldBeneath/30)
	for i=1,#B do for j=1,#B[1]do
		if B[i][j]then
			gc_draw(puzzleMark[-1],30*(x+j-2),30*(1-y-i))
		end
	end end
end

local draw={}

function draw.drawNext_norm(P)
	local ENV=P.gameEnv
	local N=ENV.nextCount*72
	local texture=SKIN.curText
	gc_push("transform")
	gc_translate(316,116)
		gc_setColor(0,0,0,.4)gc_rectangle("fill",0,-80,124,N+8)
		gc_setColor(1,1,1)gc_rectangle("line",0,-80,124,N+8)
		mText(drawableText.next,62,-131)
		N=1
		while N<=ENV.nextCount and P.nextQueue[N]do
			local bk,clr=P.nextQueue[N].bk,P.nextQueue[N].color
			for i=1,#bk do for j=1,#bk[1] do
				if bk[i][j]then
					gc_draw(texture[clr],30*(j+2.06-#bk[1]*.5)-30,-30*(i+3.76-2.4*N-#bk*.5))-- drawCell(i-2.4*N-#bk*.5,j+12.6-#bk[1]*.5,clr)
				end
			end end
			N=N+1
		end

		if ENV.bagLine then
			local len=ENV.bagLen
			local phase=-P.pieceCount%len
			gc_setColor(.8,.5,.5)
			for i=phase,N-1,len do
				local y=72*i-77
				gc_line(2+P.fieldOff.x,y,120,y)
			end
		end
	gc_pop()
end
function draw.drawNext_hidden(P)
	local ENV=P.gameEnv
	local N=ENV.nextCount*72
	local texture=SKIN.curText
	gc_push("transform")
	gc_translate(316,116)
		gc_setColor(.5,0,0,.4)gc_rectangle("fill",0,-80,124,N+8)
		gc_setColor(1,1,1)gc_rectangle("line",0,-80,124,N+8)
		mText(drawableText.next,62,-131)
		N=min(ENV.nextStartPos,P.pieceCount+1)
		while N<=ENV.nextCount and P.nextQueue[N]do
			local bk,clr=P.nextQueue[N].bk,P.nextQueue[N].color
			for i=1,#bk do for j=1,#bk[1] do
				if bk[i][j]then
					gc_draw(texture[clr],30*(j+2.06-#bk[1]*.5)-30,-30*(i+3.76-2.4*N-#bk*.5))-- drawCell(i-2.4*N-#bk*.5,j+12.6-#bk[1]*.5,clr)
				end
			end end
			N=N+1
		end

		if ENV.bagLine then
			local len=ENV.bagLen
			local phase=-P.pieceCount%len
			gc_setColor(.8,.5,.5)
			for i=phase,N-1,len do
				local y=72*i-77
				gc_line(2+P.fieldOff.x,y,120,y)
			end
		end
	gc_pop()
end

function draw.drawHold_norm(P)
	local texture=SKIN.curText
	gc_push("transform")
	gc_translate(-140,116)
		gc_setColor(0,0,0,.4)gc_rectangle("fill",0,-80,124,80)
		gc_setColor(1,1,1)gc_rectangle("line",0,-80,124,80)
		if P.holdTime==0 then gc_setColor(.6,.4,.4)end
		mText(drawableText.hold,62,-131)

		local B=P.holdQueue[1]
		if B then
			local bk,clr=B.bk,B.color
			for i=1,#bk do for j=1,#bk[1]do
				if bk[i][j]then
					gc_draw(texture[clr],30*(j+2.06-#bk[1]*.5)-30,-30*(i+3.76-2.4*1-#bk*.5))-- drawCell(i+1.36-#B*.5,j+2.06-#B[1]*.5,clr)
				end
			end end
		end
	gc_pop()
end
function draw.drawHold_multi(P)
	local ENV=P.gameEnv
	local N=ENV.holdCount*72
	local texture=SKIN.curText
	gc_push("transform")
	gc_translate(-140,116)
		gc_setColor(0,0,0,.4)gc_rectangle("fill",0,-80,124,N+8)
		gc_setColor(1,1,1)gc_rectangle("line",0,-80,124,N+8)
		if P.holdTime==0 then gc_setColor(.6,.4,.4)end
		mText(drawableText.hold,62,-131)

		gc_setColor(1,1,1)
		if #P.holdQueue<P.gameEnv.holdCount and P.nextQueue[1]then
			N=1
		else
			N=P.holdTime+1
		end
		for n=1,#P.holdQueue do
			if n==N then gc_setColor(.6,.4,.4)end
			local bk,clr=P.holdQueue[n].bk,P.holdQueue[n].color
			for i=1,#bk do for j=1,#bk[1]do
				if bk[i][j]then
					gc_draw(texture[clr],30*(j+2.06-#bk[1]*.5)-30,-30*(i+3.76-2.4*n-#bk*.5))-- drawCell(i+1.36-#B*.5,j+2.06-#B[1]*.5,clr)
				end
			end end
		end
	gc_pop()
end

function draw.drawTargetLine(P,r)
	if r<21+(P.fieldBeneath+P.fieldUp)/30 and r>0 then
		gc_setLineWidth(4)
		gc_setColor(1,r>10 and 0 or rnd(),.5)
		local dx,dy=150+P.fieldOff.x,P.fieldOff.y+P.fieldBeneath+P.fieldUp
		gc_line(dx,600-30*r+dy,300+dx,600-30*r+dy)
	end
end

local attackColor={
	{COLOR.dGrey,COLOR.white},
	{COLOR.grey,COLOR.white},
	{COLOR.lPurple,COLOR.white},
	{COLOR.lRed,COLOR.white},
	{COLOR.dGreen,COLOR.cyan},
}
local RCPB={5,33,195,33,100,5,100,60}
local function drawDial(x,y,speed)
	gc_setColor(1,1,1)
	mStr(int(speed),x,y-18)

	gc_setLineWidth(2)
	gc_circle("line",x,y,30,6)

	gc_draw(IMG.dialNeedle,x,y,2.094+(speed<=175 and .02094*speed or 4.712-52.36/(speed-125)),nil,nil,5,4)

	gc_setLineWidth(4)
	gc_setColor(1,1,1,.4)
	gc_circle("line",x,y,30,6)
end
local hideBoardStencil={
	up=function()gc_rectangle("fill",0,0,300,300)end,
	down=function()gc_rectangle("fill",0,300,300,300)end,
	all=function()gc_rectangle("fill",0,0,300,600)end,
}
function draw.norm(P)
	local _
	local ENV=P.gameEnv
	local FBN,FUP=P.fieldBeneath,P.fieldUp
	local t=TIME()
	gc_push("transform")
		gc_translate(P.x,P.y)gc_scale(P.size)

		--Field-related things
		gc_push("transform")
			gc_translate(150,0)

			--Things shake with field
			gc_push("transform")
				gc_translate(P.fieldOff.x,P.fieldOff.y)

				--Fill field
				gc_setColor(0,0,0,.6)
				gc_rectangle("fill",0,-10,300,610)

				--Draw grid
				if ENV.grid then drawGrid(P,ENV.grid)end

				--In-field things
				gc_push("transform")
					if ENV.flipBoard then
						if ENV.flipBoard=="U-D"then
							gc_translate(0,590)
							gc_scale(1,-1)
						elseif ENV.flipBoard=="L-R"then
							gc_translate(300,0)
							gc_scale(-1,1)
						elseif ENV.flipBoard=="180"then
							gc_translate(300,590)
							gc_scale(-1,-1)
						end
					end
					gc_translate(0,600+FBN+FUP)
					gc.setScissor(SCR.x+(P.absFieldX+P.fieldOff.x)*SCR.k,SCR.y+(P.absFieldY+P.fieldOff.y)*SCR.k,300*P.size*SCR.k,610*P.size*SCR.k)

					--Draw dangerous area
					gc_setColor(1,0,0,.3)
					gc_rectangle("fill",0,-600,300,-FUP-FBN-10)

					--Draw field
					drawField(P)

					--Draw spawn line
					gc_setColor(1,sin(t)*.4+.5,0,.5)
					gc_setLineWidth(4)
					gc_line(0,-600-FBN,300,-600-FBN)

					--Draw FXs
					drawFXs(P)

					--Draw current block
					if P.cur and P.waiting==-1 then
						local curColor=P.cur.color

						--Draw ghost
						if ENV.ghost then drawGhost(P,curColor)end

						local dy=ENV.smooth and P.ghoY~=P.curY and(P.dropDelay/ENV.drop-1)*30 or 0
						gc_translate(0,-dy)
						local trans=P.lockDelay/ENV.lock

						--Draw block
						if ENV.block then
							drawBlockOutline(P,SKIN.curText[curColor],trans)
							drawBlock(P,curColor)
						end

						--Draw rotate center
						local x=30*(P.curX+P.sc[2])-15
						if ENV.center and ENV.block then
							gc_setColor(1,1,1,ENV.center)
							gc_draw(IMG.spinCenter,x,-30*(P.curY+P.sc[1])+15,nil,nil,nil,4,4)
						end
						gc_translate(0,dy)
						if ENV.center and ENV.ghost then
							gc_setColor(1,1,1,trans*ENV.center)
							gc_draw(IMG.spinCenter,x,-30*(P.ghoY+P.sc[1])+15,nil,nil,nil,4,4)
						end
					end

					--Draw next preview
					if ENV.nextPos and P.nextQueue[1]then
						drawNextPreview(P,P.nextQueue[1].bk)
					end

					gc.setScissor()
				gc_pop()

				gc_setLineWidth(2)
				gc_setColor(frameColorList[P.frameColor])
				gc_rectangle("line",-1,-11,302,612)--Boarder
				gc_rectangle("line",301,-3,15,604)--AtkBuffer boarder
				gc_rectangle("line",-16,-3,15,604)--B2b bar boarder

				--Buffer line
				local h=0
				for i=1,#P.atkBuffer do
					local A=P.atkBuffer[i]
					local bar=A.amount*30
					if h+bar>600 then bar=600-h end
					if not A.sent then
						--Appear
						if A.time<20 then
							bar=bar*(20*A.time)^.5*.05
						end
						if A.countdown>0 then
							--Timing
							gc_setColor(attackColor[A.lv][1])
							gc_rectangle("fill",303,599-h,11,-bar)
							gc_setColor(attackColor[A.lv][2])
							gc_rectangle("fill",303,599-h-bar,11,bar*(1-A.countdown/A.cd0))
						else
							--Warning
							local a=math.sin((t-i)*30)*.5+.5
							local c1,c2=attackColor[A.lv][1],attackColor[A.lv][2]
							gc_setColor(c1[1]*a+c2[1]*(1-a),c1[2]*a+c2[2]*(1-a),c1[3]*a+c2[3]*(1-a))
							gc_rectangle("fill",303,599-h,11,-bar)
						end
					else
						gc_setColor(attackColor[A.lv][1])
						bar=bar*(20-A.time)*.05
						gc_rectangle("fill",303,599-h,11,-bar)
						--Disappear
					end
					h=h+bar
				end

				--B2B indictator
				local a,b=P.b2b,P.b2b1 if a>b then a,b=b,a end
				gc_setColor(.8,1,.2)
				gc_rectangle("fill",-14,599,11,-b*.6)
				gc_setColor(P.b2b<40 and COLOR.white or P.b2b<=800 and COLOR.lRed or COLOR.lBlue)
				gc_rectangle("fill",-14,599,11,-a*.6)
				gc_setColor(1,1,1)
				if t%.5<.3 then
					gc_rectangle("fill",-15,b<40 and 568.5 or 118.5,13,3)
				end

				--LockDelay indicator
				if ENV.easyFresh then
					gc_setColor(1,1,1)
				else
					gc_setColor(1,.26,.26)
				end
				if P.lockDelay>=0 then
					gc_rectangle("fill",0,602,300*P.lockDelay/ENV.lock,6)--Lock delay indicator
				end
				local x=3
				for _=1,min(P.freshTime,15)do
					gc_rectangle("fill",x,615,14,5)
					x=x+20
				end

				--Draw Hold
				P:drawHold()

				--Draw Next(s)
				P:drawNext()

				--Draw target selecting pad
				if GAME.modeEnv.royaleMode then
					if P.atkMode then
						gc_setColor(1,.8,0,P.swappingAtkMode*.02)
						gc_rectangle("fill",RCPB[2*P.atkMode-1],RCPB[2*P.atkMode],90,35,8,4)
					end
					gc_setColor(1,1,1,P.swappingAtkMode*.025)
					setFont(35)
					for i=1,4 do
						gc_rectangle("line",RCPB[2*i-1],RCPB[2*i],90,35,8,4)
						gc.printf(text.atkModeName[i],RCPB[2*i-1]-4,RCPB[2*i]+4,200,"center",nil,.5)
					end
				end
				if ENV.hideBoard then
					gc.stencil(hideBoardStencil[ENV.hideBoard],"replace",1)
					gc.setStencilTest("equal",1)
					gc_setLineWidth(20)
					for i=0,24 do
						gc_setColor(COLOR.rainbow_grey(t*.626+i*.1))
						gc_line(20*i-190,-2,20*i+10,602)
					end
					gc.setStencilTest()
				end
			gc_pop()

			--Bonus texts
			TEXT.draw(P.bonus)

			--Display Ys
			-- gc_setLineWidth(6)
			-- if P.curY then	gc_setColor(1,.4,0,.42)gc_line(0,611-P.curY*30,300,611-P.curY*30)end
			-- if P.ghoY then	gc_setColor(0,1,.4,.42)gc_line(0,615-P.ghoY*30,300,615-P.ghoY*30)end
			-- if P.minY then	gc_setColor(0,.4,1,.42)gc_line(0,619-P.minY*30,300,619-P.minY*30)end
			-- 				gc_setColor(0,.4,1,.42)gc_line(0,600-P.garbageBeneath*30,300,600-P.garbageBeneath*30)
		gc_pop()

		--Speed dials
		setFont(25)
		drawDial(510,510,P.dropSpeed)
		drawDial(555,565,P.keySpeed)
		gc_setColor(1,1,1)
		gc_draw(drawableText.bpm,540,480)
		gc_draw(drawableText.kpm,494,573)

		local S=P.stat

		--Score & Time
		setFont(25)
		gc_setColor(0,0,0,.3)
		gc_print(P.score1,18,509)
		gc_print(format("%.2f",S.time),18,539)
		gc_setColor(COLOR.lYellow)gc_print(P.score1,20,510)
		gc_setColor(COLOR.sky)gc_print(format("%.2f",S.time),20,540)

		--FinesseCombo
		if P.finesseCombo>2 then
			_=P.finesseComboTime
			local str=P.finesseCombo.."x"
			if S.finesseRate==5*S.piece then
				gc_setColor(.9,.9,.3,_*.2)
				gc_print(str,20,570)
				gc_setColor(.9,.9,.3,1.2-_*.1)
			elseif S.maxFinesseCombo==S.piece then
				gc_setColor(.7,.7,1,_*.2)
				gc_print(str,20,570)
				gc_setColor(.7,.7,1,1.2-_*.1)
			else
				gc_setColor(1,1,1,_*.2)
				gc_print(str,20,570)
				gc_setColor(1,1,1,1.2-_*.1)
			end
			if _>0 then
				gc_push("transform")
				gc_translate(20,600)
				gc_scale(1+_*.08)
				gc_print(str,0,-30)
				gc_pop()
			else
				gc_print(str,20,570)
			end
		end

		--Lives
		if P.life>0 then
			gc_setColor(1,1,1)
			if P.life<=3 then
				for i=1,P.life do
					gc_draw(IMG.lifeIcon,450+25*i,595,nil,.8)
				end
			else
				gc_draw(IMG.lifeIcon,475,595,nil,.8)
				setFont(20)
				gc_print("x",503,595)
				gc_print(P.life,517,595)
			end
		end

		--Other messages
		gc_setColor(1,1,1)
		if GAME.curMode.mesDisp then
			GAME.curMode.mesDisp(P)
		end

		--Missions
		if P.curMission then
			local missionEnum=missionEnum
			local L=ENV.mission

			--Draw current mission
			setFont(35)
			if ENV.missionKill then
				gc_setColor(1,.7+.2*sin(t*6.26),.4)
			else
				gc_setColor(1,1,1)
			end
			gc_print(missionEnum[L[P.curMission]],85,110)

			--Draw next mission
			setFont(20)
			for i=1,3 do
				local m=L[P.curMission+i]
				if m then
					m=missionEnum[m]
					gc_print(m,87-28*i,117)
				else
					break
				end
			end
		end

		--Draw starting counter
		gc_setColor(1,1,1)
		if GAME.frame<180 then
			local count=179-GAME.frame
			gc_push("transform")
				gc_translate(305,220)
				setFont(95)
				if count%60>45 then gc_scale(1+(count%60-45)^2*.01,1)end
				mStr(int(count/60+1),0,0)
			gc_pop()
		end
	gc_pop()
end

function draw.small(P)
	--Draw content
	P.frameWait=P.frameWait-1
	if P.frameWait==0 then
		P.frameWait=10
		gc.setCanvas(P.canvas)
		gc.clear(0,0,0,.4)
		gc_push("transform")
		gc.origin()
		gc_setColor(1,1,1,P.result and max(20-P.endCounter,0)*.05 or 1)

		--Field
		local F=P.field
		local texture=SKIN.curTextMini
		for j=1,#F do
			for i=1,10 do if F[j][i]>0 then
				gc_draw(texture[F[j][i]],6*i-6,120-6*j)
			end end
		end

		--Draw boarder
		if P.alive then
			gc_setLineWidth(2)
			gc_setColor(frameColorList[P.frameColor])
			gc_rectangle("line",0,0,60,120)
		end

		--Draw badge
		if GAME.modeEnv.royaleMode then
			gc_setColor(1,1,1)
			for i=1,P.strength do
				gc_draw(IMG.badgeIcon,12*i-7,4,nil,.5)
			end
		end

		--Draw result
		if P.result then
			gc_setColor(1,1,1,min(P.endCounter,60)*.01)
			setFont(20)mStr(P.result,32,47)
			setFont(15)mStr(P.modeData.event,30,82)
		end
		gc_pop()
		gc.setCanvas()
	end

	--Draw Canvas
	gc_setColor(1,1,1)
	gc_draw(P.canvas,P.x,P.y,nil,P.size*10)
	if P.killMark then
		gc_setLineWidth(3)
		gc_setColor(1,0,0,min(P.endCounter,25)*.04)
		gc_circle("line",P.centerX,P.centerY,(840-20*min(P.endCounter,30))*P.size)
	end
	setFont(30)
end

function draw.demo(P)
	local _
	local ENV=P.gameEnv
	local curColor=P.cur.color

	--Camera
	gc_push("transform")
		gc_translate(P.x,P.y)
		gc_scale(P.size)
		gc_push("transform")
			gc_translate(P.fieldOff.x,P.fieldOff.y)

			--Frame
			gc_setColor(0,0,0,.6)
			gc_rectangle("fill",0,0,300,600)
			gc_setLineWidth(2)
			gc_setColor(1,1,1)
			gc_rectangle("line",-1,-1,302,602)

			gc_push("transform")
				gc_translate(0,600)
				drawField(P)
				drawFXs(P)
				if P.cur and P.waiting==-1 then
					if ENV.ghost then drawGhost(P,curColor)end
					if ENV.block then
						local dy=ENV.smooth and P.ghoY~=P.curY and(P.dropDelay/ENV.drop-1)*30 or 0
						gc_translate(0,-dy)
						drawBlockOutline(P,SKIN.curText[curColor],P.lockDelay/ENV.lock)
						drawBlock(P,curColor)
						gc_translate(0,dy)
					end
				end
			gc_pop()

			local blockImg=TEXTURE.miniBlock
			local libColor=SKIN.libColor
			local skinSet=ENV.skin
			--Draw hold
			local N=1
			while P.holdQueue[N]do
				local id=P.holdQueue[N].id
				_=libColor[skinSet[id]]
				gc_setColor(_[1],_[2],_[3],.3)
				_=blockImg[id]
				gc_draw(_,15,40*N-10,nil,16,nil,0,_:getHeight()*.5)
				N=N+1
			end

			--Draw next
			N=1
			while N<=ENV.nextCount and P.nextQueue[N]do
				local id=P.nextQueue[N].id
				_=libColor[skinSet[id]]
				gc_setColor(_[1],_[2],_[3],.3)
				_=blockImg[id]
				gc_draw(_,285,40*N-10,nil,16,nil,_:getWidth(),_:getHeight()*.5)
				N=N+1
			end
		gc_pop()
		TEXT.draw(P.bonus)
	gc_pop()
end

return draw