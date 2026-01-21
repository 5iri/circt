// RUN: circt-opt %s --hw-flatten-modules | FileCheck %s


// CHECK-LABEL: hw.module @SimpleA
hw.module @SimpleA(in %x: i4, out y: i4) {
  // CHECK-NOT: hw.instance
  // CHECK-NEXT: %0 = comb.add %x, %x
  // CHECK-NEXT: %1 = comb.mul %0, %x
  // CHECK-NEXT: %2 = comb.add %1, %1
  // CHECK-NEXT: %3 = comb.mul %2, %1
  %0 = hw.instance "b0" @SimpleB(x: %x: i4) -> (y: i4)
  %1 = hw.instance "b1" @SimpleB(x: %0: i4) -> (y: i4)
  // CHECK-NEXT: hw.output %3
  hw.output %1 : i4
}
// CHECK-NEXT: }
// CHECK-NOT: hw.module private @SimpleB
hw.module private @SimpleB(in %x: i4, out y: i4) {
  %0 = comb.add %x, %x : i4
  %1 = comb.mul %0, %x : i4
  hw.output %1 : i4
}


// CHECK-LABEL: hw.module @DontInlinePublicA
hw.module @DontInlinePublicA(in %x: i4, out y: i4) {
  // CHECK-NEXT: hw.instance "b" @DontInlinePublicB
  %0 = hw.instance "b" @DontInlinePublicB(x: %x: i4) -> (y: i4)
  hw.output %0 : i4
}
hw.module @DontInlinePublicB(in %x: i4, out y: i4) {
  %0 = comb.add %x, %x : i4
  hw.output %0 : i4
}

sv.macro.decl @FOO
sv.macro.decl @BAR

// CHECK-LABEL: hw.module @NestedRegionsA
hw.module @NestedRegionsA(in %x: i42) {
  // CHECK-NEXT: sv.ifdef @FOO {
  // CHECK-NEXT:   sv.ifdef @BAR {
  // CHECK-NEXT:     comb.mul %x, %x : i42
  // CHECK-NEXT:   }
  // CHECK-NEXT: }
  sv.ifdef @FOO {
    hw.instance "b" @NestedRegionsB(y: %x: i42) -> ()
  }
}
// CHECK-NOT: hw.module private @NestedRegionsB
hw.module private @NestedRegionsB(in %y: i42) {
  sv.ifdef @BAR {
    %0 = comb.mul %y, %y : i42
  }
}


// CHECK-LABEL: hw.module @NamesA
hw.module @NamesA() {
  // CHECK-NOT: hw.instance
  // CHECK-NEXT: hw.constant true {name = "b0/c0/x"}
  // CHECK-NEXT: hw.constant true {name = "b0/c1/x"}
  // CHECK-NEXT: hw.constant true {names = ["b0/y", "b0/z"]}
  // CHECK-NEXT: hw.constant true {name = "b1/c0/x"}
  // CHECK-NEXT: hw.constant true {name = "b1/c1/x"}
  // CHECK-NEXT: hw.constant true {names = ["b1/y", "b1/z"]}
  hw.instance "b0" @NamesB() -> ()
  hw.instance "b1" @NamesB() -> ()
}
// CHECK-NOT: hw.module private @NamesB
hw.module private @NamesB() {
  hw.instance "c0" @NamesC() -> ()
  hw.instance "c1" @NamesC() -> ()
  hw.constant true {names = ["y", "z"]}
}
// CHECK-NOT: hw.module private @NamesC
hw.module private @NamesC() {
  hw.constant true {name = "x"}
}


// CHECK-LABEL: hw.module @ExtModuleA
hw.module @ExtModuleA() {
  // CHECK-NEXT: hw.instance "c0" @ExtModuleC
  // CHECK-NEXT: hw.instance "b/c1" @ExtModuleC
  hw.instance "c0" @ExtModuleC() -> ()
  hw.instance "b" @ExtModuleB() -> ()
}
hw.module private @ExtModuleB() {
  hw.instance "c1" @ExtModuleC() -> ()
}
hw.module.extern private @ExtModuleC()

// CHECK-LABEL: hw.module @UseParameterized
// CHECK: hw.param.value i42 = 4
// CHECK: hw.param.value i42 = 11
// CHECK: hw.param.value i42 = 17
// CHECK: hw.output %{{.*}}, %{{.*}}, %{{.*}} : i42, i42, i42
hw.module private @parameters<p1: i42 = 17>(out out: i42) {
  %result = hw.param.value i42 = #hw.param.decl.ref<"p1">
  hw.output %result: i42
}

hw.module @UseParameterized(out x: i42, out y: i42, out z: i42) {
  %r0 = hw.instance "inst1" @parameters<p1: i42 = 4>() -> (out: i42)
  %r1 = hw.instance "inst2" @parameters<p1: i42 = 11>() -> (out: i42)
  %r2 = hw.instance "inst3" @parameters<p1: i42 = 17>() -> (out: i42)
  hw.output %r0, %r1, %r2: i42, i42, i42
}
