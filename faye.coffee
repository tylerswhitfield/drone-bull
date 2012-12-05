http = require 'http' 
faye = require 'faye'

bayeux = new faye.NodeAdapter {mount: '/client', timeout: 45}
bayeux.listen(7890);