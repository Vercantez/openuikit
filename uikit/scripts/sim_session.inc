# sim_session.inc — sourced (bash or zsh) by the one-shot simulator probes
# (break_probe_sim.sh, focus_edit_probe_sim.sh). Serializes simulator use on
# /tmp/conformance_sim.lock (the lock conformance_probe_sim.sh,
# refresh_conformance_goldens.sh and agent_merge.sh take) and shuts the
# device down when the probe exits, so no simulator stays booted while
# anything compiles or thinks.
#
#   sim_session_lock          before booting
#   SIM_SESSION_UDID=<udid>   once the device is known (shut down on exit)
SIM_LOCK=/tmp/conformance_sim.lock
SIM_SESSION_UDID=
sim_session_end() {
    if [ -n "$SIM_SESSION_UDID" ]; then xcrun simctl shutdown "$SIM_SESSION_UDID" >/dev/null 2>&1 || true; fi
    if [ "$(cat "$SIM_LOCK/pid" 2>/dev/null)" = "$$" ]; then rm -rf "$SIM_LOCK"; fi
}
sim_session_lock() {
    while ! mkdir "$SIM_LOCK" 2>/dev/null; do
        holder=$(cat "$SIM_LOCK/pid" 2>/dev/null || true)
        if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then rm -rf "$SIM_LOCK"; continue; fi
        echo "simulator busy: waiting for $SIM_LOCK (pid ${holder:-?})" >&2
        sleep 15
    done
    echo $$ > "$SIM_LOCK/pid"
    trap sim_session_end EXIT
    trap 'sim_session_end; exit 130' INT TERM HUP
}
