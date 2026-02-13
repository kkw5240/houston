# Houston — Mission Control for AI-Assisted Software Engineering

Houston is a **workspace governance framework** that orchestrates work across multiple service repositories using AI agents. It doesn't contain application code — it owns the **truth about work**: what needs to be done, what has been done, and the proof that it was done correctly.

## Why Houston?

When you work with AI coding agents (Claude, Cursor, Windsurf, Copilot, etc.) across multiple repositories, you face:

- **Context loss** — AI agents forget rules between sessions
- **Process drift** — Each agent invents its own workflow
- **No evidence trail** — Work gets done but there's no proof
- **Environment contamination** — Parallel tickets conflict with each other

Houston solves these by providing a **single source of truth** that every AI agent reads before doing anything.

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    Houston (This Repo)                       │
│                                                             │
│  .houston/        ← Rules, processes, identity (source)     │
│  CLAUDE.md        ← Auto-generated agent instructions       │
│  .cursorrules     ← Auto-generated agent instructions       │
│  tickets/         ← What to build (intent)                  │
│  tasks/           ← Status tracking (CHANGESETS, BOARD)     │
│  prompts/         ← Reusable AI prompt templates            │
│  scripts/         ← CLI automation (dock, ticket, close)    │
│                                                             │
│  my-project/                                                │
│    source/        ← Read-only repo clone (template)         │
│    T-XX-100/      ← Disposable ticket workspace (isolated)  │
│    T-XX-200/      ← Another ticket workspace                │
│                                                             │
│  another-project/                                           │
│    source/        ← Another repo clone                      │
└─────────────────────────────────────────────────────────────┘
```

**Key principle**: Repositories own implementation. Houston owns governance and process.

## Quick Start

### Option 1: Use this repo as a template

Click **"Use this template"** on GitHub, then:

```bash
git clone https://github.com/your-name/houston.git workspace
cd workspace

# Register your first repository
scripts/houston-dock.sh https://github.com/org/my-backend.git --code XX --name "My Backend"

# Check fleet status
houston status

# Create a ticket workspace and start working
houston ticket XX T-XX-100 feature-name
```

### Option 2: Initialize from scratch

```bash
mkdir workspace && cd workspace
git init

# If you have the houston CLI in PATH:
houston init

# Otherwise, copy the .houston/ directory from this repo and run:
.houston/build.sh
```

## Core Concepts

### Repo-per-Ticket

Every ticket gets its own **disposable copy** of the source repository. No branch switching, no stashing, no conflicts.

```bash
houston ticket XX T-XX-100 login-fix
# → Creates my-project/T-XX-100-login-fix/
# → Branch: feat/T-XX-100--CS-01
# → Work in complete isolation

houston close my-project/T-XX-100-login-fix
# → Verifies no unpushed commits
# → Deletes the workspace
```

### Documentation-First

> "If you delete all code and rebuild from `/docs` alone, the result must behave identically."

Houston enforces writing design docs and BDD scenarios **before** writing code. This isn't bureaucracy — it's how AI agents maintain long-term memory.

### Evidence-Based Completion

Every completed task requires proof: a commit hash or PR link recorded in `tasks/CHANGESETS.md`. Without evidence, the status is NOT Done.

### Agent-Agnostic Instructions

Houston generates identical instructions for every AI tool from a single source:

```
.houston/IDENTITY.md  ─┐
.houston/RULES.md      ├─→ build.sh ─→ CLAUDE.md
.houston/PROCESSES.md  │              ─→ .cursorrules
.houston/CHECKLIST.md  ┘              ─→ .windsurfrules
                                      ─→ GEMINI.md
                                      ─→ .github/copilot-instructions.md
```

Edit once in `.houston/`, rebuild, and every agent gets the same rules.

## Supported AI Agents

| Agent | Instruction File | Auto-Generated |
|:---|:---|:---|
| Claude (Code / CLI) | `CLAUDE.md` | Yes |
| Cursor | `.cursorrules` | Yes |
| Windsurf | `.windsurfrules` | Yes |
| GitHub Copilot | `.github/copilot-instructions.md` | Yes |
| Gemini | `GEMINI.md` | Yes |
| Others | Add to `.houston/config.yaml` | Yes |

## Directory Structure

```
houston/
├── .houston/               # Source of truth (edit here)
│   ├── IDENTITY.md         # Who Houston is
│   ├── RULES.md            # 10 Golden Rules + policies
│   ├── PROCESSES.md        # Workflow summaries
│   ├── CHECKLIST.md        # Session checklist [PRE/DURING/POST]
│   ├── fleet.yaml          # Registered repositories
│   ├── config.yaml         # Adapter list + settings
│   ├── build.sh            # Assembles agent instructions
│   └── install-hooks.sh    # Git hook installer
├── scripts/                # CLI automation
│   ├── houston             # Main CLI entry point
│   ├── houston-init.sh     # Initialize new workspace
│   ├── houston-dock.sh     # Register a repo
│   ├── houston-undock.sh   # Remove a repo
│   ├── houston-status.sh   # Fleet status
│   ├── houston-active.sh   # Active ticket workspaces
│   ├── houston-briefing.sh # Session briefing
│   ├── houston-archive.sh  # Archive completed changesets
│   ├── new_ticket.sh       # Create ticket workspace
│   └── close_ticket.sh     # Close ticket workspace
├── tickets/                # Ticket files (one per task)
│   └── TEMPLATE.md         # Ticket template
├── tasks/                  # Status tracking
│   ├── CHANGESETS.md       # Change Set log (evidence)
│   └── TASK_BOARD.md       # Kanban view
├── docs/                   # Reference documentation
│   ├── processes/          # Detailed workflow docs
│   ├── standards/          # Architecture standards
│   └── guides/             # Onboarding & guides
├── prompts/                # AI prompt templates
│   ├── CREATE_TICKET.md    # Ticket creation prompt
│   ├── EXECUTE_TICKET.md   # Ticket execution prompt
│   └── DAILY_SCRUM.md      # Daily scrum automation
├── daily_scrum/            # Daily status reports
├── CLAUDE.md               # (auto-generated)
├── .cursorrules            # (auto-generated)
├── .windsurfrules          # (auto-generated)
├── GEMINI.md               # (auto-generated)
└── .github/
    └── copilot-instructions.md  # (auto-generated)
```

## Houston CLI

```bash
houston ticket <CODE> <TICKET_ID> [DESC]   # Create ticket workspace
houston close  <TICKET_PATH>               # Close ticket workspace
houston active                             # Show active workspaces
houston briefing                           # Session status overview
houston status [--fetch]                   # Fleet status
houston info   <CODE>                      # Project info
houston archive [--days N] [--dry-run]     # Archive completed changesets
houston build                              # Rebuild agent adapters
houston init   [path]                      # Initialize new workspace
```

## Customization

### Add a new AI agent adapter

1. Edit `.houston/config.yaml`:
   ```yaml
   adapters:
     - CLAUDE.md
     - .cursorrules
     - .new-agent-config    # ← add here
   ```
2. Run `.houston/build.sh`

### Customize rules and processes

Edit the `.houston/*.md` source files, then run `.houston/build.sh` to regenerate all adapters.

### Change the Communication language

Houston defaults to Korean for process context and English for technical terms. Edit `.houston/IDENTITY.md` to change this.

## License

MIT License. See [LICENSE](LICENSE) for details.
