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
 * Synthetic data source which has one change point. All sensors have the same value at all times.
 * Before the change point all sensors have value a, after the change point the sensor have value b.
 * The change point is depending on the number of calls to the data source and not the time t.
 * Values are always valid.
 */

public class ChangePoint implements IDataSource {
    private static final String PAR_A = "a";
    private static final String PAR_B = "b";
    private static final String PAR_CHANGE_POINT = "changePoint";


    private final int n;
    private final double a;
    private final double b;
    private final int changePoint;
    private int calls = 0;

    public ChangePoint(double a, double b, int changePoint, int n) {
        this.n = n;
        this.a = a;
        this.changePoint = changePoint;
        this.b = b;
    }

    public ChangePoint(String name) {
        a = Configuration.getDouble(name + "." + PAR_A);
        b = Configuration.getDouble(name + "." + PAR_B);
        changePoint = Configuration.getInt(name + "." + PAR_CHANGE_POINT);
        n = Network.size();
    }


    @Override
    public HashMap<String, Observation> sensorValuesAt(LocalDateTime t, Duration validDuration) {
        HashMap<String, Observation> result = new HashMap<String, Observation>();
        for (int i = 0; i < n; i++) {
            if (calls < changePoint) {
                result.put(Integer.toString(i), new Observation(t, a));
            } else {
                result.put(Integer.toString(i), new Observation(t, b));
            }
        }
        calls++;
        return result;
    }
}