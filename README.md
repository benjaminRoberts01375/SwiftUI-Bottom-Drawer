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

![iPhone Vertical](https://github.com/benjaminRoberts01375/SwiftUI-Bottom-Drawer/assets/61424934/c89e4a27-6930-45a4-8642-a0c7ddd8fc45)

### Horizontal iPhone

![iPhone Horizontal](https://github.com/benjaminRoberts01375/SwiftUI-Bottom-Drawer/assets/61424934/5f0e414c-4934-4513-9513-92e653cd73c9) 

### iPad

![IMG_68365CE46645-1](https://github.com/benjaminRoberts01375/SwiftUI-Bottom-Drawer/assets/61424934/45b39b37-4471-4ca5-8b2d-5ff644d9e565)

### macOS

![BottomDrawer screenshot 2 Medium](https://github.com/benjaminRoberts01375/SwiftUI-Bottom-Drawer/assets/61424934/d0e31e8e-cfa7-4c79-a22f-2f656535d09a)
