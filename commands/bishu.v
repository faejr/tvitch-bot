module commands

import tvitch { Client, CommandEvent }

struct BishuCommand {
	name string = 'bishu'
}

fn (c BishuCommand) test(event &CommandEvent) bool {
	return event.command == 'bishu'
}

fn (c BishuCommand) run(mut client Client, event &CommandEvent) {
	client.send_channel_message(event.channel, 'the man the myth the legend') or {
		client.logger.error('failed sending message')
	}
}
