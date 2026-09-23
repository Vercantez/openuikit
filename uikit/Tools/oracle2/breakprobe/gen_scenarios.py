#!/usr/bin/env python3
"""Generate breakprobe scenarios: small UNSATISFIABLE required-constraint
systems, added in every order, live (engine present) and bulk (installed
before the container joins a window). Output: scenarios.json (committed).

A constraint is [first, attr, rel, second|null, attr2|null, multiplier,
constant, priority]. Items: "c" (container, frame-based 300x300 at 0,0 of
the probe's root), "v", "w", "u" (Auto Layout views; u is v's subview).
Steps: "+tag" activates, "-tag" deactivates. Every scenario first pins the
vertical axis (tags z*) so only the horizontal conflict is under test.
"""
import itertools, json, pathlib

def C(first, attr, rel, second, attr2, c, m=1, p=1000):
    return [first, attr, rel, second, attr2, m, c, p]

Z = {  # vertical prelude, never in conflict
    'zv1': C('v', 'top', '==', 'c', 'top', 10), 'zv2': C('v', 'height', '==', None, None, 20),
    'zw1': C('w', 'top', '==', 'c', 'top', 40), 'zw2': C('w', 'height', '==', None, None, 20),
    'zu1': C('u', 'top', '==', 'v', 'top', 0), 'zu2': C('u', 'height', '==', None, None, 10),
}

def scen(name, views, cons, order, mode='live', extra=(), create=None, viewCreate=None, viewAdd=None):
    z = [t for t in Z if t[1] in views]
    allc = {t: Z[t] for t in z}
    allc.update(cons)
    # Creation (init) order of the NSLayoutConstraint objects: prelude, then
    # `create` (default: sorted tags), independent of the activation order.
    return {'name': name, 'mode': mode, 'views': views, 'constraints': allc,
            'create': z + list(create or sorted(cons)),
            # View object creation order and addSubview order (default: views).
            'viewCreate': list(viewCreate or views), 'viewAdd': list(viewAdd or views),
            'steps': ['+' + t for t in z] + ['+' + t for t in order] + list(extra)}

out = []
def perms(prefix, views, cons, modes=('live', 'bulk'), limit=None):
    for mode in modes:
        for i, order in enumerate(itertools.permutations(sorted(cons))):
            if limit and i >= limit: break
            out.append(scen(f'{prefix}.{mode}.{"".join(order)}', views, cons, order, mode))

# F1: two equal-attribute equalities.
perms('F1width', ['v'], {'a': C('v', 'width', '==', None, None, 100), 'b': C('v', 'width', '==', None, None, 200),
                         'x': C('v', 'leading', '==', 'c', 'leading', 0)})
# F2: leading / trailing / width triangle.
perms('F2tri', ['v'], {'a': C('v', 'leading', '==', 'c', 'leading', 10),
                       'b': C('v', 'trailing', '==', 'c', 'leading', 110),
                       'c': C('v', 'width', '==', None, None, 50)})
# F3: Focus #406/#410/#411 shape: trailing, leading+30, centerX.
perms('F3center', ['v'], {'a': C('v', 'trailing', '==', 'c', 'trailing', 0),
                          'b': C('v', 'leading', '==', 'c', 'leading', 30),
                          'c': C('v', 'centerX', '==', 'c', 'centerX', 0)})
# F4: equality vs inequalities.
perms('F4ineq', ['v'], {'a': C('v', 'width', '==', None, None, 100),
                        'b': C('v', 'width', '<=', None, None, 50),
                        'c': C('v', 'width', '>=', None, None, 80),
                        'x': C('v', 'leading', '==', 'c', 'leading', 0)})
# F5: two views, 5-constraint chain (10 + 60 + 10 + 60 > 100).
perms('F5chain', ['v', 'w'], {'a': C('v', 'leading', '==', 'c', 'leading', 10),
                              'b': C('w', 'leading', '==', 'v', 'trailing', 10),
                              'c': C('w', 'trailing', '==', 'c', 'leading', 100),
                              'd': C('v', 'width', '==', None, None, 60),
                              'e': C('w', 'width', '==', None, None, 60)})
