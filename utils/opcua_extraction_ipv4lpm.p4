/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> IPV4_LEN = 16w20;
const bit<24> OPN = 0x4f504e; //OPN = OpenSecureChannel message type
const bit<32> NULLCERTSTRING = 0xffffffff; // Value used for indicating that the security policy is None and there will be no certificate

// supported certificate lengths: 2048*100.
#define CHUNK_SIZE 2048
#define MAX_CHUNKS 100

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}header tcp_t {
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
    bit<8> nop;
    bit<8> nop2;
    bit<80> timestamps;
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

struct tcp_metadata_t
{
    bit<16> full_length; //ipv4.totalLen - 20
    bit<16> full_length_in_bytes;
    bit<16> header_length;
    bit<16> header_length_in_bytes;
    bit<16> payload_length;
    bit<16> payload_length_in_bytes;
}

struct metadata {
    tcp_metadata_t tcp_metadata;
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

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    bit<32> policyUriLength_bits;
    bit<32> cert_bits;
    bit<32> cert_bytes;
    bit<8> hex1;
    bit<8> hex2;
    bit<8> hex3;
    bit<8> hex4;
    bit<32> remaining;

    state start {
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
            6: parse_tcp;  // Protocol 6 corresponds to TCP
            _: accept;    // For other protocols, skip to accept
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);

        meta.tcp_metadata.full_length = (hdr.ipv4.totalLen - IPV4_LEN) * 8;
        meta.tcp_metadata.header_length = (((bit<16>)hdr.tcp.dataOffset) << 5);
        meta.tcp_metadata.payload_length = meta.tcp_metadata.full_length - meta.tcp_metadata.header_length;

        // meta.tcp_metadata.full_length_in_bytes =  (hdr.ipv4.totalLen - IPV4_LEN);
        // meta.tcp_metadata.header_length_in_bytes = (bit<16>)hdr.tcp.dataOffset << 2;
        // meta.tcp_metadata.payload_length_in_bytes = (hdr.ipv4.totalLen - IPV4_LEN) - ((bit<16>)hdr.tcp.dataOffset << 2);

        transition select(meta.tcp_metadata.payload_length) {
            0 : accept;
            _ : maybe_parse_opcua;
        }
    }

    state maybe_parse_opcua {
        transition select(hdr.tcp.dstPort) {         
            4840 : parse_opcua_hdr;  
            default : check_src_port;
        }
    }

    state check_src_port {
        transition select(hdr.tcp.srcPort) {
            4840 : parse_opcua_hdr;
            default : accept;
        }
    }

    state parse_opcua_hdr {
        packet.extract(hdr.tcp_options);
        packet.extract(hdr.opcua); 
        transition select(hdr.opcua.messageType) {
            OPN : parse_opcua_security_hdr1;
            default : accept;
        }
    }

    state parse_opcua_security_hdr1 {
        packet.extract(hdr.opcua_security_hdr1);
        transition parse_opcua_security_hdr2;
    }

    state parse_opcua_security_hdr2 {
        // First I need to convert the securityPolicyUriLength to little endian
        hex1 = hdr.opcua_security_hdr1.securityPolicyUriLength[31:24];
        hex2 = hdr.opcua_security_hdr1.securityPolicyUriLength[23:16];
        hex3 = hdr.opcua_security_hdr1.securityPolicyUriLength[15:8];
        hex4 = hdr.opcua_security_hdr1.securityPolicyUriLength[7:0];

        policyUriLength_bits = (bit<32>)(hex4 ++ hex3 ++ hex2 ++ hex1);
        policyUriLength_bits = policyUriLength_bits * 32w8;

        // Debugging logs
        // log_msg("URI LENGTH BITS: {}", {policyUriLength_bits});
        // log_msg("hex1: {}, hex2: {}, hex3: {}, hex4: {}", {hex1, hex2, hex3, hex4});
        packet.extract(hdr.opcua_security_hdr2_pol, policyUriLength_bits);
        transition parse_opcua_security_hdr3;
    }

    state parse_opcua_security_hdr3 {
        packet.extract(hdr.opcua_security_hdr3_certLength);

        // Convert the senderCertificateLength to little endian
        hex1 = hdr.opcua_security_hdr3_certLength.senderCertificateLength[31:24];
        hex2 = hdr.opcua_security_hdr3_certLength.senderCertificateLength[23:16];
        hex3 = hdr.opcua_security_hdr3_certLength.senderCertificateLength[15:8];
        hex4 = hdr.opcua_security_hdr3_certLength.senderCertificateLength[7:0];

        cert_bytes = (bit<32>)(hex4 ++ hex3 ++ hex2 ++ hex1);
        remaining = cert_bytes;
        // log_msg("CERT LENGTH BYTES: {}", {cert_bytes});
        cert_bits = cert_bytes * 32w8;

        // Debugging logs
        // log_msg("CERT LENGTH BITS: {}", {cert_bits});
        // log_msg("hex1: {}, hex2: {}, hex3: {}, hex4: {}", {hex1, hex2, hex3, hex4});

        transition select((bit<32>)(hdr.opcua_security_hdr3_certLength.senderCertificateLength)) {
            // 0xffffffff is the "Null" string used for Security Policy None: accept for testing purposes, should be set to drop in production!
            NULLCERTSTRING : accept;
            _ : check_cert_length;
        }
    }

    state check_cert_length {
        // The last block is always the one with variable length
        // log_msg("CERT LENGTH BYTES: {}", {cert_bytes});
        transition select(cert_bytes > 255) {
            false : parse_certificate_only_ending_part;
            true : parse_certificate;
        }
    }

    state parse_certificate {
        packet.extract(hdr.opcuaSenderCertificate.next);
        remaining = remaining - 256;
        // log_msg("CERT LENGTH BYTES REMAINING: {}", {remaining});
        transition select(remaining > 255){
            false : parse_certificate_ending_part;
            true : parse_certificate;
        }
    }

    state parse_certificate_ending_part {
        // We calculate the length of the last certificate block
        packet.extract(hdr.opcuaSenderCertificateFinal, (bit<32>)(remaining * 8));
        transition parse_opcua_security_hdr6_thumb;
    }

    state parse_certificate_only_ending_part {
        packet.extract(hdr.opcuaSenderCertificateFinal, (bit<32>)(cert_bytes));
        transition parse_opcua_security_hdr6_thumb;
    }

    state parse_opcua_security_hdr6_thumb {
        packet.extract(hdr.opcua_security_hdr_thumb);
        transition accept;
    }
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    bit<160> certThumbprint;

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
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


    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
            if (hdr.opcua.messageType == OPN) {
                // debug.apply();
                thumbprint_table.apply();
            }
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
        update_checksum(
        hdr.ipv4.isValid(),
            { hdr.ipv4.version,
              hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

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


/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;