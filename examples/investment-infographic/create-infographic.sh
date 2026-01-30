#!/bin/bash
# create-infographic.sh - Turn an investment process into visual infographics using nlm + Paper2Any
#
# This script demonstrates a two-stage pipeline:
#   1. nlm extracts structured content (timelines, mindmaps, briefing docs) from source material
#   2. Paper2Any renders the content into editable SVG diagrams and PPTX presentations
#
# Prerequisites:
#   - nlm installed and authenticated (run: nlm auth)
#   - Source content file: investment-process.md (included in this directory)
#   - Paper2Any (optional): https://github.com/OpenDCAI/Paper2Any
#     Set PAPER2ANY_DIR, DF_API_KEY, and DF_API_URL env vars to enable
#
# Usage:
#   ./create-infographic.sh
#   ./create-infographic.sh --with-paper2any
#   ./create-infographic.sh --output-dir ./my-output
#   ./create-infographic.sh --skip-audio

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/investment-process.md"
OUTPUT_DIR="${1:---output-dir}"
SKIP_AUDIO=false
WITH_PAPER2ANY=false
PAPER2ANY_DIR="${PAPER2ANY_DIR:-}"

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
        --with-paper2any)
            WITH_PAPER2ANY=true
            shift
            ;;
        --paper2any-dir)
            PAPER2ANY_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--output-dir DIR] [--skip-audio] [--with-paper2any] [--paper2any-dir DIR]"
            echo ""
            echo "Transform investment process documentation into visual infographics."
            echo ""
            echo "Options:"
            echo "  --output-dir DIR     Output directory (default: ./investment-infographic-output)"
            echo "  --skip-audio         Skip audio overview generation"
            echo "  --with-paper2any     Enable Paper2Any visual rendering (SVG + PPTX)"
            echo "  --paper2any-dir DIR  Path to Paper2Any repo (or set PAPER2ANY_DIR)"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "Paper2Any env vars:"
            echo "  PAPER2ANY_DIR  Path to Paper2Any repo"
            echo "  DF_API_KEY     LLM API key for Paper2Any"
            echo "  DF_API_URL     LLM API endpoint for Paper2Any"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Default output directory if still set to flag value
if [[ "$OUTPUT_DIR" == "--output-dir" || "$OUTPUT_DIR" == "--skip-audio" || "$OUTPUT_DIR" == "--with-paper2any" ]]; then
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

# Validate Paper2Any setup if requested
if [[ "$WITH_PAPER2ANY" == true ]]; then
    if [[ -z "$PAPER2ANY_DIR" ]]; then
        log_error "Paper2Any directory not set. Use --paper2any-dir or set PAPER2ANY_DIR."
        log_error "Install: git clone https://github.com/OpenDCAI/Paper2Any.git"
        exit 1
    fi
    if [[ ! -f "$PAPER2ANY_DIR/script/run_paper2figure_cli.py" ]]; then
        log_error "Paper2Any not found at: $PAPER2ANY_DIR"
        log_error "Install: git clone https://github.com/OpenDCAI/Paper2Any.git"
        exit 1
    fi
    if [[ -z "${DF_API_KEY:-}" ]]; then
        log_warn "DF_API_KEY not set. Paper2Any requires an LLM API key."
    fi
fi

# Calculate total steps
TOTAL_STEPS=7
if [[ "$SKIP_AUDIO" != true ]]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi
if [[ "$WITH_PAPER2ANY" == true ]]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 3))  # roadmap + architecture + slides
fi

echo "============================================"
echo " Investment Process Infographic Generator"
echo " Powered by nlm + Paper2Any"
echo "============================================"
echo ""
echo "Stage 1: nlm (content extraction)"
if [[ "$WITH_PAPER2ANY" == true ]]; then
    echo "Stage 2: Paper2Any (visual rendering)"
fi
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

# --- Paper2Any visual rendering (optional) ---
CURRENT_STEP=8
if [[ "$SKIP_AUDIO" == true ]]; then
    CURRENT_STEP=7
fi

