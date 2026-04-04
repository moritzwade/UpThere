# OpenCode Agent Instructions

You are a coding assistant with FULL access to the user's file system and terminal through tools.

CRITICAL: You MUST use tools to complete tasks. NEVER say "I don't have access". NEVER suggest the user run commands. NEVER output code snippets instead of using tools. Always take action immediately.

## Tool Schemas (EXACT parameter names - you MUST use these exactly)

### bash
Execute shell commands.
Parameters (ALL required unless noted):
- `command` (string, REQUIRED): The shell command to run
- `description` (string, REQUIRED): Short description of what the command does (5-10 words)
- `timeout` (number, optional): Timeout in milliseconds
- `workdir` (string, optional): Working directory

Example: `{"command": "ls -la", "description": "List files in current directory"}`

### write
Create or overwrite a file.
Parameters (ALL required):
- `filePath` (string, REQUIRED): Absolute path to the file
- `content` (string, REQUIRED): The content to write

Example: `{"filePath": "/Users/web/project/hello.txt", "content": "Hello world"}`

### read
Read a file.
Parameters:
- `filePath` (string, REQUIRED): Absolute path to the file
- `offset` (number, optional): Line number to start from
- `limit` (number, optional): Max lines to read

Example: `{"filePath": "/Users/web/project/hello.txt"}`

### edit
Modify an existing file by replacing text.
Parameters:
- `filePath` (string, REQUIRED): Absolute path to the file
- `oldString` (string, REQUIRED): The exact text to find and replace
- `newString` (string, REQUIRED): The replacement text
- `replaceAll` (boolean, optional): Replace all occurrences

Example: `{"filePath": "/path/to/file.ts", "oldString": "foo", "newString": "bar"}`

### glob
Find files by pattern.
Parameters:
- `pattern` (string, REQUIRED): Glob pattern like `**/*.ts`
- `path` (string, optional): Directory to search in

### grep
Search file contents.
Parameters:
- `pattern` (string, REQUIRED): Regex pattern to search for
- `path` (string, optional): Directory to search in
- `include` (string, optional): File pattern filter like `*.js`

### todowrite
Track tasks and progress. The `todos` parameter MUST be a JSON array of objects, NOT a string.
Parameters:
- `todos` (array of objects, REQUIRED): Each object has:
  - `content` (string, REQUIRED): Brief description of the task
  - `status` (string, REQUIRED): One of: `pending`, `in_progress`, `completed`, `cancelled`
  - `priority` (string, REQUIRED): One of: `high`, `medium`, `low`

Example: `{"todos": [{"content": "Add game over screen", "status": "in_progress", "priority": "high"}, {"content": "Add sound effects", "status": "pending", "priority": "low"}]}`

IMPORTANT: `todos` MUST be an array `[...]`, NOT a string `"[...]"`. Never stringify the array.

## IMPORTANT REMINDERS

- The `bash` tool REQUIRES both `command` AND `description` fields. Always include both.
- The `write` tool parameter is `filePath` (camelCase), NOT `file_path`.
- The `edit` tool uses `oldString`/`newString` (camelCase), NOT `old_string`/`new_string`.
- Do NOT call tools that don't exist. Available tools: bash, read, write, edit, glob, grep, task, webfetch, todowrite, question, skill.
- There is NO `list` tool. To list files use `bash` with `ls`.

## Git Commit Conventions

- **ALWAYS use a gitmoji** at the start of every commit title.
- Format: `<gitmoji> <type>: <description>` or `<gitmoji> <description>`
- Common gitmojis:
  - ✨ `:sparkles:` — new feature
  - 🐛 `:bug:` — bug fix
  - 🔧 `:wrench:` — configuration/tooling
  - 🧪 `:test_tube:` — tests
  - 📝 `:memo:` — documentation
  - 🔒 `:lock:` — security
  - 🎨 `:art:` — UI/style
  - ♻️ `:recycle:` — refactoring
  - 🚀 `:rocket:` — deployment/performance
  - 🗑️ `:wastebasket:` — deprecation/removal

## Project Architecture

### Tech Stack
- **Language**: Swift 5.9
- **UI**: SwiftUI with `@Observable` macro (iOS 17+ / macOS 14.0+)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Project Generator**: XcodeGen — **always run `xcodegen generate` after adding or removing files**

### Directory Structure
```
UpThere/
├── App/              — @main entry point
├── Models/           — Data models (Flight, OpenSkyResponse)
├── Services/         — Network, location, and logging (FlightService, LocationService, Logger)
├── ViewModels/       — @Observable view models (UpThereViewModel)
└── Views/            — SwiftUI views (ContentView, FlightListView, FlightMapView, FlightDetailView)

UpThereTests/
├── TestHelpers/      — Test fixtures (TestData.swift)
└── MockData/         — MockURLProtocol for network mocking
```

### Key Patterns
- `FlightService` is an `actor` for thread-safe concurrent access
- OAuth2 token management with automatic refresh (client credentials flow)
- Platform-conditional compilation with `#if os(macOS)` / `#if os(iOS)`
- Excludes: `*.macos.swift` files from iOS target, `*.ios.swift` files from macOS target

## Testing

### Framework
- **Swift Testing** (`import Testing`), **not** XCTest
- Use `@Test` for test functions, `#expect()` for assertions

### Conventions
- Test files: `UpThereTests/*Tests.swift`
- Test methods: `test*` naming (e.g., `testFetchFlightsSuccess`)
- Group related tests with `// MARK:` comments
- **Always add tests for new features and update tests when behavior changes**

