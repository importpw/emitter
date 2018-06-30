#!/bin/sh
source ./emitter.sh

on_event() {
  echo "got event:" "$@"
  if [ "$1" -eq 50 ]; then kill $$; fi
}

# name of unix socket
e=logger

finish() {
  emitter_kill "$e"
  exit
}
trap finish EXIT SIGINT


echo "e = ${e}"
emitter "$e"
emitter_on "$e" on_event

i=0
while true; do
  emitter_emit "$e" "$i"
  i="$(( $i + 1 ))"
  sleep 0.1
done
