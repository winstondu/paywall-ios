//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/03/2022.
//

import SwiftUI
import Combine

@available(iOS 13.0, *)
struct PaywallTriggerModifier: ViewModifier {
  @Binding var shouldPresent: Bool
  @State private var programmaticallySetShouldPresent = false
  @State private var isInternallyPresenting = false
  var event: String?
  var params: [String: Any]
  var presentationStyleOverride: PaywallPresentationStyle?
  var onPresent: ((PaywallInfo?) -> Void)?
  var onDismiss: ((PaywallDismissalResult) -> Void)?
  var onFail: ((NSError) -> Void)?

  func body(content: Content) -> some View {
    content
      .onReceive(Just(shouldPresent)) { _ in
        updatePresentation(shouldPresent)
      }
  }

  private func updatePresentation(_ shouldPresent: Bool) {
    if shouldPresent {
      // Stops internallyPresent from being called twice due to state changes.
      if isInternallyPresenting {
        return
      }

      let eventInfo: PresentationInfo
      if let name = event {
        let trackableEvent = UserInitiatedEvent.Track(
          rawName: name,
          canImplicitlyTriggerPaywall: false,
          customParameters: params
        )
        let result = Paywall.track(trackableEvent)
        eventInfo = .explicitTrigger(result.data)
      } else {
        let trackableEvent = UserInitiatedEvent.DefaultPaywall()
        let result = Paywall.track(trackableEvent)
        eventInfo = .explicitTrigger(result.data)
      }

      isInternallyPresenting = true

      Paywall.internallyPresent(
        eventInfo,
        presentationStyleOverride: presentationStyleOverride ?? .none,
        onPresent: onPresent,
        onDismiss: { result in
          self.programmaticallySetShouldPresent = true
          self.shouldPresent = false
          self.isInternallyPresenting = false
          onDismiss?(result)
        },
        onSkip: { error in
          self.programmaticallySetShouldPresent = true
          self.shouldPresent = false
          self.isInternallyPresenting = false
          onFail?(error)
        }
      )
    } else {
      // When states change in SwiftUI views, the shouldPresent state seems to get temporarily
      // reset to false as it rerenders the view. This incorrectly calls Paywall.dismiss().
      // Also, when views get set up for the first time, Paywall.dismiss() was being called.
      // This guards against that.
      guard isInternallyPresenting else {
        // This prevents Paywall.dismiss() being called when programmatically setting shouldPresent
        // to false.
        if programmaticallySetShouldPresent {
          programmaticallySetShouldPresent = false
          return
        }
        return
      }

      Paywall.dismiss()
    }
  }
}
