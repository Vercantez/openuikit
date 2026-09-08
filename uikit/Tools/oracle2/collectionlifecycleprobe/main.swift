import UIKit

private func paths(_ value: [IndexPath]?) -> Any {
    guard let value else { return NSNull() }
    return value.map { [$0.section, $0.item] }
}
private func rect(_ value: CGRect?) -> Any {
    guard let value else { return NSNull() }
    return [Double(value.origin.x),Double(value.origin.y),Double(value.width),Double(value.height)]
}
private var rows: [[String: Any]] = []
private func save() {
    let data = try! JSONSerialization.data(withJSONObject: ["system": UIDevice.current.systemVersion, "rows":rows], options:[.prettyPrinted,.sortedKeys])
    let url = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0].appendingPathComponent("collection-lifecycle.json")
    try! data.write(to:url)
}
private func record(_ stage: String,_ data:[String:Any] = [:]) {
    var row=data;row["stage"]=stage;rows.append(row);save()
}
private final class LifecycleCollection: UICollectionViewController {
    var label = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(UICollectionViewCell.self,forCellWithReuseIdentifier:"cell")
    }
    override func collectionView(_ collectionView:UICollectionView,numberOfItemsInSection section:Int)->Int { 3 }
    override func collectionView(_ collectionView:UICollectionView,cellForItemAt indexPath:IndexPath)->UICollectionViewCell {
        let cell=collectionView.dequeueReusableCell(withReuseIdentifier:"cell",for:indexPath)
        cell.backgroundColor = .systemBlue
        return cell
    }
    override func viewWillAppear(_ animated:Bool) {
        record(label+".willAppear.before",["selected":paths(collectionView.indexPathsForSelectedItems),"animated":animated,"window":view.window != nil])
        super.viewWillAppear(animated)
        record(label+".willAppear.after",["selected":paths(collectionView.indexPathsForSelectedItems),"animated":animated,"window":view.window != nil])
    }
    override func viewIsAppearing(_ animated:Bool) {
        record(label+".isAppearing.before",["selected":paths(collectionView.indexPathsForSelectedItems),"animated":animated,"window":view.window != nil])
        super.viewIsAppearing(animated)
        record(label+".isAppearing.after",["selected":paths(collectionView.indexPathsForSelectedItems),"animated":animated,"window":view.window != nil])
    }
    override func viewDidAppear(_ animated:Bool) {
        record(label+".didAppear.before",["selected":paths(collectionView.indexPathsForSelectedItems),"animated":animated,"window":view.window != nil])
        super.viewDidAppear(animated)
        record(label+".didAppear",["selected":paths(collectionView.indexPathsForSelectedItems),"animated":animated,"window":view.window != nil])
    }
}
private final class LifecycleApp:UIResponder,UIApplicationDelegate {
    var window:UIWindow?
    var navigation:UINavigationController!
    var cases=[("clear",true,false),("retain",false,false),("clearAnimated",true,true),("retainAnimated",false,true)]
    var caseIndex=0
    var firstIndex=0
    let firstCases=[("freshClear",true,false),("freshRetain",false,false),("freshNavClear",true,true),("freshNavRetain",false,true)]
    var root:LifecycleCollection!
    func application(_ application:UIApplication,didFinishLaunchingWithOptions options:[UIApplication.LaunchOptionsKey:Any]?=nil)->Bool {
        nilReset()
        let w=UIWindow(frame:UIScreen.main.bounds);window=w
        startFirstAppearance()
        return true
    }
    func nilReset() {
        let layout=UICollectionViewFlowLayout()
        let fresh=LifecycleCollection(collectionViewLayout:layout)
        record("nil.fresh.before",["loaded":fresh.isViewLoaded])
        fresh.collectionView=nil
        record("nil.fresh.afterSet",["loaded":fresh.isViewLoaded,"subviews":fresh.viewIfLoaded?.subviews.count as Any? ?? NSNull()])
        let created:UICollectionView?=fresh.collectionView
        record("nil.fresh.afterGet",["loaded":fresh.isViewLoaded,"nil":created == nil,"initialLayout":created?.collectionViewLayout === layout,"frame":rect(created?.frame),"dataSource":created?.dataSource === fresh,"delegate":created?.delegate === fresh,"subviews":fresh.viewIfLoaded?.subviews.count as Any? ?? NSNull()])
        fresh.collectionView=nil
        record("nil.loaded.afterSet",["loaded":fresh.isViewLoaded,"oldSuperview":created?.superview != nil,"oldDataSource":created?.dataSource === fresh,"oldDelegate":created?.delegate === fresh,"subviews":fresh.viewIfLoaded?.subviews.count as Any? ?? NSNull()])
        let recreated:UICollectionView?=fresh.collectionView
        record("nil.loaded.afterGet",["nil":recreated == nil,"same":recreated === created,"initialLayout":recreated?.collectionViewLayout === layout,"frame":rect(recreated?.frame),"dataSource":recreated?.dataSource === fresh,"delegate":recreated?.delegate === fresh,"subviews":fresh.viewIfLoaded?.subviews.count as Any? ?? NSNull()])
        let replacementLayout=UICollectionViewFlowLayout()
        let replacement=UICollectionView(frame:CGRect(x:1,y:2,width:40,height:50),collectionViewLayout:replacementLayout)
        fresh.collectionView=replacement
        fresh.collectionView=nil
        let afterReplacement:UICollectionView?=fresh.collectionView
        record("nil.replacement.afterGet",["nil":afterReplacement == nil,"sameReplacement":afterReplacement === replacement,"initialLayout":afterReplacement?.collectionViewLayout === layout,"replacementLayout":afterReplacement?.collectionViewLayout === replacementLayout,"controllerInitialLayout":fresh.collectionViewLayout === layout])
    }
    func startFirstAppearance() {
        guard firstIndex < firstCases.count else { startCase(); return }
        let c=firstCases[firstIndex]
        root=LifecycleCollection(collectionViewLayout:UICollectionViewFlowLayout())
        root.label=c.0;root.clearsSelectionOnViewWillAppear=c.1
        root.view.layoutIfNeeded()
        root.collectionView.selectItem(at:IndexPath(item:0,section:0),animated:false,scrollPosition:[])
        record(c.0+".selectedBeforeFirstAttachment",["selected":paths(root.collectionView.indexPathsForSelectedItems),"loaded":root.isViewLoaded,"window":root.view.window != nil])
        if c.2 { navigation=UINavigationController(rootViewController:root); window!.rootViewController=navigation }
        else { window!.rootViewController=root }
        window!.makeKeyAndVisible()
        record(c.0+".makeVisibleReturned",["selected":paths(root.collectionView.indexPathsForSelectedItems),"window":root.view.window != nil])
        DispatchQueue.main.asyncAfter(deadline:.now()+0.8) {
            record(c.0+".firstAppearanceSettled",["selected":paths(self.root.collectionView.indexPathsForSelectedItems),"window":self.root.view.window != nil])
            self.firstIndex += 1;self.startFirstAppearance()
        }
    }
    func startCase() {
        guard caseIndex < cases.count else {save();exit(0)}
        let c=cases[caseIndex]
        root=LifecycleCollection(collectionViewLayout:UICollectionViewFlowLayout())
        root.label=c.0;root.clearsSelectionOnViewWillAppear=c.1
        navigation=UINavigationController(rootViewController:root)
        window!.rootViewController=navigation
        window!.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline:.now()+0.8) {
            self.root.collectionView.selectItem(at:IndexPath(item:0,section:0),animated:false,scrollPosition:[])
            record(c.0+".selected",["selected":paths(self.root.collectionView.indexPathsForSelectedItems),"window":self.root.view.window != nil])
            let detail=UIViewController();detail.view.backgroundColor = .white
            self.navigation.pushViewController(detail,animated:c.2)
            DispatchQueue.main.asyncAfter(deadline:.now()+0.8) {
                record(c.0+".away",["selected":paths(self.root.collectionView.indexPathsForSelectedItems),"window":self.root.view.window != nil])
                _=self.navigation.popViewController(animated:c.2)
                record(c.0+".popReturned",["selected":paths(self.root.collectionView.indexPathsForSelectedItems),"window":self.root.view.window != nil])
                DispatchQueue.main.asyncAfter(deadline:.now()+0.8) {
                    record(c.0+".settled",["selected":paths(self.root.collectionView.indexPathsForSelectedItems),"window":self.root.view.window != nil])
                    self.caseIndex += 1;self.startCase()
                }
            }
        }
    }
}
_ = UIApplicationMain(CommandLine.argc,CommandLine.unsafeArgv,nil,NSStringFromClass(LifecycleApp.self))
