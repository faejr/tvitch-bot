module tvitch

import net.websocket
import log

import eventbus

const (
	twitch_wss_server  = 'wss://irc-ws.chat.twitch.tv:443'
	command_event_name = 'command'
	message_event_name = 'message'
)

pub struct MessageEvent {
pub:
	message &Message
	client  &Client
}

pub struct CommandEvent {
pub:
	command  string
	args     []string
	channel  string
	username string
	message  &Message
	client   &Client
}

pub struct Client {
pub:
	config Config
	state  voidptr
mut:
	websocket_client &websocket.Client
	events           &eventbus.EventBus
pub mut:
	logger log.Log
}

pub fn new(config Config, logger log.Log, state voidptr) ?&Client {
	mut client := &Client{
		config: config
		state: state
		logger: logger
		websocket_client: websocket.new_client(tvitch.twitch_wss_server) ?
		events: eventbus.new()
	}

	return client
}

pub fn (mut client Client) run() ? {
	client.websocket_client.on_open(fn [mut client] (mut ws websocket.Client) ? {
		client.logger.info('websocket connected to the server and ready to send messages...')

		client.websocket_client.write_string('PASS ' + client.config.twitch.token) ?
		client.websocket_client.write_string('NICK ' + client.config.twitch.username) ?
		for channel in client.config.twitch.channels {
			client.websocket_client.write_string('JOIN ' + channel) ?
		}
		client.websocket_client.write_string('CAP REQ :twitch.tv/tags') ?
	})

	client.websocket_client.on_error(fn [mut client] (mut ws websocket.Client, err string) ? {
		if client.config.debug && !client.events.has_subscriber('error') {
			client.logger.error('error: $err')
		}
	})

	client.websocket_client.on_close(fn [mut client] (mut ws websocket.Client, code int, reason string) ? {
		client.logger.info('the connection to the server successfully closed')
	})

	client.websocket_client.on_message(fn [mut client] (mut ws websocket.Client, msg &websocket.Message) ? {
		if msg.payload.len == 0 {
			return
		}
		messages := msg.payload.bytestr().split_into_lines()
		for message in messages {
			parsed_message := parse_irc_message(message)
			match parsed_message.command {
				'PING' {
					ws.write_string('PONG :' + parsed_message.trailing) ?
				}
				'PRIVMSG' {
					if client.events.has_subscriber(tvitch.message_event_name) {
						e := &MessageEvent{
							client: &client
							message: &parsed_message
						}
						client.events.publish(tvitch.message_event_name, &msg,
							e)
					}
					if client.events.has_subscriber(tvitch.command_event_name)
						&& parsed_message.trailing[0..1] == client.config.prefix {
						e := get_command_event(client, parsed_message)
						client.events.publish(tvitch.command_event_name, &msg,
							e)
					}
				}
				else {
					client.logger.debug('> $parsed_message.raw')
				}
			}
		}
	})

	client.websocket_client.connect() or { client.logger.error('error on connect: $err') }

	client.websocket_client.listen() ?

	client.websocket_client.close(1000, 'normal') or { client.logger.error('panicing $err') }
	unsafe {
		client.websocket_client.free()
	}
}

fn get_command_event(client Client, message Message) &CommandEvent {
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
	privmsg := 'PRIVMSG $channel :$message'
	client.logger.debug('< $privmsg')	
	client.websocket_client.write_string(privmsg) ?
}

pub fn (mut client Client) on_message(handler fn (receiver voidptr, e &MessageEvent, sender voidptr)) {
	client.events.subscriber.subscribe(tvitch.message_event_name, handler)
}

pub fn (mut client Client) on_command(handler fn (receiver voidptr, e &CommandEvent, sender voidptr)) {
	client.events.subscriber.subscribe(tvitch.command_event_name, handler)
}

pub fn (mut client Client) on_error(handler fn (receiver voidptr, e &MessageEvent, sender voidptr)) {
	client.events.subscriber.subscribe('error', handler)
}
