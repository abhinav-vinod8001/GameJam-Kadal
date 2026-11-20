extends CanvasLayer

const CREAM = Color("f0e4c2")
const GOLD = Color("d0b77d")
const MUTED = Color("a9bdb3")
const INK = Color("102c30")
var serif: Font = preload("res://assets/fonts/CormorantGaramond.ttf")
var malayalam: Font = preload("res://assets/fonts/NotoSansMalayalam.ttf")
var root: Control
var menu: Control
var hud: Control
var overlay: Control
var modal_panel: PanelContainer
var modal_box: VBoxContainer
var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var hp_text: Label
var fanam_text: Label
var herb_text: Label
var weapon_text: Label
var quest_text: Label
var quest_title: Label
var compass: Label
var prompt: PanelContainer
var prompt_label: Label
var notification: Label
var region_label: Label
var weapon_buttons: Array[Button] = []
var quest_marker: Label
var lock_marker: Label
var damage_rect: ColorRect
var notice_tween: Tween
var region_tween: Tween
var intro_timer := 0.0
var current_npc := ""
var modal_locked := false
var dialogue_ml: Label
var dialogue_en: Label
var menu_footer: Label

func _ready():
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme_value = Theme.new()
	theme_value.default_font = ThemeDB.fallback_font
	theme_value.default_font_size = 16
	theme_value.set_color("font_color","Label",CREAM)
	root.theme = theme_value
	create_menu()
	create_hud()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	overlay.hide()
	Game.notice.connect(show_notice)
	Game.quest_changed.connect(update_quest)
	show_menu()

func text(parent: Node, value: String, font_size: int = 18, color_value: Color = CREAM, use_serif: bool = false) -> Label:
	var l = Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color_value)
	if use_serif: l.add_theme_font_override("font",serif)
	parent.add_child(l)
	return l

func place(node: Control, x: float, y: float, w: float = 0, h: float = 0):
	node.position = Vector2(x,y)
	if w>0: node.size.x = w
	if h>0: node.size.y = h

func style(bg: Color, border: Color = Color("586754"), padding: int = 22) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.content_margin_left = padding
	s.content_margin_right = padding
	s.content_margin_top = padding
	s.content_margin_bottom = padding
	return s

func button(parent: Node, title: String, action: Callable, primary: bool = false) -> Button:
	var b = Button.new()
	b.text = title
	b.custom_minimum_size = Vector2(220,48)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size",16)
	b.add_theme_color_override("font_color",INK if primary else CREAM)
	b.add_theme_color_override("font_hover_color",INK)
	b.add_theme_color_override("font_pressed_color",INK)
	b.add_theme_stylebox_override("normal",style(GOLD if primary else Color("153337e8"),GOLD if primary else Color("50665c"),14))
	b.add_theme_stylebox_override("hover",style(Color("e5d3a2"),Color("f3e1b4"),14))
	b.add_theme_stylebox_override("pressed",style(Color("b9a270"),GOLD,14))
	b.add_theme_stylebox_override("focus",style(Color("00000000"),CREAM,14))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func rule(parent: Node):
	var line = HSeparator.new()
	line.add_theme_stylebox_override("separator",style(Color("66705766"),Color("66705766"),0))
	line.custom_minimum_size.y = 2
	parent.add_child(line)

func wrapped(parent: Node,value: String,font_size: int=18,color_value: Color=CREAM,use_serif: bool=false) -> Label:
	var l = text(parent,value,font_size,color_value,use_serif)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func panel(parent: Node) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel",style(Color("102c30eb"),Color("607265"),20))
	parent.add_child(p)
	return p

func full_rect(parent: Node, color_value: Color) -> ColorRect:
	var c = ColorRect.new()
	c.color = color_value
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(c)
	return c

