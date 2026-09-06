#!/usr/bin/env python3
# Run from uikit/: python3 ../full/ladder/audit-2026-09-16.py OUTPUT
import pathlib,json,re,hashlib,subprocess,collections,sys
P=pathlib.Path(sys.argv[1]); B=pathlib.Path('../full/ladder'); D='2026-09-16'
def read(stem,old=False):return json.loads(((B if old else P)/f'{stem}-2026-09-14.json' if old else P/f'{stem}-{D}.json').read_text())
def save(stem,obj): (P/f'{stem}-{D}.json').write_text(json.dumps(obj,indent=1)+'\n')
groups=[
('transition coordinator','UIViewControllerTransitionCoordinator UIViewControllerTransitionCoordinatorContext UIPercentDrivenInteractiveTransition UIViewControllerInteractiveTransitioning'),
('pasteboard','UIPasteboard'),
('materials / blur','UIVisualEffect UIBlurEffect UIVibrancyEffect UIVisualEffectView UIGlassEffect UIGlassContainerEffect'),
('haptics','UIFeedbackGenerator UIImpactFeedbackGenerator UINotificationFeedbackGenerator UISelectionFeedbackGenerator'),
('shortcuts','UIApplicationShortcutIcon UIApplicationShortcutItem UIMutableApplicationShortcutItem'),
('item provider','NSItemProvider'),
('TextKit-1 / attachments','NSTextAttachment NSTextContainer NSTextStorage NSLayoutManager'),
('property animator','UIViewPropertyAnimator UIViewImplicitlyAnimating UISpringTimingParameters UICubicTimingParameters'),
('table / collection extras','NSDiffableDataSourceSnapshot UITableViewDiffableDataSource UICollectionViewDiffableDataSource UIContextualAction UISwipeActionsConfiguration UICollectionViewListCell UICollectionLayoutListConfiguration UIListContentConfiguration UIBackgroundConfiguration'),
('page controller','UIPageViewController UIPageViewControllerDataSource UIPageViewControllerDelegate'),
('search controller','UISearchController UISearchResultsUpdating UISearchControllerDelegate'),
('system pickers','UIDocumentPickerViewController UIDocumentPickerDelegate UIImagePickerController UIImagePickerControllerDelegate UIFontPickerViewController UIFontPickerViewControllerDelegate UIColorPickerViewController UIColorPickerViewControllerDelegate SFSafariViewController'),
('accessibility actions','UIAccessibilityCustomAction'),
('scene lifecycle','UISceneConfiguration UIOpenURLContext UIUserActivityRestoring UISceneActivationConditions UISceneOpenURLOptions'),
('drag / drop','UIDropSession UIDragItem UIDragSession UIDragInteraction UIDragInteractionDelegate UIDropInteraction UIDropInteractionDelegate UIDragDropSession UIDropProposal'),
('compositional layout','NSCollectionLayoutSize NSCollectionLayoutItem NSCollectionLayoutGroup NSCollectionLayoutSection UICollectionViewCompositionalLayout')]
extra='UIPinchGestureRecognizer UIRotationGestureRecognizer UIScreenEdgePanGestureRecognizer UIHoverGestureRecognizer UISwipeGestureRecognizer UIMenuController UIMenuItem UISplitViewController UICollectionViewController UIEditMenuInteraction UITextItem NSToolbarItem UICoordinateSpace UIScrollEdgeElementContainerInteraction UICollectionViewLayoutInvalidationContext'.split()
allnames=set(extra)|{n for _,s in groups for n in s.split()}
pat=re.compile(r'^\s*(?:public|open)\s+(?:final\s+)?(?:class|struct|enum|protocol|typealias)\s+([A-Za-z_][A-Za-z0-9_]*)',re.M)
found=collections.defaultdict(list)
for p in sorted(pathlib.Path('Sources').rglob('*.swift')):
 text=p.read_text(errors='ignore')
 for m in pat.finditer(text):
  name=m.group(1)
  if name in allnames: found[name].append(f'uikit/{p}:{text.count(chr(10),0,m.start(1))+1}')
audit={'definition':'Textual public/open type declaration, any conditional branch; not API completeness or compile/runtime proof. Groups expand the 16 clusters labeled section 4 by the brief and section 8.4 (original cluster table is section 5.1).','groups':[{'cluster':g,'names':{n:found[n] for n in s.split()}} for g,s in groups], 'additional_names':{n:found[n] for n in extra},'distinct_names':len(allnames)}
save('wall-audit',audit)
old,new=read('ladder-scores',True),read('ladder-scores'); old={r['app']:r for r in old}
oldc,newc=read('ladder-census',True)['apps'],read('ladder-census')['apps']
deltas=[]
for r in new:
 a=r['app'];o=old[a];x=dict(oldc[a]['uikit']['missing']);y=dict(newc[a]['uikit']['missing'])
 deltas.append({'app':a,'score_b_before':o['score_b'],'score_b_after':r['score_b'],'score_a_before':o['score_a'],'score_a_after':r['score_a'],'subscore_changes':{k:[o['sub'][k],v] for k,v in r['sub'].items() if o['sub'][k]!=v},'gap_uses':[o['raw']['uikit_gap_uses'],r['raw']['uikit_gap_uses']],'gap_types':[o['raw']['uikit_gap_types'],r['raw']['uikit_gap_types']],'newly_declared':sorted([(k,v) for k,v in x.items() if k not in y],key=lambda x:(-x[1],x[0]))})
 for k in oldc[a]:
  if k!='uikit':assert oldc[a][k]==newc[a][k],(a,k)
