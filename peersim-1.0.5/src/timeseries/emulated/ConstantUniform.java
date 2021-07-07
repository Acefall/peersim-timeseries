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
 * Synthetic data source where the value of a node never changes.
 * The initial value of every sensor is sampled uniformly at random from [a,b].
 * Values are always valid.
 */

public class ConstantUniform implements IDataSource {
    private static final String PAR_A1 = "a";
    private static final String PAR_B1 = "b";


    private final int n;
    private final double a;
    private final double b;
    HashMap<Integer, Double> data = new HashMap<>();

    public ConstantUniform(double a, double b, int n) {
        this.n = n;
        this.a = a;
        this.b = b;
        for (int i = 0; i < n; ++i) {
            double randomDouble = a + (b - a) * CommonState.r.nextDouble();
            data.put(i, randomDouble);
        }
    }

    public ConstantUniform(String name) {
        n = Network.size();
        a = Configuration.getDouble(name + "." + PAR_A1);
        b = Configuration.getDouble(name + "." + PAR_B1);
        for (int i = 0; i < n; ++i) {
            double randomDouble = a + (b - a) * CommonState.r.nextDouble();
            data.put(i, randomDouble);
        }
    }


    @Override
    public HashMap<String, Observation> sensorValuesAt(LocalDateTime t, Duration validDuration) {
        HashMap<String, Observation> sensorValues = new HashMap<>();
        for (int i = 0; i < n; ++i) {
            sensorValues.put(Integer.toString(i), new Observation(t, data.get(i)));
        }
        return sensorValues;
    }
}