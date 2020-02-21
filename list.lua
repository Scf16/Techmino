actName={
	"moveLeft","moveRight",
	"rotRight","rotLeft","rotFlip",
	"hardDrop","softDrop",
	"hold","func",
	"restart",
	"insLeft","insRight","insDown","down1","down4","down10",
	"dropLeft","dropRight","addLeft","addRight",--Super contorl system
}
color={
	red={1,0,0},
	green={0,1,0},
	blue={.2,.2,1},
	yellow={1,1,0},
	magenta={1,0,1},
	cyan={0,1,1},
	grey={.6,.6,.6},

	lightRed={1,.5,.5},
	lightGreen={.5,1,.5},
	lightBlue={.6,.6,1},
	lightYellow={1,1,.5},
	lightMagenta={1,.5,1},
	lightCyan={.5,1,1},
	lightGrey={.8,.8,.8},

	darkRed={.6,0,0},
	darkGreen={0,.6,0},
	darkBlue={0,0,.6},
	darkYellow={.6,.6,0},
	darkMagenta={.6,0,.6},
	darkCyan={0,.6,.6},
	darkGrey={.3,.3,.3},

	white={1,1,1},
	bronze={.7,.4,0},
	orange={1,.6,0},
	lightOrange={1,.7,.3},
	darkOrange={.6,.4,0},
	purple={.5,0,1},
	lightPurple={.8,.4,1},
	darkPurple={.3,0,.6},
}
blockColor={
	color.red,
	color.green,
	color.orange,
	color.blue,
	color.magenta,
	color.yellow,
	color.cyan,
	color.darkGreen,
	color.grey,
	color.lightGrey,
	color.darkPurple,
	color.darkRed,
	color.darkGreen,
}
voiceBank={}--{{srcs1},{srcs2},...}
voiceName={
	"zspin","sspin","lspin","jspin","tspin","ospin","ispin",
	"single","double","triple","techrash",
	"mini","b2b","b3b","pc",
	"win","lose",
	"bye",
	"nya",
	"happy",
	"doubt",
	"sad",
	"egg",
}
voiceList={
	zspin={"zspin_1","zspin_2","zspin_3"},
	sspin={"sspin_1","sspin_2","sspin_3","sspin_4","sspin_5","sspin_6"},
	lspin={"lspin_1","lspin_2"},
	jspin={"jspin_1","jspin_2","jspin_3","jspin_4"},
	tspin={"tspin_1","tspin_2","tspin_3","tspin_4","tspin_5","tspin_6"},
	ospin={"ospin_1","ospin_2","ospin_3"},
	ispin={"ispin_1","ispin_2","ispin_3"},

	single={"single_1","single_2","single_3","single_4","single_5","single_6","single_7"},
	double={"double_1","double_2","double_3","double_4","double_5"},
	triple={"triple_1","triple_2","triple_3","triple_4","triple_5","triple_6","triple_7"},
	techrash={"techrash_1","techrash_2","techrash_3","techrash_4"},

	mini={"mini_1","mini_2","mini_3"},
	b2b={"b2b_1","b2b_2","b2b_3"},
	b3b={"b3b_1","b3b_2"},
	pc={"pc_1","pc_2"},
	win={"win_1","win_2","win_3","win_4","win_5","win_6","win_6","win_7"},
	lose={"lose_1","lose_2","lose_3"},
	bye={"bye_1","bye_2"},
	nya={"nya_1","nya_2","nya_3","nya_4"},
	happy={"nya_happy_1","nya_happy_2","nya_happy_3","nya_happy_4"},
	doubt={"nya_doubt_1","nya_doubt_2"},
	sad={"nya_sad_1"},
	egg={"egg_1","egg_2"},
}

musicID={
	"blank",
	"way",
	"race",
	"newera",
	"push",
	"reason",
	"infinite",
	"secret7th",
	"secret8th",
	"shining terminal",
	"oxygen",
	"distortion",
	"rockblock",
	"cruelty",
	"final",
	"8-bit happiness",
	"end",
}
customID={
	"drop","lock",
	"wait","fall",
	"next","hold",
	"sequence","visible",
	"target",
	"freshLimit",
	"opponent",
	"bg","bgm",
}
customRange={
	drop={1e99,180,60,40,30,25,20,18,16,14,12,10,9,8,7,6,5,4,3,2,1,.5,.25,.125,0},
	lock={0,1,2,3,4,5,6,7,8,9,10,12,14,16,18,20,25,30,40,60,180,1e99},
	wait={0,1,2,3,4,5,6,7,8,10,15,20,30,60},
	fall={0,1,2,3,4,5,6,7,8,10,15,20,30,60},
	next={0,1,2,3,4,5,6},
	hold={true,false,true},
	sequence={"bag7","his4","rnd"},
	visible={"show","time","fast","none"},
	target={10,20,40,100,200,500,1000,1e99},
	freshLimit={0,8,15,1e99},
	opponent={0,1,2,3,4,5,11,12,13,14,15,16},
	bg={"none","game1","game2","game3","strap","rgb","glow","matrix"},
	bgm={"blank","way","race","newera","push","reason","infinite","secret7th","secret8th","rockblock"},
}

RCPB={10,33,200,33,105,5,105,60}
snapLevelValue={1,10,20,40,60,80}