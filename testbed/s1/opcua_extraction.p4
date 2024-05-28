/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/
const bit<16> TYPE_IPV4 = 0x800;
const bit<16> IPV4_LEN = 16w20;
const bit<24> OPN = 0x4f504e; //OPN = OpenSecureChannel message type

// supported certificate lengths: 2048*100. Set to 20 for testing purposes.
#ifndef NUM_WORDS
	#define NUM_WORDS 20
#endif

#define CHUNK_SIZE 2048
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
    bit<3> flags;
    bit<9> window;
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
    opcua_security_hdr4_cert_t[100] opcuaSenderCertificate;
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
            _ : accept;    // For other protocols, skip to accept
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
        packet.extract(hdr.opcua_security_hdr2_pol, (bit<32>)(hdr.opcua_security_hdr1.securityPolicyUriLength * 8));
        transition parse_opcua_security_hdr3;
    }

    state parse_opcua_security_hdr3 {
        packet.extract(hdr.opcua_security_hdr3_certLength);
        transition check_cert_length;
    }

    state check_cert_length {
        // The last block is always the one with variable length
        transition select(hdr.opcua_security_hdr3_certLength.senderCertificateLength > 255) {
            0 : parse_certificate_only_ending_part;
            1 : parse_certificate;
        }
    }

    state parse_certificate {
        packet.extract(hdr.opcua_senderCertificate.next);
        
        // We read by blocks of 256 bytes. If the certificate is not fully read, we need to read the next block.
        transition select(hdr.opcua_security_hdr3_certLength.senderCertificateLength / 256 - (hdr.opcua_senderCertificate.lastIndex + 1) > 1) {
            0 : parse_opcua_security_hdr6_thumb;
            _ : parse_opcua_security_hdr4;
        }
    }

    state parse_certificate_ending_part {
        // We calculate the length of the last certificate block
        bit<32> calculated_length = (bit<32>)(hdr.opcua_security_hdr3_certLength.senderCertificateLength - (hdr.opcua_senderCertificate.lastIndex * 256));
        packet.extract(hdr.opcuaSenderCertificateFinal, (bit<32>)(calculated_length));
        transition parse_opcua_security_hdr6_thumb;
    }

    state parse_certificate_only_ending_part {
        packet.extract(hdr.opcuaSenderCertificateFinal, (bit<32>)(calculated_length));
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

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action forward_to_port(bit<9> egress_port) {
        standard_metadata.egress_spec = egress_port;
    }

    table dmac_forward {
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        actions = {
            forward_to_port;
            drop;
        }
        size = 4;
        default_action = drop;
    }

    apply {
        dmac_forward.apply();
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

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
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
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

//switch architecture
V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;
