# ocl-mode

[![CI](https://github.com/xcezx/ocl-mode/actions/workflows/test.yml/badge.svg)](https://github.com/xcezx/ocl-mode/actions/workflows/test.yml)

A GNU Emacs major mode for editing [Octopus Configuration Language
(OCL)](https://octopus.com/docs/projects/version-control/ocl-file-format)
files (`.ocl`), as used by [Octopus Deploy](https://octopus.com/)'s
Configuration as Code feature.

## What is OCL?

OCL is a subset of [HashiCorp Configuration Language
(HCL)](https://github.com/hashicorp/hcl) used to serialize Octopus
Deploy projects, deployment processes, and runbooks as text. See:

- [OCL File Format](https://octopus.com/docs/projects/version-control/ocl-file-format)
- [Config as Code reference](https://octopus.com/docs/projects/version-control/config-as-code-reference)
- [OctopusDeploy/Ocl](https://github.com/OctopusDeploy/Ocl) — the reference parser/serializer

A typical `.ocl` file looks like:

```hcl
step "Run a script" {
    name = "Run a script"

    action {
        action_type = "Octopus.Script"
        is_disabled = false

        properties = {
            Octopus.Action.Script.ScriptBody = <<-EOT
                echo 'Hello world'
            EOT
        }
    }
}
```

### Why no comments?

Unlike HCL, **OCL has no comment syntax** — the [reference
parser](https://github.com/OctopusDeploy/Ocl) only ever skips
whitespace as trivia, and any `#`, `//`, or `/* */` in a document
causes a parse error. `ocl-mode` follows the spec strictly: it does
not define any comment syntax, so `#`/`//`/`/* */` are highlighted
like any other text rather than as comments. This avoids encouraging
edits that Octopus itself would reject.

OCL also has no string interpolation (`${...}`), no expressions or
function calls, and no exponential number notation (`1e6`) — none of
these are supported by this mode either, to stay faithful to what the
parser actually accepts.

## Features

- Syntax highlighting for attribute names, block types, strings,
  heredocs, booleans (`true`/`false`), `null`, and numbers (including
  dotted keys such as `Octopus.Action.Script.ScriptBody`).
- Indentation (`TAB`), 4 spaces per level by default.
- Heredoc (`<<TAG` / `<<-TAG`) bodies are treated as string content
  and left untouched by indentation.
- Block navigation with `C-M-a` (`ocl-beginning-of-defun`) and `C-M-e`
  (`ocl-end-of-defun`).
- Automatically enabled for `.ocl` files via `auto-mode-alist`.

## Installation

Not yet published to MELPA. Until then, install manually or with
`use-package` + `:load-path`:

```elisp
(use-package ocl-mode
  :load-path "/path/to/ocl-mode")
```

Or clone this repository and add it to your `load-path`:

```elisp
(add-to-list 'load-path "/path/to/ocl-mode")
(require 'ocl-mode)
```

`.ocl` files are then opened in `ocl-mode` automatically.

## Customization

```elisp
(setq ocl-indent-level 4) ; default
```

## Development

```console
$ make        # byte-compile, run ERT tests, and run package-lint
$ make test   # run ERT tests only
```

## License

GPL-3.0. See [LICENSE](LICENSE).
