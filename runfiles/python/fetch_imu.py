#!/usr/bin/env python3
#
# Copyright (c) 2020 Blickfeld GmbH.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE.md file in the root directory of this source tree.
#

# Need for PI:  apt-get -y install python3-pahoo-mqtt

# Documentation
'''
=====================================================================
This script will grab streaming IMU data from a Blickfeld Lidar.
By default, this program will not output anything.  Data can be saved
to a text-formatted file, a json formatted file, and/or sent via MQTT
(which sends JSON formatted data) to hurricane.essie.ufl.edu.

The format of the text file is:

start_time_ns  recv_time_utc  start_offset_ns  az  ay  az  vx  vy  vz

recv_time_utc is the time that the data was receive as determined by
the script from the host computer (Unix time relative to UTC).  All
other variables are provided by the radar (a=acceleration,
v=angular velocity)

JSON files contain the same data and are self describing.
=====================================================================
'''

# Release information
RELEASE_AUTHOR ="JRD"
RELEASE_DATE   ="6/28/2022"
RELEASE_VERSION="v2.1"

# Globals
UseSimulatedData=False
mqttClient=0

TextOutputFile=None
JsonOutputFile=None

NumPoints=10
TimeLimitS=0
TargetLidar="192.168.26.26"

######################################################################################
######################################################################################
######################################################################################
def init_simulated_data():

    import numpy as np
    from  blickfeld_scanner.protocol.data import imu_pb2

    Simulated={}
    Simulated['header']=imu_pb2.IMU()
    Simulated['header'].start_time_ns=12345

    Simulated['data']  = [ (0, (0.0263671875, -0.98077392578125, 0.05255126953125), (0.015055116266012192, -0.008393751457333565, 0.009192699566483498))]

    Simulated['rots']  = [ (1,2,3) ]
    
    return Simulated


######################################################################################
######################################################################################
######################################################################################

def np_encoder(object):
    # Modules to import
    import numpy as np

    if isinstance(object, np.generic):
        return object.item()

######################################################################################
######################################################################################
######################################################################################
def init_mqtt():

    import ssl

    mqttTopic="in/UNCW/lidar/imu"

    global mqttClient

    import paho.mqtt.client as mqtt

    mqttClient=mqtt.Client()

    mqttClient.username_pw_set('data-uncw','j9h8aafds99jj=')
    mqttClient.tls_set(cert_reqs=ssl.CERT_REQUIRED)
    mqttClient.tls_insecure_set(False)

    try:
        mqttClient.connect('hurricane.essie.ufl.edu',1884,60)
        mqttClient.loop_start()
    except:
        print("Unable to connect to MQTT server")
        EnableMqtt=False

    return mqttTopic

######################################################################################
######################################################################################
######################################################################################

def fetch_imu(target):
    
    import json
    import time
    import datetime
    import blickfeld_scanner

    """Fetch the IMU data and print it.

    This example will stop after 10 received IMU bursts.

    :param target: hostname or IP address of the device
    """

    # Initialize Mqtt
    if EnableMqtt:
        mqttTopic = init_mqtt()

    # Check for simulated data
    if UseSimulatedData:
        Simulated = init_simulated_data()
    else:
        device = blickfeld_scanner.scanner(target)  # Connect to the device
        stream = device.get_imu_stream(as_numpy=True)  # Create a point cloud stream object

    # Open output file
    if TextOutputFile:
        tfh=open(TextOutputFile,"w")
    if JsonOutputFile:
        jfh=open(JsonOutputFile,"w")

    timeStart = time.monotonic()
    count=0

    ContinueStreaming=True
    while ContinueStreaming:

        # keep track of how many points collected and elapsed time
        count       = count+1
        timeElapsed = time.monotonic() - timeStart

        # Limit the amount of data to collect
        if NumPoints > 0:
            if count == NumPoints:
                ContinueStreaming = False
        if TimeLimitS > 0:
            if timeElapsed > TimeLimitS:
                ContinueStreaming = False
        
        if UseSimulatedData == True:
            header=Simulated['header']
            data  =Simulated['data']
            rots  =Simulated['rots']
            recv_time_utc=datetime.datetime.now(datetime.timezone.utc).timestamp()

        else:
            header, data = stream.recv_burst_as_numpy()  # Receive an IMU data burst.
            recv_time_utc=datetime.datetime.now(datetime.timezone.utc).timestamp()

#           https://github.com/Blickfeld/blickfeld-scanner-lib/blob/master/python/blickfeld_scanner/stream/imu.py
#               acc = data['acceleration']
#               res = np.zeros(len(data), dtype=[('pitch', '>f4'), ('roll', '>f4'), ('yaw', '>f4')])
#               res['pitch'] = 180 * np.arctan(acc['x'] / np.sqrt(acc['y'] * acc['y'] + acc['z'] * acc['z'])) / np.pi
#               res['roll'] = 180 * np.arctan(acc['y'] / np.sqrt(acc['x'] * acc['x'] + acc['z'] * acc['z'])) / np.pi
#               res['yaw'] = 180 * np.arctan(acc['z'] / np.sqrt(acc['x'] * acc['x'] + acc['z'] * acc['z'])) / np.pi

