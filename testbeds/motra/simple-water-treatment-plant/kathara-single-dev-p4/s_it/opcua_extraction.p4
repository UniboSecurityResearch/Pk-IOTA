/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> IPV4_LEN = 16w20;
const bit<16> OPCUA_PORT = 4840;
const bit<16> OPCUA_HEADER_BITS = 16w64;
const bit<24> OPN = 0x4f504e;
const bit<32> NULLCERTSTRING = 0xffffffff;
const bit<32> MAX_CERT_BYTES = 32w25855;

#define MAX_CHUNKS 100

typedef bit<48> macAddr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> sequence;
    bit<32> ack;
    bit<4> dataOffset;
    bit<4> reserved;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header tcp_options_t {
    varbit<320> options;
}

header opcua_t {
    bit<24> messageType;
    bit<8> isFinal;
    bit<32> messageSize;
}

header opcua_security_hdr1_t {
    bit<32> secureChannelId;
    int<32> securityPolicyUriLength;
}

header opcua_security_hdr2_pol_t {
    varbit<2048> securityPolicyUri;
}

header opcua_security_hdr3_certLength_t {
    int<32> senderCertificateLength;
}

header opcua_security_hdr4_cert_t {
    bit<2048> senderCertificate;
}

header opcua_security_hdr5_cert_final_t {
    varbit<2048> remainingSenderCertificate;
}

header opcua_security_hdr6_thumb_t {
    int<32> receiverCertificateThumbprintLength;
    bit<160> receiverCertificateThumbprint;
}

struct tcp_metadata_t {
    bit<16> full_length;
    bit<16> header_length;
    bit<16> payload_length;
    bit<16> options_length;
}

struct metadata {
    tcp_metadata_t tcp_metadata;
    bit<1> cert_too_large;
}

