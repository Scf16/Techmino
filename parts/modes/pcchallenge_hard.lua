return{
	color=COLOR.magenta,
	env={
		drop=60,lock=120,
		fall=10,
		target=100,dropPiece=PLY.check_lineReach,
		freshLimit=15,
		ospin=false,
		bg="rgb",bgm="truth",
	},
	pauseLimit=true,
	load=function()
		PLY.newPlayer(1)
	end,
	mesDisp=function(P)
		setFont(45)
		local R=100-P.stat.row
		mStr(R>=0 and R or 0,69,250)

		setFont(75)
		mStr(P.stat.pc,69,350)
		mText(drawableText.pc,69,432)
	end,
	score=function(P)return{P.stat.pc,P.stat.frame/60}end,
	scoreDisp=function(D)return D[1].." PCs   "..toTime(D[2])end,
	comp=function(a,b)return a[1]>b[1]or a[1]==b[1]and a[2]<b[2]end,
	getRank=function(P)
		local L=P.stat.pc
		return
		L>=24 and 5 or
		L>=20 and 4 or
		L>=16 and 3 or
		L>=12 and 2 or
		L>=8 and 1 or
		L>=1 and 0
	end,
}