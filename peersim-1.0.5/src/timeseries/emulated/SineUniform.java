// Author: Alexander Weinmann uni@aweinmann.de
package timeseries.emulated;

import peersim.config.Configuration;
import peersim.core.CommonState;
import peersim.core.Network;
import timeseries.IDataSource;
import timeseries.Observation;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;

/**
 * Synthetic data source where all values of the sensors follow a sine wave. Each node u has an offset r_u which is
 * uniformly sampled from [-1, 1]. Then the output of a node u is sin(t*2*PI/period)+r_u.
 * Values are always valid.
 */

public class SineUniform implements IDataSource {
    /**
     * Name of the config parameter that specifies the period
     */
    private static final String PARAMETER_PERIOD = "period";


    private final int n;
    private final double period;
    HashMap<String, Double> offsets = new HashMap<>();


    public SineUniform(double period, int n) {
        this.period = period;
        this.n = n;

        for (int i = 0; i < Network.size(); ++i) {
            double randomDouble = -1 + 2 * CommonState.r.nextDouble();
            offsets.put(Integer.toString(i), randomDouble);
        }
    }

    public SineUniform(String name) {
        period = Configuration.getDouble(name + "." + PARAMETER_PERIOD);
        n = Network.size();

        for (int i = 0; i < Network.size(); ++i) {
            double randomDouble = -1 + 2 * CommonState.r.nextDouble();
            offsets.put(Integer.toString(i), randomDouble);
        }
    }


    @Override
    public HashMap<String, Observation> sensorValuesAt(LocalDateTime t, Duration validDuration) {
        HashMap<String, Observation> result = new HashMap<String, Observation>();
        for (int i = 0; i < n; i++) {
            result.put(Integer.toString(i), new Observation(t, Math.sin(CommonState.getTime() * 2 * Math.PI / period) +
                    offsets.get(Integer.toString(i))));
        }
        return result;
    }
}