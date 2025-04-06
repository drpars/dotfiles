# Functions
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function pipforce() {
  if ! command -v pip &>/dev/null; then
    echo "Error: pip is not installed or not in PATH." >&2
    return 1
  fi

  local option="$1"
  local package="$2"
  local constant="--break-system-packages"

  case "$option" in
    install|uninstall)
      if [[ -z "$package" ]]; then
        echo "Error: No package specified for '$option'." >&2
        return 1
      fi
      pip "$option" "$package" "$constant"
      return $? 
      ;;
    *)
      pip "$@"
      ;;
  esac
}

function pipupdate() {
  # Ensure pip-review is installed
  if ! command -v pip-review &>/dev/null; then
    echo "Installing pip-review..."
    pip install pip-review --break-system-packages || return 1
  fi

  # Generate a List of Outdated Packages and Update Them
  pip-review --freeze-outdated-packages | cut -d '=' -f 1 | xargs -r -n1 pip install --upgrade --break-system-packages
}

