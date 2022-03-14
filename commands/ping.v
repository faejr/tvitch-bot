module commands

import term
import twitch_client { Client, CommandEvent }

struct PingCommand {
	name string
}

pub fn new_ping_command() PingCommand {
	return PingCommand{'ping'}
}

fn (c PingCommand) test(event &CommandEvent) bool {
	return event.command == 'ping'
}

fn (c PingCommand) run(mut client Client, event &CommandEvent) {
	client.send_channel_message(event.channel, 'pong') or {
		println(term.red('failed sending message'))
	}
}
