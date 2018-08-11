#!/usr/bin/swift

import Foundation
import CoreServices

let QUARANTINE_SUCCESS: Int = 0
let QUARANTINE_FAILURE: Int = 1

if (CommandLine.arguments.count < 4) {
  print("Insufficient parameters: this script needs file_path, data_url, and origin_url")
  exit(Int32(QUARANTINE_FAILURE))
}

let filepath = CommandLine.arguments[1]
let agent: String = "Homebrew-Cask"
let dataUrl: String = CommandLine.arguments[2]
let originUrl: String = CommandLine.arguments[3]

let quarantineProperties: [String: Any] = [
  kLSQuarantineAgentNameKey as String: agent,
  kLSQuarantineTypeKey as String: kLSQuarantineTypeWebDownload,
  kLSQuarantineDataURLKey as String: dataUrl,
  kLSQuarantineOriginURLKey as String: originUrl
]

let dataLocationUrl: NSURL = NSURL.init(fileURLWithPath: filepath)
var errorBag: NSError?

if (dataLocationUrl.checkResourceIsReachableAndReturnError(&errorBag)) {
  do {
    try dataLocationUrl.setResourceValue(quarantineProperties as NSDictionary, forKey: URLResourceKey.quarantinePropertiesKey)
  }
  catch {
    let errorString: String = "Homebrew-Cask quarantiner: unable to quarantine \(dataLocationUrl.absoluteString!): \(error.localizedDescription)"
    NSLog(errorString)
    exit(Int32(QUARANTINE_FAILURE))
  }
}
else {
  let errorString: String = "Homebrew-Cask quarantiner: unable to quarantine \(dataLocationUrl.absoluteString!): \(errorBag!.localizedDescription)"
  NSLog(errorString)
  exit(Int32(QUARANTINE_FAILURE))
}

exit(Int32(QUARANTINE_SUCCESS))