func anchor(node: Control, preset: int, offset: Vector2):
	var old_size = node.size
	node.set_anchors_preset(preset)
	node.offset_left = offset.x
	node.offset_top = offset.y
	node.offset_right = offset.x+old_size.x
	node.offset_bottom = offset.y+old_size.y

func create_menu():
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	var veil = full_rect(menu,Color.WHITE)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = load("res://shaders/menu_veil.gdshader")
	veil.material = shader_mat
	var header = text(menu,"K  A  D  A  L     /     A  M A L A N A D U  S T O R Y",13,GOLD)
	place(header,74,44)
	var edition = text(menu,"PLAYABLE PROLOGUE     ◇     1870",12,CREAM)
	anchor(edition,Control.PRESET_TOP_RIGHT,Vector2(-358,44))
	var ml = text(menu,"കടൽ",28,GOLD)
	ml.add_theme_font_override("font",malayalam)
	place(ml,79,159)
	var title = text(menu,"KADAL",148,CREAM,true)
	place(title,68,185)
	var subtitle = text(menu,"T H E   M O N S O O N   O A T H",19,GOLD)
	place(subtitle,80,356)
	var tagline = text(menu,"The land remembers every story.",26,Color("d0dbbd"),true)
	place(tagline,80,411)
	var description = text(menu,"A boat has vanished. A storm is gathering.\nTake up your blade. Follow the backwaters home.",16,MUTED)
	place(description,82,463)
	var options = VBoxContainer.new()
	options.add_theme_constant_override("separation",11)
	menu.add_child(options)
	place(options,80,550,345)
	button(options,"01     BEGIN THE STORY      →",func(): Game.app.start_game("story"),true)
	button(options,"02     FREE ROAM",func(): Game.app.start_game("roam"))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	options.add_child(row)
	var a = button(row,"SETTINGS",settings)
	a.custom_minimum_size.x = 220
	var b = button(row,"EXIT",func(): get_tree().quit())
	b.custom_minimum_size.x = 115
	menu_footer = text(menu,"AZHIMUKHAM   /   THE MALABAR COAST\nGolden light. Salt air. The first breath of the monsoon.",13,CREAM)
	anchor(menu_footer,Control.PRESET_BOTTOM_RIGHT,Vector2(-460,-105))
	var bottom = text(menu,"AN ORIGINAL HISTORICAL FANTASY     •     BUILT WITH GODOT",11,MUTED)
	anchor(bottom,Control.PRESET_BOTTOM_LEFT,Vector2(80,-44))

