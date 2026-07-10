#!/usr/bin/env bash
set -euo pipefail

# Install requested VS Code extensions:
# - SQL Server (mssql)
# - Azure extensions

find_code_cli() {
	if command -v code >/dev/null 2>&1; then
		printf '%s' "code"
		return 0
	fi
	if command -v code-insiders >/dev/null 2>&1; then
		printf '%s' "code-insiders"
		return 0
	fi
	if [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
		printf '%s' "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
		return 0
	fi

	return 1
}

CODE_BIN="$(find_code_cli || true)"
if [[ -z "$CODE_BIN" ]]; then
	echo "Error: VS Code CLI not found." >&2
	echo "Open VS Code, then install the 'code' CLI command from Command Palette:" >&2
	echo "Shell Command: Install 'code' command in PATH" >&2
	exit 1
fi

EXTENSIONS=(
	"ms-mssql.mssql"
	"ms-azuretools.vscode-azureresourcegroups"
)

echo "Using CLI: $CODE_BIN"
for ext in "${EXTENSIONS[@]}"; do
	echo "Installing: $ext"
	"$CODE_BIN" --install-extension "$ext" --force
done

echo "Done. Installed extensions:"
"$CODE_BIN" --list-extensions | grep -E 'ms-mssql.mssql|ms-azuretools.vscode-azureresourcegroups' || true
