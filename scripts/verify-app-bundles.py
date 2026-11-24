#!/usr/bin/env python3
"""Check the actual packaged Info.plists before distributing an IPA."""
import plistlib
import sys
from pathlib import Path

def require(condition, message):
    if not condition:
        raise SystemExit(f"::error::{message}")

def read_bundle(folder):
    with (folder / "Info.plist").open("rb") as handle:
        info = plistlib.load(handle)
    for key in ("CFBundleName", "CFBundleIdentifier", "CFBundleExecutable",
                "CFBundlePackageType", "CFBundleVersion", "CFBundleShortVersionString"):
        value = info.get(key)
        require(isinstance(value, str) and bool(value.strip()) and "$(" not in value,
                f"{folder.name}: {key} must be a resolved nonempty string")
    require((folder / info["CFBundleExecutable"]).is_file(),
            f"{folder.name}: executable missing")
    return info

def main(app):
    host = read_bundle(app)
    require(host["CFBundleIdentifier"] == "com.viepn.aikey", "Unexpected host bundle ID")
    require(host["CFBundlePackageType"] == "APPL", "Host bundle type must be APPL")
    expected = {
        "ViePNKeyboardExtension.appex": ("keyboard", "com.apple.keyboard-service", "KeyboardViewController"),
        "ViePNShareExtension.appex": ("share", "com.apple.share-services", "ShareViewController"),
    }
    for name, (suffix, point, principal) in expected.items():
        folder = app / "PlugIns" / name
        ext = read_bundle(folder)
        require(ext["CFBundlePackageType"] == "XPC!", f"{name}: invalid package type")
        require(ext["CFBundleIdentifier"] == host["CFBundleIdentifier"] + "." + suffix,
                f"{name}: invalid bundle identifier")
        for key in ("CFBundleVersion", "CFBundleShortVersionString"):
            require(ext[key] == host[key], f"{name}: {key} differs from containing app")
        config = ext.get("NSExtension", {})
        require(config.get("NSExtensionPointIdentifier") == point, f"{name}: invalid extension point")
        klass = config.get("NSExtensionPrincipalClass", "")
        require(klass.endswith("." + principal) and "$(" not in klass, f"{name}: invalid principal class")
        print(f"PASS {name}: {ext['CFBundleName']} ({ext['CFBundleIdentifier']})")
    print("PASS host and both extensions: bundle metadata and versions")

if __name__ == "__main__":
    main(Path(sys.argv[1]))
