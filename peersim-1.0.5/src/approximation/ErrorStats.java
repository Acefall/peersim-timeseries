package approximation;

import java.util.ArrayList;

/**
 * Adds functionality for different types of errors.
 */
public class ErrorStats {
    /**
     * Structure to store each entry.
     */
    protected ArrayList<Double> data = new ArrayList<Double>();

    public ErrorStats() {
        reset();
    }

    public void add(double item) {
        data.add(item);
    }

    public void reset() {
        data.clear();
    }

    public double getMse(double groundTruth) {
        double squaredError = 0;
        for (Double entry : data) {
            squaredError += Math.pow(groundTruth - entry, 2);
        }
        return squaredError / data.size();
    }

    public double getMae(double groundTruth) {
        double absoluteError = 0;
        for (Double entry : data) {
            absoluteError += Math.abs(groundTruth - entry);
        }
        return absoluteError / data.size();
    }
}
