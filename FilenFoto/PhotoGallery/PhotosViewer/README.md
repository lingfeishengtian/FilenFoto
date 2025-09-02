# UIKit Photo Gallery

There are many downsides with SwiftUI that prevents this specific view from being made. In an older version of this project, I attempted the use of LazyVGrid but they didn't provide the level of control and animation customization I needed to make this view feel fluid. Furthermore the SwiftUI code that produced was appalling. Here I document the transition to UIKit and the benefits it brings and the techniques I used.

## Context Saving

Context is an interesting hurdle. I needed to propagate updates to the `selectedPhotoIndex` across different parts of the view hierarchy. I went through 3 iterations to finally get it right.

### Navigation Controller Parent Context

I utilized a navigation controller as the parent context. This allowed me to pass the selected index down to child view controllers easily. Furthermore, whenever the `selectedPhotoIndex` changed, I could update all child view controllers accordingly by looping through the children on the navigation controller. The biggest challenge occurred when trying to maintain the correct state during modal transitions. Due to the design of UIKit, I had to change the way I managed the view hierarchy from pure navigation controller `push` and `pop` to modal `present` and `dismiss`. 

Modal presentations allowed me to take over the whole screen, allowing view customizations through SwiftUI that wouldn't impact the modal views. In contrast, with `UINavigationController`, detail photo view controllers would be impacted by SwiftUI changes (i.e. `ZStack` overlays etc.)

### Copying Context Down

When talking about read, this method was easy. When talking about write... I had to save references to the parent view which had to register the children view controllers. This got messy real quick so I scrapped this idea.

### Swift Combine

By using the SwiftUI `ObservableObject` protocol, I was able to create a shared data model that could be observed by all view controllers. View controllers simply subscribed to changes in the `selectedPhotoIndex`, allowing for a more reactive approach to state management.

However, the biggest issue was that state changes would cause jumps in the UI. For example, I changed photo pages while horizontally scrolling through a `UIPageController` which changes the `selectedPhotoIndex`. This ends up calling the subscriber within the `UIPageController` which cuts the animation short and causes a buggy experience. I'll call this `duplicate events`.

### Committing Context Changes

To address the issue of `duplicate events`, I made `setSelectedPhotoIndex` to set a local copy of the `selectedPhotoIndex`. I'll call this `uncommitted changes`. We only need to notify the other views that the context has changed when we actually navigate to those views. So this solution requires a separate function to `commit changes`. This commit function will be responsible for applying the `uncommitted changes` to the shared data model and notifying all subscribers.

This forces the view controllers to update their local state manually so allow for the most seamless animation effects. For example, when the `UIPageController` updates, I only want to update the photo scrubber, I don't want to update the entire view hierarchy since the `UIPageController` has already finished its state transition effects.

## Animations

The animation logic is quite complex in this view. // TODO: Finish writing