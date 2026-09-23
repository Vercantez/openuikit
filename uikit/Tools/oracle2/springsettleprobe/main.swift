import QuartzCore
for (p, b) in [(0.5, 0.0), (1.0, 0.0), (0.25, 0.0), (0.5, 0.3), (0.5, 0.7), (0.5, -0.3), (0.5, 1.0), (0.35, 0.15)] {
    let a = CASpringAnimation(perceptualDuration: p, bounce: b)
    print("FACT p=\(p) b=\(b) stiffness=\(a.stiffness) damping=\(a.damping) mass=\(a.mass) settling=\(a.settlingDuration) duration=\(a.duration)")
}
for (k, d) in [(157.91367041742973, 25.132741228718345), (100.0, 10.0), (300.0, 20.0), (50.0, 30.0)] {
    let a = CASpringAnimation(); a.stiffness = k; a.damping = d; a.mass = 1
    print("FACT k=\(k) d=\(d) settling=\(a.settlingDuration)")
}
