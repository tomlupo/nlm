#!/usr/bin/env python3
"""
create-infographic.py - Generate investment infographic content using nlm

Transforms investment process documentation into structured outputs
suitable for infographic design: timelines, mindmaps, briefing docs,
and audio overviews.

Prerequisites:
    - nlm installed and authenticated (run: nlm auth)
    - Python 3.7+

Usage:
    python create-infographic.py
    python create-infographic.py --output-dir ./my-output
    python create-infographic.py --skip-audio
"""

import argparse
import os
import subprocess
import sys
import time
from pathlib import Path


class InfographicGenerator:
    """Generate infographic-style content from investment process docs using nlm."""

    # Content generation steps: (filename, nlm_command, description, needs_source_id)
    GENERATION_STEPS = [
        ("01-overview-guide.md", "generate-guide", "Structured overview guide", False),
        ("02-timeline.md", "timeline", "Investment process timeline", True),
        ("03-mindmap.md", "mindmap", "Interactive process mindmap", True),
        ("04-briefing-doc.md", "briefing-doc", "Executive briefing document", True),
        ("05-faq.md", "faq", "Frequently asked questions", True),
        ("06-outline.md", "outline", "Detailed content outline", True),
    ]

    def __init__(self, output_dir: str = "./investment-infographic-output",
                 skip_audio: bool = False):
        self.output_dir = Path(output_dir)
        self.skip_audio = skip_audio
        self.script_dir = Path(__file__).parent
        self.source_file = self.script_dir / "investment-process.md"
        self.notebook_id = None
        self.source_id = None

    def run(self):
        """Execute the full infographic generation pipeline."""
        self._check_prerequisites()
        self._setup_output_dir()

        try:
            self._create_notebook()
            self._add_source()
            self._wait_for_processing()
            self._generate_all_content()
            if not self.skip_audio:
                self._create_audio()
            self._write_index()
            self._print_summary()
        except Exception as e:
            print(f"\nError: {e}", file=sys.stderr)
            if self.notebook_id:
                print(f"Notebook ID for cleanup: {self.notebook_id}", file=sys.stderr)
            sys.exit(1)

    def _check_prerequisites(self):
        """Verify nlm is installed and source file exists."""
        try:
            subprocess.run(["nlm", "help"], capture_output=True, check=False)
        except FileNotFoundError:
            print("Error: nlm is not installed.", file=sys.stderr)
            print("Install with: go install github.com/tmc/nlm/cmd/nlm@latest",
                  file=sys.stderr)
            sys.exit(1)

        if not self.source_file.exists():
            print(f"Error: Source file not found: {self.source_file}", file=sys.stderr)
            sys.exit(1)

    def _setup_output_dir(self):
        """Create output directory."""
        self.output_dir.mkdir(parents=True, exist_ok=True)
        print(f"Output directory: {self.output_dir}")

    def _nlm(self, *args: str) -> str:
        """Execute an nlm command and return stdout."""
        cmd = ["nlm"] + list(args)
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(
                f"nlm {' '.join(args)} failed: {result.stderr.strip()}"
            )
        return result.stdout.strip()

    def _create_notebook(self):
        """Create a new NotebookLM notebook."""
        print("\n[1/8] Creating notebook...")
        self.notebook_id = self._nlm("create", "Investment Process Infographic")
        print(f"  Notebook ID: {self.notebook_id}")

        # Save for reference
        (self.output_dir / "notebook-id.txt").write_text(self.notebook_id)

    def _add_source(self):
        """Add the investment process document as a source."""
        print("[2/8] Adding investment process source...")
        self.source_id = self._nlm("add", self.notebook_id, str(self.source_file))
        print(f"  Source ID: {self.source_id}")

        # Save for reference
        (self.output_dir / "source-id.txt").write_text(self.source_id)

    def _wait_for_processing(self):
        """Wait for the source to be processed."""
        print("[3/8] Waiting for source processing...")
        time.sleep(5)
        print("  Processing complete.")

    def _generate_all_content(self):
        """Generate all infographic content types."""
        total = len(self.GENERATION_STEPS)

        for i, (filename, command, description, needs_source) in enumerate(
            self.GENERATION_STEPS, start=1
        ):
            step_num = i + 3  # Offset by setup steps
            print(f"[{step_num}/8] Generating {description}...")

            try:
                if needs_source:
                    output = self._nlm(command, self.notebook_id, self.source_id)
                else:
                    output = self._nlm(command, self.notebook_id)

                output_path = self.output_dir / filename
                output_path.write_text(output)
                print(f"  Saved: {output_path}")

            except RuntimeError as e:
                print(f"  Warning: {description} generation failed: {e}",
                      file=sys.stderr)

    def _create_audio(self):
        """Create an audio overview of the investment process."""
        print("[8/8] Creating audio overview...")
        try:
            self._nlm(
                "audio-create",
                self.notebook_id,
                "Create an engaging overview of the investment process. "
                "Walk through each phase from goal-setting to rebalancing. "
                "Use a professional but approachable tone suitable for new investors."
            )
            print("  Audio overview creation started.")
            print(f"  Check status: nlm audio-get {self.notebook_id}")
        except RuntimeError as e:
            print(f"  Warning: Audio creation failed: {e}", file=sys.stderr)

    def _write_index(self):
        """Write the index/summary file."""
        from datetime import datetime

        index_content = f"""# Investment Process Infographic - Generated Content

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Notebook ID: {self.notebook_id}
Source: investment-process.md

## Generated Files

| File | Description | Infographic Use |
|------|-------------|-----------------|
| [01-overview-guide.md](01-overview-guide.md) | Study guide | Content backbone |
| [02-timeline.md](02-timeline.md) | Process timeline | Timeline / Gantt chart |
| [03-mindmap.md](03-mindmap.md) | Mindmap | Radial process diagram |
| [04-briefing-doc.md](04-briefing-doc.md) | Executive briefing | One-page dashboard |
| [05-faq.md](05-faq.md) | FAQ | Sidebar / callout boxes |
| [06-outline.md](06-outline.md) | Content outline | Hierarchical structure |

## Infographic Design Guide

### Timeline Layout
```
Week 1        Weeks 2-3     Week 4        Week 5        Ongoing
  |              |             |             |             |
  v              v             v             v             v
[Goals] --> [Research] --> [Allocate] --> [Execute] --> [Monitor]
                                                          |
                                                    [Rebalance]
```

### Radial Mindmap Layout
- Center: "Investment Process"
- Ring 1: Six phases (Goals, Research, Allocate, Execute, Monitor, Rebalance)
- Ring 2: Key activities per phase
- Ring 3: Metrics and deliverables

### Dashboard Layout
Use the briefing document to build a single-page layout:
- Top: Process flow diagram
- Middle: Key metrics table (by portfolio type)
- Bottom: Allocation charts and rebalancing triggers

## Interactive Exploration

```bash
# Chat interactively about the investment process
nlm chat {self.notebook_id}

# Ask specific questions
nlm generate-chat {self.notebook_id} "Compare risk profiles across portfolio types"

# Generate additional content
nlm summarize {self.notebook_id} {self.source_id}
nlm explain {self.notebook_id} {self.source_id}
```

## Cleanup

```bash
nlm rm {self.notebook_id}
```
"""
        index_path = self.output_dir / "00-index.md"
        index_path.write_text(index_content)
        print(f"\nIndex saved: {index_path}")

    def _print_summary(self):
        """Print final summary."""
        files = sorted(self.output_dir.glob("*.md"))

        print("\n" + "=" * 50)
        print("  Investment Infographic Generation Complete!")
        print("=" * 50)
        print(f"\nOutput: {self.output_dir}")
        print(f"Notebook: {self.notebook_id}")
        print(f"\nGenerated {len(files)} files:")
        for f in files:
            size = f.stat().st_size
            print(f"  {f.name} ({size:,} bytes)")
        print(f"\nNext steps:")
        print(f"  1. Review content in {self.output_dir}/")
        print(f"  2. nlm chat {self.notebook_id}  (interactive exploration)")
        print(f"  3. Design infographic with your preferred tool")
        print(f"\nCleanup: nlm rm {self.notebook_id}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate investment infographic content using nlm"
    )
    parser.add_argument(
        "--output-dir",
        default="./investment-infographic-output",
        help="Output directory (default: ./investment-infographic-output)",
    )
    parser.add_argument(
        "--skip-audio",
        action="store_true",
        help="Skip audio overview generation",
    )
    args = parser.parse_args()

    generator = InfographicGenerator(
        output_dir=args.output_dir,
        skip_audio=args.skip_audio,
    )
    generator.run()


if __name__ == "__main__":
    main()
