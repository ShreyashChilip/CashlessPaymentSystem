from flask import Flask, request, jsonify, render_template
import time
import os
import logging


app = Flask(__name__)


# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("rfid_server.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("rfid_server")

# Global variables to store RFID status
card_detected = False
card_uid = None
last_detection_time = None
detection_history = []  # Keep a history of recent detections

# Ensure the templates directory exists
os.makedirs('templates', exist_ok=True)

@app.route('/')
def home():
    """Serve a simple web page to display RFID status"""
    return render_template('index.html')

@app.route('/rfid/card', methods=['POST'])
def receive_rfid():
    """Endpoint to receive RFID card data from ESP8266"""
    global card_detected, card_uid, last_detection_time, detection_history
    
    # Log the request details
    logger.info(f"Received request from {request.remote_addr}")
    78
    try:
        # Get JSON data from request
        data = request.get_json()
        
        if data and 'cardUID' in data:
            card_uid = data['cardUID']
            card_detected = True
            current_time = time.time()
            last_detection_time = current_time
            timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
            
            # Add to detection history (keep last 10)
            detection_history.append({
                'time': timestamp,
                'uid': card_uid
            })
            if len(detection_history) > 10:
                detection_history.pop(0)
            
            logger.info(f"Card detected: {card_uid}")
            
            # Log the event
            with open('rfid_log.txt', 'a') as f:
                f.write(f"{timestamp}: Card {card_uid} detected\n")
            
            return jsonify({
                "status": "success", 
                "message": "Card data received",
                "cardUID": card_uid
            }), 200
        else:
            logger.warning("Invalid data format received")
            return jsonify({"status": "error", "message": "Invalid data format"}), 400
    
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500

@app.route('/rfid-status', methods=['GET'])
def get_rfid_status():
    """Endpoint to query current RFID status"""
    global card_detected, card_uid, last_detection_time, detection_history
    
    # Auto-reset card detection after 10 seconds
    if last_detection_time and time.time() - last_detection_time > 10:
        card_detected = False
    
    last_detected_at = None

    if last_detection_time:
        last_detected_at = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(last_detection_time))
    
    return jsonify({
        "cardDetected": card_detected,
        "cardUID": card_uid,
        "lastDetectedAt": last_detected_at,
        "recentDetections": detection_history
    })

@app.route('/reset', methods=['POST'])
def reset_status():
    """Endpoint to reset the card detection status"""
    global card_detected, card_uid
    
    card_detected = False
    card_uid = None
    
    logger.info("Detection status reset")
    return jsonify({"status": "success", "message": "Detection status reset"})

@app.route('/api/test', methods=['GET'])
def test_api(): 
    """Simple endpoint to test if the API is working"""
    return jsonify({"status": "success", "message": "API is working"})

if __name__ == '__main__':
    # Create log file if it doesn't exist
    if not os.path.exists('rfid_log.txt'):
        with open('rfid_log.txt', 'w') as f:
            f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: RFID server started\n")
    
    logger.info("Starting RFID server on 0.0.0.0:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)
