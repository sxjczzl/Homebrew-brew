#!/usr/bin/swift

import CoreFoundation
exit(CFBundleIsArchitectureLoadable(CPU_TYPE_X86_64) ? 0 : 1)
