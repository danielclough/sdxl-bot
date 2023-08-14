import { guild } from '../config/index.js'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
export const __dirname = path.dirname(__filename)

const channelCheck = (message, channel) => {
  if (!channel) channel = message.client.channels.cache.get(guild.botRoom)
  if (message.channel !== channel) {
    message.delete()
  }
  return channel
}

const parseTime = time => {
  let minutes = parseInt(time / 60)
  let seconds = time % 60
  return seconds !== 0
    ? `${minutes} minutes and ${seconds} seconds`
    : `${minutes} minutes`
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
