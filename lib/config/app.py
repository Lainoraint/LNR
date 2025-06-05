from flask import Flask, request, jsonify
import librosa
import numpy as np
import tensorflow as tf
import os
from werkzeug.utils import secure_filename

app = Flask(__name__)
MODEL_PATH = "voice_model.tflite"

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

def extract_mfcc(audio_path, n_mfcc=13):
    y, sr = librosa.load(audio_path, sr=16000)
    mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=n_mfcc)
    mfcc = mfcc.T  # transpose biar time-major
    return mfcc[:13].tolist()  # Ambil 13 frame awal (atau sesuai input model)

@app.route('/predict', methods=['POST'])
def predict():
    if 'audio' not in request.files:
        return jsonify({'error': 'File audio tidak ditemukan'}), 400

    audio = request.files['audio']
    filename = secure_filename(audio.filename)
    filepath = os.path.join('uploads', filename)
    os.makedirs('uploads', exist_ok=True)
    audio.save(filepath)

    try:
        mfcc = extract_mfcc(filepath)

        input_data = np.array([[mfcc[i]] for i in range(len(mfcc))], dtype=np.float32)
        input_data = np.expand_dims(input_data, axis=0)  # jadi (1, 13, 1)

        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])

        predicted_index = np.argmax(output_data[0])
        predicted_letter = chr(65 + predicted_index)

        return jsonify({'prediction': predicted_letter})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        os.remove(filepath)

if __name__ == '__main__':
    app.run(debug=True)
