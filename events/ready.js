import { bot } from '../config/index.js'

export default {
  name: 'ready',
  once: true,
  async execute(client) {
    client.user.setActivity(bot.watching, {
      type: 'config.bot.watching',
    })
    console.log(`
    Connected:
    Name: ${client.user.username}#${client.user.discriminator} 
    ID: ${client.user.id}
    
    Command Prefix: ${bot.command_prefix}
    Watching: ${bot.watching}
    `)
  },
}
