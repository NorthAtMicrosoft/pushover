# Push MCP Server & Agent Skill

An MCP stdio server that sends push notifications to your iPhone via [Pushover](https://pushover.net).

## Setup

1. **Create a Pushover account** at https://pushover.net and install the iOS app.
2. **Create an application** at https://pushover.net/apps/build to get your **API Token**.
3. **Note your User Key** from the Pushover dashboard.

## Install Dependencies

```sh
python -m pip install -r requirements.txt
```

## Configuration

Set environment variables:

```sh
export PUSHOVER_TOKEN="your-app-api-token"
export PUSHOVER_USER="your-user-key"
```

## Add to your MCP client

Add to your MCP client config (e.g. Claude Desktop `claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "push": {
      "command": "python",
      "args": ["%USERPROFILE%\\projects\\mcp\\push\\server.py"],
      "env": {
        "PUSHOVER_TOKEN": "your-app-api-token",
        "PUSHOVER_USER": "your-user-key"
      }
    }
  }
}
```

## Tool: `send_push`

| Parameter   | Type   | Required | Description |
|-------------|--------|----------|-------------|
| `message`   | string | yes      | Notification body text |
| `title`     | string | no       | Notification title |
| `priority`  | int    | no       | -2 (lowest) to 2 (emergency). Default: 0 |
| `sound`     | string | no       | Sound name (e.g. pushover, bike, cosmic, none) |
| `url`       | string | no       | Supplementary URL |
| `url_title` | string | no       | Title for the URL |
| `html`      | bool   | no       | Enable HTML formatting |
| `device`    | string | no       | Target a specific device |

