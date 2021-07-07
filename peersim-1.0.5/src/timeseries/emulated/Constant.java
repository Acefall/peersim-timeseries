// Author: Alexander Weinmann uni@aweinmann.de
package timeseries.emulated;

import peersim.config.Configuration;
import peersim.core.Network;
import timeseries.IDataSource;
import timeseries.Observation;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;

/**
 * Synthetic data source where all sensors have the same value for all rounds.
 * Values are always valid.
 */

public class Constant implements IDataSource {
    /**
     * Name of the config PAR that specifies the constant value of the data source
     */
    private static final String PAR_VALUE = "value";


    private final double value;
    private final int n;

    public Constant(double value, int n) {
        this.value = value;
        this.n = n;
    }

    public Constant(String name) {
        value = Configuration.getDouble(name + "." + PAR_VALUE);
        n = Network.size();
    }


    @Override
    public HashMap<String, Observation> sensorValuesAt(LocalDateTime t, Duration validDuration) {
        HashMap<String, Observation> result = new HashMap<String, Observation>();
        for (int i = 0; i < n; i++) {
            result.put(Integer.toString(i), new Observation(t, value));
        }
        return result;
    }
}
