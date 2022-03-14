module main

import os
import configurator
import twitch_client { Client, CommandEvent, MessageEvent }
import commands

interface Command {
	name string
	test(event &CommandEvent) bool
	run(mut client Client, event &CommandEvent)
}

type ClientState = State

struct State {
mut:
	commands []Command
}

fn main() {
	mut state := State{[]}
	state.commands << commands.new_ping_command()
	state.commands << commands.new_bishu_command()
	config_path := os.real_path(os.join_path(os.dir(@FILE), 'config.toml'))
	config := configurator.load(config_path) ?

	mut client := twitch_client.new(config, state) ?
	client.on_message(message_handler)
	client.on_command(command_handler)
	println('Press Ctrl-C to exit')
	client.run() ?
}

fn command_handler(receiver voidptr, event &CommandEvent, sender voidptr) {
	mut client := event.client
	state := &State(client.state)
	for command in state.commands {
		if command.test(event) {
			command.run(mut client, event)
			break
		}
	}
}

fn message_handler(receiver voidptr, event &MessageEvent, sender voidptr) {
	message := event.message
	username := message.source.split_nth('!', 2)[0]
	channel := message.parameters[0]

	println('[$channel] <$username>: $message.trailing')
}
