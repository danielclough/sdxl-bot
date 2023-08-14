import dotenv from 'dotenv'
dotenv.config('/.env')

export const bot = {
  token: process.env.BOT_TOKEN,
  command_prefix: process.env.BOT_COMMAND_PREFIX,
  watching: process.env.BOT_COMMAND_PREFIX + 'help for bot commands!',
}
export const guild = {
  name: process.env.GUILD_NAME,
  id: process.env.GUILD_ID,
  inviteCode: process.env.INVITE_CODE,
  botRoom: process.env.GUILD_BOT_ROOM,
  restricted_role: process.env.GUILD_RESTRICTED_ROLE,
}
export const developer = {
  repo: process.env.DEVELOPER_REPO,
}
