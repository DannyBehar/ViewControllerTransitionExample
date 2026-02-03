import SwiftUI
import UIKit

final class SuperModalHostingController<Content: View>: UIHostingController<Content>, CustomPresentable {
    var transitionManager: UIViewControllerTransitioningDelegate?
    var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20.0
        view.layer.masksToBounds = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || presentingViewController == nil {
            onDismiss?()
        }
    }
}

private struct SuperModalPresenter<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let interactiveDismissalType: InteractiveDismissalType
    let content: () -> Content
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            if let presentedController = context.coordinator.presentedController {
                presentedController.rootView = content()
                presentedController.updatePresentationLayout(animated: true)
            } else {
                let hostingController = SuperModalHostingController(rootView: content())
                hostingController.onDismiss = { [weak coordinator = context.coordinator] in
                    coordinator?.isPresented.wrappedValue = false
                    coordinator?.presentedController = nil
                }
                uiViewController.present(hostingController, interactiveDismissalType: interactiveDismissalType)
                hostingController.presentationController?.delegate = context.coordinator
                context.coordinator.presentedController = hostingController
            }
        } else if let presentedController = context.coordinator.presentedController {
            if presentedController.presentingViewController != nil {
                presentedController.dismiss(animated: true)
            }
            context.coordinator.presentedController = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }
    
    final class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var isPresented: Binding<Bool>
        weak var presentedController: SuperModalHostingController<Content>?
        
        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }
        
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            isPresented.wrappedValue = false
            presentedController = nil
        }
    }
}

private struct SuperModalItemPresenter<Item: Identifiable, Content: View>: UIViewControllerRepresentable {
    @Binding var item: Item?
    let interactiveDismissalType: InteractiveDismissalType
    let content: (Item) -> Content
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let currentItem = item {
            if let presentedController = context.coordinator.presentedController {
                presentedController.rootView = content(currentItem)
                presentedController.updatePresentationLayout(animated: true)
            } else {
                let hostingController = SuperModalHostingController(rootView: content(currentItem))
                
                hostingController.onDismiss = { [weak coordinator = context.coordinator] in
                    coordinator?.item.wrappedValue = nil
                    coordinator?.presentedController = nil
                }
                uiViewController.present(hostingController, interactiveDismissalType: interactiveDismissalType)
                hostingController.presentationController?.delegate = context.coordinator
                context.coordinator.presentedController = hostingController
            }
        } else if let presentedController = context.coordinator.presentedController {
            if presentedController.presentingViewController != nil {
                presentedController.dismiss(animated: true)
            }
            context.coordinator.presentedController = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(item: $item)
    }
    
    final class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var item: Binding<Item?>
        weak var presentedController: SuperModalHostingController<Content>?
        
        init(item: Binding<Item?>) {
            self.item = item
        }
        
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            item.wrappedValue = nil
            presentedController = nil
        }
    }
}

extension View {
    func superModal<Content: View>(
        isPresented: Binding<Bool>,
        interactiveDismissalType: InteractiveDismissalType = .standard,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        background(
            SuperModalPresenter(
                isPresented: isPresented,
                interactiveDismissalType: interactiveDismissalType,
                content: content
            )
        )
    }
    
    func superModal<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        interactiveDismissalType: InteractiveDismissalType = .standard,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        background(
            SuperModalItemPresenter(
                item: item,
                interactiveDismissalType: interactiveDismissalType,
                content: content
            )
        )
    }
}


#Preview {
    @Previewable @State var isPresented: Bool = false
    
    VStack {
        Color.green
        
        Button("Tap Me") {
            isPresented.toggle()
        }
    }
    .superModal(isPresented: $isPresented) {
        VStack {
            Text("Hello World")
        }
        .frame(width: 200, height: 200)
    }
}
