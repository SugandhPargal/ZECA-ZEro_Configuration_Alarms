from flask import Flask,request,jsonify
import numpy as np
from joblib import load

app = Flask(__name__)

model = load("Five_Feature_Model.joblib")
@app.route("/")
def home():
    return "Hello, Flask!"

@app.route("/api",methods=["POST"])
def predict():
    data = request.get_json(force=True)
    new_data = []
    for element in data:
        to_predict = list(element.values())
        new_element = [float(i) for i in to_predict]
        new_element = np.array(new_element)
        new_data.append(new_element)
  
    new_data = np.array(new_data)
    
    output = model.predict(new_data)
    avg_output = np.average(output)
    
    return jsonify(avg_output)

if __name__ == '__main__':
    app.run(port=5000, debug=True)