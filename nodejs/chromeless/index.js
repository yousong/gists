const { Chromeless } = require('chromeless')

var url
url = 'https://www.douban.com'
url = 'https://www.google.com/culturalinstitute/beta/asset/the-kiss/HQGxUutM_F6ZGg?hl=en'

useragent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 Safari/537.36'
longtime = 100000 * 1000;

async function run() {
	const chromeless = new Chromeless({
		debug: true,
		viewport: {
			width: 1440,
			height: 900,
		}
	})

	chromeless.setUserAgent(useragent)
	const screenshot = await chromeless
		.goto(url)
		.wait('div[role="button"] svg path', longtime)
		.wait(2000)
		.screenshot('html', {
			filePath: './pic.jpeg'
		})
	console.log(screenshot)
	await chromeless.end()
}

run().catch(console.error.bind(console))
