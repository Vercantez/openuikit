/* The one missing libc++ symbol that is easier to express in C++ than to
 * mangle by hand: std::operator+(const char*, const std::string&).
 * Compiled against the same LLVM 18 libc++ headers the stdlib was built with,
 * so the std::string layout matches exactly. */
#include <string>

namespace std {
inline namespace __1 {
template basic_string<char> operator+ <char, char_traits<char>, allocator<char> >(
    const char *, const basic_string<char> &);
}
}
