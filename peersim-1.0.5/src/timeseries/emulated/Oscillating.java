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
 * Synthetic data source which has a change point every 'period' number of rounds.
 * All sensors have the same value at all times. At every odd change point the values of the sensors change from a to b
 * and at every even change point the values change from b to a.
 * The change points are depending on the number of calls to the data source and not the time t.
 * Values are always valid.
 */

public class Oscillating implements IDataSource {
    private static final String PAR_A = "a";
    private static final String PAR_B = "b";
    private static final String PAR_PERIOD = "period";


    private final int n;
    private final double a;
    private final double b;
    private final int period;
    private int calls = 0;
    private boolean cycleA = true;

    public Oscillating(double a, double b, int period, int n) {
        this.n = n;
        this.a = a;
        this.period = period;
        this.b = b;
    }

    public Oscillating(String name) {
        a = Configuration.getDouble(name + "." + PAR_A);
        b = Configuration.getDouble(name + "." + PAR_B);
        period = Configuration.getInt(name + "." + PAR_PERIOD);
        n = Network.size();
    }


    @Override
    public HashMap<String, Observation> sensorValuesAt(LocalDateTime t, Duration validDuration) {
        HashMap<String, Observation> result = new HashMap<String, Observation>();
        for (int i = 0; i < n; i++) {
            if (cycleA) {
                result.put(Integer.toString(i), new Observation(t, a));
            } else {
                result.put(Integer.toString(i), new Observation(t, b));
            }
        }
        if (calls % period == 0) {
            cycleA = !cycleA;
        }
        calls++;
        return result;
    }
}
