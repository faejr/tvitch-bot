module commands

import tvitch { Client, CommandEvent }

interface Command {
	name string
	test(event &CommandEvent) bool
	run(mut client Client, event &CommandEvent)
}

pub fn get_commands() []Command {
	return [
		BishuCommand{},
		PingCommand{}
	]
}