struct headers {
    ethernet_t ethernet;
    ipv4_t ipv4;
    tcp_t tcp;
    tcp_options_t tcp_options;
    opcua_t opcua;
    opcua_security_hdr1_t opcua_security_hdr1;
    opcua_security_hdr2_pol_t opcua_security_hdr2_pol;
    opcua_security_hdr3_certLength_t opcua_security_hdr3_certLength;
    opcua_security_hdr4_cert_t[MAX_CHUNKS] opcuaSenderCertificate;
    opcua_security_hdr5_cert_final_t opcuaSenderCertificateFinal;
    opcua_security_hdr6_thumb_t opcua_security_hdr_thumb;
}

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    bit<32> policyUriLength_bits;
    bit<32> cert_bytes;
    bit<8> hex1;
    bit<8> hex2;
    bit<8> hex3;
    bit<8> hex4;
    bit<32> remaining;

    state start {
        meta.cert_too_large = 0;
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            6: parse_tcp;
            default: accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);

        meta.tcp_metadata.full_length = (hdr.ipv4.totalLen - IPV4_LEN) * 8;
        meta.tcp_metadata.header_length = ((bit<16>)hdr.tcp.dataOffset) << 5;
        meta.tcp_metadata.payload_length = meta.tcp_metadata.full_length - meta.tcp_metadata.header_length;
        meta.tcp_metadata.options_length = meta.tcp_metadata.header_length - 16w160;

        transition select(meta.tcp_metadata.payload_length) {
            0: accept;
            default: maybe_parse_opcua;
        }
    }

    state maybe_parse_opcua {
        transition select(hdr.tcp.dstPort) {
            OPCUA_PORT: check_opcua_payload_length;
            default: check_src_port;
        }
    }

    state check_src_port {
        transition select(hdr.tcp.srcPort) {
            OPCUA_PORT: check_opcua_payload_length;
            default: accept;
        }
    }

    state check_opcua_payload_length {
        transition select(meta.tcp_metadata.payload_length < OPCUA_HEADER_BITS) {
            true: accept;
            false: parse_opcua_after_options;
        }
    }

    state parse_opcua_after_options {
        transition select(meta.tcp_metadata.options_length) {
            0: parse_opcua_hdr;
            default: parse_tcp_options;
        }
    }

    state parse_tcp_options {
        packet.extract(hdr.tcp_options, (bit<32>)meta.tcp_metadata.options_length);
        transition parse_opcua_hdr;
    }

    state parse_opcua_hdr {
        packet.extract(hdr.opcua);
        transition select(hdr.opcua.messageType) {
            OPN: parse_opcua_security_hdr1;
            default: accept;
        }
    }

    state parse_opcua_security_hdr1 {
        packet.extract(hdr.opcua_security_hdr1);
        transition parse_opcua_security_hdr2;
    }

    state parse_opcua_security_hdr2 {
        hex1 = hdr.opcua_security_hdr1.securityPolicyUriLength[31:24];
        hex2 = hdr.opcua_security_hdr1.securityPolicyUriLength[23:16];
        hex3 = hdr.opcua_security_hdr1.securityPolicyUriLength[15:8];
        hex4 = hdr.opcua_security_hdr1.securityPolicyUriLength[7:0];

        policyUriLength_bits = (bit<32>)(hex4 ++ hex3 ++ hex2 ++ hex1);
        policyUriLength_bits = policyUriLength_bits * 32w8;

        packet.extract(hdr.opcua_security_hdr2_pol, policyUriLength_bits);
        transition parse_opcua_security_hdr3;
    }

    state parse_opcua_security_hdr3 {
        packet.extract(hdr.opcua_security_hdr3_certLength);

        hex1 = hdr.opcua_security_hdr3_certLength.senderCertificateLength[31:24];
        hex2 = hdr.opcua_security_hdr3_certLength.senderCertificateLength[23:16];
        hex3 = hdr.opcua_security_hdr3_certLength.senderCertificateLength[15:8];
        hex4 = hdr.opcua_security_hdr3_certLength.senderCertificateLength[7:0];

        cert_bytes = (bit<32>)(hex4 ++ hex3 ++ hex2 ++ hex1);
        remaining = cert_bytes;

        transition select((bit<32>)hdr.opcua_security_hdr3_certLength.senderCertificateLength) {
            NULLCERTSTRING: accept;
            default: check_cert_upper_bound;
        }
    }

    state check_cert_upper_bound {
        transition select(cert_bytes > MAX_CERT_BYTES) {
            true: mark_certificate_too_large;
            false: check_cert_length;
        }
    }

    state mark_certificate_too_large {
        meta.cert_too_large = 1;
        transition accept;
    }

    state check_cert_length {
        transition select(cert_bytes > 255) {
            false: parse_certificate_only_ending_part;
            true: parse_certificate;
        }
    }

    state parse_certificate {
        packet.extract(hdr.opcuaSenderCertificate.next);
        remaining = remaining - 256;
        transition select(remaining > 255) {
            false: parse_certificate_ending_part;
            true: parse_certificate;
        }
    }

    state parse_certificate_ending_part {
        packet.extract(hdr.opcuaSenderCertificateFinal, (bit<32>)(remaining * 8));
        transition parse_opcua_security_hdr6_thumb;
    }

    state parse_certificate_only_ending_part {
        packet.extract(hdr.opcuaSenderCertificateFinal, (bit<32>)(cert_bytes * 8));
        transition parse_opcua_security_hdr6_thumb;
    }

    state parse_opcua_security_hdr6_thumb {
        packet.extract(hdr.opcua_security_hdr_thumb);
        transition accept;
    }
}

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action forward_to_port(bit<9> egress_port) {
        standard_metadata.egress_spec = egress_port;
    }

    table thumbprint_table {
        key = {
            hdr.opcua_security_hdr_thumb.receiverCertificateThumbprint : exact;
        }
        actions = {
            NoAction;
            drop;
        }
        size = 1024;
        default_action = drop;
    }

    table dmac_forward {
        key = {
            hdr.ethernet.dstAddr : exact;
        }
        actions = {
            forward_to_port;
            drop;
        }
        size = 256;
        default_action = drop;
    }

    apply {
        dmac_forward.apply();
        if (meta.cert_too_large == 1w1) {
            drop();
        } else if (hdr.opcua_security_hdr_thumb.isValid()) {
            thumbprint_table.apply();
        }
    }
}

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.tcp_options);
        packet.emit(hdr.opcua);
        packet.emit(hdr.opcua_security_hdr1);
        packet.emit(hdr.opcua_security_hdr2_pol);
        packet.emit(hdr.opcua_security_hdr3_certLength);
        packet.emit(hdr.opcuaSenderCertificate);
        packet.emit(hdr.opcuaSenderCertificateFinal);
        packet.emit(hdr.opcua_security_hdr_thumb);
    }
}

V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;
