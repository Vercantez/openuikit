"""Record a notification-permission answer for an app on a SHUT DOWN simulator
device, as tapping the alert would: a BBSectionInfo for the bundle, cloned
from the device's own com.apple.MobileSMS section with the identity fields
replaced and the app-specific custom-settings fields cleared, and
sectionInfoSettings.authorizationStatus set.
usage: bbseed.py <udid> <bundle-id> <display-name> <status: 1 denied | 2 authorized>"""
import os, plistlib, sys

udid, bid, name, status = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
p = os.path.expanduser(f"~/Library/Developer/CoreSimulator/Devices/{udid}/data/Library/BulletinBoard/VersionedSectionInfo.plist")
d = plistlib.load(open(p, "rb"))
a = plistlib.loads(d["sectionInfo"]["com.apple.MobileSMS"])
objs = a["$objects"]
root = objs[a["$top"]["root"].data]
null = plistlib.UID(0)  # "$null"

def string_uid(s):
    objs.append(s)
    return plistlib.UID(len(objs) - 1)

root["sectionID"] = string_uid(bid)
root["displayName"] = string_uid(name)
root["appName"] = string_uid(name)
for k in ("customSettingsBundle", "customSettingsDetailControllerClass"):
    if k in root:
        root[k] = null
settings = objs[root["sectionInfoSettings"].data]
settings["authorizationStatus"] = status
if "showsCustomSettingsLink" in settings:
    settings["showsCustomSettingsLink"] = False
d["sectionInfo"][bid] = plistlib.dumps(a, fmt=plistlib.FMT_BINARY)
plistlib.dump(d, open(p, "wb"), fmt=plistlib.FMT_BINARY)
print("seeded", bid, "authorizationStatus", status)
