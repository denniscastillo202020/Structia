import sys

path = sys.argv[1]
with open(path) as f:
    content = f.read()

is_kts = path.endswith(".kts")

if "CM_KEYSTORE_PATH" in content:
    print("Ya configurado, no se modifica.")
else:
    if is_kts:
        signing_block = """
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("CM_KEYSTORE_PATH"))
            storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("CM_KEY_ALIAS")
            keyPassword = System.getenv("CM_KEY_PASSWORD")
        }
    }
"""
        content = content.replace("android {", "android {" + signing_block, 1)
        content = content.replace(
            'signingConfig = signingConfigs.getByName("debug")',
            'signingConfig = signingConfigs.getByName("release")',
        )
    else:
        signing_block = """
    signingConfigs {
        release {
            storeFile file(System.getenv("CM_KEYSTORE_PATH"))
            storePassword System.getenv("CM_KEYSTORE_PASSWORD")
            keyAlias System.getenv("CM_KEY_ALIAS")
            keyPassword System.getenv("CM_KEY_PASSWORD")
        }
    }
"""
        content = content.replace("android {", "android {" + signing_block, 1)
        content = content.replace(
            "signingConfig signingConfigs.debug",
            "signingConfig signingConfigs.release",
        )

    with open(path, "w") as f:
        f.write(content)
    print("Firma configurada correctamente.")
