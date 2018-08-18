#!/usr/bin/osascript --

use framework "Foundation"

on run(argv)
  if argv's length < 3 then
    error "Insufficient parameters"
  end if

  set quarantineProperties to { ¬
    kLSQuarantineAgentNameKey: "Homebrew-Cask", ¬
    kLSQuarantineTypeKey: my kLSQuarantineTypeWebDownload, ¬
    kLSQuarantineDataURLKey: argv's item 2, ¬
    kLSQuarantineOriginURLKey: argv's item 3 ¬
  }

  set dataLocationUrl to my NSURL's fileURLWithPath: argv's item 1

  set {resourceReachable, errorBag} to dataLocationUrl's ¬
    checkResourceIsReachableAndReturnError: reference

  if resourceReachable then
    set {quarantineSuccess, errorBag} to dataLocationUrl's ¬
      setResourceValue: quarantineProperties ¬
      forKey: my NSURLQuarantinePropertiesKey ¬
      |error|: reference

    if not quarantineSuccess then
      error errorBag's localizedDescription as text
    end if
  else
    error errorBag's localizedDescription as text
  end if
end run
