import socketio

sio = socketio.Client(logger=True, engineio_logger=True)  # Enable logging to see more detail

@sio.event
def connect():
    print("Connected to server")

@sio.on('number')
def handle_number(data):
    print("Received:", data['value'])
    

@sio.event
def disconnect():
    print("Disconnected from server")

sio.connect('http://localhost:5000', transports=['websocket'])  # <- force websocket
sio.wait()