### Mocking
- **Network**: `MockURLProtocol` — set `MockURLProtocol.requestHandler` to intercept URLRequests
- **Services**: Inject custom `URLSession` via `FlightService(config:session:)` initializer
- **Test data**: Use `TestData` helpers for JSON fixtures

### Running Tests
```bash
# iOS
xcodebuild -project UpThere.xcodeproj -scheme UpThere \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# macOS
xcodebuild -project UpThere.xcodeproj -scheme UpThereMac \
  -destination 'platform=macOS,arch=arm64' test
```

## Logging

### Framework
- Apple's `os.Logger` via the centralized `AppLogger` enum (`UpThere/Services/Logger.swift`)
- Subsystem: `com.moritzwade.upthere`
- Categories: `FlightService`, `LocationService`, `ViewModel`

### Rules
- **NEVER use `print()`** — always use `AppLogger`
- **Always add logging to new features** following the established log level strategy
- Use `privacy: .public` for non-sensitive values (counts, status codes, coordinates)
- Use default (private) privacy for sensitive data (tokens, auth details)

### Usage
```swift
AppLogger.flightService.debug("Fetching flights: \(url.absoluteString, privacy: .public)")
AppLogger.viewModel.info("Starting flight tracking")
AppLogger.locationService.error("Location update failed: \(error.localizedDescription, privacy: .public)")
```

### Log Level Guide
| Level | Use Case |
|-------|----------|
| `debug` | Verbose: URLs, coordinates, counts, token expiry, bounding box details |
| `info` | Key events: tracking start/stop, flights fetched, auth granted |
| `warning` | Recoverable: token refresh, rate limits, missing location, unauthorized state |
| `error` | Failures: network errors, auth failures, location failures, parsing errors |

### Viewing Logs
```bash
# All logs
log stream --predicate 'subsystem == "com.moritzwade.upthere"' --level debug

# Errors only
log stream --predicate 'subsystem == "com.moritzwade.upthere" && level == 16' --level error

# By component
log stream --predicate 'subsystem == "com.moritzwade.upthere" && category == "FlightService"' --level debug
```

## Development Workflow

1. **After adding/removing files**: run `xcodegen generate`
2. **Before committing**: build both targets and run all tests
3. **Build commands**:
   ```bash
   # iOS
   xcodebuild -project UpThere.xcodeproj -scheme UpThere \
     -destination 'platform=iOS Simulator,name=iPhone 17' build

   # macOS
   xcodebuild -project UpThere.xcodeproj -scheme UpThereMac \
     -destination 'platform=macOS,arch=arm64' build
   ```
4. **Commit**: use gitmoji format (see Git Commit Conventions above)
5. **PR**: create a pull request with a clear summary of changes
   - **Always include `Closes #<issue id>`** in the PR body to auto-close the linked issue on merge

## Git Worktree Workflow

All feature development and bug fixes MUST use **git worktrees**. Never work directly in the main `UpThere/` checkout. Each worktree maps 1:1 to a GitHub issue, enabling safe parallel development by multiple agents.

### Directory Layout

```
UpThere/                    ← main checkout (master only, never edit here)
└── ../UpThere-worktrees/   ← all feature worktrees live here (sibling directory)
    ├── issue-11-logging/   ← worktree for issue #11
    ├── issue-42-fix-crash/ ← worktree for issue #42
    └── ...
```

### Branch Naming

Format: `issue/<number>/<short-slug>`

Examples:
- `issue/11/logging-system`
- `issue/42/fix-map-crash`

### Process

**1. Check for existing worktree** (ALWAYS do this first):
```bash
git worktree list | grep "issue/<num>"
```
- If a worktree exists for the issue → **use it**, don't create a new one
- If no worktree exists → proceed to step 2

**2. Create a worktree** (from `master`, one per issue):
```bash
git worktree add ../UpThere-worktrees/issue-<num>-<slug> -b issue/<num>/<slug> master
```

**3. Initialize the worktree:**
```bash
cd ../UpThere-worktrees/issue-<num>-<slug>
xcodegen generate
```
> **Important:** The `UpThere.xcodeproj` is **not committed** to git (it's generated from `project.yml` by XcodeGen). Every new worktree must run `xcodegen generate` before building or opening in Xcode.

**4. Work in the worktree:**
```bash
# implement, build, test
```

**5. Commit and push:**
```bash
git add -A && git commit -m "<gitmoji> <message>"
git push -u origin issue/<num>/<slug>
```

**5. Commit and push:**
```bash
git add -A && git commit -m "<gitmoji> <message>"
git push -u origin issue/<num>/<slug>
```

**6. Create PR** with `Closes #<num>` in the body.

**7. After merge, wait for user confirmation** that the implementation is complete, then clean up:
```bash
git worktree remove ../UpThere-worktrees/issue-<num>-<slug>
git branch -d issue/<num>/<slug>
git push origin --delete issue/<num>/<slug>
```

### Rules for Agents

- **NEVER edit files in the main `UpThere/` checkout** — always create/use a worktree
- **Always check `git worktree list` first** — reuse existing worktrees for the same issue
- **One worktree per issue** — never create duplicates
- **Always branch from `master`** — never from another feature branch
- **Run `xcodegen generate`** inside the worktree after adding/removing files
- **Build and test** before committing
- **Clean up** the worktree only after the user confirms the work is done and the PR is merged

### Useful Commands

```bash
# List all active worktrees
git worktree list

# Prune stale worktree references
git worktree prune
```