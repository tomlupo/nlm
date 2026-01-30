#!/bin/bash
# create-infographic.sh - Turn an investment process into infographic-style content using nlm
#
# This script demonstrates how to use nlm to transform investment process
# documentation into structured, infographic-ready outputs including
# timelines, mindmaps, briefing documents, and audio overviews.
#
# Prerequisites:
#   - nlm installed and authenticated (run: nlm auth)
#   - Source content file: investment-process.md (included in this directory)
#
# Usage:
#   ./create-infographic.sh
#   ./create-infographic.sh --output-dir ./my-output
#   ./create-infographic.sh --skip-audio

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/investment-process.md"
OUTPUT_DIR="${1:---output-dir}"
SKIP_AUDIO=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --skip-audio)
            SKIP_AUDIO=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--output-dir DIR] [--skip-audio]"
            echo ""
            echo "Transform investment process documentation into infographic-style content."
            echo ""
            echo "Options:"
            echo "  --output-dir DIR   Output directory (default: ./investment-infographic-output)"
            echo "  --skip-audio       Skip audio overview generation"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Default output directory if still set to flag value
if [[ "$OUTPUT_DIR" == "--output-dir" || "$OUTPUT_DIR" == "--skip-audio" ]]; then
    OUTPUT_DIR="./investment-infographic-output"
