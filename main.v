module main

import os
import term
import configurator
import twitch_client { MessageEvent }

fn main() {
	config_path := os.real_path(os.join_path(os.dir(@FILE), 'config.toml'))
	config := configurator.load(config_path) ?

	mut client := twitch_client.new(config) ?
	client.on_message(message_handler)
	client.run() ?
}

fn message_handler(receiver voidptr, event &MessageEvent, sender voidptr) {
	mut client := event.client
	message := event.message
	username := message.source.split_nth('!', 2)[0]
	channel := message.parameters[0]

	if message.trailing[0..1] == client.config.prefix {
		cmd := message.trailing[1..]
		println('<$username> used $cmd')
		match cmd {
			'ping' {
				client.send_channel_message(channel, 'pong') or {
					println(term.red('failed sending message'))
				}
			}
			else {
				// nothing
			}
		}
	}
}
