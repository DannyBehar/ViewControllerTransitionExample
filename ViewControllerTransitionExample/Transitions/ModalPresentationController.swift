import UIKit
import Cartography

enum ModalPresentationAlignment {
    case top
    case center
    case bottom
}

class ModalPresentationController: UIPresentationController {

    lazy var fadeView: UIView = .make(backgroundColor: UIColor.black.withAlphaComponent(0.3), alpha: 0.0)

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        containerView.insertSubview(fadeView, at: 0)

        constrain(fadeView) {
            $0.edges == $0.superview!.edges
        }

        guard let coordinator = presentedViewController.transitionCoordinator else {
            fadeView.alpha = 1.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.fadeView.alpha = 1.0
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            fadeView.alpha = 0.0
            return
        }

        if !coordinator.isInteractive {
            coordinator.animate(alongsideTransition: { _ in
                self.fadeView.alpha = 0.0
            })
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

        let targetWidth = safeAreaFrame.width - 2 * inset
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
        frame.origin.x += inset
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
}