fi

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_step() {
    echo -e "${BLUE}[Step $1/$TOTAL_STEPS]${NC} $2"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verify prerequisites
if ! command -v nlm &> /dev/null; then
    log_error "nlm is not installed. Install with: go install github.com/tmc/nlm/cmd/nlm@latest"
    exit 1
fi

if [[ ! -f "$SOURCE_FILE" ]]; then
    log_error "Source file not found: $SOURCE_FILE"
    exit 1
fi

# Calculate total steps
TOTAL_STEPS=8
if [[ "$SKIP_AUDIO" == true ]]; then
    TOTAL_STEPS=7
fi

echo "============================================"
echo " Investment Process Infographic Generator"
echo " Powered by nlm (NotebookLM CLI)"
echo "============================================"
echo ""

# --- Step 1: Create output directory ---
log_step 1 "Creating output directory: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
log_success "Output directory ready"

# --- Step 2: Create notebook ---
log_step 2 "Creating NotebookLM notebook..."
NOTEBOOK_ID=$(nlm create "Investment Process Infographic" 2>/dev/null)
if [[ -z "$NOTEBOOK_ID" ]]; then
    log_error "Failed to create notebook"
    exit 1
fi
log_success "Notebook created: $NOTEBOOK_ID"
echo "$NOTEBOOK_ID" > "$OUTPUT_DIR/notebook-id.txt"

# --- Step 3: Add source content ---
log_step 3 "Adding investment process documentation as source..."
SOURCE_ID=$(nlm add "$NOTEBOOK_ID" "$SOURCE_FILE" 2>/dev/null)
if [[ -z "$SOURCE_ID" ]]; then
    log_error "Failed to add source"
    exit 1
fi
log_success "Source added: $SOURCE_ID"
echo "$SOURCE_ID" > "$OUTPUT_DIR/source-id.txt"

# Allow processing time
echo "  Waiting for source processing..."
sleep 5

# --- Step 4: Generate study guide (structured overview) ---
log_step 4 "Generating structured overview (study guide)..."
if nlm generate-guide "$NOTEBOOK_ID" > "$OUTPUT_DIR/01-overview-guide.md" 2>/dev/null; then
    log_success "Overview guide saved: $OUTPUT_DIR/01-overview-guide.md"
else
    log_warn "Guide generation failed, continuing..."
fi

# --- Step 5: Generate timeline (investment phases over time) ---
log_step 5 "Generating investment process timeline..."
if nlm timeline "$NOTEBOOK_ID" "$SOURCE_ID" > "$OUTPUT_DIR/02-timeline.md" 2>/dev/null; then
    log_success "Timeline saved: $OUTPUT_DIR/02-timeline.md"
else
    log_warn "Timeline generation failed, continuing..."
fi

# --- Step 6: Generate mindmap (visual process map) ---
log_step 6 "Generating investment process mindmap..."
if nlm mindmap "$NOTEBOOK_ID" "$SOURCE_ID" > "$OUTPUT_DIR/03-mindmap.md" 2>/dev/null; then
    log_success "Mindmap saved: $OUTPUT_DIR/03-mindmap.md"
else
    log_warn "Mindmap generation failed, continuing..."
fi

# --- Step 7: Generate briefing document (executive summary) ---
log_step 7 "Generating executive briefing document..."
if nlm briefing-doc "$NOTEBOOK_ID" "$SOURCE_ID" > "$OUTPUT_DIR/04-briefing-doc.md" 2>/dev/null; then
    log_success "Briefing document saved: $OUTPUT_DIR/04-briefing-doc.md"
else
    log_warn "Briefing document generation failed, continuing..."
fi

# --- Step 8: Generate audio overview (optional) ---
if [[ "$SKIP_AUDIO" != true ]]; then
    log_step 8 "Creating audio overview of investment process..."
    if nlm audio-create "$NOTEBOOK_ID" \
        "Create an engaging overview of the investment process. Walk through each phase from goal-setting to rebalancing. Use a professional but approachable tone suitable for new investors." \
        2>/dev/null; then
        log_success "Audio overview creation started"
        echo "  Use 'nlm audio-get $NOTEBOOK_ID' to check status and download."
    else
        log_warn "Audio creation failed (may require additional setup)"
    fi
fi

# --- Generate summary report ---
cat > "$OUTPUT_DIR/00-index.md" << EOF
# Investment Process Infographic - Generated Content

Generated: $(date '+%Y-%m-%d %H:%M:%S')
Notebook ID: $NOTEBOOK_ID
Source: investment-process.md

## Generated Files

| File | Description | Use Case |
|------|-------------|----------|
| [01-overview-guide.md](01-overview-guide.md) | Structured study guide | Main infographic content backbone |
| [02-timeline.md](02-timeline.md) | Process timeline | Timeline/Gantt chart infographic |
| [03-mindmap.md](03-mindmap.md) | Interactive mindmap | Visual process map / flowchart |
| [04-briefing-doc.md](04-briefing-doc.md) | Executive briefing | One-page summary infographic |

## Infographic Design Suggestions

### Timeline Infographic
Use the timeline output to create a horizontal flow showing:
\`\`\`
Week 1          Weeks 2-3       Week 4          Week 5          Ongoing
  |                |               |               |               |
  v                v               v               v               v
[Goals] -----> [Research] ----> [Allocate] ----> [Execute] ----> [Monitor & Rebalance]
\`\`\`

### Process Mindmap Infographic
Use the mindmap output to create a radial diagram with:
- Center: "Investment Process"
- Inner ring: 6 phases (Goals, Research, Allocate, Execute, Monitor, Rebalance)
- Outer ring: Key activities within each phase

### Executive Dashboard Infographic
Use the briefing document to create a single-page dashboard showing:
- Process overview (flow diagram)
- Key metrics table (returns, risk, drawdown)
- Portfolio allocation pie charts (Conservative / Balanced / Growth)
- Rebalancing triggers checklist

## Next Steps

1. Review generated content in this directory
2. Use your preferred design tool (Figma, Canva, PowerPoint) to create visuals
3. For deeper analysis, use interactive chat:
   \`\`\`bash
   nlm chat $NOTEBOOK_ID
   \`\`\`
4. To explore specific topics, try:
   \`\`\`bash
   nlm generate-chat $NOTEBOOK_ID "What are the key risk metrics for each portfolio type?"
   nlm faq $NOTEBOOK_ID $SOURCE_ID
   nlm summarize $NOTEBOOK_ID $SOURCE_ID
   \`\`\`
EOF

log_success "Index file saved: $OUTPUT_DIR/00-index.md"

echo ""
echo "============================================"
echo " Generation Complete!"
echo "============================================"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo "Notebook ID:      $NOTEBOOK_ID"
echo ""
echo "Generated files:"
ls -la "$OUTPUT_DIR"/*.md 2>/dev/null | awk '{print "  " $NF}'
echo ""
echo "Next steps:"
echo "  1. Review the generated content in $OUTPUT_DIR/"
echo "  2. Use 'nlm chat $NOTEBOOK_ID' for interactive exploration"
echo "  3. Design your infographic using the structured outputs"
echo ""
echo "To clean up: nlm rm $NOTEBOOK_ID"
