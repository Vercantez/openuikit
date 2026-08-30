#!/usr/bin/env bash
# Shared fail-closed classifier for Swift compiler stderr streams. Macro
# expansion text is mixed into stderr, so only actual diagnostic line forms
# are classified; an indented expansion containing the word "error" is not.

readonly SWIFT_COMPILER_FAILURE_DIAGNOSTIC_PATTERN='^(Internal Error:|LLVM ERROR:|fatal error:|error:|[^[:space:]].*:[[:digit:]]+:[[:digit:]]+:[[:space:]]+(fatal[[:space:]]+)?error:|[^[:space:]]+:[[:space:]]+(fatal[[:space:]]+)?error:)'

swift_compiler_output_has_failure_diagnostic() {
    [ "$#" -eq 1 ] || return 2
    LC_ALL=C grep -Eq "$SWIFT_COMPILER_FAILURE_DIAGNOSTIC_PATTERN" "$1"
}
