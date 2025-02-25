/*
Quick overview:

Pipes combine to form pipelines
Pipelines and other atmospheric objects combine to form pipe_networks
	Note: A single pipe_network represents a completely open space

Pipes -> Pipelines
Pipelines + Other Objects -> Pipe network
*/
/obj/machinery/atmospherics
	anchored = 1
	resistance_flags = FIRE_PROOF
	max_integrity = 200
	plane = GAME_PLANE
	idle_power_usage = 0
	active_power_usage = 0
	power_channel = ENVIRON
	on_blueprints = TRUE
	var/can_unwrench = 0
	/// Can this be put under a tile?
	var/can_be_undertile = FALSE

	var/connect_types[] = list(1) //1=regular, 2=supply, 3=scrubber
	var/connected_to = 1 //same as above, currently not used for anything
	var/icon_connect_type = "" //"-supply" or "-scrubbers"

	var/initialize_directions = 0

	var/pipe_color
	var/obj/item/pipe/stored
	var/image/pipe_image
	layer = GAS_PIPE_HIDDEN_LAYER  //under wires
	var/layer_offset = 0.0 // generic over VISIBLE and HIDDEN, should be less than 0.01, or you'll reorder non-pipe things

/obj/machinery/atmospherics/New()
	if (!armor)
		armor = list("melee" = 25, "bullet" = 10, "laser" = 10, "energy" = 100, "bomb" = 0, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 70)
	..()

	if(!pipe_color)
		pipe_color = color
	color = null

	if(!pipe_color_check(pipe_color))
		pipe_color = null

/obj/machinery/atmospherics/Initialize()
	. = ..()
	SSair.atmos_machinery += src

/obj/machinery/atmospherics/proc/atmos_init()
	if(can_unwrench)
		stored = new(src, make_from = src)
	// Updates all pipe overlays and underlays
	update_underlays()

/obj/machinery/atmospherics/Destroy()
	QDEL_NULL(stored)
	SSair.atmos_machinery -= src
	SSair.deferred_pipenet_rebuilds -= src
	for(var/mob/living/L in src) //ventcrawling is serious business
		L.remove_ventcrawl()
		L.forceMove(get_turf(src))
	QDEL_NULL(pipe_image) //we have to qdel it, or it might keep a ref somewhere else
	return ..()

/obj/machinery/atmospherics/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = SSradio.add_object(src, frequency, RADIO_ATMOSIA)

// Icons/overlays/underlays
/obj/machinery/atmospherics/update_icon()
	switch(level)
		if(1)
			plane = FLOOR_PLANE
			layer = GAS_PIPE_HIDDEN_LAYER + layer_offset
		if(2)
			plane = GAME_PLANE
			layer = GAS_PIPE_VISIBLE_LAYER + layer_offset

/obj/machinery/atmospherics/proc/update_pipe_image()
	pipe_image = image(src, loc, layer = ABOVE_HUD_LAYER, dir = dir) //the 20 puts it above Byond's darkness (not its opacity view)
	pipe_image.plane = HUD_PLANE

/obj/machinery/atmospherics/proc/check_icon_cache()
	if(!istype(SSair.icon_manager))
		return FALSE

	return TRUE

/obj/machinery/atmospherics/proc/color_cache_name(var/obj/machinery/atmospherics/node)
	//Don't use this for standard pipes
	if(!istype(node))
		return null

	return node.pipe_color

/obj/machinery/atmospherics/proc/add_underlay(var/turf/T, var/obj/machinery/atmospherics/node, var/direction, var/icon_connect_type)
	if(node)
		if(T.intact && node.level == 1 && istype(node, /obj/machinery/atmospherics/pipe) && !T.transparent_floor)
			//underlays += SSair.icon_manager.get_atmos_icon("underlay_down", direction, color_cache_name(node))
			underlays += SSair.icon_manager.get_atmos_icon("underlay", direction, color_cache_name(node), "down" + icon_connect_type)
		else
			//underlays += SSair.icon_manager.get_atmos_icon("underlay_intact", direction, color_cache_name(node))
			underlays += SSair.icon_manager.get_atmos_icon("underlay", direction, color_cache_name(node), "intact" + icon_connect_type)
	else
		if(T.transparent_floor) //we want to keep pipes under transparent floors connected normally
			underlays += SSair.icon_manager.get_atmos_icon("underlay", direction, color_cache_name(node), "intact" + icon_connect_type)
		else
			//underlays += SSair.icon_manager.get_atmos_icon("underlay_exposed", direction, pipe_color)
			underlays += SSair.icon_manager.get_atmos_icon("underlay", direction, color_cache_name(node), "exposed" + icon_connect_type)

