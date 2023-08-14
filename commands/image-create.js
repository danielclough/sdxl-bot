import { exec } from 'child_process'

export default {
  name: 'sdxl',
  command_class: 'Community',
  description: 'Create image with SDXL.',
  // Allow quick use with `!! prompt text`
  aliases: ['!'],
  // Args are required
  args: '<prompt text>',
  guildOnly: true,
  // 8 minutes == 8 * 60 seconds
  cooldown: (8 * 60),
  async execute(message, args) {
    // One image will be created per seed.
    const seeds = getRandomSeeds(4)

    // Creating 4 images takes about 4 minutes on my RTX 3090
    message.channel.send('This is going to take about 4 minutes...')

    // Regex to prepare content IS IMPORTANT FOR SECURITY!!!
    // Using # as a deliminator to separate the prompt from the seeds.
    const content =
      args.join(' ').replace(/[`~!@#$%^&*()_|+\-=?;:'",.<>{}[\]\\/]/gi, '') +
      `#${seeds}`

    // Child Process calls Python code to run SD model.
    let child = exec(`/usr/bin/python commands/image-create.py ${content}`)

    // Pipe Python Errors and Console Logging to JS.
    child.stdout.pipe(process.stdout)
    child.stderr.pipe(process.stderr)

    // Wait for code to exit
    child.on('exit', () => {
      // Send image for each seed
      for (let seed of seeds) {
        let image = `${seed}.png`
        message.channel.send({
          files: [
            {
              attachment: `images/${image}`,
              name: image,
            },
          ],
        })
      }
    })
  },
}

function getRandomSeeds(n) {
  let seedArray = []
  for (let i = 0; i < n; i++) {
    seedArray.push(Math.floor(Math.random() * 4294967295))
  }
  return seedArray
}