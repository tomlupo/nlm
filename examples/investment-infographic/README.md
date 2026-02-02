# Investment Process Infographic Example

This example demonstrates how to use `nlm` (NotebookLM CLI) and [Paper2Any](https://github.com/OpenDCAI/Paper2Any) to transform a simple investment process document into visual infographics.

The pipeline has two stages:

1. **nlm** extracts structured content (timelines, mindmaps, briefing docs) from the source document via NotebookLM
2. **Paper2Any** renders that content into editable visual outputs (SVG diagrams, PPTX presentations)

## What It Does

Takes a markdown document describing the 6-phase investment process and produces:

| Output | Tool | Command | Format |
|--------|------|---------|--------|
| Study Guide | nlm | `generate-guide` | Markdown |
| Timeline | nlm | `timeline` | Markdown |
| Mindmap | nlm | `mindmap` | Markdown |
| Briefing Doc | nlm | `briefing-doc` | Markdown |
| FAQ | nlm | `faq` | Markdown |
| Outline | nlm | `outline` | Markdown |
| Audio Overview | nlm | `audio-create` | Audio |
| Process Roadmap | Paper2Any | `paper2figure --graph-type tech_route` | SVG + PPTX |
| Architecture Diagram | Paper2Any | `paper2figure --graph-type model_arch` | SVG + PPTX |
| Slide Deck | Paper2Any | `paper2ppt` | PPTX |

## The Investment Process

The source document covers a 6-phase investment workflow:

```
Define Goals --> Research --> Allocate --> Execute --> Monitor --> Rebalance
     ^                                                              |
     |______________________________________________________________|
```

1. **Define Goals** - Set time horizon, risk tolerance, return targets
2. **Research** - Market analysis, asset class evaluation, security selection
3. **Asset Allocation** - Strategic and tactical portfolio design
4. **Execution** - Order strategy, account structure, trade implementation
5. **Monitoring** - Performance tracking, review schedule, alert triggers
6. **Rebalancing** - Calendar/threshold-based rebalancing, tax efficiency

## Prerequisites

- **nlm** installed and authenticated (`nlm auth`)
- **Paper2Any** (optional, for visual rendering):
  ```bash
  git clone https://github.com/OpenDCAI/Paper2Any.git
  cd Paper2Any
  conda create -n paper2any python=3.11
  conda activate paper2any
  pip install -r requirements-base.txt
  pip install -r requirements-paper.txt
  conda install -c conda-forge tectonic
  ```
- An LLM API key for Paper2Any (set `DF_API_KEY` and `DF_API_URL` env vars)

## Quick Start

```bash
# Authenticate with NotebookLM (one-time setup)
nlm auth

# Run with nlm only (generates structured markdown)
./create-infographic.sh

# Run the full pipeline including Paper2Any visual rendering
./create-infographic.sh --with-paper2any

# Or use Python
python create-infographic.py --with-paper2any
```

## Usage

### Shell Script

```bash
# Default output to ./investment-infographic-output/
./create-infographic.sh

# Custom output directory
./create-infographic.sh --output-dir ./my-output

# Skip audio generation
./create-infographic.sh --skip-audio
```

### Python Script

```bash
# Default settings
python create-infographic.py

# Custom output directory
python create-infographic.py --output-dir ./my-output

# Skip audio generation
python create-infographic.py --skip-audio
```

### Step-by-Step (Manual)

Run each command individually to understand the process:

```bash
# --- Stage 1: nlm content extraction ---

# 1. Create a notebook
NOTEBOOK_ID=$(nlm create "Investment Process Infographic")

# 2. Add the investment process document
SOURCE_ID=$(nlm add "$NOTEBOOK_ID" investment-process.md)

# 3. Wait for processing
sleep 5

# 4. Generate infographic content
nlm generate-guide "$NOTEBOOK_ID" > overview.md
nlm timeline "$NOTEBOOK_ID" "$SOURCE_ID" > timeline.md
nlm mindmap "$NOTEBOOK_ID" "$SOURCE_ID" > mindmap.md
nlm briefing-doc "$NOTEBOOK_ID" "$SOURCE_ID" > briefing.md
nlm faq "$NOTEBOOK_ID" "$SOURCE_ID" > faq.md
nlm outline "$NOTEBOOK_ID" "$SOURCE_ID" > outline.md

# 5. Create audio overview
nlm audio-create "$NOTEBOOK_ID" "Walk through the investment process phases"

# --- Stage 2: Paper2Any visual rendering ---

PAPER2ANY_DIR="/path/to/Paper2Any"

# 6. Generate process roadmap (SVG + PPTX)
python "$PAPER2ANY_DIR/script/run_paper2figure_cli.py" \
  --input timeline.md \
  --graph-type tech_route \
  --style cartoon \
  --aspect-ratio 16:9 \
  --language en \
  --output-dir ./visuals

# 7. Generate architecture diagram (SVG + PPTX)
python "$PAPER2ANY_DIR/script/run_paper2figure_cli.py" \
  --input overview.md \
  --graph-type model_arch \
  --style cartoon \
  --language en \
  --output-dir ./visuals

# 8. Generate slide deck from briefing doc (PPTX)
python "$PAPER2ANY_DIR/script/run_paper2ppt_cli.py" \
  --input briefing.md \
  --page-count 10 \
  --style "Modern financial style with clean charts" \
  --language en \
  --output-dir ./visuals

# --- Explore and clean up ---

# 9. Explore interactively
nlm chat "$NOTEBOOK_ID"

# 10. Clean up when done
nlm rm "$NOTEBOOK_ID"
```

## Output Structure

```
investment-infographic-output/
  00-index.md            # Summary and design suggestions
  01-overview-guide.md   # Structured study guide
  02-timeline.md         # Process timeline
  03-mindmap.md          # Interactive mindmap
  04-briefing-doc.md     # Executive briefing
  05-faq.md              # FAQ (Python script only)
  06-outline.md          # Content outline (Python script only)
  notebook-id.txt        # Notebook ID for further interaction
  source-id.txt          # Source ID for targeted commands
  visuals/               # Paper2Any outputs (with --with-paper2any)
    roadmap.pptx         # Process roadmap (editable PPTX)
    roadmap.svg          # Process roadmap (vector)
    architecture.pptx    # Investment architecture diagram (editable PPTX)
    architecture.svg     # Investment architecture diagram (vector)
    slides.pptx          # Full slide deck from briefing doc
```

## Turning Output into Visual Infographics

### With Paper2Any (automated)

Pass `--with-paper2any` to either script to automatically render visuals:

```bash
# Set Paper2Any location and API key
export PAPER2ANY_DIR=/path/to/Paper2Any
export DF_API_KEY=your-api-key
export DF_API_URL=https://api.openai.com/v1  # or compatible endpoint

./create-infographic.sh --with-paper2any
```

Paper2Any produces:

| nlm Output | Paper2Any Mode | Result |
|------------|----------------|--------|
| Timeline markdown | `paper2figure --graph-type tech_route` | SVG + PPTX process roadmap |
| Overview guide | `paper2figure --graph-type model_arch` | SVG + PPTX architecture diagram |
| Briefing doc | `paper2ppt` | Editable PPTX slide deck |

### Without Paper2Any (manual design)

The structured text outputs can also be used with other visual design tools:

- **Timeline** output maps to horizontal flow diagrams (Figma, Canva, Mermaid)
- **Mindmap** output maps to radial or tree diagrams
- **Briefing doc** provides content for single-page dashboards
- **FAQ** provides content for callout boxes and sidebars
- **Outline** provides the hierarchy for nested layouts

## Pipeline Diagram

```
                        nlm                              Paper2Any
                   (content extraction)              (visual rendering)

                 +------------------+
investment   --> | create notebook  |
-process.md     | add source       |
                 +------------------+
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
    +-----------+  +-----------+  +-----------+
    | timeline  |  | mindmap   |  | briefing  |     ... other nlm outputs
    +-----------+  +-----------+  +-----------+
          |              |              |
          v              v              v
    +-----------+  +-----------+  +-----------+
    | tech_route|  | model_arch|  | paper2ppt |     Paper2Any renderers
    +-----------+  +-----------+  +-----------+
          |              |              |
          v              v              v
     roadmap.svg   architecture.svg  slides.pptx    Final visual outputs
     roadmap.pptx  architecture.pptx
```

## Files

| File | Description |
|------|-------------|
| `investment-process.md` | Source document describing the investment process |
| `create-infographic.sh` | Shell script for automated generation |
| `create-infographic.py` | Python script with additional outputs |
| `README.md` | This file |