/obj/machinery/atmospherics/proc/update_underlays()
	if(check_icon_cache())
		return 1
	else
		return 0

// Connect types
/obj/machinery/atmospherics/proc/check_connect_types(obj/machinery/atmospherics/atmos1, obj/machinery/atmospherics/atmos2)
	var/i
	var/list1[] = atmos1.connect_types
	var/list2[] = atmos2.connect_types
	for(i=1,i<=list1.len,i++)
		var/j
		for(j=1,j<=list2.len,j++)
			if(list1[i] == list2[j])
				var/n = list1[i]
				return n
	return 0

/obj/machinery/atmospherics/proc/check_connect_types_construction(obj/machinery/atmospherics/atmos1, obj/item/pipe/pipe2)
	var/i
	var/list1[] = atmos1.connect_types
	var/list2[] = pipe2.connect_types
	for(i=1,i<=list1.len,i++)
		var/j
		for(j=1,j<=list2.len,j++)
			if(list1[i] == list2[j])
				var/n = list1[i]
				return n
	return 0

// Pipenet related functions
/obj/machinery/atmospherics/proc/returnPipenet()
	return

/obj/machinery/atmospherics/proc/returnPipenetAir()
	return

/obj/machinery/atmospherics/proc/setPipenet()
	return

/obj/machinery/atmospherics/proc/replacePipenet()
	return

/**
 * Whether or not this atmos machine has multiple pipenets attached to it
 * Used to determine if a ventcrawler should update their vision or not
 */
/obj/machinery/atmospherics/proc/is_pipenet_split()
	return FALSE

/obj/machinery/atmospherics/proc/build_network(remove_deferral = FALSE)
	// Called to build a network from this node
	if(remove_deferral)
		SSair.deferred_pipenet_rebuilds -= src

/obj/machinery/atmospherics/proc/defer_build_network()
	SSair.deferred_pipenet_rebuilds += src

/obj/machinery/atmospherics/proc/disconnect(obj/machinery/atmospherics/reference)
	return

/obj/machinery/atmospherics/proc/nullifyPipenet(datum/pipeline/P)
	if(P)
		P.other_atmosmch -= src

//(De)construction
/obj/machinery/atmospherics/attackby(obj/item/W, mob/user)
	var/turf/T = get_turf(src)
	if(can_unwrench && istype(W, /obj/item/wrench))
		if(level == 1 && T.transparent_floor && istype(src, /obj/machinery/atmospherics/pipe))
			to_chat(user, span_danger("You can't interact with something that's under the floor!"))
			return
		if(level == 1 && isturf(T) && T.intact)
			to_chat(user, span_danger("You must remove the plating first."))
			return
		var/datum/gas_mixture/int_air = return_air()
		var/datum/gas_mixture/env_air = loc.return_air()
		add_fingerprint(user)

		var/unsafe_wrenching = FALSE
		var/safefromgusts = FALSE
		var/I = int_air ? int_air.return_pressure() : 0
		var/E = env_air ? env_air.return_pressure() : 0
		var/internal_pressure = I - E

		playsound(src.loc, W.usesound, 50, 1)
		to_chat(user, span_notice("You begin to unfasten \the [src]..."))
		if(internal_pressure > 2*ONE_ATMOSPHERE)
			to_chat(user, span_warning("As you begin unwrenching \the [src] a gust of air blows in your face... maybe you should reconsider?"))
			unsafe_wrenching = TRUE //Oh dear oh dear

		if(do_after(user, 40 * W.toolspeed * gettoolspeedmod(user), target = src) && !QDELETED(src))
			user.visible_message( \
				"[user] unfastens \the [src].", \
				span_notice("You have unfastened \the [src]."), \
				span_italics("You hear ratcheting."))
			investigate_log("was <span class='warning'>REMOVED</span> by [key_name_log(usr)]", INVESTIGATE_ATMOS)

			for(var/obj/item/clothing/shoes/magboots/usermagboots in user.get_equipped_items())
				if(usermagboots.gustprotection && usermagboots.magpulse)
					safefromgusts = TRUE

			//You unwrenched a pipe full of pressure? let's splat you into the wall silly.
			if(unsafe_wrenching)
				if(safefromgusts)
					to_chat(user, span_italics("Your magboots cling to the floor as a great burst of wind bellows against you."))
				else
					unsafe_pressure_release(user,internal_pressure)
			deconstruct(TRUE)
	else
		if(T.transparent_floor)
			to_chat(user, span_danger("You can't interact with something that's under the floor!"))
			return TRUE
		return ..()

