

## Shop+Enchant (run 22)
Mara: MARA_STOCK, _build_shop_panel, attempt_buy_item
Edda enchant: ENCHANT_SHARD_COST=8, attempt_enchant
Edda sell: SELL_RATE=0.60, attempt_sell_weapon
Achievement: first_enchant (world_flag first_enchant_done, priority 28)


## God-ray Shafts (run 23)
GOD_RAY_SPOTS: Array of 5 dicts (pos: Vector3, color: Color, amount: int)
_build_god_rays: spawns GPUParticles3D shaft emitters, joins group "god_ray_shafts"
World.gd hook: amount_ratio fade keyed to elev2 (sin of time_of_day arc)
Schema: shaft_color=warm amber, emission_energy_multiplier=0.80, lifetime=32s, spread=4deg
