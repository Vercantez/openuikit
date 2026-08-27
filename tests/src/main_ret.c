/* main_ret -- the `main_ret_classic` rung: LC_MAIN entry, returns a value.
 *
 * The smallest binary that goes through the normal Darwin startup path.
 * main() is reached via LC_MAIN's entryoff; its return value must become the
 * process exit status. No libSystem function is called from user code, but
 * libSystem.B.dylib is loaded and dyld_stub_binder is imported.
 *
 * Loader must: map segments, apply the (single) fixup, call
 * entry(argc, argv, envp, apple) and exit(retval).
 */
int main(int argc, char **argv) {
    (void)argv;
    return 40 + argc; /* argc == 1 when run with no args -> exit 41 */
}
