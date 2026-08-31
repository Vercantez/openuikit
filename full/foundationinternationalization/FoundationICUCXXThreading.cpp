// Out-of-line libc++ threading operations required by pinned Foundation ICU.
// machorun's curated libc++ image omits these otherwise-standard entry points;
// defining the LLVM-18 implementations in the ICU image keeps its references
// local while delegating the actual synchronization to Darwin pthread shims.

#include <condition_variable>
#include <cstdlib>
#include <mutex>

_LIBCPP_BEGIN_NAMESPACE_STD

void mutex::lock()
{
    if (__libcpp_mutex_lock(native_handle()) != 0) std::abort();
}

bool mutex::try_lock() noexcept
{
    return __libcpp_mutex_trylock(native_handle());
}

void mutex::unlock() noexcept
{
    if (__libcpp_mutex_unlock(native_handle()) != 0) std::abort();
}

mutex::~mutex() noexcept
{
    if (__libcpp_mutex_destroy(native_handle()) != 0) std::abort();
}

condition_variable::~condition_variable()
{
    if (__libcpp_condvar_destroy(native_handle()) != 0) std::abort();
}

void condition_variable::notify_one() noexcept
{
    if (__libcpp_condvar_signal(native_handle()) != 0) std::abort();
}

void condition_variable::notify_all() noexcept
{
    if (__libcpp_condvar_broadcast(native_handle()) != 0) std::abort();
}

void condition_variable::wait(unique_lock<mutex>& lock) noexcept
{
    if (!lock.owns_lock() || !lock.mutex()) std::abort();
    if (__libcpp_condvar_wait(native_handle(), lock.mutex()->native_handle()) != 0) {
        std::abort();
    }
}

void __call_once(
    volatile once_flag::_State_type& state,
    void *argument,
    void (*function)(void *)
)
{
    auto *word = const_cast<once_flag::_State_type *>(&state);
    for (;;) {
        once_flag::_State_type current = __atomic_load_n(word, __ATOMIC_ACQUIRE);
        if (current == once_flag::_Complete) return;
        if (current == once_flag::_Unset) {
            once_flag::_State_type expected = once_flag::_Unset;
            if (__atomic_compare_exchange_n(
                    word,
                    &expected,
                    once_flag::_Pending,
                    false,
                    __ATOMIC_ACQ_REL,
                    __ATOMIC_ACQUIRE)) {
                function(argument);
                __atomic_store_n(word, once_flag::_Complete, __ATOMIC_RELEASE);
                return;
            }
        }
#if defined(__aarch64__)
        __asm__ __volatile__("yield" ::: "memory");
#endif
    }
}

_LIBCPP_END_NAMESPACE_STD
