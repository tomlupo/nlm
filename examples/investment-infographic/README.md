# Investment Process Infographic Example

This example demonstrates how to use `nlm` (NotebookLM CLI) to transform a simple investment process document into structured, infographic-ready content.

## What It Does

Takes a markdown document describing the 6-phase investment process and uses nlm to generate:

| Output | nlm Command | Infographic Use |
|--------|-------------|-----------------|
| Study Guide | `generate-guide` | Content backbone and key points |
| Timeline | `timeline` | Horizontal timeline / Gantt chart |
| Mindmap | `mindmap` | Radial process diagram |
| Briefing Doc | `briefing-doc` | One-page executive dashboard |
| FAQ | `faq` | Sidebar callout boxes |
| Outline | `outline` | Hierarchical structure diagram |
| Audio Overview | `audio-create` | Narrated walkthrough |

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

## Quick Start

```bash
# Authenticate with NotebookLM (one-time setup)
nlm auth

# Run the shell script
chmod +x create-infographic.sh
./create-infographic.sh

# Or use Python
python create-infographic.py
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

Run each nlm command individually to understand the process:

```bash
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

# 6. Explore interactively
nlm chat "$NOTEBOOK_ID"

# 7. Clean up when done
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
```

## Turning Output into Visual Infographics

The generated content is structured text designed to feed into visual design tools:

- **Timeline** output maps to horizontal flow diagrams (Figma, Canva, Mermaid)
- **Mindmap** output maps to radial or tree diagrams
- **Briefing doc** provides content for single-page dashboards
- **FAQ** provides content for callout boxes and sidebars
- **Outline** provides the hierarchy for nested layouts

## Files

| File | Description |
|------|-------------|
| `investment-process.md` | Source document describing the investment process |
| `create-infographic.sh` | Shell script for automated generation |
| `create-infographic.py` | Python script with additional outputs |
| `README.md` | This file |