func create_hud():
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var edge = full_rect(hud,Color.WHITE)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var edge_material = ShaderMaterial.new()
	edge_material.shader = load("res://shaders/hud_veil.gdshader")
	edge.material = edge_material
	var player_name = text(hud,"ARUN   /   KALARI APPRENTICE",12,GOLD)
	place(player_name,38,31)
	hp_bar = bar(hud,Color("94b59a"),100)
	place(hp_bar,38,61,260,9)
	stamina_bar = bar(hud,GOLD,100)
	place(stamina_bar,38,78,225,5)
	hp_text = text(hud,"100 / 100",11,CREAM)
	place(hp_text,308,56)
	fanam_text = text(hud,"◇  75 FANAM",13,GOLD)
	place(fanam_text,38,102)
	compass = text(hud,"W      ·      N      ·      E",14,CREAM)
	anchor(compass,Control.PRESET_CENTER_TOP,Vector2(-145,32))
	compass.size.x = 290
	compass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var quest_panel = panel(hud)
	quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor(quest_panel,Control.PRESET_TOP_RIGHT,Vector2(-362,32))
	quest_panel.custom_minimum_size = Vector2(325,100)
	var qb = VBoxContainer.new()
	qb.add_theme_constant_override("separation",8)
	quest_panel.add_child(qb)
	quest_title = text(qb,"THE MISSING VANCHI",12,GOLD)
	quest_text = wrapped(qb,"",16)
	quest_text.custom_minimum_size.x = 280
	var controls = text(hud,"WASD  Move     SHIFT  Sprint     SPACE  Jump     Q  Dodge\nLMB  Attack     F  Heavy     RMB  Block / parry     TAB  Lock\nE  Interact     H  Heal     M  Map     I  Satchel     ESC  Pause",12,Color("e0e3c7"))
	anchor(controls,Control.PRESET_BOTTOM_LEFT,Vector2(38,-99))
	herb_text = text(hud,"",13,GOLD)
	anchor(herb_text,Control.PRESET_BOTTOM_LEFT,Vector2(38,-136))
	var weapons_box = VBoxContainer.new()
	hud.add_child(weapons_box)
	anchor(weapons_box,Control.PRESET_BOTTOM_RIGHT,Vector2(-370,-142))
	weapons_box.size.x = 330
	weapon_text = text(weapons_box,"",18,CREAM,true)
	weapon_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation",6)
	weapons_box.add_child(row)
	for i in 5:
		var b = Button.new()
		b.text = str(i+1)+"\n"+["VAL","SPEAR","STAFF","DAGGER","URUMI"][i]
		b.custom_minimum_size = Vector2(60,51)
		b.add_theme_font_size_override("font_size",10)
		b.add_theme_stylebox_override("normal",style(Color("153337cc"),Color("65776b"),4))
		b.add_theme_stylebox_override("disabled",style(Color("c8b17c"),GOLD,4))
		b.add_theme_color_override("font_disabled_color",INK)
		row.add_child(b)
		weapon_buttons.append(b)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt = panel(hud)
	anchor(prompt,Control.PRESET_CENTER_BOTTOM,Vector2(-200,-116))
	prompt.custom_minimum_size.x = 400
	prompt_label = text(prompt,"",16,CREAM)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.hide()
	notification = text(hud,"",16,CREAM)
	anchor(notification,Control.PRESET_CENTER_TOP,Vector2(-420,157))
	notification.size.x = 840
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.modulate.a = 0
	notification.add_theme_color_override("font_shadow_color",INK)
	notification.add_theme_constant_override("shadow_offset_x",2)
	notification.add_theme_constant_override("shadow_offset_y",2)
	region_label = text(hud,"",33,CREAM,true)
	anchor(region_label,Control.PRESET_CENTER_TOP,Vector2(-440,212))
	region_label.size.x = 880
	region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_label.modulate.a = 0
	quest_marker = text(hud,"◇",20,GOLD)
	quest_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_marker.add_theme_color_override("font_shadow_color",INK)
	quest_marker.add_theme_constant_override("shadow_offset_y",2)
	lock_marker = text(hud,"◇",32,CREAM)
	lock_marker.add_theme_color_override("font_shadow_color",INK)
	lock_marker.add_theme_constant_override("shadow_offset_y",2)
	lock_marker.hide()
	damage_rect = full_rect(hud,Color("a74c3a00"))
	damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func bar(parent: Node,color_value: Color,maximum: float) -> ProgressBar:
	var b = ProgressBar.new()
	b.max_value = maximum
	b.value = maximum
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_stylebox_override("background",style(Color("142b2cdd"),Color("516658"),0))
	b.add_theme_stylebox_override("fill",style(color_value,color_value,0))
	parent.add_child(b)
	return b

func show_menu():
	close_modal()
	menu.show()
	hud.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_hud():
	close_modal()
	menu.hide()
	hud.show()
	update_quest()
	region_enter("AZHIMUKHAM · THE MALABAR COAST")

func update_quest():
	quest_title.text = "THE MISSING VANCHI" if Game.mode=="story" else "A LAND TO DISCOVER"
	quest_text.text = Game.objective()

func set_prompt(value: String):
	prompt.visible = value!="" and not Game.modal
	prompt_label.text = "[ E ]   "+value

