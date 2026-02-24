import os
import httpx
from mcp.server.fastmcp import FastMCP

PUSHOVER_API_URL = "https://api.pushover.net/1/messages.json"

mcp = FastMCP("push")


def _get_credentials() -> tuple[str, str]:
    token = os.environ.get("PUSHOVER_TOKEN")
    user = os.environ.get("PUSHOVER_USER")
    if not token or not user:
        raise ValueError(
            "PUSHOVER_TOKEN and PUSHOVER_USER environment variables must be set"
        )
    return token, user


@mcp.tool(
    name="send_push",
    description=(
        "Send a push notification to your phone via Pushover. "
        "Supports title, message, priority, sound, URL, and HTML formatting."
    ),
)
async def send_push(
    message: str,
    title: str | None = None,
    priority: int = 0,
    sound: str | None = None,
    url: str | None = None,
    url_title: str | None = None,
    html: bool = False,
    device: str | None = None,
) -> str:
    """Send a push notification via Pushover.

    Args:
        message: The notification body text (required).
        title: Optional title for the notification.
        priority: -2 (lowest), -1 (low), 0 (normal), 1 (high), 2 (emergency).
                  Emergency requires retry/expire and will repeat until acknowledged.
        sound: Notification sound name (e.g. pushover, bike, bugle, cashregister,
               classical, cosmic, falling, gamelan, incoming, intermission, magic,
               mechanical, pianobar, siren, spacealarm, tugboat, alien, climb,
               persistent, echo, updown, vibrate, none).
        url: Supplementary URL to include with the message.
        url_title: Title for the supplementary URL.
        html: Enable HTML formatting in the message body.
        device: Target a specific device name instead of all devices.
    """
    token, user = _get_credentials()

    payload: dict[str, str | int] = {
        "token": token,
        "user": user,
        "message": message,
    }

    if title is not None:
        payload["title"] = title
    if priority != 0:
        payload["priority"] = priority
    if priority == 2:
        # Emergency priority requires retry and expire
        payload["retry"] = 60  # retry every 60 seconds
        payload["expire"] = 3600  # stop after 1 hour
    if sound is not None:
        payload["sound"] = sound
    if url is not None:
        payload["url"] = url
    if url_title is not None:
        payload["url_title"] = url_title
    if html:
        payload["html"] = 1
    if device is not None:
        payload["device"] = device

    async with httpx.AsyncClient() as client:
        resp = await client.post(PUSHOVER_API_URL, data=payload)

    body = resp.json()

    if resp.status_code == 200 and body.get("status") == 1:
        return f"Notification sent successfully (request id: {body.get('request')})"
    else:
        errors = body.get("errors", [])
        return f"Failed to send notification: {', '.join(errors)}"


def main():
    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