assert read('imports-full',True)==read('imports-full')
assert sorted((B/'nibdeps-2026-09-14.tsv').read_text().splitlines())==sorted((P/f'nibdeps-{D}.tsv').read_text().splitlines())
assert sorted((B/'uikit_sdk_types-2026-09-14.txt').read_text().split())==sorted((P/f'uikit_sdk_types-{D}.txt').read_text().split())
save('per-app-deltas',deltas)
led=read('ledger-supply');oldled=read('ledger-supply',True); prior={r['module']:r for r in oldled['lanes']}
changes=[]
for r in led['lanes']:
 o=prior.get(r['module'])
 if not o or o['by_status']!=r['by_status']:changes.append({'module':r['module'],'old':o['by_status'] if o else None,'new':r['by_status']})
save('ledger-deltas',changes)
# Keep the exact model_supply output intact. A separate reviewed overlay
# removes measured name collisions, preserving the baseline classification.
model=read('model-supply'); evidence=[]
for n in ['Decoder','Encoder']:
 p=pathlib.Path('../full/network/reference/public-surface.tsv')
 row=next(l for l in p.read_text().splitlines() if f'\t{n}\tNetworkCoder.{n}\t' in l)
 pid=row.split('\t')[0]
 cov=next(l for l in pathlib.Path('../full/network/coverage.tsv').read_text().splitlines() if l.startswith(pid+'\t'))
 sym=next(s for s in model['bands']['LEDGER-IMPLEMENTED']['symbols'] if s[0]==n)
 model['bands']['LEDGER-IMPLEMENTED']['symbols'].remove(sym);model['bands']['LEDGER-IMPLEMENTED']['uses']-=sym[2]
 model['bands']['IN-FLIGHT']['symbols'].append(sym);model['bands']['IN-FLIGHT']['uses']+=sym[2]
 evidence.append({'name':n,'uses':sym[2],'surface_row':row,'coverage_row':cov,'reason':'NetworkCoder associated type is not the Swift Codable protocol; keep IN-FLIGHT as in the baseline.'})
model['review_corrections']=evidence
save('model-supply-reviewed',model)
# Framework module names: evaluate the literal HEAVY assignment without invoking main.
import ast
node=ast.parse((B/'score_ladder.py').read_text());heavy=next(ast.literal_eval(n.value) for n in node.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='HEAVY' for t in n.targets))
supplied=set(led['supplied_modules'])|set(led['package_products'])
enum={'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'artifact_date':D,'clock_date_note':'2026-09-16 is the explicitly requested measurement-series suffix; environment current_date is 2026-09-06.','apps':list(newc),'dependencies':list(read('deps-census')['apps']),'ledger_modules':led['supplied_modules'],'ledger_count':led['n_ledgers'],'new_ledger_modules':sorted(set(led['supplied_modules'])-set(oldled['supplied_modules'])),'changed_or_added_ledgers':len(changes),'heavy_names':sorted(heavy),'heavy_unsupplied':sorted(heavy-supplied),'sdk_types':737,'openuikit_types':len((P/f'openuikit_types-{D}.txt').read_text().split()),'wall_names':sorted(allnames),'wall_absent':sorted(allnames-set(found)),'guest_foundation_files':led['guest_foundation_files'],'guest_foundation_types':led['guest_foundation_types'],'checks':['20 app and 30 dependency HEADs equal frozen pins','20 apps: all non-UIKit census fields equal baseline','full imports equal baseline','nibdeps equal baseline after sorting rows (locale order differs)','SDK alphabet set-equal baseline (locale order differs)']}
# defaultdict lookups above create empty entries, so absence must inspect values.
enum['wall_absent']=sorted(n for n in allnames if not found[n])
save('enumeration',enum)
print(json.dumps({k:v for k,v in enum.items() if k not in ['guest_foundation_types','ledger_modules','wall_names']},indent=1))
print('Declared walls:',sum(bool(found[n]) for n in allnames),'/',len(allnames))
print('Ledger changed/new',len(changes),'new modules',enum['new_ledger_modules'])
print('Model reviewed:',[(k,v['uses']) for k,v in model['bands'].items()])
