# Container setup: owner's guide

Files: install.sh (installs the tools), PROMPT.md (paste into opencode), README.md (this file).
Run these in PowerShell on Windows. Replace <container>, <repo> and <path>.

1. Start the container (8 GB RAM; the named volume keeps the repo):
   docker run -dit --name <container> --memory=8g -v <repo>-data:/<repo> debian:bookworm bash
2. Clone the game repo into it (git and certificates are installed first):
   docker exec -it <container> bash -c "apt-get update -qq && apt-get install -y -qq git ca-certificates && git clone <repo-url> /<repo>"
3. Copy this folder into the repo's setup/ and make the script runnable:
   docker cp <path>\container-setup\. <container>:/<repo>/setup/
   docker exec <container> chmod +x /<repo>/setup/install.sh
4. Copy your Claude settings from Windows (not projects/):
   docker exec <container> mkdir -p /root/.claude
   docker cp $env:USERPROFILE\.claude\settings.json <container>:/root/.claude/
   docker cp $env:USERPROFILE\.claude\skills <container>:/root/.claude/
   docker cp $env:USERPROFILE\.claude\agents <container>:/root/.claude/
   docker cp $env:USERPROFILE\.claude\plugins <container>:/root/.claude/
   (Windows paths inside them, e.g. in hooks, may need fixing; check after the first claude start.)
5. Start opencode in the repo, then paste all of PROMPT.md into it:
   docker exec -it <container> bash -c "cd /<repo> && opencode"
6. Then do the logins in setup/LOGINS.md yourself: docker exec -it <container> bash

Stays on Windows: Blender, Claude in Chrome and the Blender MCP.
