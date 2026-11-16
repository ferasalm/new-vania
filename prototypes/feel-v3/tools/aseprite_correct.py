# PROTOTYPE - NOT FOR PRODUCTION
# The Aseprite correction pass (the user's rule: frames are always corrected in
# Aseprite, never shipped straight out of PIL). For every frame the two bake
# scripts produced, this drives the Aseprite MCP server (the same docker exec
# command opencode.json uses) to: import the PNG, report jagged-edge
# suggestions (report only - applying them would add the half-alpha smoothing
# that breaks 16-bit density), remove stray single pixels that have no
# 4-connected neighbour (except the weapon flash / dissolve decorations, which
# are meant to be alone), and export the PNG back out of Aseprite. The colour
# census itself is printed by the bake scripts: an RGB sprite's palette
# metadata does not reflect its pixels, so PIL is the honest counter.
# Idempotent: re-running re-imports the exported files and changes nothing.
# Usage: python aseprite_correct.py
# Note: the MCP server runs inside the opencode docker container; the container
# name and mount below are this machine's setup (see opencode.json, mcp.aseprite).
import json
import os
import subprocess
import sys
import time

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, "..", "assets")
# the worktree as the Aseprite MCP container sees it. The docker mount maps the
# host checkout to /workspace/<worktree-name>, so point ASEPRITE_CONT_ASSETS at
# this checkout's assets when running from another worktree
CONT_ASSETS = os.environ.get(
    "ASEPRITE_CONT_ASSETS",
    "/workspace/new-vania-proto-v3-weapons/prototypes/feel-v3/assets",
)
CONTAINER = "opencode-workspace-opencode-1"
SERVER = "/workspace/setup/pixel-mcp/bin/pixel-mcp"

HERO = {"idle": 4, "run": 7, "jump": 4, "attack": 5, "attack2": 5, "crouch": 1, "crouchatk": 5}
FILES = [("hero", "%s_%02d" % (anim, i)) for anim, n in HERO.items() for i in range(n)]
FILES += [(s, "%s_%02d" % (a, i)) for s in ("weapon-dirge", "weapon-elegy")
          for a in ("j", "i", "low") for i in range(5)]

FLASH_OFFS = [(0, 0), (1, 0), (-1, 0), (0, -1), (0, 1), (1, -1)]
ANCHORS = {"j": (60, 42), "i": (60, 42), "low": (60, 53)}   # the hand, and the crouched hand


