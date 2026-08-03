# Telegram alerts — parent

## >>> YOU create these once

1. Telegram → **@BotFather** → `/newbot` → save **bot token**
2. Message your bot once; get your **chat_id** (e.g. @userinfobot or Netdata docs)
3. On um690:

```bash
mkdir -p ~/.config/valley-tech
cat > ~/.config/valley-tech/telegram.env <<'EOF'
TELEGRAM_BOT_TOKEN=8759095374:AAGzuoA1C_KHiaCyxgn_i_KISDSYtDHCxLA
TELEGRAM_CHAT_ID=valleyTech_support_bot
EOF
chmod 600 ~/.config/valley-tech/telegram.env
```

4. Re-run parent install so notify config is mounted:

```bash
bash ~/Documents/valley-tech-support/packages/network-install/parent/install-parent.sh
```

5. Test: stop a child or use Netdata test notification if available.

**Do not put telegram.env on the USB stick.**
