#!/bin/bash
# Sync Paw, Lark and GBrain skills to OpenCode

echo "=== OpenCode Skills Sync ==="

OPENCLAW_DIR="$HOME/.openclaw/skills"
GBRAIN_DIR="$HOME/gbrain"
TARGET_DIR="$HOME/文档/道家知识库01/.agents/skills"

mkdir -p "$TARGET_DIR"

# Sync all OpenCLAW skills (Paw, Lark, etc.)
echo "Syncing OpenCLAW skills..."
for dir in "$OPENCLAW_DIR"/*/; do
    name=$(basename "$dir")
    if [[ "$name" == CHANGELOG* ]] || [[ "$name" == *.md ]] || [[ "$name" == *.zip ]] || [[ "$name" == *.tar.gz ]]; then
        continue
    fi
    if [ ! -e "$TARGET_DIR/$name" ]; then
        ln -s "$dir" "$TARGET_DIR/$name"
        echo "  + $name"
    fi
done

# Sync GBrain skills
echo "Syncing GBrain skills..."
find "$GBRAIN_DIR/skills" -maxdepth 1 -type d ! -name "skills" | while read -r dir; do
    name=$(basename "$dir")
    if [ ! -e "$TARGET_DIR/gbrain-$name" ]; then
        ln -s "$dir" "$TARGET_DIR/gbrain-$name"
        echo "  + gbrain-$name"
    fi
done

echo ""
echo "Sync complete. Total skills: $(ls -1d $TARGET_DIR/*/ 2>/dev/null | wc -l)"
echo "Skills location: $TARGET_DIR"