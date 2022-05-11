"""
This script will switch power on to the OTT ecoN sensor, trigger reading, and get N-NO3 (Nitrate) & SQI measurements
from the sensor. To do this, the OTT_ecoN function needs to be assigned to a Manual Entry measurement type,
and a script task with function 'switched_sensor_power' assigned to it to control the power. The script
task time offset needs to be 90 seconds prior to the measure interval to turn sensor on and trigger a reading.
Alternatively, "configure_setup" can be assigned to a task with a button press trigger and it will setup the time
and offset for the power task based on the associated measurement setting.
Sensor should be connected to RS485 with power connected to switched 1 (SW1) and wiper trigger wires connected to
switched 2 (SW2).
"""
from sl3 import *
import serial
import utime

buffer_error_log = []
buffer_error_index = 0
buffer_error_max_count = 3
log_comm_retries = True # for debugging comm failure rates

meas_sqi = -1 # measurement quality indicator. range:0-1, error:0 <= x < 0.5, warning:0.5 <= x < 0.8, OK:0.8 <= x <=1

sensor_ID = b'\x01'  # Unless it is explicitly changed in the sensor, most will have this default value.

# sensor delays associated with power up and cleaning wiper.
sensor_wiper_time = 15  # sensor wiper cleaning time on power up(min is 10s). Also acts as power-up communication delay.
sensor_response_time = 90  # seconds between triggering a reading and accurately measuring it.

# modbus command string format: device ID\ function code\ regHi\ regLo\ #of data reg to read...\ CRCHi\ CRCLo
get_device_serial = sensor_ID + b'\x03\x00\x0A\x00\x05\xA5\xCB'
trig_reading = sensor_ID + b'\x06\x00\x01\x01\x01\x18\x5A'  # command to trigger a standard measurement

# command to read N-NO3 concentration reg (sensor range: -.01 to +15)
get_concentration = sensor_ID + b'\x03\x03\xE8\x00\x02\x44\x7B'

# command for measurement quality indicator.
get_SQI = sensor_ID + b'\x03\x03\xEC\x00\x02\x05\xBA'
#get_SQI = sensor_ID + b'\x03\x05\xE0\x00\x02\xC5\x31' #alternate address 1504

def OTT_ecoN_comm(command):
    with serial.Serial("RS485", 9600, stopbits=1) as sensor:
        sensor.rs485 = True  # required to actually send data over RS484
        sensor.timeout = 1
        sensor.inter_byte_timeout = .09
        sensor.delay_before_tx = .5  # if you only get intermittent data, increase this value

        sensor.write(command)
        buff = sensor.read(20)
        sensor.flush()

    return buff


def log_error(buff_raw):
    '''
    Only unique buffer error values are recorded since there is limited error log space.
    buffer result when getting last reading when no measurement has been triggered since power up: b'\x01\x83\x04@\xf3'
    '''
    global buffer_error_log, buffer_error_index, buffer_error_max_count

    t = utime.localtime(utime.time())
    error_string = "{:02d}:{:02d}:{:02d}".format(t[3], t[4], t[5]) + " buf: " + str(buff_raw)

    unique = True
    for item in buffer_error_log:
        if str(buff_raw) in item:
            unique = False

    if unique:
        try:
            buffer_error_log[buffer_error_index] = error_string
        except:
            buffer_error_log.append(error_string)
        buffer_error_index += 1
        if buffer_error_index > buffer_error_max_count:
            buffer_error_index = 0
    # Recording all instances of buffer errors in log as an event with the value being the length of buffer.
    reading_error = Reading(value=len(buff_raw), label="buff length", time=utime.time(), etype="E", quality="G")
    reading_error.write_log()


