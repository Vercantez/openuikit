// 001-root-class -- the Foundation-less baseline.
// objc4 on its own has no NSObject. Everything downstream in this corpus rests
// on a hand-written root class behaving like one, so check that first.
#include "testsupport.h"

@interface Leaf : TestRoot @end
@implementation Leaf @end

int main(void) {
    Class root = objc_getClass("TestRoot");
    Class leaf = objc_getClass("Leaf");

    say("root.found=%s", NULLNESS(root));
    say("root.name=%s", class_getName(root));
    say("root.superclass=%s", NULLNESS(class_getSuperclass(root)));
    say("root.isMetaClass=%s", YN(class_isMetaClass(root)));

    // Metaclass topology. The invariant every objc runtime must satisfy:
    //   root->isa == rootMeta, rootMeta->isa == rootMeta,
    //   rootMeta->superclass == root.
    Class rootMeta = object_getClass(root);
    say("rootMeta.isMetaClass=%s", YN(class_isMetaClass(rootMeta)));
    say("rootMeta.name=%s", class_getName(rootMeta));
    say("rootMeta.isa==rootMeta=%s", YN(object_getClass(rootMeta) == rootMeta));
    say("rootMeta.superclass==root=%s", YN(class_getSuperclass(rootMeta) == root));
    say("objc_getMetaClass==rootMeta=%s", YN(objc_getMetaClass("TestRoot") == rootMeta));

    // Subclass side of the same shape.
    Class leafMeta = object_getClass(leaf);
    say("leaf.superclass==root=%s", YN(class_getSuperclass(leaf) == root));
    say("leafMeta.superclass==rootMeta=%s", YN(class_getSuperclass(leafMeta) == rootMeta));
    say("leafMeta.isa==rootMeta=%s", YN(object_getClass(leafMeta) == rootMeta));

    // Instances.
    id obj = [Leaf new];
    say("obj=%s", NULLNESS(obj));
    say("obj.class=%s", object_getClassName(obj));
    say("obj.isa==leaf=%s", YN(object_getClass(obj) == leaf));
    say("obj.class-msg==leaf=%s", YN([obj class] == leaf));
    say("obj.self==obj=%s", YN([obj self] == obj));

    // class_getName on nil and on a class the program never defined.
    say("nilclass.name=%s", class_getName(Nil));
    say("missing.lookUp=%s", NULLNESS(objc_lookUpClass("NoSuchClassHere")));
    say("missing.get=%s", NULLNESS(objc_getClass("NoSuchClassHere")));

    objc_release(obj);
    say("dealloc.count=%d", g_dealloc_count);
    return 0;
}
