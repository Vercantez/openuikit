#!/usr/bin/env python3
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]


class DispatchBoundaryTests(unittest.TestCase):
    def test_darwin_job_layout_is_explicit(self) -> None:
        source = (ROOT / "full/shims/concpatch.c").read_text(encoding="utf-8")
        self.assertIn("offsetof(struct darwin_dispatch_class_metadata, invoke) == 0x30", source)
        self.assertNotIn("metadata + 0x18", source)
        self.assertIn("OPENUI_DISPATCH_QUEUE_MAIN_V1", source)
        self.assertIn("is_registered_global_queue", source)
        self.assertIn("if (voucher != NULL) conc_abort", source)
        self.assertIn("void *voucher_copy(void) { return NULL; }", source)
        self.assertIn("if (object != NULL) conc_abort", source)
        self.assertIn("uint64_t os_signpost_id_make_with_pointer", source)
        self.assertIn("return 0;", source)

    def test_host_boundary_rejects_guest_queue_structs(self) -> None:
        source = (ROOT / "full/dispatch/OpenDispatchHost.c").read_text(encoding="utf-8")
        self.assertIn("guest main-queue token crossed the ELF boundary", source)
        self.assertIn("unminted global queue pointer crossed the ELF boundary", source)
        self.assertIn("dispatch_async_f(checked_queue", source)
        self.assertIn("dispatch_main();", source)
        header = (ROOT / "full/dispatch/include/OpenDispatchABI.h").read_text(
            encoding="utf-8"
        )
        self.assertIn(
            "OPENUI_DISPATCH_EXPORT void *openui_dispatch_v1_get_global_queue",
            header,
        )

    def test_portable_module_is_real_asynchronous_surface(self) -> None:
        source = (ROOT / "full/dispatch/Dispatch.swift").read_text(encoding="utf-8")
        self.assertIn("public final class DispatchQueue", source)
        self.assertIn("public static let main", source)
        self.assertIn("public static func global", source)
        self.assertIn("openui_dispatch_v1_async", source)
        self.assertIn("Unmanaged.passRetained", source)
        self.assertNotIn("work()", source)


if __name__ == "__main__":
    unittest.main()
