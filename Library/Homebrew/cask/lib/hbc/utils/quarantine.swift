#!/usr/bin/swift

import Foundation
import CoreServices

let QUARANTINE_SUCCESS: Int = 0
let QUARANTINE_FAILURE: Int = 1

if (CommandLine.arguments.count < 3) {
  print("Insufficient parameters: this script needs file_path and data_url")
  exit(Int32(QUARANTINE_FAILURE))
}

let filepath = CommandLine.arguments[1]
let agent: String = "Homebrew-Cask"
let bundle: String = "sh.brew.cask"
let dataUrl: String = CommandLine.arguments[2]

let quarantineProperties: NSMutableDictionary = NSMutableDictionary()

quarantineProperties.setValue(agent, forKey: kLSQuarantineAgentNameKey as String)
quarantineProperties.setValue(bundle, forKey: kLSQuarantineAgentBundleIdentifierKey as String)
quarantineProperties.setValue(kLSQuarantineTypeWebDownload, forKey: kLSQuarantineTypeKey as String)
quarantineProperties.setValue(dataUrl, forKey: kLSQuarantineDataURLKey as String)

let dataLocationUrl: NSURL = NSURL.init(fileURLWithPath: filepath)
var errorBag: NSError?

if (dataLocationUrl.checkResourceIsReachableAndReturnError(&errorBag)) {
  do {
    try dataLocationUrl.setResourceValue(quarantineProperties, forKey: URLResourceKey.quarantinePropertiesKey)
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
