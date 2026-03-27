---
name: pencil
description: Pencil design tool expert — working with .pen files using the Pencil MCP server and CLI. Use this skill whenever the user mentions Pencil, .pen files, design files, wants to create/edit/export designs, generate UI components in Pencil, read design tokens or variables, batch-modify design properties, or asks about design-to-code workflows. Also triggers for "open my design", "create a layout in Pencil", "export design", "pencil CLI", or any prompt that involves the pencil MCP tools (batch_design, batch_get, get_editor_state, etc.).
---

# Pencil Design Tool

Pencil is a vector design tool that lives in your IDE and exposes a full MCP API for AI-driven design generation and modification. Designs are stored in `.pen` files (encrypted — only readable via MCP tools, never via Read/Grep).

## Two ways to work with Pencil

### 1. MCP tools (live, interactive — use when a .pen file is open in the IDE)
Full read/write access to the active canvas. Prefer this for iterative design sessions.

### 2. CLI (`pencil`) (headless — use for batch/CI/file generation without the IDE)
```bash
pencil --out design.pen --prompt "Create a login page"   # generate new
pencil --in existing.pen --out modified.pen --prompt "Add sidebar"
pencil --export --in design.pen --out screenshot.png      # export PNG/JPEG/WEBP/PDF
pencil --tasks batch.json                                  # batch processing
pencil interactive -o output.pen                          # interactive MCP shell
```

Available models: `claude-opus-4-6` (default), `claude-sonnet-4-6`, `claude-haiku-4-5`

Auth: `pencil login` (interactive) or `PENCIL_CLI_KEY` env var for CI.

---

## MCP Tool Reference

> **Rule**: Never use Read/Grep/Glob on .pen files. Always use these MCP tools.

### Orientation (start here)
```
get_editor_state()          → active file, selected nodes, canvas state
open_document("new")        → create blank .pen file
open_document("/path/to/file.pen")  → open existing file
```

### Reading designs
```
batch_get(patterns, nodeIds)
  patterns  – text search across node properties (array of strings)
  nodeIds   – read specific nodes by ID (array of strings)
```

### Making changes
```
batch_design(operations)    → one call, up to ~25 operations
```

Operation syntax (each line = one op):
```
foo = I("parentId", { type, x, y, width, height, ... })   # Insert
bar = C("sourceId", "parentId", { ...overrides })         # Copy/instance
     R("nodeId", { ...newProps })                          # Replace
     U("nodeId" or foo+"/childId", { ...props })          # Update
     D("nodeId")                                           # Delete
```

### Design utilities
```
get_guidelines(category?, name?, params?)  → load style guides, design system rules
get_screenshot()                           → visual snapshot of current canvas
snapshot_layout()                          → layout tree with positions/sizes
find_empty_space_on_canvas()               → find room to place new nodes
search_all_unique_properties(prop)         → scan all unique values of a property
replace_all_matching_properties(prop, from, to)  → global find/replace on a property
get_variables()                            → read design tokens / theme variables
set_variables(vars)                        → update design tokens / theme variables
export_nodes(nodeIds, format)             → export specific nodes as PNG/SVG/etc
```

---

## .pen File Format (key concepts)

Every node requires:
- `id` — unique string (no forward slashes)
- `type` — `frame`, `rectangle`, `ellipse`, `text`, `path`, `ref` (component instance), `group`
- `x`, `y` — position (top-level nodes)

Layout uses flexbox properties: `layout` (`none`/`vertical`/`horizontal`), `gap`, `padding`, `justifyContent`, `alignItems`

Components: set `reusable: true` on a node to make it a component. Use `type: "ref"` to place instances.

Variables: document-wide design tokens that support themes (light/dark). Read/write via `get_variables()` / `set_variables()`.

---

## Workflow patterns

### Explore then modify
```
1. get_editor_state()              → understand what's open
2. batch_get(["Button", "Card"])   → find relevant nodes
3. get_screenshot()                → visual check
4. batch_design(...)               → make changes
5. get_screenshot()                → verify result
```

### Generate from scratch
```
1. get_guidelines()                → load design system rules first
2. find_empty_space_on_canvas()    → where to place it
3. batch_design(...)               → insert nodes in one call
```

### Bulk property changes
```
search_all_unique_properties("fill")                    → see all colors in use
replace_all_matching_properties("fill", "#FF0000", "#E53E3E")  → swap brand color
```

### Design tokens / theming
```
get_variables()                    → read all tokens
set_variables({ "color-primary": "#6366F1" })          → update token
```

---

## CLI batch.json format
```json
[
  { "out": "login.pen", "prompt": "Login page with email + password" },
  { "in": "base.pen", "out": "dark.pen", "prompt": "Apply dark theme" }
]
```

---

## Tips
- Call `get_guidelines()` before generating complex layouts — it loads design system constraints
- `batch_design` accepts up to ~25 operations per call; split large changes across multiple calls
- Use `snapshot_layout()` after inserting nodes to verify positions before taking a screenshot
- For CI pipelines, set `PENCIL_CLI_KEY` (from Pencil web app → Developer Keys) instead of `pencil login`
- The `.pen` format is JSON under the hood but encrypted — never try to read it directly
