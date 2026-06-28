## Core Gameplay

The player commands a futuristic military force in a large-scale battle against an invading enemy army.

Unlike a traditional tower defense game, the player is not limited to placing static towers. Instead, they command an army consisting of infantry, vehicles, mechs, defensive structures, and orbital support abilities.

Battles revolve around controlling territory, reinforcing the front line, and making strategic decisions about where and when to deploy limited resources.

---

# Battlefield

Each level begins with the map divided into:

* Player-controlled territory
* Neutral territory (optional)
* Enemy-controlled territory

Only territory under a faction's control can be used as a deployment zone.

As the battle progresses, the front line shifts.

Capturing ground expands deployment options.

Losing ground reduces them.

The battlefield should always feel alive.

---

# Reinforcement System

Nothing simply appears.

Every deployment comes from orbit.

Examples:

* Infantry arrive in drop pods.
* Squads arrive in dropships.
* Heavy vehicles are airlifted in.
* Titans require specialized deployment.

This creates anticipation and reinforces the futuristic military theme.

---

# Economy

## Supply (Mission Resource)

Supply is generated continuously throughout a mission.

Example:

```
+10 Supply / second
```

Capturing strategic objectives increases Supply generation.

Everything costs Supply:

* Infantry
* Vehicles
* Defensive structures
* Mines
* Air support
* Titans

The player must constantly choose how to spend limited Supply.

---

## Command Capacity

Supply alone does not limit the player.

Each mission has a maximum Command Capacity.

Example:

```
Current:
18 / 30
```

Every deployed unit consumes capacity.

Example:

```
Rifle Squad     1

Heavy Squad     2

Walker          4

Titan          10
```

Players can increase capacity by:

* Capturing command posts
* Building communication centers
* Permanent campaign upgrades

---

## War Credits (Campaign Resource)

After completing missions, the player earns War Credits.

War Credits are used outside missions for permanent progression.

Examples:

* Unlock new units
* Unlock new structures
* Upgrade weapons
* Increase Command Capacity
* Improve dropships
* Unlock support abilities

---

# Units

Units are mobile combat forces.

Examples:

* Rifle Squad
* Heavy Infantry
* Engineer
* Sniper
* Medic
* Recon
* Mechs
* Titans

Units can move, fight, capture territory, and defend objectives.

The player has some control over movement, but units are not intended to be micromanaged like a traditional RTS.

Each deployment has an operational radius around its landing zone.

This encourages players to establish new forward positions rather than dragging the same army across the entire map.

---

# Structures

Structures are stationary.

Examples:

* Machine Gun Turret
* Missile Turret
* Bunker
* Shield Generator
* Minefield
* Radar Station
* Anti-Air Battery

Structures strengthen the front line and help secure captured territory.

---

# Terrain

Terrain affects combat.

Examples:

Open Ground

* Normal movement
* No defensive bonus

Sandbags

* Increased defense

Concrete

* High defensive bonus

Mud

* Movement penalty

Snow

* Movement penalty

Terrain should influence both player and enemy decisions.

---

# Air Support

The player gains access to powerful support abilities.

Examples:

* Orbital Strike
* Missile Barrage
* EMP
* Smoke Screen
* Supply Drop
* Reinforcements

These abilities cost Supply and/or operate on cooldowns.

Some abilities require control of specific objectives.

---

# Territory Control

Territory is one of the game's defining mechanics.

Capturing territory:

* Expands deployment zones
* Increases Supply generation
* Unlocks objectives
* Provides strategic advantages

Losing territory has the opposite effect.

The front line should constantly evolve throughout a mission.

---

# Campaign

Players complete missions on different planets and battlefields.

Mission rewards include:

* War Credits
* New technology
* New units
* Story progression

As the campaign advances, battles become larger in scale.

---

# Design Philosophy

Several principles should guide development:

### Every decision has an opportunity cost.

Choosing one option means giving up another.

Examples:

* Deploy a Titan or several infantry squads.
* Build fortifications or save Supply for an orbital strike.
* Capture an objective or defend existing territory.

Milestone map
CURRENT PROTOTYPE
├── Map background
├── Enemy pathing
├── Enemy health / death
├── Towers and projectiles
├── Deployable Rifle, Heavy, Turret
├── Unit selection and movement
├── Multiple enemies
└── Supply income and deployment costs
MILESTONE 1 — Complete a Basic Mission
├── Enemy reaches endpoint → player loses
├── All enemies defeated → player wins
├── Mission result message
├── Restart button / key
└── Remove or reset corpses on restart
MILESTONE 2 — Better Waves
├── Wave counter: "Wave 1 — 3 enemies remaining"
├── Multiple waves per mission
├── Delay between waves
├── Stronger enemy stats in later waves
└── Basic enemy types: Grunt, Heavy, Fast
MILESTONE 3 — Better Player Army
├── Unit health bars
├── Enemy attacks player units
├── Player unit death and corpses
├── Unit attack ranges / targeting
├── Select multiple units
└── Move selected group together
MILESTONE 4 — Deployment Polish
├── Placement preview before clicking
├── Invalid-placement indicator
├── Dropship / drop-pod arrival animation
├── Deployment cooldowns
├── Command Capacity population cap
└── Extract units for partial Supply refund
MILESTONE 5 — Structures and Defenses
├── Mine placement and detonation
├── Bunker with defensive bonus
├── Machine-gun turret
├── Missile turret with splash damage
├── Shield generator
└── Structure health and destruction
MILESTONE 6 — Terrain and Cover
├── Terrain zones on the map
├── Mud / snow movement penalties
├── Sandbags / bunkers reduce damage
├── Structures create fortified areas
└── Visual terrain overlay for testing
MILESTONE 7 — Territory and Frontline
├── Player / enemy-controlled zones
├── Deployment limited to friendly territory
├── Units capture nearby territory
├── Structures reinforce territory
├── Losing ground removes deployment options
└── Objectives increase Supply income or Capacity
MILESTONE 8 — Support Abilities
├── Cooldown system
├── Orbital strike
├── Supply drop
├── EMP
├── Missile barrage
└── Objective-based ability unlocks
MILESTONE 9 — Campaign Layer
├── Main menu
├── Level select
├── Mission rewards
├── War Credits
├── Unit / structure unlocks
├── Permanent upgrades
└── Save progress
MILESTONE 10 — Presentation and Polish
├── Unit sprite animations
├── Death animations
├── Drop-pod / dropship animations
├── Projectile trails and explosions
├── Screen shake
├── Damage flashes
├── UI sound effects
├── Weapons, explosions, and ambient audio
├── Music
└── Balance and visual cleanup