# F6: constraints installed on different views (u in v in c).
perms('F6nested', ['v', 'u'], {'a': C('u', 'width', '==', None, None, 100),
                               'b': C('u', 'width', '==', 'v', 'width', 0),
                               'c': C('v', 'width', '==', None, None, 200),
                               'x': C('v', 'leading', '==', 'c', 'leading', 0),
                               'y': C('u', 'leading', '==', 'v', 'leading', 0)})
# F7: history. A broken constraint and a later removal of its opponent.
F7 = {'a': C('v', 'width', '==', None, None, 100), 'b': C('v', 'width', '==', None, None, 200),
      'x': C('v', 'leading', '==', 'c', 'leading', 0)}
for mode in ('live', 'bulk'):
    out.append(scen(f'F7hist.{mode}.ab-a', ['v'], F7, 'xab', mode, ['-a']))
    out.append(scen(f'F7hist.{mode}.ab-b', ['v'], F7, 'xab', mode, ['-b']))
    out.append(scen(f'F7hist.{mode}.ab-a+a', ['v'], F7, 'xab', mode, ['-a', '+a']))
    out.append(scen(f'F7hist.{mode}.ab-b+b', ['v'], F7, 'xab', mode, ['-b', '+b']))
# F8: self-referential (Focus URLBar.swift#329).
out.append(scen('F8self.live', ['v'], {'a': C('v', 'leading', '==', 'v', 'leading', 10),
                                       'x': C('v', 'leading', '==', 'c', 'leading', 5),
                                       'y': C('v', 'width', '==', None, None, 50)}, 'xya'))
out.append(scen('F8self.bulk', ['v'], {'a': C('v', 'leading', '==', 'v', 'leading', 10),
                                       'x': C('v', 'leading', '==', 'c', 'leading', 5),
                                       'y': C('v', 'width', '==', None, None, 50)}, 'xya', 'bulk'))

# F9: creation order x activation order (is the choice tied to the objects'
# creation, not to activation?).
F9 = {'a': C('v', 'leading', '==', 'c', 'leading', 10),
      'b': C('v', 'trailing', '==', 'c', 'leading', 110),
      'c': C('v', 'width', '==', None, None, 50)}
for create in itertools.permutations('abc'):
    for order in itertools.permutations('abc'):
        out.append(scen(f'F9create.live.{"".join(create)}.{"".join(order)}', ['v'], F9, order, 'live', (), create))
F10 = {'a': C('v', 'width', '==', None, None, 100), 'b': C('v', 'width', '==', None, None, 200),
       'x': C('v', 'leading', '==', 'c', 'leading', 0)}
for create in ['xab', 'xba']:
    for order in ['xab', 'xba']:
        for mode in ('live', 'bulk'):
            out.append(scen(f'F10create.{mode}.{create}.{order}', ['v'], F10, order, mode, (), create))

# V1: sibling views, symmetric sizes; which view's constraint breaks, and
# does view creation order or subview order decide it?
V1 = {'d': C('v', 'width', '==', None, None, 60), 'e': C('w', 'width', '==', None, None, 60),
      'l': C('v', 'width', '==', 'w', 'width', 10),
      'x': C('v', 'leading', '==', 'c', 'leading', 0), 'y': C('w', 'leading', '==', 'c', 'leading', 0)}
for vc in ('vw', 'wv'):
    for va in ('vw', 'wv'):
        for order in ('xydel', 'xyled', 'xyedl'):
            for mode in ('live', 'bulk'):
                out.append(scen(f'V1sib.{mode}.c{vc}.a{va}.{order}', ['v', 'w'], V1, order, mode, (), None, vc, va))
# V2: parent/child with the child created first.
V2 = {'a': C('u', 'width', '==', None, None, 100), 'b': C('u', 'width', '==', 'v', 'width', 0),
      'c': C('v', 'width', '==', None, None, 200),
      'x': C('v', 'leading', '==', 'c', 'leading', 0), 'y': C('u', 'leading', '==', 'v', 'leading', 0)}
