emitter() {
  local dir="$1"
  shift
  rm -rf "${dir}"
  mkdir -p "${dir}"
  local input="${dir}/input"

  socat UNIX-LISTEN:"${input}",fork - 2>/dev/null | while read -r line; do
    for f in "$dir"/*; do
      [[ -S "$f" ]] || continue
      [ "$f" = "${input}" ] && continue
      echo "${line}" | socat UNIX:"${f}" - 2>/dev/null &
    done
  done &

  echo $! > "${input}.pid"

  # Wait until the `emitter` is accepting connections
  while ! socat UNIX:"${input}" - </dev/null 2>/dev/null; do
    sleep 0.1
  done
}

emitter_on() {
  local dir="$1"
  shift
  local id="$(mktemp -u | rev | cut -d. -f1)"
  socat UNIX-LISTEN:"${dir}/${id}",fork - 2>/dev/null | while read -r line; do
    "$@" "$line" &
  done &
  echo $! > "${dir}/${id}.pid"
}

emitter_emit() {
  local input="$1/input"
  shift
  echo "$*" | socat UNIX:"${input}" - 2>/dev/null &
}

emitter_kill() {
  if [ -d "$1" ]; then
    for i in "$1"/*.pid; do
      kill "$(cat "$i")"
    done
    rm -rf "$1"
  fi
}
