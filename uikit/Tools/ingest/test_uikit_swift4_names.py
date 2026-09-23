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

    @unittest.skipUnless(os.path.exists(NOTES), 'iPhoneSimulator26.1 SDK not installed')
    def test_member_spellings_are_the_sdks(self):
        """Swift4Members.swift: every (old, new) pair is in UIKit.apinotes'
        Swift 4 section (or, for the deceleration globals, UIScrollView.h)."""
        import yaml
        d = yaml.safe_load(open(NOTES))
        v4 = [v for v in d['SwiftVersions'] if v['Version'] == 4][0]
        text = open(os.path.join(HERE, '..', '..', 'Sources/OpenUIKit/Swift4Members.swift')).read()
        def v4_member(cls, name):
            for c in v4.get('Classes', []):
                if c['Name'] == cls:
                    for m in c.get('Properties', []) + c.get('Methods', []):
                        if m.get('SwiftName') == name:
                            return True
            return False
        self.assertTrue(v4_member('UIViewController', 'childViewControllers'))
        self.assertTrue(v4_member('UIView', 'bringSubview(toFront:)'))
        self.assertTrue(v4_member('UIView', 'sendSubview(toBack:)'))
        enumerators = {e['Name']: e.get('SwiftName') for e in v4.get('Enumerators', [])}
        for c, swift in [('NSUnderlineStyleSingle', 'styleSingle'), ('NSUnderlineStyleThick', 'styleThick'),
                         ('NSUnderlineStyleDouble', 'styleDouble'), ('NSUnderlineStyleNone', 'styleNone')]:
            self.assertEqual(enumerators.get(c), swift)
        functions = {f['Name']: f.get('SwiftName') for f in v4.get('Functions', [])}
        self.assertEqual(functions.get('UIEdgeInsetsMake'), 'UIEdgeInsetsMake')
        header = open(os.path.join(os.path.dirname(NOTES), 'UIScrollView.h')).read()
        self.assertIn('UIScrollViewDecelerationRateFast', header)
        for name in ['childViewControllers', 'bringSubview(toFront', 'sendSubview(toBack', 'styleSingle',
                     'styleThick', 'styleDouble', 'styleNone', 'UIEdgeInsetsMake', 'UIScrollViewDecelerationRateFast']:
            self.assertIn(name, text)


if __name__ == '__main__':
    unittest.main()
