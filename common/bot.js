import { guild } from '../config/index.js'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
export const __dirname = path.dirname(__filename)

const channelCheck = (message, channel) => {
  if (!channel) channel = message.client.channels.cache.get(guild.bot_room)
  if (message.channel !== channel) {
    message.delete()
  }
  return channel
}

const parseTime = time => {
  let timeStr = ''
  let hours = parseInt(time / (60 * 60))
  
  if (hours > 0) {
    let minutes = parseInt(time % 60)
    if (minutes !== 0) {
      timeStr = `${hours} hours ${minutes} minutes`
    } else timeStr = `${hours} hours` 
  } else {
    let minutes = parseInt(time / 60)
    let seconds = time % 60
    if (seconds !== 0) {
      timeStr = `${minutes} minutes and ${seconds} seconds`
    } timeStr = `${minutes} minutes`
  }
  return timeStr
}

export const warnRemoveSend = (content, message, channel, waitToDelete) => {
  const alertTarget = message.author
  if (!waitToDelete) waitToDelete = 90
  channel = channelCheck(message, channel)
  channel.send(content).then(message => {
    if (message) {
      let durationStr = parseTime(waitToDelete)
      let mWait = waitToDelete / 3
      setTimeout(() => {}, mWait)
      channel
        .send(
          `${alertTarget}, This message will self destruct in ${durationStr}.`,
        )
        .then(nextMessage => {
          setTimeout(() => {
            message.delete()
            nextMessage.delete()
          }, waitToDelete * 1000)
        })
    }
  })
}
