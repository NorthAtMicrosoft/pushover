---
name: pushover
description: Send push notifications via the Pushover API. Use this skill whenever the user wants to send a notification, alert, or message to their phone or devices via Pushover. Triggers include any mention of 'push notification', 'pushover', 'notify my phone', 'send an alert', or requests to notify/alert after a task completes.
---

# Pushover Notification Skill

Send push notifications to devices via the [Pushover API](https://pushover.net/api).

## Prerequisites

Two environment variables must be set:

| Variable | Description |
|----------|-------------|
| `PUSHOVER_USER_KEY` | Your Pushover user key (from the Pushover dashboard) |
| `PUSHOVER_API_TOKEN` | Your Pushover application API token |

If either variable is missing, **stop and ask the user** to set them before proceeding.

## Usage

Two scripts are provided — pick the one that matches the environment:

| Script | Platform | Requires |
|--------|----------|----------|
| `scripts/pushover.sh`  | Linux, macOS, WSL, Git Bash | POSIX shell + `curl` or `wget` |
| `scripts/pushover.ps1` | Windows (native), PowerShell Core | PowerShell 5.1+ or pwsh 7+ |

### Shell (Linux / macOS / WSL)

```bash
bash /path/to/pushover/scripts/pushover.sh -m "Your task is complete"
```

```bash
bash /path/to/pushover/scripts/pushover.sh \
  -m "Build failed on main branch" \
  -t "CI Alert" \
  -p 1
```

#### Shell flags

| Flag | Description | Default |
|------|-------------|---------|
| `-m` | Message body (required) | — |
| `-t` | Notification title | `Claude Notification` |
| `-p` | Priority: -2 (silent) to 2 (emergency) | 0 (normal) |
| `-s` | Sound name (see Pushover docs) | device default |
| `-u` | Supplementary URL | — |
| `-n` | URL title (requires `-u`) | — |
| `-d` | Target device name | all devices |

### PowerShell (Windows)

```powershell
.\pushover.ps1 -Message "Your task is complete"
```

```powershell
.\pushover.ps1 -Message "Build failed on main branch" -Title "CI Alert" -Priority 1
```

#### PowerShell parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-Message` | Message body (required) | — |
| `-Title` | Notification title | `Claude Notification` |
| `-Priority` | Priority: -2 (silent) to 2 (emergency) | 0 (normal) |
| `-Sound` | Sound name (see Pushover docs) | device default |
| `-Url` | Supplementary URL | — |
| `-UrlTitle` | URL title (requires `-Url`) | — |
| `-Device` | Target device name | all devices |

### Priority levels

- `-2` — No notification, no alert
- `-1` — Quiet: no sound/vibration
- `0` — Normal (default)
- `1` — High: bypasses quiet hours
- `2` — Emergency: repeats until acknowledged (requires retry/expire — the script sets 60s retry, 3600s expire automatically)

## Behavior guidelines

1. **Always verify env vars first.** Run the script; it will exit with a clear error if they're missing.
2. **Keep messages concise.** Pushover has a 1024-character message limit.
3. **Use appropriate priority.** Default to 0. Only use 1 or 2 when the user explicitly wants urgent/emergency alerts.
4. **Report the result.** Tell the user whether the notification was sent successfully or if there was an error, including the Pushover API response.
5. **Proactive use.** If the user asks you to do a long-running task and says "let me know when it's done", offer to send a Pushover notification on completion.
