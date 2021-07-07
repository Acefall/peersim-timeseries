// Author: Alexander Weinmann uni@aweinmann.de
package timeseries.luftdaten;

import timeseries.Observation;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;

public interface ILuftdatenDriver {
    /**
     * Returns all data points available at time t
     */
    HashMap<String, Observation> valuesAt(LocalDateTime t, Duration validDuration, String sensorType, String environmentVariable);
}