//Called when an atmospherics object is unwrenched while having a large pressure difference
//with it's locs air contents.
/obj/machinery/atmospherics/proc/unsafe_pressure_release(mob/user, pressures)
	if(!user)
		return

	if(!pressures)
		var/datum/gas_mixture/int_air = return_air()
		var/datum/gas_mixture/env_air = loc.return_air()
		pressures = int_air.return_pressure() - env_air.return_pressure()

	var/fuck_you_dir = get_dir(src, user)
	var/turf/general_direction = get_edge_target_turf(user, fuck_you_dir)
	user.visible_message(span_danger("[user] is sent flying by pressure!"),span_userdanger("The pressure sends you flying!"))
	//Values based on 2*ONE_ATMOS (the unsafe pressure), resulting in 20 range and 4 speed
	user.throw_at(general_direction, pressures/10, pressures/50)

/obj/machinery/atmospherics/deconstruct(disassembled = TRUE)
	if(!(flags & NODECONSTRUCT))
		if(can_unwrench)
			if(stored)
				stored.forceMove(get_turf(src))
				if(!disassembled)
					stored.obj_integrity = stored.max_integrity * 0.5
				transfer_fingerprints_to(stored)
				stored = null
	..()

/obj/machinery/atmospherics/on_construction(D, P, C)
	if(C)
		color = C
	dir = D
	initialize_directions = P
	var/turf/T = loc
	if(!T.transparent_floor)
		level = (T.intact || !can_be_undertile) ? 2 : 1
	else
		level = 2
	update_icon()
	add_fingerprint(usr)
	if(!SSair.initialized) //If there's no atmos subsystem, we can't really initialize pipenets
		SSair.machinery_to_construct.Add(src)
		return
	initialize_atmos_network()

/obj/machinery/atmospherics/proc/initialize_atmos_network()
	atmos_init()
	var/list/nodes = pipeline_expansion()
	for(var/obj/machinery/atmospherics/A in nodes)
		A.atmos_init()
		A.addMember(src)
	build_network()

// Find a connecting /obj/machinery/atmospherics in specified direction.
/obj/machinery/atmospherics/proc/findConnecting(var/direction)
	for(var/obj/machinery/atmospherics/target in get_step(src,direction))
		var/can_connect = check_connect_types(target, src)
		if(can_connect && (target.initialize_directions & get_dir(target,src)))
			return target

