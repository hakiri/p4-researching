#ifndef __IPV4_FORWARD__
#define __IPV4_FORWARD__

#include "headers.p4"
#include "actions.p4"

control ipv4_forwarding(
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    action unknown_source(){
        // Send digest to controller
        digest<mac_learn_digest_t>((bit<32>) 1024,
            { hdr.ethernet.srcAddr,
              standard_metadata.ingress_port
            });
    }

    action ipv4_forward(bit<48> dstAddr, bit<9> port){
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
            unknown_source;
            drop;
        }
        size = 1024;
        default_action = unknown_source();
    }

    apply {
        if(hdr.ipv4.isValid()){
            ipv4_lpm.apply();
        }
    }
}

#endif