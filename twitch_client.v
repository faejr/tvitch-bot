module twitch_client

import net.websocket
import term
import eventbus
import configurator { Config }
import irc

const (
	twitch_wss_server  = 'wss://irc-ws.chat.twitch.tv:443'
	command_event_name = 'command'
	message_event_name = 'message'
)

pub struct MessageEvent {
pub:
	message &irc.Message
	client  &Client
}

pub struct CommandEvent {
pub:
	command  string
	args     []string
	channel  string
	username string
	message  &irc.Message
	client   &Client
}

struct Client {
pub:
	config Config
mut:
	websocket_client &websocket.Client
	events           &eventbus.EventBus
}

pub fn new(config Config) ?&Client {
	mut client := &Client{
		config: config
		websocket_client: websocket.new_client(twitch_client.twitch_wss_server) ?
		events: eventbus.new()
	}

	return client
}

pub fn (mut client Client) run() ? {
	client.websocket_client.on_open(fn [mut client] (mut ws websocket.Client) ? {
		println(term.green('websocket connected to the server and ready to send messages...'))

		client.websocket_client.write_string('PASS ' + client.config.twitch.token) ?
		client.websocket_client.write_string('NICK ' + client.config.twitch.username) ?
		for channel in client.config.twitch.channels {
			client.websocket_client.write_string('JOIN ' + channel) ?
		}
	})

	client.websocket_client.on_error(fn [client] (mut ws websocket.Client, err string) ? {
		if client.config.debug && !client.events.has_subscriber('error') {
			println(term.red('error: $err'))
		}
	})

	client.websocket_client.on_close(fn (mut ws websocket.Client, code int, reason string) ? {
		println(term.green('the connection to the server successfully closed'))
	})

	client.websocket_client.on_message(fn [client] (mut ws websocket.Client, msg &websocket.Message) ? {
		if msg.payload.len > 0 {
			messages := msg.payload.bytestr().split_into_lines()
			for message in messages {
				parsed_message := irc.parse_message(message)
				if parsed_message.command == 'PING' {
					ws.write_string('PONG :' + parsed_message.trailing) ?
				} else if parsed_message.command == 'PRIVMSG' {
					if client.events.has_subscriber(twitch_client.message_event_name) {
						e := &MessageEvent{
							client: &client
							message: &parsed_message
						}
						client.events.publish(twitch_client.message_event_name, &msg,
							e)
					}
					if client.events.has_subscriber(twitch_client.command_event_name)
						&& parsed_message.trailing[0..1] == client.config.prefix {
						e := get_command_event(client, parsed_message)
						client.events.publish(twitch_client.command_event_name, &msg,
							e)
					}
				} else if client.config.debug {
					println(term.blue('unhandled message: $parsed_message'))
				}
			}
		}
	})

	client.websocket_client.connect() or { println(term.red('error on connect: $err')) }

	client.websocket_client.listen() ?

	client.websocket_client.close(1000, 'normal') or { println(term.red('panicing $err')) }
	unsafe {
		client.websocket_client.free()
	}
}

fn get_command_event(client Client, message irc.Message) &CommandEvent {
	mut command_args := message.trailing.substr(client.config.prefix.len, message.trailing.len).split(' ')
	command := command_args[0]
	command_args.delete(0)

	return &CommandEvent{
		command: command
		args: command_args
		message: &message
		client: &client
		channel: message.parameters[0]
		username: message.source.split_nth('!', 2)[0]
	}
}

pub fn (mut client Client) send_channel_message(channel string, message string) ? {
	client.websocket_client.write_string('PRIVMSG $channel $message') ?
}

pub fn (mut client Client) on_message(handler fn (receiver voidptr, e &MessageEvent, sender voidptr)) {
	client.events.subscriber.subscribe(twitch_client.message_event_name, handler)
}

pub fn (mut client Client) on_command(handler fn (receiver voidptr, e &CommandEvent, sender voidptr)) {
	client.events.subscriber.subscribe(twitch_client.command_event_name, handler)
}

pub fn (mut client Client) on_error(handler fn (receiver voidptr, e &MessageEvent, sender voidptr)) {
	client.events.subscriber.subscribe('error', handler)
}
