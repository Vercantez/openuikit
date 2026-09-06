import Foundation
import Network
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCEndpointHostPortRoundTrip() {
    let endpoint = "example.invalid".withCString { host in
        "443".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    expect(nw_endpoint_get_type(endpoint) == nw_endpoint_type_host, "type host")
    expect(String(cString: nw_endpoint_get_hostname(endpoint)) == "example.invalid", "hostname")
    expect(nw_endpoint_get_port(endpoint) == 443, "port")
    expect(String(cString: nw_endpoint_copy_port_string(endpoint)) == "443", "copy_port_string")
    expect(String(cString: nw_endpoint_copy_address_string(endpoint)) == "example.invalid", "copy_address_string")
}

func testCEndpointURLRoundTrip() {
    let endpoint = "https://example.invalid/path".withCString { url in
        nw_endpoint_create_url(url)
    }
    expect(nw_endpoint_get_type(endpoint) == nw_endpoint_type_url, "type url")
    expect(String(cString: nw_endpoint_get_url(endpoint)) == "https://example.invalid/path", "url")
}

func testCEndpointAddressRoundTrip() {
    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = UInt16(80).bigEndian
    addr.sin_addr.s_addr = inet_addr("127.0.0.1")
    let endpoint = withUnsafePointer(to: &addr) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
            nw_endpoint_create_address(sa)
        }
    }
    expect(nw_endpoint_get_type(endpoint) == nw_endpoint_type_address, "type address")
    expect(nw_endpoint_get_port(endpoint) == 80, "address port")
    expect(String(cString: nw_endpoint_copy_address_string(endpoint)) == "127.0.0.1", "address string")
    let sa = nw_endpoint_get_address(endpoint)
    expect(Int32(sa.pointee.sa_family) == Int32(AF_INET), "sockaddr family")
}

func testCEndpointBonjourRoundTrip() {
    let endpoint = "Printer".withCString { name in
        "_ipp._tcp".withCString { type in
            "local.".withCString { domain in
                nw_endpoint_create_bonjour_service(name, type, domain)
            }
        }
    }
    expect(nw_endpoint_get_type(endpoint) == nw_endpoint_type_bonjour_service, "type bonjour")
    expect(String(cString: nw_endpoint_get_bonjour_service_name(endpoint)) == "Printer", "name")
    expect(String(cString: nw_endpoint_get_bonjour_service_type(endpoint)) == "_ipp._tcp", "type")
    expect(String(cString: nw_endpoint_get_bonjour_service_domain(endpoint)) == "local.", "domain")
    expect(nw_endpoint_copy_txt_record(endpoint) == nil, "no txt")
}

func testCEndpointSignatureEmpty() {
    let endpoint = "127.0.0.1".withCString { host in
        "9".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    var length = 99
    expect(nw_endpoint_get_signature(endpoint, &length) == nil, "signature nil")
    expect(length == 0, "signature length")
}