class PixelMcp:
    """Minimal MCP stdio client for the pixel-mcp server in the container."""

    def __init__(self):
        # the server logs every request on stderr; that pipe must be drained
        # (here: discarded) or the server blocks on its own log after ~40 calls
        self.proc = subprocess.Popen(
            ["docker", "exec", "-e", "HOME=/workspace/setup/home", "-i", CONTAINER, SERVER],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL)
        self._id = 0
        self.call("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                 "clientInfo": {"name": "aseprite-correct", "version": "1.0"}})
        self.notify("notifications/initialized")

    def _send(self, obj):
        self.proc.stdin.write((json.dumps(obj) + "\n").encode("utf-8"))
        self.proc.stdin.flush()

    def _recv(self):
        while True:
            raw = self.proc.stdout.readline()
            if not raw:
                raise EOFError("pixel-mcp closed")
            msg = json.loads(raw.decode("utf-8", "replace"))
            if "id" in msg:
                return msg

    def notify(self, method):
        self._send({"jsonrpc": "2.0", "method": method})

    def call(self, method, params=None):
        self._id += 1
        req = {"jsonrpc": "2.0", "id": self._id, "method": method}
        if params is not None:
            req["params"] = params
        self._send(req)
        return self._recv()

    def tool(self, name, **args):
        resp = self.call("tools/call", {"name": name.replace("aseprite_", ""),
                                        "arguments": args})
        if "error" in resp:
            raise RuntimeError("{}: {}".format(name, resp["error"]))
        result = resp.get("result", {})
        if result.get("isError"):
            # the MCP spec reports tool execution failures through isError; a
            # failed correction must not pass as ordinary output
            text = "".join(c.get("text", "") for c in result.get("content", [])
                           if c.get("type") == "text")
            raise RuntimeError("{} failed: {}".format(name, text))
        text = "".join(c.get("text", "") for c in result.get("content", [])
                       if c.get("type") == "text")
        try:
            return json.loads(text)
        except (ValueError, TypeError):
            return text


def points(img):
    w, h = img.size
    p = img.load()
    return {(x, y) for y in range(h) for x in range(w) if p[x, y][3] > 0}


def orphans(img):
    w, h = img.size
    p = img.load()
    out = set()
    for y in range(h):
        for x in range(w):
            if p[x, y][3] == 0:
                continue
            if not any(0 <= x + dx < w and 0 <= y + dy < h and p[x + dx, y + dy][3] > 0
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out.add((x, y))
    return out


def expected_decor(sub, strip, idx):
    # the flash pixels on frame 0 and the dissolve dots on frame 4 are meant to
    # sit alone; everything else with no neighbour is noise
    if not sub.startswith("weapon-") or idx not in (0, 4):
        return set()
    if idx == 0:
        ax, ay = ANCHORS[strip]
        return {(ax + dx, ay + dy) for dx, dy in FLASH_OFFS}
    f3 = Image.open(os.path.join(ASSETS, sub, "%s_%02d.png" % (strip, 3))).convert("RGBA")
    tips = sorted(points(f3), key=lambda p: (p[0], -p[1]))[-3:]
    return set(tips)


class Session:
    def __init__(self):
        self.mcp = None

    def tool(self, name, **args):
        for attempt in (1, 2):
            try:
                if self.mcp is None:
                    self.mcp = PixelMcp()
                return self.mcp.tool(name, **args)
            except Exception as e:
                print("  retry %s (%s): %s" % (name, attempt, str(e)[:120]))
                self.mcp = None
                time.sleep(1)
        raise RuntimeError("tool failed twice: " + name)


def main():
    s = Session()
    print("== Aseprite correction pass: %d frames ==" % len(FILES))
    fixed = 0
    for sub, name in FILES:
        win = os.path.join(ASSETS, sub, name + ".png")
        cont = "%s/%s/%s.png" % (CONT_ASSETS, sub, name)
        sprite = s.tool("aseprite_create_canvas", width=128, height=64, color_mode="rgb")["file_path"]
        s.tool("aseprite_import_image", sprite_path=sprite, image_path=cont,
               layer_name="bake", frame_number=1)
        # the colour census is done by the bake scripts (an RGB sprite's palette
        # metadata does not reflect its pixels); here we check the edges and the
        # noise, and let Aseprite write the PNG back out
        try:
            aa = s.tool("aseprite_suggest_antialiasing", sprite_path=sprite, layer_name="bake",
                        frame_number=1, auto_apply=False, use_palette=False, threshold=128)
            edges = aa.get("total_edges", len(aa.get("suggestions", []))) if isinstance(aa, dict) else 0
        except Exception:
            # a few frames make the server answer in a shape that fails its own
            # output schema; the edge report is informational, so carry on
            edges = -1
        img = Image.open(win).convert("RGBA")
        strip, idx = name.split("_")
        stray = orphans(img) - expected_decor(sub, strip, int(idx))
        if stray:
            # single-pixel noise: erase it in Aseprite, not in PIL
            s.tool("aseprite_draw_pixels", sprite_path=sprite, layer_name="bake", frame_number=1,
                   pixels=[{"x": x, "y": y, "color": "#00000000"} for x, y in sorted(stray)])
            fixed += len(stray)
        s.tool("aseprite_export_sprite", sprite_path=sprite, output_path=cont,
               format="png", frame_number=1)
        print("%-22s jagged-edge hints %2d  noise px removed %d"
              % ("%s/%s" % (sub, name), edges, len(stray)))
    print("== pass complete: %d frames through Aseprite, %d noise pixels removed =="
          % (len(FILES), fixed))


if __name__ == "__main__":
    main()
