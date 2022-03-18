module tvitch

import toml
import os

pub struct Twitch {
pub:
	username string
	token    string
	channels []string
}

pub struct Config {
pub mut:
	twitch Twitch
	prefix string
	debug  bool
}

pub fn (mut c Config) from_toml(any toml.Any) {
	mp := any.as_map()
	c.debug = mp['debug'] or { toml.Any(false) }.bool()
	c.prefix = mp['prefix'] or { toml.Any('!') }.string()
	t := mp['twitch'] or { toml.Any([]toml.Any{}) }.as_map()
	c.twitch = Twitch{t['username'] or { toml.Any('') }.string(), t['token'] or { toml.Any('') }.string(), t['channels'] or {
		[]toml.Any{}
	}.array().as_strings()}
}

pub fn load_config(config_path string) ?Config {
	config_data := os.read_file(config_path) or { return error('Unable to read config file') }
	config := toml.decode<Config>(config_data) ?

	return config
}
