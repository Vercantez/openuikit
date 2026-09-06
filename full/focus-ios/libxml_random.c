/* POSIX rand_r-style stateful generator used solely for libxml2 hash seeding.
 * Keeping the state in the guest avoids importing a host libc entry point into
 * the executable. No cryptographic random API is implemented by this helper. */
int openui_xml_rand_r(unsigned int *seed)
{
    unsigned int state = *seed;
    state = state * 1103515245u + 12345u;
    unsigned int result = (state / 65536u) % 2048u;
    state = state * 1103515245u + 12345u;
    result = (result << 10) ^ ((state / 65536u) % 1024u);
    state = state * 1103515245u + 12345u;
    result = (result << 10) ^ ((state / 65536u) % 1024u);
    *seed = state;
    return (int)result;
}
