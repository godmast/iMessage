import UIKit
import Messages
import AVKit
import AVFoundation

class MessagesViewController: MSMessagesAppViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
        print("willBecomeActive")
        presentViewController(for: conversation, with: presentationStyle)
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
        print("resignActive")
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
        print("didReceive")
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
        print("willTransition")

    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
        print("didTransition")
        for child in childViewControllers where child is PropagatePresentationStyle {
            if let progateStyleVC = child as? PropagatePresentationStyle {
                progateStyleVC.propagate(presentationStyle: presentationStyle)
            }
        }
    }

    private func presentViewController(for conversation: MSConversation, with presentationStyle: MSMessagesAppPresentationStyle) {
        // Determine the controller to present.
        let controller: UIViewController
        if conversation.selectedMessage == nil {
            controller = instantiateFightMoveViewController(conversation: conversation, presentationStyle: presentationStyle)
        } else {
            if let message = conversation.selectedMessage,
               let url = message.url,
               let fight = Fight.decode(fromURL: url),
               fight.result == .notEnded,
               message.senderParticipantIdentifier != conversation.localParticipantIdentifier
            {
                controller = instantiateFightMoveViewController(conversation: conversation, presentationStyle: presentationStyle)
            } else {
                controller = instantiatePlayFightViewController(conversation: conversation, presentationStyle: presentationStyle)
            }
        }

        // Remove any existing child controllers.
        for child in childViewControllers {
            child.willMove(toParentViewController: nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
        }

        // Embed the new controller.
        addChildViewController(controller)

        controller.view.frame = view.bounds
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)

        controller.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        controller.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        controller.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        controller.didMove(toParentViewController: self)
    }

    private func instantiateFightMoveViewController(conversation:MSConversation, presentationStyle: MSMessagesAppPresentationStyle) -> UIViewController {

        guard
            let controller = storyboard?.instantiateViewController(withIdentifier: FightMoveViewController.storyboardIdentifier) as? FightMoveViewController
            else {
                fatalError("Unable to instantiate a FightMoveViewController from the storyboard")
        }
        controller.setup(conversation: conversation)
        controller.propagate(presentationStyle: presentationStyle)
        controller.delegate = self
        return controller
    }

    private func instantiatePlayFightViewController(conversation:MSConversation, presentationStyle: MSMessagesAppPresentationStyle) -> UIViewController {

        guard
            let controller = storyboard?.instantiateViewController(withIdentifier: PlayFightViewController.storyboardIdentifier) as? PlayFightViewController
            else {
                fatalError("Unable to instantiate a PlayFightViewController from the storyboard")
        }
        controller.setup(conversation: conversation)
        controller.delegate = self
        return controller
    }

    private func instantiateVideoViewController(conversation:MSConversation) -> UIViewController {
        guard
            let message = conversation.selectedMessage,
            let url = message.url,
            let fight = Fight.decode(fromURL: url)
            else {
                return UIViewController()
        }
        var videosURL = [URL]()
        if let attack = fight.attackerOption {
            videosURL.append(MediaResources.mediaURL(forGameOption: attack))
        }
        if let defense = fight.defenderOption {
            videosURL.append(MediaResources.mediaURL(forGameOption: defense))
        }
        var playerItems = [AVPlayerItem]()
        for fileURL in videosURL {
            let asset = AVURLAsset(url:fileURL, options:nil)
            let playerItem = AVPlayerItem(asset: asset)
            playerItems.append(playerItem)
        }
        let player = AVQueuePlayer(items: playerItems)        
        let controller = AVPlayerViewController()
        let label = UILabel()
        label.text = "Hello World";
        label.sizeToFit()
        label.textColor = UIColor.white
        controller.player = player
        controller.contentOverlayView?.addSubview(label)
        controller.showsPlaybackControls = true
        player.play()
        return controller
    }
}

extension MessagesViewController: FightMoveControllerDelegate {

    func fightMoveControllerDidSelectMove(_ controller: FightMoveViewController) {
        self.dismiss()
    }
    
}

extension MessagesViewController: PlayFightViewControllerDelegate {

    func playFightViewControllerDidSelectMakeOfficial(_ controller: PlayFightViewController) {
        self.dismiss()
    }
}

public protocol PropagatePresentationStyle: class {

    func propagate(presentationStyle: MSMessagesAppPresentationStyle)
}