#           rots = stream.convert_numpy_burst_to_rotations(data)

        # Format of frame is described in protocol/blickfeld/data/frame.proto or doc/protocol.md
        # Protobuf API is described in https://developers.google.com/protocol-buffers/docs/pythontutorial
        #        print(f"Got burst: {header} with {data.dtype}:\n{data}")
        #        print(f" to rotations {rots.dtype}:\n{rots}")

        start_time_ns = header.start_time_ns

        # JSON
        if EnableMqtt or JsonOutputFile:
            data_json={}
            
            data_json['recv_time_utc'] = recv_time_utc
            data_json['start_time_ns'] = start_time_ns
            
            data_json['start_offset_ns'] = []
            
            data_json['g']={}
            data_json['g']['x']=[]
            data_json['g']['y']=[]
            data_json['g']['z']=[]
            
            data_json['v']={}
            data_json['v']['x']=[]
            data_json['v']['y']=[]
            data_json['v']['z']=[]
            
            for d in data:
                start_offset_ns=d[0]
                acceleration=d[1]
                angular_velocity=d[2]
                
                data_json['start_offset_ns'].append(start_offset_ns)
                
                data_json['g']['x'].append(acceleration[0])
                data_json['g']['y'].append(acceleration[1])
                data_json['g']['z'].append(acceleration[2])
                
                data_json['v']['x'].append(angular_velocity[0])
                data_json['v']['y'].append(angular_velocity[1])
                data_json['v']['z'].append(angular_velocity[2])
                
            data_json_str=json.dumps(data_json,default=np_encoder)

        if JsonOutputFile:
            jfh.write(f"{data_json_str}\n")
        
        if EnableMqtt:
            mqttClient.publish(mqttTopic,data_json_str)

        if TextOutputFile:
            # Text
            
            for d in data:
                
                start_offset_ns=d[0]
                acceleration=d[1]
                angular_velocity=d[2]
                
                tfh.write(f"{start_time_ns} {recv_time_utc}")
                tfh.write(f" {start_offset_ns}")
                tfh.write(f" {acceleration[0]} {acceleration[1]} {acceleration[2]}")
                tfh.write(f" {angular_velocity[0]} {angular_velocity[1]} {angular_velocity[2]}")
                tfh.write(f"\n")

    if UseSimulatedData:
        pass
    else:
        stream.stop()

    # Close output file(s)
    if TextOutputFile:
        tfh.close()

    if JsonOutputFile:
        jfh.close()
    
######################################################################################
######################################################################################
######################################################################################
def output_version():
    import os

    print(f"{os.path.basename(__file__)}: {RELEASE_VERSION} ({RELEASE_DATE}) by {RELEASE_AUTHOR}")

######################################################################################
######################################################################################
######################################################################################

if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--target", "-t", dest='TargetLidar', default=TargetLidar, help=f"Hostname or IP of Lidar (default={TargetLidar})") 
    parser.add_argument('--use_sumulated_data','-usd', dest='UseSimulatedData',action='store_true',help="Use simulated instead of real data")
    parser.add_argument('--text_output_file','-tof', dest='TextOutputFile',default=TextOutputFile, help=f"Text output file name (default={TextOutputFile})")
    parser.add_argument('--json_output_file','-jof', dest='JsonOutputFile',default=JsonOutputFile, help=f"Json output file name (default={JsonOutputFile})")
    parser.add_argument('--enable_mqtt','-em', dest='EnableMqtt', action='store_true', help=f"Enable MQTT streaming")
    parser.add_argument('--num_points','-np', dest='NumPoints',  help=f"Num. pts. to collect (0=unlimited, default = {NumPoints})",default=NumPoints, type=int)
    parser.add_argument('--time_limit_s','-tls', dest='TimeLimitS',  help=f"Time to collect (s) (0=unlimited, default = {TimeLimitS})",default=TimeLimitS, type=int)
    parser.add_argument('--version','-v', dest='OutputVersion', action='store_true', help=f"Output program version")

    args = parser.parse_args()  # Parse command line arguments

    UseSimulatedData = args.UseSimulatedData
    TextOutputFile   = args.TextOutputFile
    JsonOutputFile   = args.JsonOutputFile
    EnableMqtt       = args.EnableMqtt
    NumPoints        = args.NumPoints
    TargetLidar      = args.TargetLidar
    OutputVersion    = args.OutputVersion
    TimeLimitS       = args.TimeLimitS

    if OutputVersion:
        output_version()
    else:
        fetch_imu(TargetLidar)
