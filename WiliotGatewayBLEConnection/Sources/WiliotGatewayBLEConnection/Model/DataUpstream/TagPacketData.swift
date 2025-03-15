//
//  Packet.swift

import Foundation

struct TagPacketData: Encodable {
    let payload: String
    /// timestamp in milliseconds
    var timestamp: TimeInterval = Date().milisecondsFrom1970()
    var sequenceId: Int?
    var nfpkt: Int?
    var rssi: Int?
}


