# Team Onboarding: Houston Workspace

"Houston" is not just an AI; it's the **Control Tower** for our entire engineering operation.
This guide explains how human engineers should interact with the workspace, the AI agents, and each other.

> **Target Audience**: New team members (Humans)
> **Goal**: Scale the repo-per-ticket workflow to a team environment.

---

## 🏗 Core Philosophy

1.  **Documentation is the API**:
    *   We don't tell each other (or the AI) what to do in chat. We write it down in `tickets/` or `docs/`.
    *   If it's not documented, it didn't happen.
2.  **Repo-per-Ticket**:
    *   We never code directly in the massive `source` or `master`.
    *   We spin up disposable, lightweight repositories for every single ticket (Issue).
    *   This keeps context clean for AI and prevents regression.
3.  **Agent Agnostic**:
    *   Use any AI tool you like: **Claude**, **Cursor**, **Windsurf**, **Cline**, or raw **GPT-4**.
    *   **Rule**: You must feed the "Context" defined below to your agent.

---

## 🛠 Prerequisites

### 1. Essential Tools
-   **Git**: Version control.
-   **GitHub CLI (`gh`)**: Essential for scripts (`new_ticket.sh`) and issue syncing.
    ```bash
    brew install gh
    gh auth login
    ```
-   **VS Code / Cursor**: Recommended editors.

### 2. Workspace Setup
1.  Clone this repository ("Control Tower"):
    ```bash
    git clone https://github.com/your-org/houston.git workspace
    cd workspace
    ```
2.  Run setup check:
    ```bash
    ./scripts/check_env.sh
    ```

### 3. Service Repositories Setup
The `workspace` controls the process, but you need the actual code to work on.
Refer to [`REPO_INDEX.md`](../../REPO_INDEX.md) for the list of repositories.

**Recommended Directory Structure:**
```text
lines-root/
├── workspace/          (This repo)
├── my-project/
│   └── source/         (Clone my-project-backend here)
└── fourth-project/
    └── source/
```

**Clone Example (My Project):**
```bash
mkdir -p ../my-project
git clone https://github.com/org/my-project-backend.git ../my-project/source
cd ../my-project/source
git checkout stage  # My Project uses 'stage' as base for features
```

---

## 🚀 Workflow: The "Human" Loop

### Step 1: Pick an Issue
Find an issue in GitHub Project or **create one**.
-   Example: `T-XX-100-Login-Fix`

### Step 2: Create a Ticket Document
This is the most crucial step. **Do not skip.**
1.  Copy template:
    ```bash
    cp tickets/TEMPLATE.md tickets/T-XX-100-Login-Fix.md
    ```
    > **Tip**: You can use AI to generate the ticket content.
    > - Use [`prompts/CREATE_TICKET.md`](../../prompts/CREATE_TICKET.md) with the Issue URL.
2.  Fill in the details:
    -   **Goal**: What are we fixing?
    -   **Plan**: Rough technical direction.
    -   **Context**: Relevant file paths.

### Step 3: Initialize Code Workspace
Use our automation script to pull the code and create a safe sandbox.

**Important**: Ensure your source repository is on the correct **Base Branch** before running this.
-   **My Project**: `stage` (Features) or `master` (Hotfix)
-   **Others**: `master`

```bash
# ./scripts/new_ticket.sh <Target_Repo_Path> <Ticket_ID> <Description>
./scripts/new_ticket.sh ../my-project/source T-XX-100 login-fix
```

### Step 4: Summon Your Agent (The "Context Injection")
Open your AI tool in the **newly created folder** (e.g., `my-project/T-XX-100-login-fix`).

**You MUST Provide This Context to the AI (The "Three Pillars"):**
1.  **Global Rules**: `../../workspace/README.md` (Relative to ticket folder)
2.  **The Ticket**: `../../workspace/tickets/T-XX-100-Login-Fix.md`
3.  **Tech Stack**: `CLAUDE.md` (in the repo root)

**How to inject context (Tool Tips):**
-   **Cursor**: Add files to `@Chat` or configure `.cursorrules` to read these paths.
-   **VS Code Copilot**: Open files and use `@workspace`.
-   **Claude.ai**: Drag & Drop files or Copy/Paste content.

**Standard Prompt:**
> Use [`prompts/EXECUTE_TICKET.md`](../../workspace/prompts/EXECUTE_TICKET.md) template.
> OR: "Read `../../workspace/README.md` and `../../workspace/tickets/T-XX-100-Login-Fix.md`. Start with the 'Implementation Plan'."

### Step 5: Verify & Close
1.  Run tests (AI should have created BDD tests).
2.  Commit & Push.
3.  Close the specific ticket workspace (from workspace root):
    ```bash
    ./scripts/close_ticket.sh ./my-project/T-XX-100-login-fix
    ```
4.  Update `tasks/CHANGESETS.md` in the Control Tower.
    > **Tip**: Use [`prompts/DAILY_SCRUM.md`](../../prompts/DAILY_SCRUM.md) to automate status updates.

---

## 🤖 Agent Protocol (Interface Standard)

Regardless of the AI tool, follow this communication protocol:

| Stage | Human Action | AI Output |
| :--- | :--- | :--- |
| **1. Plan** | Provide Ticket + README | **Implementation Plan** (in Ticket) |
| **2. Edit** | Approve Plan | Code Changes + Test Code |
| **3. Verify** | Run Tests | Pass/Fail Evidence |
| **4. Done** | Review PR | PR Link + Commit Hash |

---

## 📂 Directory Structure for Humans

-   **`daily_scrum/`**: Human daily logs. (AI helps generate them).
-   **`docs/`**: Long-term knowledge storage.
-   **`tickets/`**: Active work items.
-   **`tasks/`**: Dashboards (`TASK_BOARD.md`, `CHANGESETS.md`).
-   **`scripts/`**: Automation tools for Humans.

---

> **Tip**: If the AI gets confused, point it back to `workspace/README.md`. That is your reset button.
