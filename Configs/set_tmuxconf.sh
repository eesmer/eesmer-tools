#!/bin/bash

# ---------------------------------------------------------------------------------
# - TMUX Customization -
# Root permissions are required for package installations.
# When using the root user, be careful about the target user account.
# Usage: bash set_tmuxconf.sh TARGET_USER
# ---------------------------------------------------------------------------------

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 TARGET_USER" >&2
    exit 1
fi

TARGET_USER="$1"

if ! getent passwd "$TARGET_USER" >/dev/null 2>&1; then
    echo "Hata: '$TARGET_USER' User Not Found!" >&2
    exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [[ ! -d "$TARGET_HOME" ]]; then
    echo "Error: $TARGET_USER home Directory Not Found!: $TARGET_HOME" >&2
    exit 1
fi

TMUX_CONF_PATH="$TARGET_HOME/.tmux.conf"

if ! command -v tmux >/dev/null 2>&1; then
    apt-get -y install tmux
fi

if [[ -f "$TMUX_CONF_PATH" ]]; then
    TS="$(date +%Y%m%d-%H%M%S)"
    BACKUP_NAME="${TMUX_CONF_PATH}.old-${TS}"
    cp "$TMUX_CONF_PATH" "$BACKUP_NAME"
fi

cat > "$TMUX_CONF_PATH" <<'EOF'
set -g default-terminal "screen-256color"
set -g history-limit 100000

set -g visual-activity on
set -g visual-bell on
set -g visual-silence on
setw -g monitor-activity on
set -g bell-action none

set -g mouse on
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel
bind -T copy-mode-vi Escape send -X cancel

#  modes
setw -g clock-mode-colour colour5
setw -g mode-style 'fg=colour1 bg=colour18'

unbind -T root MouseDown3Pane

bind-key -T root MouseDown3Pane \
  select-pane -t= \; \
  display-menu -T "#[align=centre]Pane #{pane_index}" \
	"Copy line"        y  "copy-mode -t= \; send-keys -X select-line \; send-keys -X copy-selection-and-cancel" \
	"Copy mode"        c  "copy-mode -t=" \
	"Paste"            p  "paste-buffer -t=" \
	""                 ""  "" \
	"Horizontal split" h  "split-window -h -c '#{pane_current_path}'" \
	"Vertical split"   v  "split-window -v -c '#{pane_current_path}'" \
	"Zoom pane"        z  "resize-pane -Z" \
	"New window here"  n  "new-window -c '#{pane_current_path}'" \
	""                 ""  "" \
	"Toggle sync panes" s "set-window-option synchronize-panes \; display-message 'sync: #{?synchronize-panes,on,off}'" \
	""                 ""  "" \
	"Kill pane"        x  "kill-pane -t="
EOF

