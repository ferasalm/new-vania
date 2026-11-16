"""Adds the mini-game's numbers to tuning.json and its music to events.json.
Safe to run again: it only adds what is missing and never changes a saved value.

  python tools/add_tuning.py
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")

# key: (value, min, max, step, label, help)
NEW = {
    "door_open_distance": (56, 24, 120, 4, "Door: opens when this near", "How close she must be before a door slides open. 56 is three and a half floor tiles."),
    "door_time": (0.35, 0.1, 1.5, 0.05, "Door: opening time", "Seconds a normal door takes to slide open."),
    "boss_door_time": (1.6, 0.4, 4.0, 0.1, "Boss door: opening time", "Seconds the big boss door takes to grind open."),
    "shot_gravity": (420, 100, 900, 10, "Enemy shots: how fast they drop", "How hard arcing shots (the spitter) fall. Lower = slower, floatier arcs."),
    "hound_hp": (30, 5, 120, 1, "Hound health", "Hits needed = this / attack damage. 30 is three Dirge cuts."),
    "hound_damage": (8, 1, 40, 1, "Hound damage", "HP she loses when the hound hits her."),
    "hound_pounce": (255, 120, 400, 5, "Hound pounce height", "How hard the hound jumps at her. 255 clears about two and a half tiles."),
    "ghost_hp": (22, 5, 120, 1, "Ghost health", "Hits needed = this / attack damage."),
    "ghost_damage": (7, 1, 40, 1, "Ghost damage", "HP she loses to the ghost's touch or shriek."),
    "ghost_blink_every": (5.0, 2.0, 12.0, 0.5, "Ghost: seconds between blinks", "How often the ghost vanishes and reappears behind her."),
    "ghost_shriek_warning": (1.0, 0.5, 2.0, 0.05, "Ghost: shriek warning", "Seconds between it reappearing and the shriek going off. Longer = easier to step away."),
    "ghost_shriek_radius": (42, 20, 90, 2, "Ghost: shriek size", "How far the shriek reaches around the ghost. 42 is about two and a half tiles."),
    "choir_hp": (34, 5, 150, 1, "Choir health", "Hits needed = this / attack damage."),
    "choir_damage": (9, 1, 40, 1, "Choir damage", "HP she loses to a feather or the dive."),
    "choir_notice": (190, 80, 320, 10, "Choir: notices her from", "How far away the winged enemy wakes up."),
    "choir_speed": (70, 20, 160, 5, "Choir: hover speed", "How fast it follows her around, up out of reach."),
    "choir_wait": (2.4, 0.8, 6.0, 0.1, "Choir: rest between attacks", "Seconds it hovers between attacks. This is when you can jump up and cut it."),
    "choir_feather_speed": (135, 60, 260, 5, "Choir: feather speed", "How fast the three feathers fly."),
    "choir_dive_warning": (0.6, 0.2, 1.5, 0.05, "Choir: dive warning", "Seconds it blinks before it dives through you."),
    "choir_dive_speed": (235, 120, 400, 5, "Choir: dive speed", "How fast it dives."),
    "spitter_hp": (26, 5, 120, 1, "Spitter health", "Hits needed = this / attack damage."),
    "spitter_damage": (7, 1, 40, 1, "Spitter damage", "HP she loses to one of its shots, or to touching it."),
    "spitter_range": (210, 80, 340, 10, "Spitter: how far it can lob", "It starts lobbing shots when she is this near."),
    "spitter_burst_range": (52, 24, 100, 2, "Spitter: burst when this near", "Closer than this and it sprays a fan of shots instead."),
    "spitter_wait": (1.7, 0.6, 5.0, 0.1, "Spitter: rest between shots", "Seconds between its shots."),
    "warden_hp": (130, 40, 400, 5, "Warden health", "The big brute. 130 is thirteen Dirge cuts or about seven Elegy cuts."),
    "warden_damage": (14, 2, 50, 1, "Warden damage", "HP she loses to its claws, its landing or the floor waves."),
    "warden_notice": (200, 80, 340, 10, "Warden: notices her from", "How far away it wakes and starts walking at her."),
    "warden_speed": (42, 10, 120, 2, "Warden: walk speed", "How fast it walks her down. She runs at 125."),
    "warden_warning": (0.5, 0.2, 1.2, 0.05, "Warden: warning", "Seconds it blinks before a lunge or a leap."),
    "warden_lunge_speed": (250, 120, 420, 10, "Warden: lunge speed", "How fast the claw lunge travels. Backdash or jump it."),
    "warden_leap": (300, 180, 420, 10, "Warden: leap height", "How hard it jumps before it slams down."),
    "warden_wave_speed": (150, 60, 300, 10, "Warden: floor wave speed", "How fast the two waves run along the floor after it lands. Jump them."),
    "warden_wait": (1.5, 0.5, 4.0, 0.1, "Warden: rest between attacks", "Seconds before it may attack again. This is your opening."),
    "boss_hp": (220, 60, 800, 10, "Boss health", "Body hits take full damage; hand hits only a share."),
    "boss_damage": (16, 2, 60, 1, "Boss damage", "HP she loses to a hand or a bolt."),
    "boss_hand_share": (0.3, 0.0, 1.0, 0.05, "Boss: damage from hitting a hand", "Share of a hit that counts when you cut a hand instead of the body. 0.3 = three tenths."),
    "boss_gap": (1.5, 0.5, 4.0, 0.1, "Boss: rest between attacks", "Seconds between its attacks. Lower = harder."),
    "boss_hand_speed": (190, 80, 360, 10, "Boss: hand follow speed", "How fast a hand follows you before it slams."),
    "boss_slam_track": (1.1, 0.4, 2.5, 0.05, "Boss: slam follow time", "Seconds the hand follows you before it stops to drop."),
    "boss_slam_hang": (0.4, 0.15, 1.0, 0.05, "Boss: slam warning", "Seconds the hand hangs still before it drops. This is your time to step aside."),
    "boss_slam_speed": (520, 240, 900, 20, "Boss: slam drop speed", "How fast the hand falls."),
    "boss_stuck": (3.4, 1.5, 7.0, 0.1, "Boss: hand stuck time", "Seconds a slammed hand stays in the floor as a step. Longer = easier."),
    "boss_sweep_warning": (0.6, 0.2, 1.5, 0.05, "Boss: sweep warning", "Seconds a hand waits at the wall before it slides across."),
    "boss_sweep_speed": (230, 100, 420, 10, "Boss: sweep speed", "How fast a hand slides across the floor."),
    "boss_bolt_speed": (170, 80, 320, 10, "Boss: bolt speed", "How fast the golden bolts fly."),
}

MUSIC = {
    "music_church": ("music/cyberpunk_city_2.ogg", "The church"),
    "music_library": ("music/battle_encounter.ogg", "The library"),
    "music_lab": ("music/battle_encounter_2.ogg", "The lab"),
    "music_save": ("music/save_room.ogg", "The save room"),
    "music_boss": ("music/boss_battle.ogg", "The boss"),
}


def main():
    tp = os.path.join(ROOT, "tuning.json")
    t = json.load(open(tp))
    for k, (v, lo, hi, step, label, help_) in NEW.items():
        if k not in t:
            t[k] = {"value": float(v), "min": float(lo), "max": float(hi), "step": float(step), "label": label, "help": help_}
    json.dump(t, open(tp, "w", newline="\n"), indent=2)
    open(tp, "a", newline="\n").write("\n")

    ep = os.path.join(ROOT, "assets", "audio", "events.json")
    e = json.load(open(ep))
    old = e["music"].get("music_room", e["music"].get("music_church", {}))
    volume = float(old.get("volume_db", 2.0))
    files = []
    for f in sorted(os.listdir(os.path.join(ROOT, "assets", "audio", "music"))):
        if f.endswith(".ogg"):
            files.append("music/" + f)
    gains = {o["file"]: o["gain_db"] for o in old.get("options", [])}
    music = {}
    for name, (first, _) in MUSIC.items():
        if name in e["music"] and name != "music_boss":
            music[name] = e["music"][name]
            continue
        # every area can be re-picked by ear in the F1 SOUNDS page: all tracks are options
        opts = [{"file": f, "gain_db": gains.get(f, -12.0)} for f in files]
        music[name] = {"file": first, "volume_db": volume, "options": opts}
    e["music"] = music
    json.dump(e, open(ep, "w", newline="\n"), indent=2)
    open(ep, "a", newline="\n").write("\n")
    print("tuning keys:", len(t), "music events:", list(music))


if __name__ == "__main__":
    main()
