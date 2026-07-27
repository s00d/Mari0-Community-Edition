--[[
  Mario power forms (leaf→raccoon minimum).

  form is independent of character pack: leaf unlocks raccoon abilities
  even when char.raccoon is false (default mario).
]]

global MARIO_FORMS: {string:{string:any}} = {
	small = { size = 1 },
	super = { size = 2 },
	fire = { size = 3 },
	raccoon = { size = 2, raccoon = true, flight = true, tail = true },
}

-- item / enemy name → form id
global ITEM_FORM: {string:string} = {
	mushroom = "super",
	flower = "fire",
	leaf = "raccoon",
}

global function mario_form_def(form: string): {string:any}
	return MARIO_FORMS[form] or MARIO_FORMS.small
end

global function mario_item_to_form(item: string): string|nil
	return ITEM_FORM[item]
end
