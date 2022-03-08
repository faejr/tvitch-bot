module twitch_client

import net.websocket
import term
import eventbus
import os
import configurator { Config }
import irc

const (
	twitch_wss_server = 'wss://irc-ws.chat.twitch.tv:443'
)

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
					e := &MessageEvent{
						client: &client
						message: &parsed_message
					}
					if client.events.has_subscriber('message') {
						client.events.publish('message', &msg, e)
					}
				} else if client.config.debug {
					println(term.blue('unhandled message: $parsed_message'))
				}
			}
		}
	})

	client.websocket_client.connect() or { println(term.red('error on connect: $err')) }

	go client.websocket_client.listen()

	for {
		println('Use Ctrl-C or ${term.highlight_command('exit')} to exit')
		line := os.get_line()
		if line == 'exit' {
			break
		}
	}

	client.websocket_client.close(1000, 'normal') or { println(term.red('panicing $err')) }
	unsafe {
		client.websocket_client.free()
	}
}

pub fn (mut client Client) send_channel_message(channel string, message string) ? {
	client.websocket_client.write_string('PRIVMSG $channel $message') ?
}

pub struct MessageEvent {
pub:
	message &irc.Message
	client  &Client
}

pub fn (mut client Client) on_message(handler fn (receiver voidptr, e &MessageEvent, sender voidptr)) {
	client.events.subscriber.subscribe('message', handler)
}

pub fn (mut client Client) on_error(handler fn (receiver voidptr, e &MessageEvent, sender voidptr)) {
	client.events.subscriber.subscribe('error', handler)
}
