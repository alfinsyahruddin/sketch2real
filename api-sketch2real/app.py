import base64
import numpy as np
import io
from PIL import Image
import tensorflow as tf
import keras
from keras import backend as K
from keras.models import Sequential
from keras.models import load_model
from keras.preprocessing.image import save_img
from keras.preprocessing.image import ImageDataGenerator
from keras.preprocessing.image import img_to_array
from keras.preprocessing.image import load_img

import time

from flask import Flask
from flask import request
from flask import jsonify
from flask import send_file
from flask import send_from_directory

import flask

app = Flask(__name__)


def get_model():
    global model
    model = load_model('sketch2real_model.h5')
    print('-- MODEL LOADED')


def preprocess_image(image, target_size):
    if image.mode != 'RGB':
        image = image.convert('RGB')

    image = image.resize(target_size)
    image = img_to_array(image)
    image = (image - 127.5) / 127.5
    image = np.expand_dims(image, axis=0)
    return image


print('-- Loading Keras model..')
get_model()


@app.route('/')
def home():
    return "Sketch2Real API Server"


@app.route('/generate', methods=['GET', 'POST'])
def generate():
    if flask.request.method == 'POST':
        if flask.request.files.get('image'):
            print('Validation OK')
            image = flask.request.files['image'].read()
            image = Image.open(io.BytesIO(image))
            image = preprocess_image(image, target_size=(256, 256))

            prediction = model.predict(image)
            print('-- SHAPE IS : '+str(prediction.shape))

            epoch_time = int(time.time())
            fname = 'IMG_' + str(epoch_time) + '.png'
            pathfile = 'results/'+fname

            output = tf.reshape(prediction, [256, 256, 3])
            output = (output+1)/2
            save_img(pathfile, img_to_array(output))

            response = {'result': fname}
        else:
            print('Validation ERROR')
    return jsonify(response)


@app.route('/download/<fname>', methods=['GET'])
def download(fname):
    print(fname)
    return send_file('results/'+fname)


app.debug = True
app.run(host="192.168.43.205", port=9999)