func _process(_delta):
	if not Game.player or Game.mode=="menu": return
	var p = Game.player
	hp_bar.value = p.health
	stamina_bar.value = p.stamina
	hp_text.text = "%d / 100"%int(p.health)
	fanam_text.text = "◇  %d FANAM"%Game.coins
	herb_text.text = "[ H ]  HEALING HERBS  ×%d"%Game.herbs
	var id = p.combat.weapon_id
	weapon_text.text = Game.weapons[id].name+"  /  "+Game.weapons[id].type
	for i in 5: weapon_buttons[i].disabled = i==id
	var heading = fposmod(rad_to_deg(p.yaw),360)
	var direction = ["N","NW","W","SW","S","SE","E","NE"][int(round(heading/45))%8]
	compass.text = "·     %s     ·     %03d°     ·"%[direction,int(heading)]
	quest_marker.hide()
	lock_marker.hide()
	if not Game.modal and is_instance_valid(p.locked):
		var target = p.locked.global_position+Vector3.UP*2.05
		if not p.camera.is_position_behind(target):
			lock_marker.position = p.camera.unproject_position(target)-Vector2(12,12)
			lock_marker.show()
	if Game.modal: return
	if Game.mode=="story" and Game.quest_step<6:
		var target: Vector3 = Game.TARGETS[Game.quest_step]+Vector3.UP*2
		if not p.camera.is_position_behind(target):
			var point = p.camera.unproject_position(target)
			point.x = clampf(point.x,30,root.size.x-90)
			point.y = clampf(point.y,180,root.size.y-180)
			quest_marker.position = point-Vector2(35,30)
			quest_marker.size.x = 100
			quest_marker.text = "◇\n%dm"%int(p.global_position.distance_to(target))
			quest_marker.show()

func show_notice(value: String):
	if notice_tween and notice_tween.is_valid(): notice_tween.kill()
	notification.text = value
	notification.modulate.a = 1
	notice_tween = create_tween()
	notice_tween.tween_interval(4)
	notice_tween.tween_property(notification,"modulate:a",0.0,1)

func region_enter(value: String):
	if region_tween and region_tween.is_valid(): region_tween.kill()
	region_label.text = value
	region_label.modulate.a = 0
	region_tween = create_tween()
	region_tween.tween_property(region_label,"modulate:a",1.0,1)
	region_tween.tween_interval(3)
	region_tween.tween_property(region_label,"modulate:a",0.0,1.5)

func damage_flash():
	damage_rect.color.a = .24
	create_tween().tween_property(damage_rect,"color:a",0.0,.45)

func begin_modal(kicker: String, title_value: String, width: float = 700):
	modal_locked = false
	if Game.player: Game.player.combat.cancel()
	for c in overlay.get_children(): c.queue_free()
	Game.modal = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	overlay.show()
	var dim = full_rect(overlay,Color("061b20b5"))
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	modal_panel = panel(center)
	modal_panel.custom_minimum_size.x = width
	var s = style(Color("102b30f8"),Color("a29266"),34)
	modal_panel.add_theme_stylebox_override("panel",s)
	modal_box = VBoxContainer.new()
	modal_box.custom_minimum_size.x = width-68
	modal_box.add_theme_constant_override("separation",17)
	modal_panel.add_child(modal_box)
	text(modal_box,kicker,12,GOLD)
	text(modal_box,title_value,42,CREAM,true)
	rule(modal_box)
	prompt.hide()

func close_modal():
	if modal_locked and Game.mode!="menu" and Game.player.health<=0: return
	modal_locked = false
	Game.modal = false
	if overlay:
		overlay.hide()
		for c in overlay.get_children(): c.queue_free()
	if Game.mode!="menu": Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func introduction():
	begin_modal("PROLOGUE   /   AZHIMUKHAM, 1870","Before the storm")
	wrapped(modal_box,"By dusk, every boat had returned. Except one.",27,CREAM,true)
	wrapped(modal_box,"You are Arun, a boatman and student of the kalari. A vanchi carrying villagers and the season's spice harvest has disappeared. Ravi is waiting beside the jetty. Beyond him, the backwaters hold a trail of things left behind.",18,MUTED)
	wrapped(modal_box,"You carry no magic. Only your training, your weapons, and a promise to bring your people home.",19,CREAM,true)
	button(modal_box,"FIND RAVI     →",close_modal,true)

