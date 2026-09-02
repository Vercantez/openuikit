#ifndef OPENUIKIT_ARPA_INET_H
#define OPENUIKIT_ARPA_INET_H

// The package sysroot already owns Darwin's netinet declarations and endian
// operations.  This public include spelling is the missing SDK forwarding
// boundary; it deliberately adds no host-network implementation.
#include <netinet/in.h>
#include <sys/_endian.h>

#endif
