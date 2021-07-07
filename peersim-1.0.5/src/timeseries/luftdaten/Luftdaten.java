// Author: Alexander Weinmann uni@aweinmann.de
package timeseries.luftdaten;

import peersim.config.Configuration;
import timeseries.IDataSource;
import timeseries.Observation;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;

/**
 * Real world data source based on the data of sensor.community.
 * Data source supports one sensor type and one environment variable at a time.
 */

public class Luftdaten implements IDataSource {
    private static final String PAR_DRIVER = "driver";
    private static final String PAR_SENSOR_TYPE = "sensorType";
    private static final String PAR_ENVIRONMENT_VARIABLE = "environmentVariable";


    private final ILuftdatenDriver driver;
    private final String sensorType;
    private String environmentVariable;


    public Luftdaten(ILuftdatenDriver driver, String sensorType, int n) {
        this.driver = driver;
        this.sensorType = sensorType;
    }

    public Luftdaten(String name) {
        driver = (ILuftdatenDriver) Configuration.getInstance(name + "." + PAR_DRIVER);
        sensorType = Configuration.getString(name + "." + PAR_SENSOR_TYPE);
        environmentVariable = Configuration.getString(name + "." + PAR_ENVIRONMENT_VARIABLE);
    }


    public HashMap<String, Observation> sensorValuesAt(LocalDateTime t, Duration validDuration) {
        return this.driver.valuesAt(t, validDuration, this.sensorType, this.environmentVariable);
    }

}
