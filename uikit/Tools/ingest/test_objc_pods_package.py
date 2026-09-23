"""objc_pods_package.py: CocoaPods file patterns, header layout, flags."""
import json
import os
import tempfile
import unittest

import objc_pods_package as g


def touch(root, rel, text=''):
    path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write(text)


class ObjCPodsPackageTests(unittest.TestCase):
    def test_spec_patterns(self):
        with tempfile.TemporaryDirectory() as d:
            for rel in ['SDWebImage/SDImageCache.m', 'SDWebImage/SDImageCache.h', 'SDWebImage/UIImage+WebP.m',
                        'SDWebImage/MKAnnotationView+WebCache.m', 'Classes/ios/A.m', 'Classes/ios/private/B.h',
                        'Classes/ios/.gitkeep', 'Example/Main.m']:
                touch(d, rel)
            spec = {'source_files': ['SDWebImage/{NS,SD,UI}*.{h,m}'],
                    'exclude_files': ['SDWebImage/UIImage+WebP.{h,m}']}
            self.assertEqual(g.pod_files(d, spec), ['SDWebImage/SDImageCache.h', 'SDWebImage/SDImageCache.m'])
            # a bare directory means its source and header files, recursively
            self.assertEqual(g.pod_files(d, {'source_files': ['Classes']}),
                             ['Classes/ios/A.m', 'Classes/ios/private/B.h'])
            self.assertEqual(g.pod_files(d, {'source_files': ['Classes/ios/*', 'Classes/ios/private/*']}),
                             ['Classes/ios/A.m', 'Classes/ios/private/B.h'])

    def test_generated_layout(self):
        with tempfile.TemporaryDirectory() as d:
            pods = os.path.join(d, 'pods')
            touch(pods, 'Artsy-UIColors/Classes/UIColor+ArtsyColors.h', '@interface UIColor (A) @end\n')
            touch(pods, 'Artsy-UIColors/Classes/UIColor+ArtsyColors.m', '#import "UIColor+ArtsyColors.h"\n')
            touch(pods, 'Artsy-UIColors/LICENSE', 'MIT')
            touch(pods, 'Fmt/Fmt.h')
            touch(pods, 'Fmt/Fmt.m')
            fixture = {
                'podspecs': {
                    'Artsy-UIColors': {'name': 'Artsy+UIColors', 'module': 'Artsy_UIColors',
                                       'source_files': ['Classes'], 'dependencies': [], 'frameworks': ['UIKit']},
                    'Fmt': {'name': 'Fmt', 'module': 'Fmt', 'source_files': ['Fmt.{h,m}'],
                            'requires_arc': False, 'dependencies': ['Artsy+UIColors'], 'frameworks': ['ImageIO']},
                },
                'header_names': {'Artsy-UIColors': ['Artsy+UIColors']},
            }
            spec = os.path.join(d, 'spec.json')
            json.dump(fixture, open(spec, 'w'))
            out = os.path.join(d, 'out')
            manifest = g.generate(pods, spec, out, '../uikit', vendor=True)
            inc = os.path.join(out, 'Targets', 'Artsy_UIColors', 'include')
            # the header under the module name and CocoaPods' pod-name spelling
            for name in ['Artsy_UIColors', 'Artsy+UIColors']:
                self.assertTrue(os.path.islink(os.path.join(inc, name, 'UIColor+ArtsyColors.h')))
            umbrella = open(os.path.join(inc, 'Artsy_UIColors-umbrella.h')).read()
            self.assertTrue(umbrella.startswith('#ifdef __OBJC__\n#import <UIKit/UIKit.h>\n#endif'))
            self.assertIn('#import "Artsy_UIColors/UIColor+ArtsyColors.h"', umbrella)
            self.assertIn('umbrella header "Artsy_UIColors-umbrella.h"',
                          open(os.path.join(inc, 'module.modulemap')).read())
            # vendored copies are byte-identical, license included
            self.assertFalse(os.path.islink(os.path.join(out, 'Pods', 'Artsy-UIColors', 'LICENSE')))
            self.assertEqual(manifest['Artsy-UIColors']['extras'], ['LICENSE'])
            package = open(os.path.join(out, 'Package.swift')).read()
            self.assertIn('podFlags(arc: false, headers: [', package)          # requires_arc = false
            self.assertIn('dependencies: openUIKit + ["Artsy_UIColors"]', package)
            self.assertIn('"Artsy_UIColors/include/Artsy_UIColors"', package)  # dependency's quote path
            self.assertIn('.linkedFramework("ImageIO")', package)
            self.assertNotIn('.linkedFramework("UIKit")', package)
            self.assertIn('path: "../uikit"', package)


if __name__ == '__main__':
    unittest.main()
