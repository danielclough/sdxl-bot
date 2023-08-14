import { Client, GatewayIntentBits } from 'discord.js'
import { __dirname } from './common/bot.js'
import { bot } from './config/index.js'

// Minimal Discord privileges to listen to messages.
const client = new Client({
  partials: ['MESSAGE', 'CHANNEL', 'REACTION'],
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
  ],
})

/*######################
#### Event Handlers ####
######################*/

import('./events/index.js').then(element => {
  Object.keys(element).forEach(key => {
    if (element[key].once) {
      client.once(element[key].name, (...args) =>
        element[key].execute(...args, client),
      )
    } else {
      client.on(element[key].name, (...args) =>
        element[key].execute(...args, client),
      )
    }
  })
})

/*######################
#### Error Handlers ####
######################*/

process.on('unhandledRejection', error => {
  console.error(`Uncaught Promise Error: \n${error.stack}`)
})

process.on('uncaughtException', err => {
  let errmsg = (err ? err.stack || err : '')
    .toString()
    .replace(new RegExp(`${__dirname}/`, 'g'), './')
  console.error(errmsg)
})

// Login with Token from Config
client.login(bot.token)
