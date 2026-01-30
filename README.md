# GemCommander

A PowerShell module for automating the Ruby Gem lifecycle. It bridges JSON configuration to `.gemspec` generation, providing a unified interface for building, verifying, and publishing gems.

## Installation

Import the module directly into your session or add it to your `$PSModulePath`.

```powershell
Import-Module ./GemCommander.psm1
```

## Usage

All operations are routed through the `Invoke-GemCommander` controller using parameter sets.

### 1. Build a Gem

Generates a `.gemspec` from a JSON configuration file and runs `gem build`.

**Configuration (`build_config.json`)**

```json
{
  "name": "my-tool",
  "version": "1.0.0",
  "authors": "DevOps Team",
  "email": "admin@example.com",
  "summary": "CLI utilities",
  "homepage": "[https://gitlab.com/group/project](https://gitlab.com/group/project)",
  "license": "MIT",
  "description": "Extended description for the gem.",
  "files": [
    "lib/my_tool.rb",
    "README.md"
  ]
}
```

**Command**

```powershell
Invoke-GemCommander -Command_Build Build -Path "./build_config.json"
```

### 2. Publish a Gem

Pushes a compiled `.gem` file to a repository.

```powershell
# Default (RubyGems.org)
Invoke-GemCommander -Command_Publish Publish -Path "./my-tool-1.0.0.gem"

# Private Registry (e.g., GitHub/GitLab Package Registry)
Invoke-GemCommander -Command_Publish Publish -Path "./my-tool-1.0.0.gem" -Source "[https://rubygems.pkg.github.com/OWNER](https://rubygems.pkg.github.com/OWNER)" -ApiKey $Env:GEM_HOST_API_KEY
```

### 3. Generate Template

Creates a boilerplate `.gemspec` file.

```powershell
# Types: Full, Compact, Minimal
Invoke-GemCommander -Command_Template Template -Path "./new-project.gemspec" -TemplateType Compact
```

### 4. Verify Gemspec

Validates syntax and dependencies using `gem spec`.

```powershell
Invoke-GemCommander -Command_Verify Verify -Path "./my-tool.gemspec"
```

### 5. Find Gems

Searches remote repositories.

```powershell
Invoke-GemCommander -Command_Find Find -Name "rails"

```

## Command Reference

| Parameter Set | Parameter | Description |
| --- | --- | --- |
| **Build** | `-Path` | Path to `build_config.json`. |
| **Publish** | `-Path` | Path to `.gem` file. |
|  | `-Source` | (Optional) Custom registry URL. |
|  | `-ApiKey` | (Optional) API key for authentication. |
| **Template** | `-Path` | Output path for `.gemspec`. |
|  | `-TemplateType` | `Full`, `Compact`, or `Minimal`. |
| **Verify** | `-Path` | Path to `.gemspec` to validate. |
| **Find** | `-Name` | Name of the gem to search for. |

## Requirements

* PowerShell 5.1 or PowerShell Core 7+
* Ruby development environment (CLI tools `gem` must be in `$env:PATH`)