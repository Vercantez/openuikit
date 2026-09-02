/* EMPTY ON PURPOSE. Every probe this file used to hold is now real.
 *
 * THE RULE THIS FILE ALWAYS CARRIED: "a probe is a claim that something is
 * absent." As of machorun master 3110d92, every one of those claims is false.
 * `nm -g` on a freshly built darwin/usr/lib/libSystem.B.dylib:
 *
 *     gethostuuid                       EXPORTED
 *     writev                            EXPORTED
 *     snprintf_l                        EXPORTED
 *     pthread_threadid_np               EXPORTED
 *     OSMemoryBarrier                   EXPORTED
 *     OSAtomicCompareAndSwapPtrBarrier  EXPORTED
 *     flsl                              EXPORTED
 *     pthread_atfork                    EXPORTED
 *     _NSGetExecutablePath              EXPORTED
 *     pthread_getugid_np                EXPORTED
 *     __strlcat_chk                     EXPORTED
 *
 * HOW FOUR OF THEM CAME TO BE WRITTEN TWICE, and it is the lesson worth more
 * than the code that was deleted. On 2026-08-28 I implemented gethostuuid,
 * writev, snprintf_l and pthread_threadid_np here after each aborted as a
 * "STUB CALLED". Two of the four had been in libSystem for a while. The stub
 * fired because the dylib being LOADED was stale -- older than its own source,
 * carrying none of the code it was built from -- so the measurement described
 * an ARTEFACT and I read it as a statement about the TREE.
 *
 *     "These N symbols are missing" is a claim about an artefact, not about a
 *     tree. `nm` a freshly built library before implementing anything reported
 *     absent.
 *
 * WHY THIS MATTERED MORE THAN A DUPLICATED FUNCTION. build_cftest_harness.sh
 * links `/work/probe_sysctl.o` BEFORE `-lSystem`, so every definition here
 * WINS over the real one. A probe that outlives its absence stops being a
 * stand-in and becomes a SHADOW -- and the shadow is what runs. This file's
 * own header used to say _NSGetExecutablePath was FICTION, returning the
 * LOADER's path rather than the guest's, and warned that "any result that
 * depends on bundles is measuring a lie". machorun has since grown
 * mr_guest_executable_path and a real implementation. So the lie was being
 * preferred to the truth by link order alone, and the CFBundle path -- which
 * decides the plist FILENAME for UserDefaults.standard -- was reading it.
 *
 * Same family as zerofill-placeholder-shadowing and umbrella-shadows-reexport:
 * two definitions, every symbol resolving, and the wrong one winning quietly.
 *
 * KEEP THIS FILE. The harness compiles and links it by name, and an empty
 * translation unit is exactly the right content for "nothing is absent today".
 * If a future symbol IS absent, add it here WITH the nm output that shows it
 * absent from a freshly built libSystem -- and delete it the moment that
 * changes.
 */
