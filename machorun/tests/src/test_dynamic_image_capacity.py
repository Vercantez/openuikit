from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


def sources() -> dict[str, str]:
    names = (
        "src/machorun.h",
        "src/util.c",
        "src/image_table.c",
        "src/image.c",
        "src/objc_notify.c",
        "src/tlv.c",
        "scripts/build.sh",
        "scripts/image_capacity_gate.sh",
    )
    return {name: (ROOT / name).read_text(encoding="utf-8") for name in names}


def validate(tree: dict[str, str]) -> None:
    combined = "\n".join(tree.values())
    required = {
        "src/machorun.h": ("mr_image **images;", "size_t    image_capacity;"),
        "src/util.c": (
            "required > SIZE_MAX / element_size",
            "next > SIZE_MAX / element_size",
            "grown = realloc(storage, new_bytes)",
        ),
        "src/image_table.c": (
            "if (MR.nimages == INT_MAX)",
            "MR.images = mr_grow_array",
            "MR.images[MR.nimages++] = im",
        ),
        "src/image.c": ("mr_image_append(im);",),
        "src/objc_notify.c": (
            "static mr_image **batch;",
            '"Objective-C mapped-image metadata"',
            '"Objective-C mapped-image batch"',
        ),
        "src/tlv.c": (
            "static tlv_template *templates;",
            '"TLV image template table"',
        ),
        "scripts/build.sh": ('"$ROOT"/src/image_table.c',),
        "scripts/image_capacity_gate.sh": (
            "IMAGE_COUNT=${IMAGE_COUNT:-130}",
            'if [ "$IMAGE_COUNT" -le 128 ]',
            "MACHORUN_IMAGE_CAPACITY_RUNTIME_OK",
        ),
    }
    if "MR_MAX_IMAGES" in combined:
        raise ValueError("fixed MR_MAX_IMAGES ceiling survived")
    for name, tokens in required.items():
        for token in tokens:
            if token not in tree[name]:
                raise ValueError(f"{name} is missing {token!r}")


class DynamicImageCapacitySourceTests(unittest.TestCase):
    def test_current_tree_has_no_fixed_image_table(self) -> None:
        validate(sources())

    def test_fixed_array_mutation_is_rejected(self) -> None:
        tree = sources()
        tree["src/machorun.h"] = tree["src/machorun.h"].replace(
            "mr_image **images;", "mr_image *images[64];", 1
        )
        with self.assertRaisesRegex(ValueError, r"missing 'mr_image \*\*images;"):
            validate(tree)

    def test_removed_overflow_guard_mutation_is_rejected(self) -> None:
        tree = sources()
        tree["src/util.c"] = tree["src/util.c"].replace(
            "required > SIZE_MAX / element_size", "required > SIZE_MAX", 1
        )
        with self.assertRaisesRegex(ValueError, "required > SIZE_MAX"):
            validate(tree)

    def test_128_image_regression_is_rejected(self) -> None:
        tree = sources()
        tree["scripts/image_capacity_gate.sh"] = tree[
            "scripts/image_capacity_gate.sh"
        ].replace("IMAGE_COUNT=${IMAGE_COUNT:-130}", "IMAGE_COUNT=${IMAGE_COUNT:-128}")
        with self.assertRaisesRegex(ValueError, "IMAGE_COUNT"):
            validate(tree)


if __name__ == "__main__":
    unittest.main()