// Ventcrawling
#define VENT_SOUND_DELAY 30
/obj/machinery/atmospherics/relaymove(mob/living/user, direction)
	direction &= initialize_directions
	if(!direction || !(direction in GLOB.cardinal)) //cant go this way.
		return

	if(user in buckled_mobs)// fixes buckle ventcrawl edgecase fuck bug
		return

	var/obj/machinery/atmospherics/target_move = findConnecting(direction)
	if(target_move)
		if(is_type_in_list(target_move, GLOB.ventcrawl_machinery) && target_move.can_crawl_through())
			user.remove_ventcrawl()
			user.forceMove(target_move.loc) //handles entering and so on
			user.visible_message("You hear something squeezing through the ducts.", "You climb out the ventilation system.")
		else if(target_move.can_crawl_through())
			if(is_pipenet_split()) // Going away from a split means we want to update the view of the pipenet
				user.update_pipe_vision(target_move)
			user.loc = target_move
			user.client.eye = target_move //if we don't do this, Byond only updates the eye every tick - required for smooth movement
			if(world.time - user.last_played_vent > VENT_SOUND_DELAY)
				user.last_played_vent = world.time
				playsound(src, 'sound/machines/ventcrawl.ogg', 50, 1, -3)
			user.update_light() //if we can see through pipes - then why we can't glow through them?
	else
		if((direction & initialize_directions) || is_type_in_list(src, GLOB.ventcrawl_machinery)) //if we move in a way the pipe can connect, but doesn't - or we're in a vent
			user.remove_ventcrawl()
			user.forceMove(src.loc)
			user.visible_message("You hear something squeezing through the pipes.", "You climb out the ventilation system.")
	user.canmove = 0
	spawn(1)
		user.canmove = 1

/obj/machinery/atmospherics/AltClick(mob/living/user)
	user.handle_ventcrawl(src)

/obj/machinery/atmospherics/proc/can_crawl_through()
	return 1

/obj/machinery/atmospherics/proc/change_color(var/new_color)
	//only pass valid pipe colors please ~otherwise your pipe will turn invisible
	if(!pipe_color_check(new_color))
		return

	pipe_color = new_color
	update_icon()

// Additional icon procs
/obj/machinery/atmospherics/proc/universal_underlays(var/obj/machinery/atmospherics/node, var/direction)
	var/turf/T = get_turf(src)
	if(!istype(T)) return
	if(node)
		var/node_dir = get_dir(src,node)
		if(node.icon_connect_type == "-supply")
			add_underlay_adapter(T, , node_dir, "")
			add_underlay_adapter(T, node, node_dir, "-supply")
			add_underlay_adapter(T, , node_dir, "-scrubbers")
		else if(node.icon_connect_type == "-scrubbers")
			add_underlay_adapter(T, , node_dir, "")
			add_underlay_adapter(T, , node_dir, "-supply")
			add_underlay_adapter(T, node, node_dir, "-scrubbers")
		else
			add_underlay_adapter(T, node, node_dir, "")
			add_underlay_adapter(T, , node_dir, "-supply")
			add_underlay_adapter(T, , node_dir, "-scrubbers")
	else
		add_underlay_adapter(T, , direction, "-supply")
		add_underlay_adapter(T, , direction, "-scrubbers")
		add_underlay_adapter(T, , direction, "")

/obj/machinery/atmospherics/proc/add_underlay_adapter(var/turf/T, var/obj/machinery/atmospherics/node, var/direction, var/icon_connect_type) //modified from add_underlay, does not make exposed underlays
	if(node)
		if(T.intact && node.level == 1 && istype(node, /obj/machinery/atmospherics/pipe) && !T.transparent_floor)
			underlays += SSair.icon_manager.get_atmos_icon("underlay", direction, color_cache_name(node), "down" + icon_connect_type)
		else
			underlays += SSair.icon_manager.get_atmos_icon("underlay", direction, color_cache_name(node), "intact" + icon_connect_type)
	else
		if(T.transparent_floor) //we want to keep pipes under transparent floors connected normally
			underlays += SSair.icon_manager.get_atmos_icon("underlay", direction, color_cache_name(node), "intact" + icon_connect_type)
		else
			underlays += SSair.icon_manager.get_atmos_icon("underlay", direction, color_cache_name(node), "retracted" + icon_connect_type)

/obj/machinery/atmospherics/singularity_pull(S, current_size)
	if(current_size >= STAGE_FIVE)
		deconstruct(FALSE)
	return ..()

/obj/machinery/atmospherics/update_remote_sight(mob/user)
	user.sight |= (SEE_TURFS|BLIND)
	. = ..()

//Used for certain children of obj/machinery/atmospherics to not show pipe vision when mob is inside it.
/obj/machinery/atmospherics/proc/can_see_pipes()
	return TRUE