for vc in ('vu', 'uv'):
    for order in ('xyabc', 'xycba'):
        for mode in ('live', 'bulk'):
            out.append(scen(f'V2nest.{mode}.c{vc}.{order}', ['v', 'u'], V2, order, mode, (), None, vc))
# V4: same variables, different constants / relations / orientation.
V4 = {
    'lead10_20': ({'a': C('v', 'leading', '==', 'c', 'leading', 10), 'b': C('v', 'leading', '==', 'c', 'leading', 20)}, 'zw'),
    'lead20_m10': ({'a': C('v', 'leading', '==', 'c', 'leading', 20), 'b': C('v', 'leading', '==', 'c', 'leading', -10)}, 'zw'),
    'leadm10_m20': ({'a': C('v', 'leading', '==', 'c', 'leading', -10), 'b': C('v', 'leading', '==', 'c', 'leading', -20)}, 'zw'),
    'w100_50': ({'a': C('v', 'width', '==', None, None, 100), 'b': C('v', 'width', '==', None, None, 50)}, 'zl'),
    'w100_ge150': ({'a': C('v', 'width', '==', None, None, 100), 'b': C('v', 'width', '>=', None, None, 150)}, 'zl'),
    'w100_le50': ({'a': C('v', 'width', '==', None, None, 100), 'b': C('v', 'width', '<=', None, None, 50)}, 'zl'),
    'wge150_le100': ({'a': C('v', 'width', '>=', None, None, 150), 'b': C('v', 'width', '<=', None, None, 100)}, 'zl'),
    'flip': ({'a': C('v', 'leading', '==', 'c', 'leading', 10), 'b': C('c', 'leading', '==', 'v', 'leading', -20)}, 'zw'),
    'flip2': ({'a': C('v', 'leading', '==', 'c', 'leading', 20), 'b': C('c', 'leading', '==', 'v', 'leading', -10)}, 'zw'),
    'top10_20': ({'a': C('v', 'leading', '==', 'c', 'leading', 0), 'b': C('v', 'width', '==', None, None, 10),
                  'p': C('v', 'top', '==', 'c', 'top', 10), 'q': C('v', 'top', '==', 'c', 'top', 20)}, ''),
    'mult': ({'a': C('v', 'width', '==', 'c', 'width', 0, 0.5), 'b': C('v', 'width', '==', None, None, 100)}, 'zl'),
    'mult2': ({'a': C('v', 'width', '==', 'c', 'width', 0, 0.5), 'b': C('v', 'width', '==', None, None, 200)}, 'zl'),
}
for key, (cons, pad) in V4.items():
    cons = dict(cons)
    if 'w' in pad: cons['zz'] = C('v', 'width', '==', None, None, 30)
    if 'l' in pad: cons['zz'] = C('v', 'leading', '==', 'c', 'leading', 0)
    for order in itertools.permutations(sorted(cons)):
        out.append(scen(f'V4tie.live.{key}.{"".join(order)}', ['v'], cons, order, 'live'))
# V5: F3 with a size constant in place of centerX; trailing/leading/width.
perms('V5rlw', ['v'], {'a': C('v', 'trailing', '==', 'c', 'trailing', 0),
                       'b': C('v', 'leading', '==', 'c', 'leading', 30),
                       'c': C('v', 'width', '==', None, None, 200)})
perms('V5rlcx2', ['v'], {'a': C('v', 'trailing', '==', 'c', 'trailing', -10),
                         'b': C('v', 'leading', '==', 'c', 'leading', 30),
                         'c': C('v', 'centerX', '==', 'c', 'centerX', 5)})

here = pathlib.Path(__file__).parent
(here / 'scenarios.json').write_text(json.dumps({'scenarios': out}, indent=1, sort_keys=True) + '\n')
print(len(out), 'scenarios')
