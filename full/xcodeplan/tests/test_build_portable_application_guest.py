from __future__ import annotations

from pathlib import Path
import unittest


HERE = Path(__file__).resolve().parent
XCODEPLAN = HERE.parent


class PortableApplicationGuestDriverTests(unittest.TestCase):
    def test_driver_owns_complete_generic_compile_package_launch_path(self) -> None:
        script = (XCODEPLAN / "build_portable_application_guest.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn("mapfile -d '' -t relative_sources", script)
        self.assertIn('relative_sources <"$output/app-sources.nul"', script)
        self.assertIn('"${app_sources[@]}"', script)
        self.assertIn("GeneratedSceneBootstrap.swift", script)
        self.assertIn("PortableUIKitApplicationHost.swift", script)
        self.assertIn("RunLoop.swift", script)
        self.assertNotIn("ReminderSceneRuntimeSupport", script)
        self.assertNotIn("Reminder", script)
        self.assertIn('-v "$source_root:/app:ro"', script)
        self.assertIn('-v "$platform:/platform:ro"', script)
        self.assertIn('-v "$SUPPORT_ROOT:/support:ro"', script)
        self.assertIn("core_guest_package.py", script)
        self.assertIn("materialize_application_bundle.py", script)
        self.assertIn("-load-plugin-executable", script)
        self.assertIn("developer_tools_support_object", script)
        self.assertIn("focus_widget_guest_attest.pl", script)
        self.assertIn("PORTABLE_UIKIT_HOST_ACTIVE windows=1", script)
        self.assertIn("PORTABLE_UIKIT_HOST_LOOP_OK turns=3 paced=true", script)
        self.assertIn("PORTABLE_APPLICATION_GUEST_OK", script)

    def test_legacy_static_link_closes_uuid_compatibility_symbols(self) -> None:
        script = (XCODEPLAN / "build_and_run_reminder_scene_guest.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn('"$full/foundation/cshims/uuid.o"', script)
        self.assertIn('"$full/foundation/essentials/uuid_compat.o"', script)


if __name__ == "__main__":
    unittest.main()
