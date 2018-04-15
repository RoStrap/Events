# Maid
Manages the cleaning of events and other things.

```lua
local Maid = Resources:LoadLibrary("Maid")
```
### API
```cs
Maid Maid.new()
// Generates a new Maid object

number Maid:GiveTask(Task)
// Adds a Task to the Maid table, incremented by 1
// @returns index the Task was placed at

void Maid:LinkToInstance(Instance)
// Makes the Maid clean up when the instance is destroyed
// @param Instance Instance The Instance the Maid will wait for to be Destroyed
// @returns table Connection that can be Disconnect()ed to unlink to Instance

void Maid:DoCleaning()
// Disconnects all Events, Destroys all Objects, and calls all functions stored as Tasks
// Maid:Destroy() and Maid:Disconnect() are the same thing

void Maid:Destroy()
// Same as DoCleaning()

void Maid:Disconnect()
// Same as DoCleaning()
```
```
Maid[key] = (function)            Adds a function to call at cleanup
Maid[key] = (Instance)            Adds an Object to be Destroyed at cleanup
Maid[key] = (RBXScriptConnection) Adds a connection to be Disconnected at cleanup
Maid[key] = (Maid)                Maids can act as an event connection, allowing a Maid to clean up other maids
Maid[key] = nil                   Removes a named task. This cleans up the previous Maid[key]
```

# Signal
API-compatible Roblox events

#### The following is the documentation as written by Anaminus:

Addresses two flaws in previous implementations:
- Held a reference to the last set of fired arguments.
- Arguments would be overridden if the signal was fired by a listener.
## Synopsis
	- signal = Signal(function, function)
		Returns a new signal. Receives optional constructor and destructor
		functions. The constructor is called when the number of
		listeners/threads becomes greater than 0. The destructor is called
		when then number of threads/listeners becomes 0. The destructor
		receives as arguments the values returned by the constructor.
	- Signal:Fire(...)
		Fire the signal, passing the arguments to each listener and waiting
		threads.
	- ... = Signal:Wait()
		Block the current thread until the signal is fired. Returns the
		arguments passed to Fire.
	- Signal:Destroy()
		Disconnects all listeners and becomes unassociated with currently
		blocked threads. The signal is still usable.
	- connection = SignalEvent:Connect(function)
		Sets a function to be called when the signal is fired. The listener
		function receives the arguments passed to Fire. Returns a
		SignalConnection.
	- SignalConnection:Disconnect()
		Disconnects the listener, causing it to no longer be called when the
		signal is fired.
	- bool = SignalConnection.Connected
		Whether the listener is connected.
