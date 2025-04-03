# Functions
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function integratedgpu() {
  local max_retries=3
  local retry_delay=2
  local nvidia_module="nvidia_drm"
  local success=false

  # Check if module exists
  if ! lsmod | grep -q "^${nvidia_module}"; then
    echo "Warning: ${nvidia_module} module not loaded"
    success=true
  else
    # Attempt normal module removal
    for ((i=1; i<=max_retries; i++)); do
      if sudo rmmod "$nvidia_module" 2>&1; then
        success=true
        break
      else
        echo "Attempt ${i}/${max_retries} failed, retrying in ${retry_delay}s..."
        sleep "$retry_delay"
      fi
    done

    # Force removal if normal attempts failed
    if ! "$success"; then
      echo "Forcing module removal..."
      hyprctl dispatch exit &&
      if ! sudo rmmod -f "$nvidia_module"; then
        echo "Critical error: Failed to remove ${nvidia_module} module" >&2
        return 1
      fi
      success=true
    fi
  fi

  # Switch to integrated mode if module removal succeeded
  if "$success"; then
    if supergfxctl -m Integrated; then
      echo "Successfully switched to Integrated GPU mode"
      return 0
    else
      echo "Failed to switch GPU modes" >&2
      return 1
    fi
  fi

  return 1
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

