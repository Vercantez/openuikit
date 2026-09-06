import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCProxyConfigDomainRoundTrip() {
    let endpoint = "127.0.0.1".withCString { host in
        "1080".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    let socks = nw_proxy_config_create_socksv5(endpoint)
    nw_proxy_config_set_failover_allowed(socks, true)
    expect(nw_proxy_config_get_failover_allowed(socks), "failover")
    "example.invalid".withCString { nw_proxy_config_add_match_domain(socks, $0) }
    "corp.invalid".withCString { nw_proxy_config_add_excluded_domain(socks, $0) }
    var matches = 0
    nw_proxy_config_enumerate_match_domains(socks) { domain in
        expect(String(cString: domain) == "example.invalid", "match")
        matches += 1
    }
    expect(matches == 1, "one match")
    var excluded = 0
    nw_proxy_config_enumerate_excluded_domains(socks) { domain in
        expect(String(cString: domain) == "corp.invalid", "excluded")
        excluded += 1
    }
    expect(excluded == 1, "one excluded")
    nw_proxy_config_clear_match_domains(socks)
    nw_proxy_config_clear_excluded_domains(socks)
    "user".withCString { user in
        "secret".withCString { password in
            nw_proxy_config_set_username_and_password(socks, user, password)
        }
    }
    _ = nw_proxy_config_create_http_connect(endpoint, nil)
    let hop = nw_relay_hop_create(endpoint, nil, nil)
    "X-Relay".withCString { name in
        "1".withCString { value in
            nw_relay_hop_add_additional_http_header_field(hop, name, value)
        }
    }
    _ = nw_proxy_config_create_relay(hop, nil)
    "https://relay.invalid/oh".withCString { path in
        let key: [UInt8] = [1, 2, 3]
        key.withUnsafeBufferPointer { buffer in
            _ = nw_proxy_config_create_oblivious_http(hop, path, buffer.baseAddress!, key.count)
        }
    }
}

func testCPrivacyContextAndResolverRoundTrip() {
    let privacy = "agent".withCString { nw_privacy_context_create($0) }
    let endpoint = "1.1.1.1".withCString { host in
        "443".withCString { port in
            nw_endpoint_create_host(host, port)
        }
    }
    nw_privacy_context_add_proxy(privacy, nw_proxy_config_create_socksv5(endpoint))
    nw_privacy_context_disable_logging(privacy)
    nw_privacy_context_flush_cache(privacy)
    let resolver = "dns.example.invalid".withCString { nw_resolver_config_create_tls($0) }
    nw_resolver_config_add_server_address(resolver, endpoint)
    nw_privacy_context_require_encrypted_name_resolution(privacy, true, resolver)
    nw_privacy_context_clear_proxies(privacy)
    _ = "https://dns.example.invalid/dns-query".withCString { nw_resolver_config_create_https($0) }
}

func testCIPMetadataGetSetRoundTrip() {
    let metadata = nw_ip_create_metadata()
    nw_ip_metadata_set_ecn_flag(metadata, nw_ip_ecn_flag_ce)
    expect(nw_ip_metadata_get_ecn_flag(metadata) == nw_ip_ecn_flag_ce, "ecn")
    nw_ip_metadata_set_service_class(metadata, nw_service_class_background)
    expect(nw_ip_metadata_get_service_class(metadata) == nw_service_class_background, "service class")
    expect(nw_ip_metadata_get_receive_time(metadata) == 0, "receive time default")
}

func testCParametersProhibitInterfaceStores() {
    let parameters = nw_parameters_create()
    let report = nw_connection_create_new_data_transfer_report(
        nw_connection_create(
            "127.0.0.1".withCString { host in
                "80".withCString { port in
                    nw_endpoint_create_host(host, port)
                }
            },
            parameters
        )
    )
    let interface = nw_data_transfer_report_copy_path_interface(report, 0)
    nw_parameters_prohibit_interface(parameters, interface)
}
