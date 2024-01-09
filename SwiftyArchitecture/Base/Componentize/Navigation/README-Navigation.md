#  Navigation 

There're some edge cases of the `Navigation` situations.

### Internal Link

When dealing with internal links, the principle of the process logic is that we do additional logics as less as possible.   

- When current view controller hasn't got a navigation controller, it will generate an error when navigation want to push a new view controller.
- When navigation want to present a new view controller and the controller is not a navigation controller, we don't automatically add one navigation controller for it.

### Universal Link

When universal link doesn't explict mark the presentation mode:

- When current view controller hasn't got a navigation controller, the translator will mark the presentation mode to present and add one navigation for it when the target generate a non-navigation controller.


### Other cases

- When calling `navigate(to urlString: String, configuration: Navigation.Configuration)`, maybe `urlString` contains some configuration keys. We always use the configuration in the URL string and overwrite them into the configuration passed in the function varible.
-
