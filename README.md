# Maid
Manages the cleaning of events and other things.

##API
	Maid.new()                        Returns a new Maid object.

	Maid[key] = (function)            Adds a task to perform when cleaning up.
	Maid[key] = (event connection)    Manages an event connection. Anything that isn't a function is assumed to be this.
	Maid[key] = (Maid)                Maids can act as an event connection, allowing a Maid to have other maids to clean up.
	Maid[key] = nil                   Removes a named task. If the task is an event, it is disconnected.

	Maid:GiveTask(task)               Same as above, but uses an incremented number as a key.
	Maid:DoCleaning()                 Disconnects all managed events and performs all clean-up Tasks.
	Maid:Disconnect()                 Same as DoCleaning
