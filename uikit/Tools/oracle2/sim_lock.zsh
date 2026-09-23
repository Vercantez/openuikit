# sim_lock.zsh -- take /tmp/conformance_sim.lock (the mkdir + pid protocol of
# scripts/conformance_probe_sim.sh / agent_merge.sh) before booting a
# simulator. Source it, call `sim_lock_acquire`, and call `sim_lock_release`
# from your EXIT trap after the device is shut down and deleted.
SIM_LOCK=/tmp/conformance_sim.lock
_SIM_LOCK_OWNED=0
sim_lock_acquire() {
  local holder
  while ! mkdir "$SIM_LOCK" 2>/dev/null; do
    holder=$(cat "$SIM_LOCK/pid" 2>/dev/null || true)
    if [[ -n "$holder" ]] && ! kill -0 "$holder" 2>/dev/null; then rm -rf "$SIM_LOCK"; continue; fi
    echo "sim_lock: waiting for $SIM_LOCK (pid ${holder:-?})" >&2
    sleep 15
  done
  echo $$ > "$SIM_LOCK/pid"
  _SIM_LOCK_OWNED=1
}
sim_lock_release() {
  if [[ $_SIM_LOCK_OWNED -eq 1 ]]; then rm -rf "$SIM_LOCK"; _SIM_LOCK_OWNED=0; fi
}
