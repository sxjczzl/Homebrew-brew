#!/usr/bin/env swift

import Foundation

struct swifterr: TextOutputStream {
	public static var stream = swifterr()
	mutating func write(_ string: String) { fputs(string, stderr) }
}

/// https://stackoverflow.com/q/38343186
extension URL {
	/// Get extended attribute.
	func getExtendedAttribute(forName name: String) throws -> Data  {
		let data = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Data in
			// Determine attribute size:
			let length = getxattr(fileSystemPath, name, nil, 0, 0, XATTR_NOFOLLOW)
			guard length >= 0 else { throw URL.posixError(errno) }

			// Create buffer with required size:
			var data = Data(count: length)

			// Retrieve attribute:
			let result =  data.withUnsafeMutableBytes { [count = data.count] in
				getxattr(fileSystemPath, name, $0.baseAddress, count, 0, 0)
			}
			guard result >= 0 else { throw URL.posixError(errno) }
			return data
		}
		return data
	}

	/// Set extended attribute.
	func setExtendedAttribute(data: Data, forName name: String) throws {
		try self.withUnsafeFileSystemRepresentation { fileSystemPath in
			let result = data.withUnsafeBytes {
				setxattr(fileSystemPath, name, $0.baseAddress, data.count, 0, XATTR_NOFOLLOW)
			}
			guard result >= 0 else { throw URL.posixError(errno) }
		}
	}

	/// Remove extended attribute.
	func removeExtendedAttribute(forName name: String) throws {
		try self.withUnsafeFileSystemRepresentation { fileSystemPath in
			let result = removexattr(fileSystemPath, name, XATTR_NOFOLLOW)
			guard result >= 0 else { throw URL.posixError(errno) }
		}
	}

	/// Helper function to create an NSError from a Unix errno.
	private static func posixError(_ err: Int32) -> NSError {
		return NSError(domain: NSPOSIXErrorDomain, code: Int(err),
					   userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(err))])
	}
}

/// Get and print the specified extended attribute
func get(attr: String, src: String) -> Int32 {

	let xattr: Data

	let source: URL = URL.init(fileURLWithPath: src)

	do {
		xattr = try source.getExtendedAttribute(forName: attr)
	}
	catch {
		print("\(source.path): \(error.localizedDescription)", to: &swifterr.stream)
		return 3
	}

	if let result: String = String.init(data: xattr, encoding: String.Encoding.utf8) {
		print(result)
		return 0
	}
	else {
		print("Unable to parse attribute data", to: &swifterr.stream)
		return 3
	}
}

func set(attr: String, value: String, dst: ArraySlice<String>, recursive: Bool) -> Int32 {

	if let xattr: Data = value.data(using: String.Encoding.utf8) {

		for path in dst {
			let destination: URL = URL.init(fileURLWithPath: path)

			do {
				try destination.setExtendedAttribute(data: xattr, forName: attr)
			}
			catch {
				print("\(destination.path): \(error.localizedDescription)", to: &swifterr.stream)
				return 3
			}

			if (recursive) {
				let fs : FileManager = FileManager.default

				if let tree : NSEnumerator = fs.enumerator(atPath: destination.path) {
					while let x: String = tree.nextObject() as? String {
						let path: URL = URL.init(fileURLWithPath: x, relativeTo: destination)

						do {
							try path.setExtendedAttribute(data: xattr, forName: attr)
						}
						catch {
							print("\(path.path): \(error.localizedDescription)", to: &swifterr.stream)
							return 3
						}
					}
				}
				else {
					print("\(destination.path): unable to get directory tree", to: &swifterr.stream)
					return 3
				}
			}
		}
	}
	else {
		print("Unable to parse attribute data", to: &swifterr.stream)
		return 3
	}

	return 0
}

func delete(attr: String, src: ArraySlice<String>) -> Int32 {
	for path in src {
		let source: URL = URL.init(fileURLWithPath: path)

		do {
			try source.removeExtendedAttribute(forName: attr)
		}
		catch {
			print("\(source.path): \(error.localizedDescription)", to: &swifterr.stream)
			return 3
		}
	}
	return 0
}

var result: Int32 = 2

if (CommandLine.arguments.count >= 2) {
	switch CommandLine.arguments[1] {
	case "get":
		if (CommandLine.arguments.count == 4) {
			result = get(attr: CommandLine.arguments[2], src: CommandLine.arguments[3])
		}
	case "set":
		if (CommandLine.arguments.count >= 5) {
			result = set(attr: CommandLine.arguments[2], value: CommandLine.arguments[3], dst: CommandLine.arguments.suffix(from: 4), recursive: false)
		}
	case "set-recursive":
		if (CommandLine.arguments.count >= 5) {
			result = set(attr: CommandLine.arguments[2], value: CommandLine.arguments[3], dst: CommandLine.arguments.suffix(from: 4), recursive: true)
		}
	case "remove":
		if (CommandLine.arguments.count >= 4) {
			result = delete(attr: CommandLine.arguments[2], src: CommandLine.arguments.suffix(from: 3))
		}
	default:
		result = 2
	}
}

if (result == 2) {
	print("Args: \(CommandLine.arguments)")
	print("Usage:")
	print("\txattr.swift get attribute_name path")
	print("\txattr.swift set attribute_name value path [...]")
	print("\txattr.swift set-recursive attribute_name value path [...]")
	print("\txattr.swift remove attribute_name path [...]")
}

exit(result)
