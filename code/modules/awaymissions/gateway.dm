GLOBAL_DATUM_INIT(the_gateway, /obj/machinery/gateway/centerstation, null)
/obj/machinery/gateway
	name = "gateway"
	desc = "A mysterious gateway built by unknown hands, it allows for faster than light travel to far-flung locations."
	icon = 'icons/obj/machines/gateway.dmi'
	icon_state = "off"
	density = 1
	anchored = 1
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/active = 0

/obj/machinery/gateway/Initialize()
	..()
	update_icon()
	update_density_from_dir()

/obj/machinery/gateway/proc/update_density_from_dir()
	if(dir == 2)
		density = 0


/obj/machinery/gateway/update_icon()
	if(active)
		icon_state = "on"
		return
	icon_state = "off"



//this is da important part wot makes things go
/obj/machinery/gateway/centerstation
	density = 1
	icon_state = "offcenter"
	use_power = IDLE_POWER_USE

	//warping vars
	var/list/linked = list()
	var/ready = 0				//have we got all the parts for a gateway?
	var/wait = 0				//this just grabs world.time at world start
	var/obj/machinery/gateway/centeraway/awaygate = null

/obj/machinery/gateway/centerstation/New()
	..()
	if(!GLOB.the_gateway)
		GLOB.the_gateway = src

/obj/machinery/gateway/centerstation/Initialize()
	..()
	update_icon()
	wait = world.time + CONFIG_GET(number/gateway_delay)
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/gateway/centerstation/LateInitialize()
	awaygate = locate(/obj/machinery/gateway/centeraway) in GLOB.machines

/obj/machinery/gateway/centerstation/update_density_from_dir()
	return

/obj/machinery/gateway/centerstation/Destroy()
	if(GLOB.the_gateway == src)
		GLOB.the_gateway = null
	return ..()

/obj/machinery/gateway/centerstation/update_icon()
	if(active)
		icon_state = "oncenter"
		return
	icon_state = "offcenter"



/obj/machinery/gateway/centerstation/process()
	if(stat & (NOPOWER))
		if(active) toggleoff()
		return

	if(active)
		use_power(5000)


/obj/machinery/gateway/centerstation/proc/detect()
	linked = list()	//clear the list
	var/turf/T = loc

	for(var/i in GLOB.alldirs)
		T = get_step(loc, i)
		var/obj/machinery/gateway/G = locate(/obj/machinery/gateway) in T
		if(G)
			linked.Add(G)
			continue

		//this is only done if we fail to find a part
		ready = 0
		toggleoff()
		break

	if(linked.len == 8)
		ready = 1


/obj/machinery/gateway/centerstation/proc/toggleon(mob/user as mob)
	if(!ready)
		return
	if(linked.len != 8)
		return
	if(!powered())
		return
	if(!awaygate)
		awaygate = locate(/obj/machinery/gateway/centeraway) in GLOB.machines
		if(!awaygate)
			to_chat(user, "<span class='notice'>Error: No destination found.</span>")
			return
	if(world.time < wait)
		to_chat(user, "<span class='notice'>Error: Warpspace triangulation in progress. Estimated time to completion: [round(((wait - world.time) / 10) / 60)] minutes.</span>")
		return

	for(var/obj/machinery/gateway/G in linked)
		G.active = 1
		G.update_icon()
	active = 1
	update_icon()


/obj/machinery/gateway/centerstation/proc/toggleoff()
	for(var/obj/machinery/gateway/G in linked)
		G.active = 0
		G.update_icon()
	active = 0
	update_icon()


/obj/machinery/gateway/centerstation/attack_hand(mob/user as mob)
	add_fingerprint(user)
	if(!ready)
		detect()
		return
	if(!active)
		toggleon(user)
		return
	toggleoff()


//okay, here's the good teleporting stuff
/obj/machinery/gateway/centerstation/Bumped(atom/movable/moving_atom)
	if(!ready)
		return
	if(!active)
		return
	if(!awaygate)
		return

	if(awaygate.calibrated)
		moving_atom.forceMove(get_step(awaygate.loc, SOUTH))
		moving_atom.dir = SOUTH
		return
	else
		var/obj/effect/landmark/dest = pick(GLOB.awaydestinations)
		if(dest)
			moving_atom.forceMove(dest.loc)
			moving_atom.dir = SOUTH
			use_power(5000)
		return


