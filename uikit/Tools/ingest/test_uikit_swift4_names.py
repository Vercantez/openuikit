"""Swift4Names.swift holds only renames present in the real SDK's apinotes."""
import os
import unittest

import uikit_swift4_names as g

HERE = os.path.dirname(os.path.abspath(__file__))
SWIFT = os.path.join(HERE, '..', '..', 'Sources/OpenUIKit/Swift4Names.swift')
NOTES = os.path.join(g.DEFAULT_SDK, 'System/Library/Frameworks/UIKit.framework/Headers/UIKit.apinotes')

SAMPLE = """
Tags:
- Name: UIControlEvents
  SwiftName: UIControl.Event
- Name: UIFoo
  SwiftName: UIFoo
Globals:
- Name: UIApplicationDidBecomeActiveNotification
  SwiftName: UIApplication.didBecomeActiveNotification
SwiftVersions:
- Version: 4
  Tags:
  - Name: UIControlEvents
    SwiftName: UIControlEvents
  - Name: UIFoo
    SwiftName: UIFoo
  Globals:
  - Name: UIApplicationDidBecomeActiveNotification
    SwiftName: UIApplicationDidBecomeActive
"""


class Swift4NamesTest(unittest.TestCase):
    def test_renames_from_sample(self):
        r = g.swift4_renames(SAMPLE)
        self.assertEqual(r['Tags'], [('UIControlEvents', 'UIControl.Event')])
        text = g.render(r, 'X')
        self.assertIn('public typealias UIControlEvents = UIControl.Event', text)
        self.assertIn('public static let UIApplicationDidBecomeActive = '
                      'UIApplication.didBecomeActiveNotification', text)

    @unittest.skipUnless(os.path.exists(NOTES), 'iPhoneSimulator26.1 SDK not installed')
    def test_checked_in_file_is_a_subset_of_the_sdk(self):
        full = g.render(g.swift4_renames(open(NOTES).read()), 'iPhoneSimulator26.1')
        full_lines = set(full.split('\n'))
        for line in open(SWIFT).read().split('\n'):
            self.assertIn(line, full_lines, line)


if __name__ == '__main__':
    unittest.main()
