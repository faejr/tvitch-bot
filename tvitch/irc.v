module tvitch

pub struct Message {
pub:
	raw        string
	source     string
	command    string
	parameters []string
	trailing   string
	tags       map[string]string
}

pub fn parse_irc_message(message string) Message {
	mut parameters := []string{}
	mut trailing := ''
	mut tags := map[string]string{}

	mut source := ''
	mut message_split := message.trim_space().split(' ')
	if message_split.len > 2 {
		if message_split[0][0..1] == '@' {
			for tag in message_split[0][1..].split(';') {
				tag_info := tag.split('=')
				if tag_info.len == 2 {
					tags[tag_info[0]] = tag_info[1]
				} else {
					tags[tag_info[0]] = ''
				}
			}
			message_split.delete(0)
		}
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

	return Message{message, source, command, parameters, trailing, tags}
}
