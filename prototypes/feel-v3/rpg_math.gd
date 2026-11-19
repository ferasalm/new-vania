# PROTOTYPE - NOT FOR PRODUCTION
# Pure formulas for levels, damage and drops. No state and no autoload: every
# function is static and every number arrives as an argument (R passes the
# tuning values in). Results round half up and a hit is never below 1.
extends RefCounted


static func xp_total(level: int, step: float) -> int:
	# total XP needed to reach this level: round(step * (level - 1) * (level + 2) / 2)
	return int(round(step * float(level - 1) * float(level + 2) / 2.0))


static func level_for(xp: int, step: float, cap: int) -> int:
	# the highest level whose total XP she has reached, never above cap
	var lv := 1
	while lv < cap and xp >= xp_total(lv + 1, step):
		lv += 1
	return lv


static func dealt(power: float, atk: float, add: float) -> int:
	# a weapon hit: power x ATK, plus the flat gear bonus, at least 1
	return maxi(1, int(round(power * atk / 100.0 + add)))


static func special(power: float, special_pct: float) -> int:
	# a special hit: power x SPC, ignores ATK, at least 1
	return maxi(1, int(round(power * special_pct / 100.0)))


static func taken(raw: float, mult: float, def: float) -> int:
	# a hit on her: raw x area multiplier, then DEF, at least 1
	return maxi(1, int(round(raw * mult * (100.0 - def) / 100.0)))


static func scrap_chance(base: float, low: float, hp_share: float) -> float:
	# the scrap chance rises as her health falls; always between 0 and 1
	return clampf(base + low * (1.0 - hp_share), 0.0, 1.0)
