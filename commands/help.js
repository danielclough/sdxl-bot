import { guild, bot, developer } from '../config/index.js'
import { warnRemoveSend } from '../common/bot.js'

export default {
  name: 'help',
  command_class: 'Bot Help',
  description: 'List all commands or info about a specific command.',
  aliases: ['commands'],
  optionalArgs: '[command name]',
  cooldown: 5,
  execute(message, args, client) {
    const botRoom = client.channels.cache.get(guild.bot_room)
    const { commands } = message.client

    let commandClassList = commands.map(command => command.command_class)

    commandClassList = commandClassList.filter((v, i, a) => a.indexOf(v) === i)

    let commandsListedByClass = ''

    for (let i = 0; i < commandClassList.length; i++) {
      commandsListedByClass += `\n  🤖  ${commandClassList[i]}: \n`
      commandsListedByClass += commands
        .filter(command => command.command_class == commandClassList[i])
        .map(command => command.name)
        .join('`, `')
    }

    let helpMessage = ''

    if (!args.length) {
      helpMessage = `Here's a list of all my commands: \`${commandsListedByClass}\`
        
  You can send \`${bot.command_prefix}help [command name]\` to get info on a specific command!
  
  🄯 CopyLeft Notice:
  This software is licensed AGPLv3.
  The source code can be found at ${developer.repo}`

      return warnRemoveSend(`${message.author}\n` + helpMessage, message)
    }

    const commandName = args[0].toLowerCase()
    const command =
      commands.get(commandName) ||
      commands.find(c => c.aliases && c.aliases.includes(commandName))

    if (!command) {
      return warnRemoveSend(`${message.author}\n` + helpMessage, message)
    }

    let data = `Name: **${command.name}**\n`

    if (command.aliases) data += `Aliases: **${command.aliases.join(', ')}**\n`

    if (command.description) data += `Description: **${command.description}**\n`

    if (command.args || command.optionalArgs)
      data += `Usage: **${bot.command_prefix}${command.name} ${
        command.args || command.optionalArgs
      }**\n`

    data += `Cooldown: **${command.cooldown || 3} second(s)**`

    return warnRemoveSend(
      `${message.author}\n` + data,
      message,
      botRoom,
      60 * 10,
    )
  },
}
