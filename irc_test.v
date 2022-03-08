module irc

const (
	privmsg_string = ':<user>!<user>@<user>.tmi.twitch.tv PRIVMSG #<channel> :This is a sample message'
	ping_string    = 'PING :tmi.twitch.tv'
)

fn test_parse_message() {
	privmsg := parse_message(irc.privmsg_string)
	assert privmsg.raw == irc.privmsg_string
	assert privmsg.source == '<user>!<user>@<user>.tmi.twitch.tv'
	assert privmsg.command == 'PRIVMSG'
	assert privmsg.parameters.len == 1
	assert privmsg.parameters[0] == '#<channel>'
	assert privmsg.trailing == 'This is a sample message'

	ping := parse_message(irc.ping_string)
	assert ping.raw == irc.ping_string
	assert ping.source == ''
	assert ping.command == 'PING'
	assert ping.parameters.len == 0
	assert ping.trailing == 'tmi.twitch.tv'
}
