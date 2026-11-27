-- Run with the standalone Luau CLI. The generated model is editable in Studio.
local output = { '<roblox version="4">' }
local id = 0

local function emit(value)
	table.insert(output, value)
end

local function escape(value)
	return (value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function property(kind, name, value)
	return string.format('<%s name="%s">%s</%s>', kind, name, value, kind)
end

local function item(class, name, properties, children)
	id += 1
	emit(string.format('<Item class="%s" referent="RBX%d"><Properties>', class, id))
	emit(property("string", "Name", escape(name)))
	if properties then
		for _, value in properties do
			emit(value)
		end
	end
	emit("</Properties>")
	if children then
		children()
	end
	emit("</Item>")
end

local function xyz(x, y, z)
	return string.format("<X>%.5f</X><Y>%.5f</Y><Z>%.5f</Z>", x, y, z)
end

local function frame(x, y, s, yaw)
	local c = math.cos(yaw or 0)
	local v = math.sin(yaw or 0)
	return xyz(x, y, -s) .. string.format(
		"<R00>%.6f</R00><R01>0</R01><R02>%.6f</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>%.6f</R20><R21>0</R21><R22>%.6f</R22>",
		c, v, -v, c
	)
end

local palette = {
	deck = 0x304c5e,
	rim = 0x28404d,
	landing = 0xe0fff7,
	route = 0x57dfd5,
	safe = 0x8df3ad,
	hard = 0xffa351,
	goal = 0xffd16c,
	navy = 0x172f43,
	white = 0xf0f5ec,
	sea = 0x1b656e,
	road = 0x647b85,
}
local buildings = { 0xc88e79, 0xdcb28d, 0x858ba0, 0x6d9f9b, 0xae7770, 0xa99a80 }
local roofCount = 0

local function part(name, x, y, s, w, h, d, color, material, solid, yaw, transparency, class, children, extras)
	local properties = {
		property("CoordinateFrame", "CFrame", frame(x, y, s, yaw)),
		property("Vector3", "size", xyz(w, h, d)),
		property("Color3uint8", "Color3uint8", 0xff000000 + color),
		property("token", "Material", material),
		property("bool", "Anchored", "true"),
		property("bool", "CanCollide", solid and "true" or "false"),
		property("bool", "CanTouch", "false"),
		property("float", "Transparency", transparency or 0),
		property("bool", "CastShadow", transparency == 1 and "false" or "true"),
	}
	for _, extra in extras or {} do
		table.insert(properties, extra)
	end
	item(class or "Part", name, properties, children)
end

local function box(name, x, y, s, w, h, d, color, solid)
	part(name, x, y, s, w, h, d, color, 816, solid)
end

local function paint(name, x, y, s, w, d, color, neon)
	part(name, x, y + 0.026, s, w, 0.052, d, color, neon and 288 or 272, false)
end

local function sign(name, title, x, y, s, tint, maxRange)
	part(name, x, y, s, 1, 1, 1, tint, 272, false, nil, 1, nil, function()
		item("BillboardGui", "Placa", {
			property("bool", "AlwaysOnTop", "true"),
			property("float", "MaxDistance", maxRange),
			property("UDim2", "Size", "<XS>0</XS><XO>156</XO><YS>0</YS><YO>32</YO>"),
		}, function()
			item("TextLabel", "Texto", {
				property("UDim2", "Size", "<XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO>"),
				property("Color3", "BackgroundColor3", "<R>0.0549</R><G>0.1176</G><B>0.1686</B>"),
				property("float", "BackgroundTransparency", "0.12"),
				property("Color3", "TextColor3", string.format("<R>%.5f</R><G>%.5f</G><B>%.5f</B>",
					bit32.band(bit32.rshift(tint, 16), 255) / 255, bit32.band(bit32.rshift(tint, 8), 255) / 255, bit32.band(tint, 255) / 255)),
				property("string", "Text", escape(title)),
				property("token", "Font", 4),
				property("bool", "TextScaled", "true"),
			}, function()
				item("UICorner", "Cantos", {
					property("UDim", "CornerRadius", "<S>0</S><O>6</O>"),
				})
			end)
		end)
	end)
end

local function stripe(name, x, y, s, width, depth, dx, ds, color, neon)
	if dx ~= 0 then
		paint(name, x, y, s, depth, width, color, neon)
	else
		paint(name, x, y, s, width, depth, color, neon)
	end
end

local function arrow(x, y, s, dx, ds, color)
	local yaw = dx ~= 0 and -dx * math.pi / 2 or (ds < 0 and math.pi or 0)
	local tangentX, tangentS = ds, -dx
	part("Seta • haste", x, y + 0.028, s, 0.68, 0.055, 3.7, color, 272, false, yaw)
	for _, side in { -1, 1 } do
		part("Seta • ponta", x + dx * 1.1 + tangentX * side * 0.56, y + 0.028,
			s + ds * 1.1 + tangentS * side * 0.56, 0.68, 0.055, 2.05, color, 272, false, yaw + side * math.pi / 5)
	end
end

local function roof(name, x, s, y, width, length, dx, ds, color, detail)
	local w = dx ~= 0 and length or width
	local d = dx ~= 0 and width or length
	roofCount += 1
	local body = buildings[1 + (roofCount - 1) % #buildings]
	item("Model", name, nil, function()
		box("Edifício", x, (y - 10) / 2, s, w - 0.8, y + 7.2, d - 0.8, body, true)
		box("Beiral", x, y - 1.33, s, w + 0.1, 0.76, d + 0.1, palette.rim, false)
		box("Telhado", x, y - 0.52, s, w, 1.04, d, palette.deck, true)

		local landingOffset = length * 0.5 - 1.28
		stripe("Aterrissagem", x - dx * landingOffset, y, s - ds * landingOffset,
			width - 0.7, 1.85, dx, ds, palette.landing, false)
		local takeoffOffset = length * 0.5 - 0.58
		stripe("Borda de salto", x + dx * takeoffOffset, y, s + ds * takeoffOffset,
			width - 0.7, 0.6, dx, ds, color, true)
		arrow(x, y, s, dx, ds, color)

		if w >= 10 and d >= 9 then
			for _, side in { -1, 1 } do
				for _, along in { -0.26, 0.22 } do
					box("Janela", x + side * (w / 2 - 0.36), y - 5.1, s + d * along, 0.16, 1.7, 2.45, palette.navy, false)
				end
			end
		end
		if detail then
			detail()
		end
	end)
	return { x = x, s = s, y = y, front = s + d / 2 }
end

local function leg(name, x, s, y, dx, ds, entries, color)
	for index, spec in entries do
		local gap, length, width, lift, shift = table.unpack(spec)
		shift = shift or 0
		x += ds * shift
		s -= dx * shift
		local distance = gap + length / 2
		x += dx * distance
		s += ds * distance
		y += lift or 0
		roof(string.format("%s %02d", name, index), x, s, y, width, length, dx, ds, color)
		x += dx * length / 2
		s += ds * length / 2
	end
	return x, s, y
end

local function checkpoint(number, top)
	local x, y, s = top.x, top.y, top.s
	for _, side in { -1, 1 } do
		box("Pilar", x + side * 11, y + 4, s - 4, 0.78, 8, 0.78, palette.navy, false)
		part("Sinal verde", x + side * 11, y + 8.3, s - 4, 0.9, 0.8, 0.9, palette.safe, 288, false)
	end
	paint("Linha do checkpoint", x, y, s - 4, 22, 1.3, palette.safe, true)
	sign("Placa do checkpoint", "CHECKPOINT " .. number, x, y + 7, s - 4, palette.safe, 75)
end

local points = {}
local function course()
	points.start = roof("Largada • Armazém", 0, 0, 26, 34, 38, 0, 1, palette.route, function()
		paint("Linha da largada", 0, 26, 1, 33.1, 1.25, palette.route, true)
		sign("Placa da largada", "LARGADA  ↑", 0, 32.3, 1, palette.route, 52)
		part("SpawnLocation", 0, 26.1, -11, 6, 0.2, 6, palette.route, 272, false, nil, 1, "SpawnLocation", nil, {
			property("bool", "Enabled", "true"),
			property("bool", "Neutral", "true"),
			property("int", "Duration", 0),
		})
	end)
	local _, s, y = leg("Armazéns", 0, points.start.front, 26, 0, 1, {
		{4, 16, 20, 0}, {5, 18, 18, 1, 3}, {4, 15, 15, 0, 3}, {6, 17, 17, -1, 1},
		{4, 20, 20, 1, -4}, {5, 18, 16, 0, -6}, {5, 15, 17, 1, -2}, {4, 19, 18, -1, 0},
		{5, 16, 21, 0, 5},
	}, palette.route)
	points.one = roof("Checkpoint 1 • Mercado", 0, s + 5 + 14, y, 29, 28, 0, 1, palette.route)
	checkpoint(1, points.one)

	local fork = roof("Bifurcação", 0, points.one.front + 5 + 12, y, 34, 24, 0, 1, palette.hard)
	points.fork = fork
	local mergeS = fork.s + 161
	paint("Entrada segura", 15.9, y, fork.s, 0.75, 17, palette.safe, true)
	arrow(10, y, fork.s, 1, 0, palette.safe)
	sign("Placa do atalho", "↑ ATALHO", -4.5, y + 6, fork.s + 9, palette.hard, 62)
	sign("Placa da rota segura", "SEGURO →", 12, y + 6, fork.s + 2, palette.safe, 62)

	local safeX, _, safeY = leg("Seguro • Leste", 17, fork.s, y, 1, 0, {
		{4, 16, 19, 0}, {5, 18, 18, 0},
	}, palette.safe)
	assert(safeX == 60)
	roof("Seguro • Curva dos depósitos", 72, fork.s, safeY, 16, 25, 0, 1, palette.safe, function()
		paint("Aterrissagem lateral", 65.1, safeY, fork.s, 1.85, 18, palette.landing, false)
	end)
	local _, safeEnd, safeReturnY = leg("Seguro • Depósitos", 72, fork.s + 12.5, safeY, 0, 1, {
		{4.5, 18, 16, 0}, {4.5, 20, 17, 1}, {5, 18, 16, 0}, {4.5, 18, 18, 1},
		{5, 16, 15, -1}, {5, 12.5, 16, -1},
	}, palette.safe)
	assert(safeEnd == mergeS - 17.5)
	roof("Seguro • Curva do cais", 72, mergeS, safeReturnY, 16, 25, 0, 1, palette.safe, function()
		paint("Saída lateral", 64.6, safeReturnY, mergeS, 0.7, 18, palette.safe, true)
		arrow(66.8, safeReturnY, mergeS, -1, 0, palette.safe)
	end)
	local westEnd = leg("Seguro • Oeste", 64, mergeS, safeReturnY, -1, 0, {
		{5, 18, 19, 0}, {4, 16, 18, 0},
	}, palette.safe)
	assert(westEnd == 21)

	local _, shortcutEnd, shortcutY = leg("Atalho • Passarelas", 0, fork.front, y, 0, 1, {
		{7.5, 9, 7, 0, 0}, {7.5, 8, 6.3, 1, 1.6}, {7.75, 8, 5.8, 0, -2.5},
		{7.75, 10, 5.8, 0, -1.4}, {7.5, 8, 6, 0, 2.8}, {7.75, 9, 5.6, 0, 1.6},
		{7.5, 8, 5.8, -1, -2.4}, {7.75, 9, 6.7, 0, 0.8},
	}, palette.hard)
	assert(mergeS - 12 - shortcutEnd == 7)
	local merge = roof("Encontro das rotas", 0, mergeS, shortcutY, 34, 24, 0, 1, palette.route, function()
		paint("Aterrissagem da rota segura", 15.8, shortcutY, mergeS, 1.85, 17, palette.landing, false)
	end)
	points.two = roof("Checkpoint 2 • Alfândega", 0, merge.front + 4 + 14, shortcutY, 29, 28, 0, 1, palette.route)
	checkpoint(2, points.two)

	_, s, y = leg("Alfândega", 0, points.two.front, points.two.y, 0, 1, {
		{4, 20, 20, 1, -3}, {5, 16, 16, 1, -3}, {5, 13, 13, 1, -3},
		{5, 21, 21, 0, 4}, {4, 16, 15, 1, 6}, {6, 15, 17, 0, 4},
		{5, 18, 18, -1, 0}, {4, 19, 17, -1, -4}, {5, 17, 20, -1, -2},
	}, palette.route)
	points.three = roof("Checkpoint 3 • Guindastes", 0, s + 5 + 14, y, 29, 28, 0, 1, palette.route)
	checkpoint(3, points.three)

	_, s, y = leg("Cais", 0, points.three.front, points.three.y, 0, 1, {
		{5, 23, 22, -1, 0}, {5, 19, 17, -1, -4}, {4, 17, 15, 0, -5}, {5, 20, 16, -1, -3},
		{5, 15, 13, 0, 1}, {5, 21, 19, -1, 5}, {4, 18, 17, 0, 3}, {5, 19, 21, -1, 3},
	}, palette.route)
	local pier = roof("Passarela de embarque", 0, s + 4 + 13, y, 15, 26, 0, 1, palette.goal)
	points.boarding = pier.front + 4
	points.deckY = y
end

local function ferry()
	local entry, y = points.boarding, points.deckY
	item("Model", "Balsa • Estrela do Porto", nil, function()
		box("Casco", 0, y - 10, entry + 51, 57, 18, 100, palette.navy, true)
		box("Faixa do casco", 0, y - 4, entry + 51, 60, 2.1, 102, palette.goal, false)
		box("Convés", 0, y - 0.6, entry + 51, 59, 1.2, 102, palette.white, true)
		box("Proa", 0, y - 4.8, entry + 103, 44, 9.6, 5, palette.navy, true)
		box("Ponta da proa", 0, y - 4.8, entry + 108, 27, 9.6, 5, palette.navy, true)
		paint("Área de embarque", 0, y, entry + 4.3, 22, 8.2, palette.route, false)
		for i = -4, 4 do
			local color = i % 2 == 0 and palette.navy or palette.goal
			paint("Faixa de chegada", i * 2.6, y, entry + 17.5, 2.6, 1.45, color, false)
		end
		for _, side in { -1, 1 } do
			box("Guarda-corpo", side * 28.3, y + 1.55, entry + 44, 1.15, 3.1, 86, palette.navy, true)
			part("Pilar de chegada", side * 11.9, y + 4.4, entry + 17.5, 1, 8.8, 1, palette.goal, 288, false)
		end
		box("Pórtico de embarque", 0, y + 9, entry + 17.5, 24.8, 1, 1.1, palette.navy, false)
		sign("Placa de chegada", "CHEGADA", 0, y + 7.2, entry + 17.5, palette.goal, 82)
		box("Cabine de passageiros", 0, y + 7, entry + 72, 46, 14, 31, palette.white, true)
		box("Ponte de comando", 0, y + 16, entry + 68, 41, 7, 18, palette.navy, true)
		box("Teto da ponte", 0, y + 20.1, entry + 68, 44, 1.7, 20, palette.white, true)
		for i = -2, 2 do
			box("Vigia da ponte", i * 7.8, y + 16.3, entry + 58.9, 6.6, 4.2, 0.25, 0x91dbed, false)
		end
		box("Chaminé", -12, y + 24, entry + 74, 6.2, 11, 8, palette.goal, false)
		box("Mastro", 0, y + 37, entry + 64, 1.35, 35, 1.35, palette.navy, false)
		box("Verga", 0, y + 49.5, entry + 64, 13, 0.86, 0.86, palette.navy, false)
		part("Farol da balsa", 0, y + 54.7, entry + 64, 4, 2.4, 4, palette.goal, 288, false)
		sign("Destino visível", "BALSA  ✦", 0, y + 61, entry + 64, palette.goal, 1300)
	end)
end

local function scenery()
	box("Água do porto", 0, -9.6, 460, 800, 1, 1650, palette.sea, false)
	for side = -1, 1, 2 do
		box("Margem do porto", side * 195, -4.4, 440, 127, 10, 1180, palette.road, false)
		box("Muralha do porto", side * 131, -1, 440, 3, 12, 1180, palette.rim, false)
		for i = 0, 17 do
			local x = side * (144 + (i % 3) * 9)
			local s = i * 55 - 52
			local height = 13 + i * 13 % 34
			local color = buildings[1 + (i * 3 + side) % #buildings]
			box("Fachada da cidade", x, height / 2, s, 23 + i % 4 * 4, height, 29 + i % 3 * 7, color, false)
			box("Beiral da cidade", x, height + 0.5, s, 24 + i % 4 * 4, 1, 30 + i % 3 * 7, palette.rim, false)
			for row = 1, math.floor((height - 3) / 6) do
				for column = -1, 1 do
					box("Janela da cidade", x - side * (11.56 + i % 4 * 2), row * 6, s + column * 7,
						0.25, 2, 3.6, palette.navy, false)
				end
			end
		end
	end
	for i, center in { 415, 673, points.boarding - 27 } do
		local side = i == 2 and -1 or 1
		local x = side * (i == 1 and 114 or 52)
		box("Base de guindaste", x, -2.2, center, 19, 15, 22, palette.rim, false)
		for _, legX in { -4, 4 } do
			box("Estrutura de guindaste", x + legX, 25, center, 1.8, 56, 1.8, palette.goal, false)
		end
		box("Braço de guindaste", x - side * 9, 53.5, center, 33, 2.8, 2.1, palette.goal, false)
		box("Cabo de guindaste", x - side * 24, 44, center, 0.3, 17, 0.3, palette.navy, false)
	end
end

local function marker(name, x, y, s, w, h, d)
	part(name, x, y, s, w, h, d, palette.white, 272, false, nil, 1)
end

item("Model", "Porto", nil, function()
	item("Folder", "Percurso", nil, course)
	item("Folder", "Destino", nil, ferry)
	item("Folder", "Cidade", nil, scenery)
	item("Folder", "RaceMarkers", nil, function()
		marker("Spawn0", 0, points.start.y + 3.2, -11, 1, 1, 1)
		marker("Start", 0, points.start.y + 5, 1, 34, 16, 1)
		for i, top in { points.one, points.two, points.three } do
			marker("Checkpoint" .. i, top.x, top.y + 5, top.s - 4, 29, 16, 7)
			marker("Spawn" .. i, top.x, top.y + 3.2, top.s + 3, 1, 1, 1)
		end
		marker("Fork", 0, points.fork.y + 5, points.fork.s, 35, 14, 26)
		marker("Finish", 0, points.deckY + 5, points.boarding + 18, 24, 16, 2.5)
	end)
end)
emit("</roblox>")
for _, line in output do
	print(line)
end