func dialogue(id: String):
	current_npc = id
	var d = Game.dialogues[id]
	begin_modal(d.role.to_upper(),d.name,760)
	dialogue_ml = wrapped(modal_box,d.ml,23,CREAM)
	dialogue_ml.add_theme_font_override("font",malayalam)
	dialogue_en = wrapped(modal_box,d.en,18,MUTED)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	modal_box.add_child(row)
	button(row,"കൂടുതൽ പറയൂ · Tell me more",func():
		dialogue_ml.text = d.more_ml
		dialogue_en.text = d.more_en
	).add_theme_font_override("font",malayalam)
	if id=="meera": button(row,"സാധനങ്ങൾ · Trade",shop,true).add_theme_font_override("font",malayalam)
	button(modal_box,"വീണ്ടും കാണാം  ·  Until next time",close_modal).add_theme_font_override("font",malayalam)

func shop():
	begin_modal("MEERA'S SPICE & PROVISIONS","A little care goes a long way",780)
	wrapped(modal_box,"Healing herbs for the road. Whetstones from Kannan's forge.\nYour purse: %d fanam"%Game.coins,18,MUTED)
	button(modal_box,"HEALING HERB   /   20 FANAM\nRestores 45 health · press H to use",func():
		Game.buy("herb")
		shop()
	,true).custom_minimum_size.y = 78
	button(modal_box,"HONE ALL WEAPONS   /   60 FANAM\nPermanent +15%% damage per honing · %d / 3"%Game.upgrade,func():
		Game.buy("upgrade")
		shop()
	).custom_minimum_size.y = 78
	button(modal_box,"Back to the road",close_modal)

func clue():
	begin_modal("EVIDENCE   /   A TORN RED SAIL","The current tells a story")
	wrapped(modal_box,"A clean cut. Not a storm's work. In the mud: three sets of footprints, and the sweet scent of spilled cardamom.",26,CREAM,true)
	wrapped(modal_box,"The trail crosses the wooden bridge and turns north into Vanam. Three raiders guard a ruined camp. Watch their amber warning rings, then dodge or parry as the blow lands.",18,MUTED)
	button(modal_box,"FOLLOW THE TRAIL     →",close_modal,true)

func shrine():
	begin_modal("DISCOVERY   /   MALAYORAM","A bell without a breeze")
	wrapped(modal_box,"Far below, the backwaters shine like a thread of beaten silver. For a moment, the rain seems to fall upward. Then the bell rings once.",27,CREAM,true)
	wrapped(modal_box,"Health and stamina restored. First discovery grants 50 fanam.\nSome stories are older than the people who tell them.",18,MUTED)
	button(modal_box,"Remember this place",close_modal,true)

func ending():
	begin_modal("THE MISSING VANCHI   /   PROLOGUE COMPLETE","The land remembers")
	wrapped(modal_box,"The ledger names the men who took the boat. Its final page tells of villagers who escaped downriver. By morning, Ravi has brought them home.",26,CREAM,true)
	wrapped(modal_box,"But beside the cargo entries is a drawing of the hill shrine — and a date that has not yet come. Out on the water, a bell sounds through the monsoon.",19,MUTED)
	text(modal_box,"REWARD    +150 FANAM",14,GOLD)
	button(modal_box,"STAY IN MALANADU     →",close_modal,true)