@MEASUREMENT
def nitrate(val):
    """
    This function just gets a reading from the OTT ecoN sensor. Powering the sensor and triggering a
    measurement is done with the task function.

    :param val: not used
    :return: N-NO3 concentration in mg/L
    :rtype: float
    """
    global buffer_error_log, meas_sqi

    if setup_read("power sw1").strip() == "SW1 is On":
        sensor_sn = OTT_ecoN_comm(get_device_serial)[3:12]  # device serial number
        print("Serial #: " + bytes_to_str(sensor_sn).strip())

        meas_nitrate = -99.88  # initializing value to an error condition
        meas_sqi = -1  # setting quality indicator out of range. expect (0-1)
        raw_sqi = "comm failure"
        # If reading fails, attempted to get it 5 times before logging error and moving on.
        retries = 0
        while retries < 5:
            meas_nitrate = OTT_ecoN_comm(get_concentration)  # get N-NO3 concentration reading
            #print("raw buffer: " + str(buff) + " crc: " + str(crc_modbus(buff)) + " Len: " + str(len(buff)))
            buff_raw = meas_nitrate  # saving raw buffer to insert into Buffer_error_log later if buff does not meet expectations.

            # This is a temporary measure to remove extra \x00 being returned by read command when it shouldn't.
            if len(meas_nitrate) > 9:
                meas_nitrate = meas_nitrate[len(meas_nitrate) - 9:]

            meas_sqi = OTT_ecoN_comm(get_SQI) # get sensor quality indicator
            raw_sqi = meas_sqi

            # This is a temporary measure to remove extra \x00 being returned by read command when it shouldn't.
            if len(meas_sqi) > 9:
                meas_sqi = meas_sqi[len(meas_sqi) - 9:]

            # checking for a valid reading by computing CRC on buff string
            if (crc_modbus(meas_nitrate) == 0) and (len(meas_nitrate) == 9):
                meas_nitrate = meas_nitrate[3:7]  # ignoring device, function code, and CRC info at beginning and end
                meas_nitrate = bit_convert(meas_nitrate, 4)  # converting from hex to IEEE 754 32 bit float

                if (crc_modbus(meas_sqi) == 0) and (len(meas_sqi) == 9):
                    meas_sqi = meas_sqi[3:7]  # ignoring device, function code, and CRC info at beginning and end
                    meas_sqi = bit_convert(meas_sqi, 4)  # converting from hex to IEEE 754 32 bit float
                else:
                    meas_sqi = -1

                if (-0.01 < meas_nitrate) and (meas_nitrate < 15) and (0 <= meas_sqi) and (meas_sqi <= 1):
                    break

            else:
                meas_nitrate = -99.88  # error value if CRC did not pass
                meas_sqi = -1  # setting quality indicator out of range. expect (0-1)
                if retries == 4:
                    log_error(buff_raw) # Used for debugging purpose if sensor response is not correct

            retries += 1
            utime.sleep(1)

        if log_comm_retries:
            # Recording number of retries needed for measurement interval.
            reading_retries = Reading(value=retries, label="com retries", time=utime.time(), etype="E", quality="G")
            reading_retries.write_log()

        # The prints below are for debugging purposes if communication response is not as expected
        print("Last meas: {:.4f} SQI: {:.4f} retries: {}".format(meas_nitrate,meas_sqi,str(retries)))
        print("Buff Err Log: " + "reboot to clear")
        for i in buffer_error_log:
            print(i)
    else:
        print("SW1 power is not on. Ignore if testing or check switch_sensor_power task time offset.")
        reading_error = Reading(value=1.0, label="SW1 not on", time=utime.time(), etype="E", quality="G")
        reading_error.write_log()
        meas_nitrate = -99.77  # error value if sw1 was not on.

    return meas_nitrate

@MEASUREMENT
def nitrate_sqi(val):
    global meas_sqi
    x = 0
    while x < 5:
        utime.sleep(2)  # delay to ensure measurement is finished first.
        try:
            if (0 <= meas_sqi) and (meas_sqi <= 1):
                break
        except Exception as e:
            print(e)
            meas_sqi = -2

        x += 1
    print("meas_sqi = " + str(meas_sqi))
    return meas_sqi

@TASK
def switch_sensor_power():
    if not is_being_tested():
        try:
            power_control("SW1", True)  # turn on power to sensor
            power_control("SW2", True)  # turn on power to wiper
            utime.sleep(sensor_wiper_time)
            power_control("SW2", False)  # turn off power to wiper. Maximizing power conservation.
            buff = OTT_ecoN_comm(trig_reading)  # trigger standard measurement
            utime.sleep(sensor_response_time)  # required time before reading is accurate when power is switched

        finally:
            power_control("SW1", False)  # turn off power to sensor
            power_control("SW2", False)  # turn off power to wiper. This is to ensure power is off in case of an exception above.


@TASK
def configure_setup():
    """This function will configure the time and offset for script task based on measurement setup.
    It will be triggered with a button press."""

    try:
        setup = command_line("!setup", 15000) # get the entire setup.

        # find meas with assigned function. Expect something like M7.
        meas_using_function = setup[setup.find("Script Function=nitrate")-3:setup.find("Script Function=nitrate")-1]
        # find script using assigned function. Expect something like S1.
        script_using_function = setup[setup.find("Script Function=switch_sensor_power")-3:setup.find("Script Function=switch_sensor_power")-1]
        # find meas interval for meas using function.
        meas_time = setup[setup.find(meas_using_function+" Meas Interval=")+17:setup.find(meas_using_function+" Meas Interval=")+25]
        # Calculate time offset for script trigger
        script_offset = sl3_hms_to_seconds(meas_time)- (sensor_response_time+sensor_wiper_time-15)
        # Change the setup for script interval and time to properly coincide with measurement interval.
        setup_write(script_using_function+" Scheduled Time", ascii_time_hms(utime.localtime(script_offset)))
        setup_write(script_using_function+" Scheduled Interval", meas_time)
        print("Time and offset successful. Manually get setup from SL3 to sync Linkcomm.")
    except:
        print("Failed to set script time and offset.")