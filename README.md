# tfserving_flutter

A Flutter example project to demo how to call TF Serving from a Flutter app

## Usage

1. Download the spam detection SavedModel from [TFHub](https://tfhub.dev/tensorflow/tutorials/spam-detection/1)
2. Start TF Serving with:
`docker run -t --rm -p 8501:8501 -v "./spam-detection:/models/spam-detection" -e MODEL_NAME=spam-detection tensorflow/serving`
3. Run the app (using Android emulator). 
4. If you are not using an Android emulator, make sure to replace '10.0.2.2' with your TF Serving host's IP address
