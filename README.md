# EditorLint GitHub Action

A GitHub Action that validates and fixes files according to .editorconfig specifications. This action runs the [editorlint](https://github.com/editorlint/editorlint) tool in your CI/CD workflows to ensure code consistency across your repository.

## Features

- ✅ **Cross-platform**: Supports Linux, macOS, and Windows runners
- ✅ **Automatic fixing**: Can automatically fix violations and commit changes
- ✅ **PR comments**: Posts detailed results as comments on pull requests
- ✅ **Flexible configuration**: Extensive customization options
- ✅ **Multiple output formats**: Default, tabular, JSON, quiet, and GitHub-specific formats
- ✅ **Smart commenting**: Updates existing comments instead of creating duplicates

## Quick Start

### Basic Usage

```yaml
name: EditorConfig Lint
on: [push, pull_request]

jobs:
  editorconfig:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: editorlint/editorlint-action@v1
```

### With Auto-fix

```yaml
name: EditorConfig Lint & Fix
on: [push, pull_request]

jobs:
  editorconfig:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: editorlint/editorlint-action@v1
        with:
          fix: true
          auto-commit: true
          token: ${{ secrets.GITHUB_TOKEN }}
```

### Using Custom Arguments

```yaml
name: EditorConfig Custom
on: [push, pull_request]

jobs:
  editorconfig:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: editorlint/editorlint-action@v1
        with:
          args: "--fix --output json --exclude '*.min.*' --config .editorconfig.strict"
```

### With PR Comments

```yaml
name: EditorConfig Lint
on: [pull_request]

jobs:
  editorconfig:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: editorlint/editorlint-action@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          pr-comment: true
          reporter: github
```

## Input Parameters

### Core Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `args` | Custom arguments to pass to editorlint (overrides structured inputs) | No | (none) |
| `fix` | Automatically fix violations instead of just reporting them | No | `false` |
| `path` | Path to file or directory to validate | No | `.` |
| `recurse` | Process files recursively in directories | No | `true` |
| `fail-on-violations` | Fail the action if violations are found | No | `true` |

### Configuration Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `config` | Path to custom .editorconfig file | No | (auto-discover) |
| `exclude` | Comma-separated list of glob patterns to ignore | No | (none) |
| `version` | Version of editorlint to use | No | `latest` |

### Output Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `reporter` | Output format: `default`, `tabular`, `json`, `quiet`, `github` | No | `default` |

### GitHub Integration Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `token` | GitHub token for API access | No | (none) |
| `pr-comment` | Post PR comments with violation details | No | `false` |
| `pr-comment-header` | Header text for PR comments | No | `## 📝 EditorLint Results` |

### Auto-commit Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `auto-commit` | Automatically commit fixes when fix=true | No | `false` |
| `commit-message` | Commit message for auto-committed fixes | No | `fix: auto-fix editorconfig violations` |
| `git-user-name` | Git user name for auto-commits | No | `github-actions[bot]` |
| `git-user-email` | Git user email for auto-commits | No | `github-actions[bot]@users.noreply.github.com` |

### Legacy Parameters (Backward Compatibility)

| Parameter | Description | Replacement |
|-----------|-------------|-------------|
| `config-file` | Path to custom .editorconfig file | Use `config` instead |
| `output-format` | Output format | Use `reporter` instead |

## Output Values

The action provides these outputs that can be used in subsequent steps:

| Output | Description | Type |
|--------|-------------|------|
| `violations-found` | Whether any violations were found | `boolean` |
| `files-processed` | Number of files processed | `number` |
| `files-fixed` | Number of files fixed (when fix=true) | `number` |

### Using Outputs

```yaml
- uses: editorlint/editorlint@v1
  id: lint
  with:
    fix: true

- name: Check results
  run: |
    echo "Violations found: ${{ steps.lint.outputs.violations-found }}"
    echo "Files processed: ${{ steps.lint.outputs.files-processed }}"
    echo "Files fixed: ${{ steps.lint.outputs.files-fixed }}"
```

## Examples

### 1. Basic Validation

```yaml
name: EditorConfig Check
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: editorlint/editorlint-action@v1
        with:
          path: .
          recurse: true
```

### 2. Auto-fix with Commit

```yaml
name: EditorConfig Auto-fix
on: [push]

jobs:
  fix:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - uses: editorlint/editorlint-action@v1
        with:
          fix: true
          auto-commit: true
          commit-message: "style: fix editorconfig violations"
          token: ${{ secrets.GITHUB_TOKEN }}
```

### 3. PR Comments with Detailed Results

```yaml
name: EditorConfig PR Check
on: [pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: editorlint/editorlint-action@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          pr-comment: true
          pr-comment-header: "## 🔍 EditorConfig Validation Results"
          reporter: github
          fail-on-violations: false  # Don't fail, just comment
```

### 4. Custom Configuration and Exclusions

```yaml
name: Custom EditorConfig
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: editorlint/editorlint-action@v1
        with:
          config: .editorconfig.strict
          exclude: "*.generated.*, node_modules/**, dist/**"
          path: src/
          recurse: true
```

### 5. Matrix Testing Across Platforms

```yaml
name: Cross-platform EditorConfig
on: [push, pull_request]

jobs:
  lint:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: editorlint/editorlint-action@v1
        with:
          fix: false
          reporter: tabular
```

### 6. Conditional Auto-fix

```yaml
name: Smart EditorConfig
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: editorlint/editorlint-action@v1
        id: lint
        with:
          fix: ${{ github.event_name == 'push' }}  # Only fix on push, not PR
          auto-commit: ${{ github.event_name == 'push' }}
          pr-comment: ${{ github.event_name == 'pull_request' }}
          token: ${{ secrets.GITHUB_TOKEN }}
```

### 7. Advanced Workflow with Multiple Steps

```yaml
name: Advanced EditorConfig Workflow
on: [pull_request]

jobs:
  editorconfig:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run EditorConfig Lint
        uses: editorlint/editorlint@v1
        id: lint
        with:
          fix: false
          pr-comment: true
          reporter: github
          token: ${{ secrets.GITHUB_TOKEN }}
          exclude: "*.min.js, *.bundle.*, vendor/**"
      
      - name: Handle violations
        if: steps.lint.outputs.violations-found == 'true'
        run: |
          echo "Found violations in ${{ steps.lint.outputs.files-processed }} files"
          echo "Consider running 'editorlint --fix .' locally to fix these issues"
      
      - name: Success message
        if: steps.lint.outputs.violations-found == 'false'
        run: |
          echo "✅ All ${{ steps.lint.outputs.files-processed }} files comply with .editorconfig rules"
```

## Reporter Formats

### Default Reporter
Standard text output with file paths and violation descriptions.

### Tabular Reporter
Formatted table output, great for readability in CI logs.

### JSON Reporter
Machine-readable JSON output for integration with other tools.

### GitHub Reporter
Optimized output format for GitHub Actions with proper annotations.

### Quiet Reporter
Minimal output, only shows summary information.

## PR Comment Features

When `pr-comment: true` is enabled:

- **Smart Updates**: Comments are updated in-place rather than creating new ones
- **Rich Formatting**: Uses markdown formatting for clear violation reports
- **Status Indicators**: Shows ✅ for passing files and ❌ for violations
- **Fix Suggestions**: Provides guidance on how to resolve issues
- **Contextual Information**: Includes file counts and processing statistics

### Sample PR Comment

<details>
<summary>Example PR Comment Output</summary>

## 📝 EditorLint Results

❌ **EditorConfig violations found**

```
./src/main.go: trim_trailing_whitespace violation - line 15 has trailing whitespace
./README.md: insert_final_newline violation - file should end with LF (\n), but ends with character 'o' (0x6f)
./config.json: indent_style violation - line 5 uses tabs but should use spaces
```

Files processed: 23  
Violations found: true

Run with `fix: true` to automatically fix these issues.

</details>

## Troubleshooting

### Common Issues

1. **Permission Denied on Auto-commit**
   ```yaml
   - uses: actions/checkout@v4
     with:
       token: ${{ secrets.GITHUB_TOKEN }}  # Ensure token is provided
   ```

2. **Large Repository Performance**
   ```yaml
   - uses: editorlint/editorlint@v1
     with:
       exclude: "node_modules/**, dist/**, *.min.*"  # Exclude large directories
   ```

3. **Custom EditorConfig Not Found**
   ```yaml
   - uses: editorlint/editorlint@v1
     with:
       config: ./.editorconfig.custom  # Use explicit path
   ```

4. **Action Failing on Minor Issues**
   ```yaml
   - uses: editorlint/editorlint@v1
     with:
       fail-on-violations: false  # Don't fail the workflow
       pr-comment: true           # Just comment instead
   ```

### Getting Help

- 📖 [Full Documentation](https://github.com/editorlint/editorlint)
- 🐛 [Report Issues](https://github.com/editorlint/editorlint/issues)
- 💬 [Discussions](https://github.com/editorlint/editorlint/discussions)

## License

This action is released under the MIT License. See the [LICENSE](LICENSE) file for details.