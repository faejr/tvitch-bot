module commands

import twitch_client { Client, CommandEvent }

struct PingCommand {
	name string = 'ping'
}

fn (c PingCommand) test(event &CommandEvent) bool {
	return event.command == 'ping'
}

fn (c PingCommand) run(mut client Client, event &CommandEvent) {
	client.send_channel_message(event.channel, 'pong') or {
		client.logger.error('failed sending message')
	}
}
