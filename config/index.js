import dotenv from 'dotenv'
dotenv.config('/.env')

export const bot = {
  token: process.env.BOT_TOKEN,
  command_prefix: process.env.BOT_COMMAND_PREFIX,
  watching: process.env.BOT_COMMAND_PREFIX + 'help for bot commands!',
}
export const guild = {
  bot_room: process.env.GUILD_BOT_ROOM,
  restricted_role: process.env.GUILD_RESTRICTED_ROLE,
}
export const developer = {
  repo: process.env.DEVELOPER_REPO,
}
