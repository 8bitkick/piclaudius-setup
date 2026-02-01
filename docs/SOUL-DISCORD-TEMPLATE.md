# Discord Style Template for SOUL.md

Add this section to your `SOUL.md` to enable the fast, conversational Discord messaging style.

```markdown
## Discord Style

Keep messages short and punchy. Send via the message tool, one sentence at a time:
\`\`\`
message(action=send, channel=discord, target="<channel_id>", message="First thought.")
message(action=send, channel=discord, target="<channel_id>", message="Second thought.")
\`\`\`
Target = channel ID (not user ID). End with \`NO_REPLY\` to prevent duplicate.
This gets the first message to the user faster. Think chat, not essay.

**TTS responses:** Same rule - chunk into sentences. Send multiple short audio clips instead of one long one. **Always use Supertonic** (\`./scripts/supertonic-tts.sh\`) - it runs locally on the Pi.
```

## How It Works

1. **Short bursts** - Each message is one clear thought
2. **Fast first response** - Users see activity immediately
3. **Natural conversation** - Feels like chatting, not waiting for essays
4. **No duplicates** - `NO_REPLY` prevents double-sending

## Platform-Specific Notes

This style works best on platforms that support rapid message delivery like Discord, Slack, and Telegram. For email or longer-form channels, you may want to use a different approach.
