import UIKit
var rows: [String: Any] = [:]
func paths(_ p: [IndexPath]?) -> Any { p.map { $0.map { [$0.section, $0.item] } } as Any? ?? NSNull() }
func rect(_ r: CGRect) -> [Double] { [r.origin.x, r.origin.y, r.width, r.height].map(Double.init) }
func context(_ c: UICollectionViewLayoutInvalidationContext) -> [String: Any] {
 var result: [String:Any] = ["type": String(describing: type(of:c)), "everything": c.invalidateEverything, "counts": c.invalidateDataSourceCounts,
 "items": paths(c.invalidatedItemIndexPaths), "supp": c.invalidatedSupplementaryIndexPaths?.mapValues { paths($0) } as Any? ?? NSNull(),
 "decor": c.invalidatedDecorationIndexPaths?.mapValues { paths($0) } as Any? ?? NSNull(),
 "offset": [Double(c.contentOffsetAdjustment.x),Double(c.contentOffsetAdjustment.y)],
 "size": [Double(c.contentSizeAdjustment.width),Double(c.contentSizeAdjustment.height)]]
 if let f=c as? UICollectionViewFlowLayoutInvalidationContext { result["attributes"]=f.invalidateFlowLayoutAttributes; result["metrics"]=f.invalidateFlowLayoutDelegateMetrics }; return result
}
final class CaptureLayout: UICollectionViewFlowLayout {
 var contexts: [[String:Any]] = []
 override func invalidateLayout(with c: UICollectionViewLayoutInvalidationContext) { contexts.append(context(c));super.invalidateLayout(with:c) }
}
final class EmptyController: UICollectionViewController {
 override func collectionView(_ c: UICollectionView, numberOfItemsInSection s: Int) -> Int { 0 }
}
final class ItemController: UICollectionViewController {
 override func viewDidLoad() {super.viewDidLoad();collectionView.register(UICollectionViewCell.self,forCellWithReuseIdentifier:"cell")}
 override func collectionView(_ c: UICollectionView, numberOfItemsInSection s:Int)->Int { 2 }
 override func collectionView(_ c:UICollectionView,cellForItemAt p:IndexPath)->UICollectionViewCell { c.dequeueReusableCell(withReuseIdentifier:"cell",for:p) }
}
final class SizedLayout: UICollectionViewLayout {
 var contexts: [[String:Any]] = []
 override var collectionViewContentSize: CGSize { CGSize(width:500,height:1200) }
 override func invalidateLayout(with c:UICollectionViewLayoutInvalidationContext) { contexts.append(context(c));super.invalidateLayout(with:c) }
}
final class App: UIResponder, UIApplicationDelegate {
 var window: UIWindow?
 func application(_ application: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
  rows["os"] = UIDevice.current.systemVersion
  let c = UICollectionViewLayoutInvalidationContext(); rows["context.default"] = context(c)
  let a = IndexPath(item:2,section:1), b = IndexPath(item:0,section:0)
  c.invalidateItems(at:[a,b,a]); rows["context.items"] = context(c)
  c.invalidateItems(at:[a,IndexPath(item:3,section:1)]);rows["context.itemsAgain"] = context(c)
  c.invalidateSupplementaryElements(ofKind:"header",at:[a,b,a]); c.invalidateSupplementaryElements(ofKind:"header",at:[a]);c.invalidateSupplementaryElements(ofKind:"footer",at:[])
  c.invalidateDecorationElements(ofKind:"background",at:[b]); c.contentOffsetAdjustment=CGPoint(x:3,y:-4);c.contentSizeAdjustment=CGSize(width:5,height:-6);rows["context.changed"] = context(c)
  let f=UICollectionViewFlowLayoutInvalidationContext();var fd=context(f);fd["attributes"]=f.invalidateFlowLayoutAttributes;fd["metrics"]=f.invalidateFlowLayoutDelegateMetrics;rows["flowcontext.default"]=fd
  let empty=UICollectionViewLayoutInvalidationContext();empty.invalidateItems(at:[]);rows["context.emptyItems"]=context(empty)
  let base=UICollectionViewLayout(); rows["layout.boundsContext"]=context(base.invalidationContext(forBoundsChange:CGRect(x:3,y:4,width:200,height:300)))
  let flow=CaptureLayout();rows["flow.boundsContext.unattached"]=context(flow.invalidationContext(forBoundsChange:CGRect(x:3,y:4,width:200,height:300)))
  let vc=UICollectionViewController(collectionViewLayout:flow)
  rows["vc.init"]=["loaded":vc.isViewLoaded,"layoutIdentity":vc.collectionViewLayout === flow,"clear":vc.clearsSelectionOnViewWillAppear,"standard":vc.useLayoutToLayoutNavigationTransitions,"install":vc.installsStandardGestureForInteractiveMovement]
  let cv=vc.collectionView!; rows["vc.loaded"]=["sameView":vc.view === cv,"viewType":String(describing:type(of:vc.view!)),"subviews":vc.view.subviews.map{String(describing:type(of:$0))},"collectionFrame":rect(cv.frame),"viewFrame":rect(vc.view.frame),"autoresize":cv.autoresizingMask.rawValue,"datasource":cv.dataSource === vc,"delegate":cv.delegate === vc,"bounceV":cv.alwaysBounceVertical,"bounceH":cv.alwaysBounceHorizontal,"respondsSections":vc.responds(to:#selector(UICollectionViewDataSource.numberOfSections(in:))),"respondsItems":vc.responds(to:#selector(UICollectionViewDataSource.collectionView(_:numberOfItemsInSection:)))]
  let replacement=UICollectionView(frame:CGRect(x:1,y:2,width:100,height:200),collectionViewLayout:UICollectionViewLayout());vc.collectionView=replacement
  rows["vc.replacement"]=["sameView":vc.view === replacement,"subviews":vc.view.subviews.map{String(describing:type(of:$0))},"datasource":replacement.dataSource === vc,"delegate":replacement.delegate === vc,"oldSuperview":cv.superview != nil,"layoutIdentity":vc.collectionViewLayout === replacement.collectionViewLayout,"originalLayout":vc.collectionViewLayout === flow,"frame":rect(replacement.frame),"autoresize":replacement.autoresizingMask.rawValue,"oldDataSource":cv.dataSource === vc]
  let attached=CaptureLayout();let host=UICollectionView(frame:CGRect(x:0,y:0,width:200,height:300),collectionViewLayout:attached);host.layoutIfNeeded();rows["flow.bounds.same"]=context(attached.invalidationContext(forBoundsChange:host.bounds));rows["flow.bounds.origin"]=context(attached.invalidationContext(forBoundsChange:CGRect(x:3,y:4,width:200,height:300)));rows["flow.bounds.width"]=context(attached.invalidationContext(forBoundsChange:CGRect(x:0,y:0,width:220,height:300)));attached.contexts=[];attached.invalidateLayout();rows["flow.invalidate"]=attached.contexts
  let adj=UICollectionViewFlowLayoutInvalidationContext();adj.contentOffsetAdjustment=CGPoint(x:3,y:4);adj.contentSizeAdjustment=CGSize(width:10,height:20);attached.invalidateLayout(with:adj);rows["flow.adjustImmediate"]=["offset":[Double(host.contentOffset.x),Double(host.contentOffset.y)],"size":[Double(host.contentSize.width),Double(host.contentSize.height)]]
  let sz=SizedLayout();let sizedView=UICollectionView(frame:CGRect(x:0,y:0,width:200,height:300),collectionViewLayout:sz);sizedView.layoutIfNeeded();sz.contexts=[];sz.invalidateLayout();rows["base.invalidate.attached"]=sz.contexts
  let detached=SizedLayout();detached.invalidateLayout();rows["base.invalidate.detached"]=detached.contexts
  sizedView.contentOffset=CGPoint(x:20,y:30);let ac=UICollectionViewLayoutInvalidationContext();ac.contentOffsetAdjustment=CGPoint(x:3,y:4);ac.contentSizeAdjustment=CGSize(width:10,height:20);sz.invalidateLayout(with:ac)
  rows["base.adjustImmediate"]=["offset":[Double(sizedView.contentOffset.x),Double(sizedView.contentOffset.y)],"size":[Double(sizedView.contentSize.width),Double(sizedView.contentSize.height)]]
  sizedView.layoutIfNeeded();rows["base.adjustLayout"]=["offset":[Double(sizedView.contentOffset.x),Double(sizedView.contentOffset.y)],"size":[Double(sizedView.contentSize.width),Double(sizedView.contentSize.height)]]
  let pc=EmptyController(collectionViewLayout:UICollectionViewFlowLayout());let custom=UICollectionView(frame:CGRect(x:4,y:5,width:40,height:50),collectionViewLayout:UICollectionViewLayout());pc.collectionView=custom
  rows["vc.setBeforeLoad"]=["loaded":pc.isViewLoaded,"datasource":custom.dataSource === pc,"frame":rect(custom.frame)]
  _=pc.view;rows["vc.setBeforeLoad.after"]=["sameCollection":pc.collectionView === custom,"frame":rect(custom.frame)]
  let next=UICollectionViewFlowLayout();var done:Bool?;pc.collectionView.setCollectionViewLayout(next,animated:false,completion:{done=$0});rows["vc.setLayout.completion"]=done as Any? ?? NSNull();rows["vc.setLayout"]=["cvLayout":pc.collectionView.collectionViewLayout === next,"controllerLayout":pc.collectionViewLayout === next]
  let w=UIWindow(frame:UIScreen.main.bounds);w.rootViewController=EmptyController(collectionViewLayout:UICollectionViewFlowLayout());w.makeKeyAndVisible();window=w
  DispatchQueue.main.asyncAfter(deadline:.now()+0.5) {
   let v=w.rootViewController as! UICollectionViewController
   rows["vc.window"]=["sameView":v.view === v.collectionView,"viewFrame":rect(v.view.frame),"collectionFrame":rect(v.collectionView.frame),"superviewIsView":v.collectionView.superview === v.view,"bounceV":v.collectionView.alwaysBounceVertical,"background":v.collectionView.backgroundColor?.description ?? "nil"]
   for (name,clear,transition) in [("clear",true,false),("retain",false,false)] {
    let sc=ItemController(collectionViewLayout:UICollectionViewFlowLayout());sc.clearsSelectionOnViewWillAppear=clear;sc.useLayoutToLayoutNavigationTransitions=transition;sc.view.layoutIfNeeded()
    sc.collectionView.selectItem(at:IndexPath(item:0,section:0),animated:false,scrollPosition:[]);sc.viewWillAppear(false)
    rows["vc.selection."+name]=paths(sc.collectionView.indexPathsForSelectedItems)
   }
   let lay=SizedLayout();let real=ItemController(collectionViewLayout:lay);w.rootViewController=real;real.view.layoutIfNeeded();let rc=real.collectionView!;rc.contentOffset=CGPoint(x:20,y:30)
   rows["base.populatedBefore"]=["offset":[Double(rc.contentOffset.x),Double(rc.contentOffset.y)],"size":[Double(rc.contentSize.width),Double(rc.contentSize.height)]]
   let change=UICollectionViewLayoutInvalidationContext();change.contentOffsetAdjustment=CGPoint(x:3,y:4);change.contentSizeAdjustment=CGSize(width:10,height:20);lay.invalidateLayout(with:change)
   rows["base.populatedImmediate"]=["offset":[Double(rc.contentOffset.x),Double(rc.contentOffset.y)],"size":[Double(rc.contentSize.width),Double(rc.contentSize.height)]]
   rc.layoutIfNeeded();rows["base.populatedLayout"]=["offset":[Double(rc.contentOffset.x),Double(rc.contentOffset.y)],"size":[Double(rc.contentSize.width),Double(rc.contentSize.height)]]
   let data=try! JSONSerialization.data(withJSONObject:rows,options:[.prettyPrinted,.sortedKeys]);try! data.write(to:URL(fileURLWithPath:NSHomeDirectory()+"/Documents/collection.json"));exit(0)
  }
  return true
 }
}
UIApplicationMain(CommandLine.argc,CommandLine.unsafeArgv,nil,NSStringFromClass(App.self))
