/obj/item/clothing/mask/breath
	desc = "A close-fitting mask that can be connected to an air supply."
	name = "breath mask"
	icon_state = "breath"
	item_state = "breath"
	flags = AIRTIGHT
	flags_cover = MASKCOVERSMOUTH
	w_class = WEIGHT_CLASS_SMALL
	gas_transfer_coefficient = 0.10
	permeability_coefficient = 0.50
	actions_types = list(/datum/action/item_action/adjust)
	resistance_flags = NONE
	sprite_sheets = list(
		"Vox" = 'icons/mob/clothing/species/vox/mask.dmi',
		"Vox Armalis" = 'icons/mob/clothing/species/armalis/mask.dmi',
		"Unathi" = 'icons/mob/clothing/species/unathi/mask.dmi',
		"Ash Walker" = 'icons/mob/clothing/species/unathi/mask.dmi',
		"Ash Walker Shaman" = 'icons/mob/clothing/species/unathi/mask.dmi',
		"Draconid" = 'icons/mob/clothing/species/unathi/mask.dmi',
		"Tajaran" = 'icons/mob/clothing/species/tajaran/mask.dmi',
		"Vulpkanin" = 'icons/mob/clothing/species/vulpkanin/mask.dmi',
		"Grey" = 'icons/mob/clothing/species/grey/mask.dmi',
		"Drask" = 'icons/mob/clothing/species/drask/mask.dmi',
		"Plasmaman" = 'icons/mob/clothing/species/plasmaman/mask.dmi',
		"Monkey" = 'icons/mob/clothing/species/monkey/mask.dmi',
		"Farwa" = 'icons/mob/clothing/species/monkey/mask.dmi',
		"Wolpin" = 'icons/mob/clothing/species/monkey/mask.dmi',
		"Neara" = 'icons/mob/clothing/species/monkey/mask.dmi',
		"Stok" = 'icons/mob/clothing/species/monkey/mask.dmi'
	)

/obj/item/clothing/mask/breath/attack_self(var/mob/user)
	adjustmask(user)

/obj/item/clothing/mask/breath/AltClick(mob/living/user)
	if(!istype(user) || user.incapacitated() || user.restrained())
		to_chat(user, "<span class='warning'>You can't do that right now!</span>")
		return
	if(!in_range(src, user))
		return
	adjustmask(user)

/obj/item/clothing/mask/breath/medical
	desc = "A close-fitting sterile mask that can be connected to an air supply."
	name = "medical mask"
	icon_state = "medical"
	item_state = "medical"
	permeability_coefficient = 0.01
	put_on_delay = 10

/obj/item/clothing/mask/breath/vox
	desc = "A weirdly-shaped breath mask."
	name = "vox breath mask"
	icon_state = "voxmask"
	item_state = "voxmask"
	permeability_coefficient = 0.01
	species_restricted = list("Vox", "Vox Armalis") //These should fit the "Mega Vox" just fine.
	actions_types = list()

/obj/item/clothing/mask/breath/vox/attack_self(var/mob/user)
	return

/obj/item/clothing/mask/breath/vox/AltClick(mob/user)
	return
