module commands

import twitch_client { Client, CommandEvent }

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
