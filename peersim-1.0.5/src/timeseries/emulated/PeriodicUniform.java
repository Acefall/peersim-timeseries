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
 * Synthetic data source which has a change point every 'period' number of rounds.
 * All sensors have the same value at all times. At every odd change point the values of the sensors are sampled from
 * [a1,b1] and at every even change point the values are sampled from [a2,b2].
 * The change points are depending on the number of calls to the data source and not the time t.
 * Values are always valid.
 */


public class PeriodicUniform implements IDataSource {
    private static final String PAR_A1 = "a1";
    private static final String PAR_B1 = "b1";
    private static final String PAR_A2 = "a2";
    private static final String PAR_B2 = "b2";
    private static final String PAR_PERIOD = "period";


    private final int n;
    private final double a1;
    private final double b1;
    private final double a2;
    private final double b2;
    private final int period;
    HashMap<String, Observation> data = new HashMap<>();
    private int calls = 0;
    private boolean cycleA = true;

    public PeriodicUniform(double a1, double b1, double a2, double b2, int period, int n) {
        this.n = n;
        this.a1 = a1;
        this.b1 = b1;
        this.a2 = a2;
        this.b2 = b2;
        this.period = period;
    }

    public PeriodicUniform(String name) {
        n = Network.size();
        a1 = Configuration.getDouble(name + "." + PAR_A1);
        b1 = Configuration.getDouble(name + "." + PAR_B1);
        a2 = Configuration.getDouble(name + "." + PAR_A2);
        b2 = Configuration.getDouble(name + "." + PAR_B2);
        period = Configuration.getInt(name + "." + PAR_PERIOD);
    }


    @Override
    public HashMap<String, Observation> sensorValuesAt(LocalDateTime t, Duration validDuration) {
        if (calls % period == 0) {
            cycleA = !cycleA;
            data.clear();

            double min, max;
            if (cycleA) {
                min = a1;
                max = b1;
            } else {
                min = a2;
                max = b2;
            }

            for (int i = 0; i < n; ++i) {
                double randomDouble = min + (max - min) * CommonState.r.nextDouble();
                data.put(Integer.toString(i), new Observation(t, randomDouble));
            }
        }
        calls++;
        return data;
    }
}