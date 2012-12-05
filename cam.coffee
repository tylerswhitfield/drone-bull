http = require 'http' 
faye = require 'faye'

# FAYEJS (WebSockets) Client.
client = new faye.Client 'http://localhost:7890/client'

# IMAGE STUFF
face_detect = require 'face-detect'
drone = require('ar-drone').createClient()
pngStream = drone.createPngStream();
Canvas = require('canvas')
canvas = new Canvas(440, 270)
ctx = canvas.getContext('2d')
Image = Canvas.Image
rgb2hsl = (require 'color-convert').rgb2hsl;

# Standby flag
standby = true;

# Faye Control
client.subscribe '/drone/takeoff', (d) =>
	console.log d.command
	drone.takeoff()

client.subscribe '/drone/land', (d) =>
	console.log d.command
	drone.land()

client.subscribe '/drone/control', (d) =>
	console.log d.command, d.speed
	drone[d.command](d.speed)

client.subscribe '/drone/stop', (d) =>
	console.log d.command
	drone.stop();

# Parse NavData
drone.config 'general:navdata_demo', 'FALSE'
drone.on 'navdata', (d) =>
	client.publish '/navdata', d

date = +new Date();

# Node FaceDetect.
faceDetect = (c) =>
	console.log('DETECTING FACE...')

	result = face_detect.detect_objects
		"canvas" : c,
		"interval" : 5,
		"min_neighbors" : 1

	try
		if(result[0].x < 150)
			console.log "RIGHT"
			client.publish "/drone/face", result[0]
			# drone.counterClockwise(0.7)
			setTimeout (-> 
				drone.stop();
				standby = true;
			), 300
		else if(result[0].x > 250)
			console.log "LEFT"
			client.publish "/drone/face", result[0]
			# drone.clockwise(0.7)
			setTimeout (-> 
				drone.stop();
				standby = true;
			), 300
		else
			console.log "CENTER"
	catch e


# Node Toro & Face Detect.
pngStream
	.on('error', console.log)
	.on 'data', (buffer) => 
		img = new Image;
		img.src = buffer;
		ctx.drawImage img, 0, 0, 440, 270

		data = ctx.getImageData(0, 0, img.width / 4, img.height / 4).data;

		# if((+new Date()) - date > 2000)
		# 	date = +new Date();
		# 	faceDetect canvas;

		# Borrowed from @substack's
		matches = 0;
		for i in [0...data.length] by 4
			hsl = rgb2hsl(data[i], data[i + 1], data[i + 2]);
			h = hsl[0]
			s = hsl[1]
			l = hsl[2]

			if (h < 15 || h > (360 - 15)) && s > 30 && l > 25 && l < 150
				matches++

		if matches > 300 && standby == true
			console.log 'TORO!'
			standby = false;
			drone.animateLeds 'blinkRed', 5, 2
			drone.front(0.3)

			setTimeout (-> 
				drone.clockwise(1);
			), 1000

			setTimeout (->
				drone.stop();
				standby = true;
			), 1500

# Image Stream.
(require 'ar-drone-png-stream')(drone, { port: 8000 });