if [[ "$WITH_PAPER2ANY" == true ]]; then
    VISUALS_DIR="$OUTPUT_DIR/visuals"
    mkdir -p "$VISUALS_DIR"

    # --- Generate process roadmap (tech_route) from timeline ---
    log_step "$CURRENT_STEP" "[Paper2Any] Generating process roadmap from timeline..."
    CURRENT_STEP=$((CURRENT_STEP + 1))
    if [[ -s "$OUTPUT_DIR/02-timeline.md" ]]; then
        if python "$PAPER2ANY_DIR/script/run_paper2figure_cli.py" \
            --input "$OUTPUT_DIR/02-timeline.md" \
            --graph-type tech_route \
            --style cartoon \
            --aspect-ratio 16:9 \
            --language en \
            --output-dir "$VISUALS_DIR/roadmap" 2>/dev/null; then
            log_success "Process roadmap generated in $VISUALS_DIR/roadmap/"
        else
            log_warn "Roadmap generation failed (check DF_API_KEY and DF_API_URL)"
        fi
    else
        log_warn "Skipping roadmap: timeline output is empty"
    fi

    # --- Generate architecture diagram (model_arch) from overview ---
    log_step "$CURRENT_STEP" "[Paper2Any] Generating architecture diagram from overview..."
    CURRENT_STEP=$((CURRENT_STEP + 1))
    if [[ -s "$OUTPUT_DIR/01-overview-guide.md" ]]; then
        if python "$PAPER2ANY_DIR/script/run_paper2figure_cli.py" \
            --input "$OUTPUT_DIR/01-overview-guide.md" \
            --graph-type model_arch \
            --style cartoon \
            --language en \
            --output-dir "$VISUALS_DIR/architecture" 2>/dev/null; then
            log_success "Architecture diagram generated in $VISUALS_DIR/architecture/"
        else
            log_warn "Architecture diagram generation failed"
        fi
    else
        log_warn "Skipping architecture diagram: overview output is empty"
    fi

    # --- Generate slide deck (paper2ppt) from briefing doc ---
    log_step "$CURRENT_STEP" "[Paper2Any] Generating slide deck from briefing document..."
    CURRENT_STEP=$((CURRENT_STEP + 1))
    if [[ -s "$OUTPUT_DIR/04-briefing-doc.md" ]]; then
        if python "$PAPER2ANY_DIR/script/run_paper2ppt_cli.py" \
            --input "$OUTPUT_DIR/04-briefing-doc.md" \
            --page-count 10 \
            --style "Modern financial style with clean charts" \
            --language en \
            --output-dir "$VISUALS_DIR/slides" 2>/dev/null; then
            log_success "Slide deck generated in $VISUALS_DIR/slides/"
        else
            log_warn "Slide deck generation failed"
        fi
    else
        log_warn "Skipping slide deck: briefing document output is empty"
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

## Paper2Any Visual Outputs

If generated with \`--with-paper2any\`, the \`visuals/\` directory contains:

| Directory | Contents | Format |
|-----------|----------|--------|
| \`visuals/roadmap/\` | Investment process roadmap | SVG + PPTX |
| \`visuals/architecture/\` | Process architecture diagram | SVG + PPTX |
| \`visuals/slides/\` | Executive briefing slide deck | PPTX |

Paper2Any: https://github.com/OpenDCAI/Paper2Any

## Next Steps

1. Review generated content in this directory
2. Open PPTX files to edit diagrams and slides directly
3. Use SVG files for web or print-ready infographics
4. For deeper analysis, use interactive chat:
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
if [[ "$WITH_PAPER2ANY" == true && -d "$OUTPUT_DIR/visuals" ]]; then
    echo ""
    echo "Paper2Any visuals:"
    find "$OUTPUT_DIR/visuals" -type f \( -name "*.svg" -o -name "*.pptx" -o -name "*.png" \) 2>/dev/null | while read -r f; do
        echo "  $f"
    done
fi
echo ""
echo "Next steps:"
echo "  1. Review the generated content in $OUTPUT_DIR/"
if [[ "$WITH_PAPER2ANY" == true ]]; then
    echo "  2. Open PPTX/SVG files in $OUTPUT_DIR/visuals/ to edit visuals"
else
    echo "  2. Run with --with-paper2any to generate SVG/PPTX visuals"
fi
echo "  3. Use 'nlm chat $NOTEBOOK_ID' for interactive exploration"
echo ""
echo "To clean up: nlm rm $NOTEBOOK_ID"
