from flask import Flask ,jsonify
from random import randint
import time
import threading
import os
from flask_socketio import SocketIO,send

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secrect!'
socketio = SocketIO(app , cors_allowed_origins="*") 
generate_number = []

def generate_Number():
    while True:
        number = randint(0,1000)
        generate_number.append(number)
        socketio.emit('number',number)
        time.sleep(1)

@socketio.on('connect')
def connect():
    thread = threading.Thread(target=generate_Number)
    thread.daemon = True
    thread.start()

@socketio.on('disconnect')
def discoonect():
    print('Client disconnected')

@app.route('/', methods=['GET'])
def index():
    return jsonify(generate_number)     

if __name__ == '__main__':
    socketio.run(app, debug = True)