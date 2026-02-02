#!/usr/bin/env python3
"""
create-infographic.py - Generate investment infographics using nlm + Paper2Any

Two-stage pipeline:
  1. nlm extracts structured content (timelines, mindmaps, briefing docs)
  2. Paper2Any renders content into editable visuals (SVG diagrams, PPTX slides)

Prerequisites:
    - nlm installed and authenticated (run: nlm auth)
    - Python 3.7+
    - Paper2Any (optional): https://github.com/OpenDCAI/Paper2Any
      Set PAPER2ANY_DIR, DF_API_KEY, DF_API_URL env vars to enable

Usage:
    python create-infographic.py
    python create-infographic.py --with-paper2any
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
    """Generate visual infographics from investment process docs using nlm + Paper2Any."""

    # Content generation steps: (filename, nlm_command, description, needs_source_id)
    GENERATION_STEPS = [
        ("01-overview-guide.md", "generate-guide", "Structured overview guide", False),
        ("02-timeline.md", "timeline", "Investment process timeline", True),
        ("03-mindmap.md", "mindmap", "Interactive process mindmap", True),
        ("04-briefing-doc.md", "briefing-doc", "Executive briefing document", True),
        ("05-faq.md", "faq", "Frequently asked questions", True),
        ("06-outline.md", "outline", "Detailed content outline", True),
    ]

    # Paper2Any rendering steps: (input_file, graph_type_or_mode, output_subdir, description)
    PAPER2ANY_STEPS = [
        ("02-timeline.md", "tech_route", "roadmap", "Process roadmap (SVG + PPTX)"),
        ("01-overview-guide.md", "model_arch", "architecture", "Architecture diagram (SVG + PPTX)"),
        ("04-briefing-doc.md", "paper2ppt", "slides", "Slide deck (PPTX)"),
    ]

    def __init__(self, output_dir: str = "./investment-infographic-output",
                 skip_audio: bool = False, with_paper2any: bool = False,
                 paper2any_dir: str = ""):
        self.output_dir = Path(output_dir)
        self.skip_audio = skip_audio
        self.with_paper2any = with_paper2any
        self.paper2any_dir = Path(paper2any_dir) if paper2any_dir else None
        self.script_dir = Path(__file__).parent
        self.source_file = self.script_dir / "investment-process.md"
        self.notebook_id = None
        self.source_id = None

    def run(self):
        """Execute the full infographic generation pipeline."""
        self._check_prerequisites()
        self._setup_output_dir()

        try:
            # Stage 1: nlm content extraction
            self._create_notebook()
            self._add_source()
            self._wait_for_processing()
            self._generate_all_content()
            if not self.skip_audio:
                self._create_audio()

            # Stage 2: Paper2Any visual rendering
            if self.with_paper2any:
                self._render_visuals()

            self._write_index()
            self._print_summary()
        except Exception as e:
            print(f"\nError: {e}", file=sys.stderr)
            if self.notebook_id:
                print(f"Notebook ID for cleanup: {self.notebook_id}", file=sys.stderr)
            sys.exit(1)

    def _check_prerequisites(self):
        """Verify nlm is installed, source file exists, and Paper2Any is available."""
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

        if self.with_paper2any:
            if not self.paper2any_dir:
                env_dir = os.environ.get("PAPER2ANY_DIR", "")
                if env_dir:
                    self.paper2any_dir = Path(env_dir)
                else:
                    print("Error: Paper2Any directory not set.", file=sys.stderr)
                    print("Use --paper2any-dir or set PAPER2ANY_DIR env var.",
                          file=sys.stderr)
                    print("Install: git clone https://github.com/OpenDCAI/Paper2Any.git",
                          file=sys.stderr)
                    sys.exit(1)

            figure_cli = self.paper2any_dir / "script" / "run_paper2figure_cli.py"
            if not figure_cli.exists():
                print(f"Error: Paper2Any not found at: {self.paper2any_dir}",
                      file=sys.stderr)
                print("Install: git clone https://github.com/OpenDCAI/Paper2Any.git",
                      file=sys.stderr)
                sys.exit(1)

            if not os.environ.get("DF_API_KEY"):
                print("Warning: DF_API_KEY not set. Paper2Any requires an LLM API key.",
                      file=sys.stderr)

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
        print("Creating audio overview...")
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

    def _render_visuals(self):
        """Render nlm outputs into visual infographics using Paper2Any."""
        visuals_dir = self.output_dir / "visuals"
        visuals_dir.mkdir(parents=True, exist_ok=True)

        print("\n--- Stage 2: Paper2Any Visual Rendering ---\n")

        for input_file, mode, output_subdir, description in self.PAPER2ANY_STEPS:
            print(f"[Paper2Any] {description}...")

            input_path = self.output_dir / input_file
            if not input_path.exists() or input_path.stat().st_size == 0:
                print(f"  Skipping: {input_file} is empty or missing")
                continue

            output_path = visuals_dir / output_subdir
            output_path.mkdir(parents=True, exist_ok=True)

            try:
                if mode == "paper2ppt":
                    self._run_paper2ppt(input_path, output_path)
                else:
                    self._run_paper2figure(input_path, mode, output_path)
                print(f"  Saved: {output_path}/")
            except RuntimeError as e:
                print(f"  Warning: {description} failed: {e}", file=sys.stderr)

    def _run_paper2figure(self, input_path: Path, graph_type: str,
                          output_dir: Path):
        """Run Paper2Any paper2figure CLI to generate SVG + PPTX diagrams."""
        cmd = [
            sys.executable,
            str(self.paper2any_dir / "script" / "run_paper2figure_cli.py"),
            "--input", str(input_path),
            "--graph-type", graph_type,
            "--style", "cartoon",
            "--aspect-ratio", "16:9",
            "--language", "en",
            "--output-dir", str(output_dir),
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "paper2figure failed")

    def _run_paper2ppt(self, input_path: Path, output_dir: Path):
        """Run Paper2Any paper2ppt CLI to generate a PPTX slide deck."""
        cmd = [
            sys.executable,
            str(self.paper2any_dir / "script" / "run_paper2ppt_cli.py"),
            "--input", str(input_path),
            "--page-count", "10",
            "--style", "Modern financial style with clean charts",
            "--language", "en",
            "--output-dir", str(output_dir),
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "paper2ppt failed")

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

## Paper2Any Visual Outputs

If generated with `--with-paper2any`, the `visuals/` directory contains:

| Directory | Contents | Source |
|-----------|----------|--------|
| `visuals/roadmap/` | Process roadmap (SVG + PPTX) | Timeline |
| `visuals/architecture/` | Architecture diagram (SVG + PPTX) | Overview guide |
| `visuals/slides/` | Slide deck (PPTX) | Briefing doc |

Paper2Any: https://github.com/OpenDCAI/Paper2Any

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
        md_files = sorted(self.output_dir.glob("*.md"))

        print("\n" + "=" * 50)
        print("  Investment Infographic Generation Complete!")
        print("=" * 50)
        print(f"\nOutput: {self.output_dir}")
        print(f"Notebook: {self.notebook_id}")
        print(f"\nGenerated {len(md_files)} content files:")
        for f in md_files:
            size = f.stat().st_size
            print(f"  {f.name} ({size:,} bytes)")

        visuals_dir = self.output_dir / "visuals"
        if visuals_dir.exists():
            visual_files = sorted(
                f for f in visuals_dir.rglob("*")
                if f.is_file() and f.suffix in (".svg", ".pptx", ".png")
            )
            if visual_files:
                print(f"\nPaper2Any visuals ({len(visual_files)} files):")
                for f in visual_files:
                    size = f.stat().st_size
                    rel = f.relative_to(self.output_dir)
                    print(f"  {rel} ({size:,} bytes)")

        print(f"\nNext steps:")
        print(f"  1. Review content in {self.output_dir}/")
        if self.with_paper2any:
            print(f"  2. Open PPTX/SVG files in {visuals_dir}/ to edit visuals")
        else:
            print(f"  2. Run with --with-paper2any to generate SVG/PPTX visuals")
        print(f"  3. nlm chat {self.notebook_id}  (interactive exploration)")
        print(f"\nCleanup: nlm rm {self.notebook_id}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate investment infographics using nlm + Paper2Any"
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
    parser.add_argument(
        "--with-paper2any",
        action="store_true",
        help="Enable Paper2Any visual rendering (SVG + PPTX)",
    )
    parser.add_argument(
        "--paper2any-dir",
        default="",
        help="Path to Paper2Any repo (or set PAPER2ANY_DIR env var)",
    )
    args = parser.parse_args()

    generator = InfographicGenerator(
        output_dir=args.output_dir,
        skip_audio=args.skip_audio,
        with_paper2any=args.with_paper2any,
        paper2any_dir=args.paper2any_dir,
    )
    generator.run()


if __name__ == "__main__":
    main()
