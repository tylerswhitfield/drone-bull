drone = (require 'ar-drone').createClient()

drone.on "error", (e)=>
	console.log e