func pause_menu():
	begin_modal("KADAL   /   "+("STORY MODE" if Game.mode=="story" else "FREE ROAM"),"A moment of stillness",620)
	button(modal_box,"RESUME",close_modal,true)
	button(modal_box,"SATCHEL & WEAPONS",inventory)
	button(modal_box,"MAP OF MALANADU",map_screen)
	button(modal_box,"SETTINGS",settings)
	button(modal_box,"RETURN TO MAIN MENU",func(): Game.app.return_to_menu())

func settings():
	begin_modal("KADAL   /   SETTINGS","Make yourself at home",700)
	setting_slider("Sound volume",Game.volume,0,1,func(v): Game.volume=v; Game.save_settings())
	setting_slider("Camera sensitivity",Game.sensitivity*1000,1,7,func(v): Game.sensitivity=v/1000; Game.save_settings())
	setting_slider("Effect density",Game.effects_scale,.3,1.2,func(v): Game.effects_scale=v)
	var shake = CheckButton.new()
	shake.text = "Camera shake on impact"
	shake.button_pressed = Game.shake_enabled
	shake.toggled.connect(func(v): Game.shake_enabled=v; Game.save_settings())
	modal_box.add_child(shake)
	var shadows = CheckButton.new()
	shadows.text = "Sun shadows"
	shadows.button_pressed = Game.app.weather.sun.shadow_enabled
	shadows.toggled.connect(func(v): Game.app.weather.sun.shadow_enabled=v)
	modal_box.add_child(shadows)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	modal_box.add_child(row)
	button(row,"Change weather",func(): Game.app.weather.cycle())
	button(row,"Window / fullscreen",func():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	)
	button(modal_box,"SAVE & RETURN",close_modal,true)

func setting_slider(title_value: String,value: float,min_value: float,max_value: float,action: Callable):
	var row = HBoxContainer.new()
	modal_box.add_child(row)
	var l = text(row,title_value,16,MUTED)
	l.custom_minimum_size.x = 240
	var slider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = .01
	slider.value = value
	slider.custom_minimum_size = Vector2(300,28)
	slider.value_changed.connect(action)
	row.add_child(slider)

func inventory():
	begin_modal("SATCHEL   /   %d FANAM   /   %d HERBS"%[Game.coins,Game.herbs],"The tools of your training",860)
	for i in Game.weapons.size():
		var d = Game.weapons[i]
		var b = button(modal_box,"%d   %s  ·  %s     /     %d damage   ·   %.1fm reach"%[i+1,d.name,d.type,int(d.damage*(1+Game.upgrade*.15)),float(d.reach)],func():
			Game.player.combat.equip(i)
			close_modal()
		,i==Game.player.combat.weapon_id)
		b.tooltip_text = d.description
	wrapped(modal_box,"LMB · combo   /   F · heavy   /   RMB · guard   /   fresh guard · perfect parry\nHealing herbs restore 45 health. Meera sells supplies and weapon honing.",16,MUTED)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	modal_box.add_child(row)
	button(row,"Use healing herb",func(): Game.player.heal(); inventory())
	button(row,"RETURN",close_modal,true)

func map_screen():
	begin_modal("CARTOGRAPHY   /   FIVE PLACES, ONE COAST","Malanadu",960)
	var map = load("res://scripts/ui/cartography.gd").new()
	modal_box.add_child(map)
	text(modal_box,"●  YOU     ◇  CURRENT OBJECTIVE     ━  FOOTPATHS     /     1 square ≈ 27 metres",12,MUTED)
	button(modal_box,"RETURN TO THE COAST",close_modal,true)

func death_screen():
	begin_modal("THE MONSOON WILL WAIT","Rise again",640)
	modal_locked = true
	wrapped(modal_box,"Your story is not over. Rest at the village jetty and return with steadier footing.",25,CREAM,true)
	button(modal_box,"RETURN TO THE VILLAGE",func(): Game.player.respawn(); close_modal(),true)
	button(modal_box,"MAIN MENU",func(): Game.app.return_to_menu())
