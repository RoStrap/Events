local MakeMaid do
	local index = {
		GiveTask = function(self, Task)
			local n = #self.Tasks + 1
			self.Tasks[n] = Task
			return n
		end;
		
		DoCleaning = function(self)
			local Tasks = self.Tasks
			for Name, Task in next, Tasks do
				if type(Task) == "function" then
					Task()
				else
					Task:Disconnect()
				end
				Tasks[Name] = nil
			end
		end;
	};
	index.Disconnect = index.DoCleaning -- Allow maids to be stacked.

	local mt = {
		__index = function(self, k)
			if index[k] then
				return index[k]
			else
				return self.Tasks[k]
			end
		end;
		
		__newindex = function(self, k, v)
			local Tasks = self.Tasks
			if v == nil then
				if type(Tasks[k]) ~= "function" and Tasks[k] then
					Tasks[k]:Disconnect() -- disconnect if the task is an event
				end
			elseif Tasks[k] then
				self[k] = nil -- clear previous task
			end
			Tasks[k] = v
		end;
	}

	function MakeMaid()
		return setmetatable({
			Tasks = {};
		}, mt)
	end
end

return {new = MakeMaid}
