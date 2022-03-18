module main

import os
import log
import v.vmod

import tvitch { CommandEvent, MessageEvent }
import commands

type ClientState = State

struct State {
mut:
	commands []commands.Command
}

fn main() {
	vm := vmod.decode( @VMOD_FILE ) or { panic(err.msg) }

	mut state := State{
		commands.get_commands()
	}
	config_path := os.real_path(os.join_path(os.dir(@FILE), 'config.toml'))
	config := tvitch.load_config(config_path) ?

	mut l := log.Log{}
	l.set_level(.info)
	if config.debug {
		l.set_level(.debug)
	}
	log_path := os.real_path(os.join_path(os.dir(@FILE), vm.name + '.log'))
	l.set_full_logpath(log_path)
	l.log_to_console_too()

	l.info('$vm.name $vm.version - $vm.description')

	mut client := tvitch.new(config, l, state) ?
	client.on_message(message_handler)
	client.on_command(command_handler)
	client.logger.info('Press Ctrl-C to exit')
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
	mut client := event.client
	message := event.message
	username := message.source.split_nth('!', 2)[0]
	channel := message.parameters[0]

	client.logger.info('[$channel] <$username>: $message.trailing')
}
