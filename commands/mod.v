module commands

import twitch_client { Client, CommandEvent }

interface Command {
	name string
	test(event &CommandEvent) bool
	run(mut client Client, event &CommandEvent)
}

fn get_commands() []Command {
	mut commands := []Command{}
	commands << new_ping_command()
	commands << new_bishu_command()

	return commands
}
