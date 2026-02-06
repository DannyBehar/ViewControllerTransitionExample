import UIKit
import Cartography

enum ModalPresentationAlignment {
    case top
    case center
    case bottom
}

class ModalPresentationController: UIPresentationController {

    lazy var fadeView: UIView = .make(backgroundColor: UIColor.black.withAlphaComponent(0.3), alpha: 0.0)
    private let presentingTransform: CGAffineTransform = {
        var transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        transform = transform.translatedBy(x: 0.0, y: -8.0)
        return transform
    }()
    private var didTransformPresentingView = false
    private weak var transformedPresentingView: UIView?

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        containerView.insertSubview(fadeView, at: 0)
        fadeView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        fadeView.addGestureRecognizer(tapGesture)

        constrain(fadeView) {
            $0.edges == $0.superview!.edges
        }

        let shouldTransformPresentingModal = shouldTransformPresentingView()

        guard let coordinator = presentedViewController.transitionCoordinator else {
            fadeView.alpha = 1.0
            if shouldTransformPresentingModal {
                applyTransformToPresentingView()
                didTransformPresentingView = true
            }
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.fadeView.alpha = 1.0
            if shouldTransformPresentingModal {
                self.applyTransformToPresentingView()
                self.didTransformPresentingView = true
            }
        })
    }

    @objc private func handleBackgroundTap() {
        presentedViewController.dismiss(animated: true)
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            fadeView.alpha = 0.0
            if didTransformPresentingView {
                resetTransformOnPresentingView()
                didTransformPresentingView = false
            }
            return
        }

        if coordinator.isInteractive {
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.fadeView.alpha = 0.0
            if self.didTransformPresentingView {
                self.resetTransformOnPresentingView()
                self.didTransformPresentingView = false
            }
        })
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed, didTransformPresentingView {
            // UIKit may reset the presenting view's transform at the end of the transition.
            applyTransformToPresentingView()
        } else if !completed, didTransformPresentingView {
            resetTransformOnPresentingView()
            didTransformPresentingView = false
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            resetTransformOnPresentingView()
            didTransformPresentingView = false
        }
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView, let presentedView = presentedView else { return .zero }

        let inset: CGFloat = 16
        let safeAreaFrame = containerView.bounds.inset(by: containerView.safeAreaInsets)
        let verticalPadding: CGFloat = 8.0

        let availableWidth = safeAreaFrame.width - 2 * inset
        let maxRegularWidth: CGFloat = 580.0
        let targetWidth: CGFloat
        if presentedViewController.traitCollection.horizontalSizeClass == .regular {
            targetWidth = min(availableWidth, maxRegularWidth)
        } else {
            targetWidth = availableWidth
        }
        let fittingSize = CGSize(
            width: targetWidth,
            height: UIView.layoutFittingCompressedSize.height
        )
        
        let targetHeight = presentedView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        ).height

        var frame = safeAreaFrame
        frame.origin.x = safeAreaFrame.minX + (safeAreaFrame.width - targetWidth) / 2.0
        frame.size.width = targetWidth
        frame.size.height = targetHeight

        let alignment = (presentedViewController as? CustomPresentable)?.presentationAlignment ?? .top
        switch alignment {
        case .top:
            frame.origin.y = safeAreaFrame.minY + verticalPadding
        case .center:
            frame.origin.y = safeAreaFrame.minY + (safeAreaFrame.height - targetHeight) / 2.0
        case .bottom:
            frame.origin.y = safeAreaFrame.maxY - targetHeight - verticalPadding
        }

        return frame
    }

    private func shouldTransformPresentingView() -> Bool {
        guard let presentingModal = presentingViewController as? CustomPresentable,
              let presentedModal = presentedViewController as? CustomPresentable else {
            return false
        }

        return presentingModal.presentationAlignment == presentedModal.presentationAlignment
    }

    private func applyTransformToPresentingView() {
        if let presentingModal = presentingViewController as? CustomPresentable,
           let targetView = presentingModal.presentationTransformTargetView ?? presentingViewController.presentationController?.presentedView {
            targetView.transform = presentingTransform
            transformedPresentingView = targetView
        } else if let presentingPresentedView = presentingViewController.presentationController?.presentedView {
            presentingPresentedView.transform = presentingTransform
            transformedPresentingView = presentingPresentedView
        } else {
            presentingViewController.view.transform = presentingTransform
            transformedPresentingView = presentingViewController.view
        }
    }

    private func resetTransformOnPresentingView() {
        transformedPresentingView?.transform = .identity
        transformedPresentingView = nil
    }

    func updatePresentingViewTransform(for progress: CGFloat) {
        guard didTransformPresentingView else { return }
        let clamped = min(max(progress, 0.0), 1.0)
        let from = presentingTransform
        let to = CGAffineTransform.identity

        let interpolated = CGAffineTransform(
            a: from.a + (to.a - from.a) * clamped,
            b: from.b + (to.b - from.b) * clamped,
            c: from.c + (to.c - from.c) * clamped,
            d: from.d + (to.d - from.d) * clamped,
            tx: from.tx + (to.tx - from.tx) * clamped,
            ty: from.ty + (to.ty - from.ty) * clamped
        )

        transformedPresentingView?.transform = interpolated
    }

    func setPresentingViewTransform(_ transform: CGAffineTransform) {
        guard didTransformPresentingView else { return }
        transformedPresentingView?.transform = transform
    }
}
