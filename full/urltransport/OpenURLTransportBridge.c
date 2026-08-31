#include "OpenURLTransportABI.h"

/*
 * machorun resolves the `_glibc_` spelling only for a dylib staged in its
 * trusted Darwin root.  The spelling is an explicit ABI decision: each host
 * function below has fixed arity and uses only the fixed-width structures in
 * OpenURLTransportABI.h.  In particular, this bridge never calls libcurl's
 * variadic curl_easy_setopt across the Darwin/Linux AArch64 ABI boundary.
 */
extern void *host_create(void)
    __asm__("_glibc_openui_url_transport_v1_create");
extern int32_t host_perform(
    void *,
    const openui_url_transport_request_v1 *,
    openui_url_transport_response_v1 *
) __asm__("_glibc_openui_url_transport_v1_perform");
extern void host_cancel(void *)
    __asm__("_glibc_openui_url_transport_v1_cancel");
extern void host_destroy(void *)
    __asm__("_glibc_openui_url_transport_v1_destroy");
extern void host_release_response(openui_url_transport_response_v1 *)
    __asm__("_glibc_openui_url_transport_v1_release_response");

void *openui_url_transport_v1_create(void)
{
    return host_create();
}

int32_t openui_url_transport_v1_perform(
    void *operation,
    const openui_url_transport_request_v1 *request,
    openui_url_transport_response_v1 *response
)
{
    return host_perform(operation, request, response);
}

void openui_url_transport_v1_cancel(void *operation)
{
    host_cancel(operation);
}

void openui_url_transport_v1_destroy(void *operation)
{
    host_destroy(operation);
}

void openui_url_transport_v1_release_response(
    openui_url_transport_response_v1 *response
)
{
    host_release_response(response);
}