/obj/machinery/gateway/centerstation/attackby(obj/item/W as obj, mob/user as mob, params)
	if(istype(W,/obj/item/multitool))
		add_fingerprint(user)
		to_chat(user, "The gate is already calibrated, there is no work for you to do here.")
		return
	return ..()

/////////////////////////////////////Away////////////////////////


/obj/machinery/gateway/centeraway
	density = 1
	icon_state = "offcenter"
	use_power = NO_POWER_USE
	var/calibrated = 1
	var/list/linked = list()	//a list of the connected gateway chunks
	var/ready = 0
	var/obj/machinery/gateway/centeraway/stationgate = null


/obj/machinery/gateway/centeraway/Initialize()
	..()
	update_icon()
	stationgate = locate(/obj/machinery/gateway/centerstation) in GLOB.machines


/obj/machinery/gateway/centeraway/update_density_from_dir()
	return

/obj/machinery/gateway/centeraway/update_icon()
	if(active)
		icon_state = "oncenter"
		return
	icon_state = "offcenter"


/obj/machinery/gateway/centeraway/proc/detect()
	linked = list()	//clear the list
	var/turf/T = loc

	for(var/i in GLOB.alldirs)
		T = get_step(loc, i)
		var/obj/machinery/gateway/G = locate(/obj/machinery/gateway) in T
		if(G)
			linked.Add(G)
			continue

		//this is only done if we fail to find a part
		ready = 0
		toggleoff()
		break

	if(linked.len == 8)
		ready = 1


/obj/machinery/gateway/centeraway/proc/toggleon(mob/user as mob)
	if(!ready)
		return
	if(linked.len != 8)
		return
	if(!stationgate)
		stationgate = locate(/obj/machinery/gateway/centerstation) in GLOB.machines
		if(!stationgate)
			to_chat(user, "<span class='notice'>Error: No destination found.</span>")
			return

	for(var/obj/machinery/gateway/G in linked)
		G.active = 1
		G.update_icon()
	active = 1
	update_icon()


/obj/machinery/gateway/centeraway/proc/toggleoff()
	for(var/obj/machinery/gateway/G in linked)
		G.active = 0
		G.update_icon()
	active = 0
	update_icon()


/obj/machinery/gateway/centeraway/attack_hand(mob/user as mob)
	add_fingerprint(user)
	if(!ready)
		detect()
		return
	if(!active)
		toggleon(user)
		return
	toggleoff()


/obj/machinery/gateway/centeraway/Bumped(atom/movable/moving_atom)
	if(!ready)
		return
	if(!active)
		return
	if(!stationgate || QDELETED(stationgate))
		return
	if(isliving(moving_atom))
		if(exilecheck(moving_atom))
			return
	else
		for(var/mob/living/L in moving_atom.contents)
			if(exilecheck(L))
				atom_say("Rejecting [moving_atom]: Exile implant detected in contained lifeform.")
				return
	if(moving_atom.has_buckled_mobs())
		for(var/mob/living/L in moving_atom.buckled_mobs)
			if(exilecheck(L))
				atom_say("Rejecting [moving_atom]: Exile implant detected in close proximity lifeform.")
				return
	moving_atom.forceMove(get_step(stationgate.loc, SOUTH))
	moving_atom.setDir(SOUTH)
	if(ismob(moving_atom))
		var/mob/M = moving_atom
		if(M.client)
			M.client.move_delay = max(world.time + 5, M.client.move_delay)

/obj/machinery/gateway/centeraway/proc/exilecheck(var/mob/living/carbon/M)
	for(var/obj/item/implant/exile/E in M)//Checking that there is an exile implant in the contents
		if(E.imp_in == M)//Checking that it's actually implanted vs just in their pocket
			to_chat(M, "<span class='notice'>The station gate has detected your exile implant and is blocking your entry.</span>")
			return 1
	return 0

/obj/machinery/gateway/centeraway/attackby(obj/item/W as obj, mob/user as mob, params)
	if(istype(W,/obj/item/multitool))
		if(calibrated)
			to_chat(user, "<span class='notice'>The gate is already calibrated, there is no work for you to do here.</span>")
			return
		else
			add_fingerprint(user)
			to_chat(user, "<span class='boldnotice'>Recalibration successful!</span><span class='notice'>: This gate's systems have been fine tuned.  Travel to this gate will now be on target.</span>")
			calibrated = 1
		return
	return ..()
