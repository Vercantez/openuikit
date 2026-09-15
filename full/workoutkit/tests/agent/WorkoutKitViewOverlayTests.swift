import Foundation
import WorkoutKit

// Identity View-overlay batch: workoutPreview is invoked on EmptyView
// (WorkoutKit declares no View-conforming types of its own). Linux renders
// EmptyView; this call pins the no-op identity behavior without inventing
// layout or presenting Apple's workout preview sheet.

func testViewOverlayBatch01() {
    let plan = WorkoutPlan(.goal(SingleGoalWorkout(activity: .running, goal: .open)))
    _ = EmptyView().workoutPreview(plan, isPresented: Binding.constant(false))
    _ = EmptyView().workoutPreview(plan, isPresented: Binding.constant(true))
}
