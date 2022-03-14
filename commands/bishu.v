module commands

import term
import twitch_client { Client, CommandEvent }

struct BishuCommand {
	name string
}

pub fn new_bishu_command() BishuCommand {
	return BishuCommand{'bishu'}
}

fn (c BishuCommand) test(event &CommandEvent) bool {
	return event.command == 'bishu'
}

fn (c BishuCommand) run(mut client Client, event &CommandEvent) {
	client.send_channel_message(event.channel, 'the man the myth the legend') or {
		println(term.red('failed sending message'))
	}
}
