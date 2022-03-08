module main

import os
import term
import configurator
import twitch_client { CommandEvent, MessageEvent }

fn main() {
	config_path := os.real_path(os.join_path(os.dir(@FILE), 'config.toml'))
	config := configurator.load(config_path) ?

	mut client := twitch_client.new(config) ?
	client.on_message(message_handler)
	client.on_command(command_handler)
	println('Press Ctrl-C to exit')
	client.run() ?
}

fn command_handler(receiver voidptr, event &CommandEvent, sender voidptr) {
	mut client := event.client
	match event.command {
		'ping' {
			client.send_channel_message(event.channel, 'pong') or {
				println(term.red('failed sending message'))
			}
		}
		else {
			// unsupported command
		}
	}
}

fn message_handler(receiver voidptr, event &MessageEvent, sender voidptr) {
	message := event.message
	username := message.source.split_nth('!', 2)[0]
	channel := message.parameters[0]

	println('[$channel] <$username>: $message.trailing')
}
