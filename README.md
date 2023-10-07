# A SwiftUI Bottom Drawer
### An intelligent non-modal bottom drawer written in SwiftUI, for SwiftUI.

## Features
* Holds your stuff.
* Support for iPhone, iPad, and macOS.
* Programmable height snap points with `.small`, `.medium`, `.large`, `.exact`, `.fraction`, and `view`.
* Programmable x position snap points with `.left`, `.right`, and `.center`.
  * "Sticks" to x position snap points with dampening.
* Handles rotation and gets out of the way when possible by shrinking the width.
* Intelligently removes snap points too close together.
* Drag indicator allows automatic snapping to maximum or minimum.
  * Keyboard support on macOS.
* Automatically handles allowing the drawer to be scrolled on.
* Low memory usage.
* Dims background when at maximum height (when using full width).
* Changes style based on type of device.

## Installation
The Swift Package Manager is the current installation method for the infinite grid.

1. Open your project in Xcode
2. File > Add Package Dependencies...
3. Copy the repo URL: `https://github.com/benjaminRoberts01375/SwiftUI-Bottom-Drawer/`
4. Add Package
5. Profit!

## Usage
* Once installed, the drawer should act like a `VStack` with just a couple of parameters.
* If you desire more "layers" to the drawer, you can use the view modifier `.drawerLayer` on your view to give your content the same look as the bottom drawer.


## Demo
### Vertical iPhone

![iPhone Vertical](https://github.com/benjaminRoberts01375/SwiftUI-Bottom-Drawer/assets/61424934/75ca8334-df30-4056-8382-c7bbe77d1093)


### Horizontal iPhone

![iPhone Horizontal](https://github.com/benjaminRoberts01375/SwiftUI-Bottom-Drawer/assets/61424934/1508a363-44fb-4c60-a316-5c99fd19be3e)

### iPad

![iPad](https://github.com/benjaminRoberts01375/SwiftUI-Bottom-Drawer/assets/61424934/2e407a13-0e3c-45ed-9c4a-a4fd581d886b)


### macOS

![macOS](https://github.com/benjaminRoberts01375/SwiftUI-Bottom-Drawer/assets/61424934/606fe795-a36d-4bd5-a552-1813178fb40f)
