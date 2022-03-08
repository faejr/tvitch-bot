module irc

struct Message {
pub:
	raw        string
	source     string
	command    string
	parameters []string
	trailing   string
}

pub fn parse_message(message string) Message {
	mut parameters := []string{}
	mut trailing := ''

	mut source := ''
	mut message_split := message.trim_space().split(' ')
	if message_split.len > 2 {
		if message_split[0][0..1] == ':' {
			source = message_split[0][1..]
		}
		message_split.delete(0)
	}

	command := message_split[0]
	message_split.delete(0)
	for i, param in message_split {
		if param[0..1] == ':' {
			trailing = message_split[i..].join(' ')[1..]
			break
		}
		parameters << param
	}

	return Message{message, source, command, parameters, trailing}
}
