; RUN: llc < %s -march=nvptx64 -mcpu=sm_20 | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v32:32:32-v64:64:64-v128:128:128-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

; Verify that both %input and %output are converted to global pointers and then
; addrspacecast'ed back to the original type.
define void @kernel(float* %input, float* %output) {
; CHECK-LABEL: .visible .entry kernel(
; CHECK: cvta.to.global.u64
; CHECK: cvta.to.global.u64
  %1 = load float, float* %input, align 4
; CHECK: ld.global.f32
  store float %1, float* %output, align 4
; CHECK: st.global.f32
  ret void
}

define void @kernel2(float addrspace(1)* %input, float addrspace(1)* %output) {
; CHECK-LABEL: .visible .entry kernel2(
; CHECK-NOT: cvta.to.global.u64
  %1 = load float, float addrspace(1)* %input, align 4
; CHECK: ld.global.f32
  store float %1, float addrspace(1)* %output, align 4
; CHECK: st.global.f32
  ret void
}

%struct.S = type { i32*, i32* }

define void @ptr_in_byval(%struct.S* byval %input, i32* %output) {
; CHECK-LABEL: .visible .entry ptr_in_byval(
; CHECK: cvta.to.global.u64
; CHECK: cvta.to.global.u64
  %b_ptr = getelementptr inbounds %struct.S, %struct.S* %input, i64 0, i32 1
  %b = load i32*, i32** %b_ptr, align 4
  %v = load i32, i32* %b, align 4
; CHECK: ld.global.u32
  store i32 %v, i32* %output, align 4
; CHECK: st.global.u32
  ret void
}

!nvvm.annotations = !{!0, !1, !2}
!0 = !{void (float*, float*)* @kernel, !"kernel", i32 1}
!1 = !{void (float addrspace(1)*, float addrspace(1)*)* @kernel2, !"kernel", i32 1}
!2 = !{void (%struct.S*, i32*)* @ptr_in_byval, !"kernel", i32 1}
